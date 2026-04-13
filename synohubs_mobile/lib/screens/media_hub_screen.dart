import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../services/session_manager.dart';
import '../services/tmdb_service.dart';
import 'video_player_screen.dart';
import '../l10n/app_localizations.dart';

/// Media file entry from FileStation.
class _MediaFile {
  final String path;
  final String name;
  final String folderName; // immediate parent folder display name
  final bool isDir;
  final int size;
  final int mtime;

  const _MediaFile({
    required this.path,
    required this.name,
    this.folderName = '',
    this.isDir = false,
    this.size = 0,
    this.mtime = 0,
  });

  bool get isVideo {
    final l = name.toLowerCase();
    return l.endsWith('.mp4') ||
        l.endsWith('.mkv') ||
        l.endsWith('.avi') ||
        l.endsWith('.mov') ||
        l.endsWith('.wmv') ||
        l.endsWith('.flv') ||
        l.endsWith('.m4v') ||
        l.endsWith('.ts') ||
        l.endsWith('.webm');
  }

  bool get isImage {
    final l = name.toLowerCase();
    return l.endsWith('.jpg') ||
        l.endsWith('.jpeg') ||
        l.endsWith('.png') ||
        l.endsWith('.gif') ||
        l.endsWith('.bmp') ||
        l.endsWith('.webp');
  }

  bool get isAudio {
    final l = name.toLowerCase();
    return l.endsWith('.mp3') ||
        l.endsWith('.flac') ||
        l.endsWith('.wav') ||
        l.endsWith('.aac') ||
        l.endsWith('.ogg') ||
        l.endsWith('.m4a');
  }

  bool get isMedia => isVideo || isImage || isAudio;

  /// Clean file name for display (remove extension + replace dots/underscores).
  String get displayName {
    final dot = name.lastIndexOf('.');
    var clean = dot > 0 ? name.substring(0, dot) : name;
    clean = clean.replaceAll('.', ' ').replaceAll('_', ' ');
    return clean;
  }
}

class MediaHubScreen extends StatefulWidget {
  const MediaHubScreen({super.key});

  @override
  State<MediaHubScreen> createState() => _MediaHubScreenState();
}

class _MediaHubScreenState extends State<MediaHubScreen> {
  // Selected media folder
  String? _selectedFolder;
  String? _selectedFolderName;

  // All media found by recursive scan
  List<_MediaFile> _allMedia = [];
  // Grouped by parent folder name
  Map<String, List<_MediaFile>> _folderGroups = {};

  // Scan state
  bool _scanning = false;
  String _scanStatus = '';
  int _scanCount = 0;
  String? _error;

  // TMDB covers
  final Map<String, String?> _tmdbPosters = {};
  final Map<String, String?> _tmdbBackdrops = {};

  // Folder picker state
  List<_FolderEntry> _shares = [];
  bool _sharesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShares();
    _loadTmdbApiKey();
  }

  // ── Data loading ─────────────────────────────────────────────

  Future<void> _loadTmdbApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('tmdb_api_key');
    if (key != null && key.isNotEmpty) {
      TmdbService.instance.setApiKey(key);
    }
  }

  Future<void> _saveTmdbApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tmdb_api_key', key);
    TmdbService.instance.setApiKey(key);
    if (_allMedia.isNotEmpty) {
      _fetchTmdbCovers();
    }
  }

  Future<void> _fetchTmdbCovers() async {
    if (!TmdbService.instance.isConfigured) return;
    final tmdb = TmdbService.instance;
    final seen = <String>{};

    for (final file in _allMedia.where((f) => f.isVideo)) {
      if (!mounted) return;
      final parsed = TmdbService.parseMediaName(file.name);
      if (parsed.isEmpty || seen.contains(parsed)) continue;
      seen.add(parsed);

      final poster = await tmdb.getPosterUrl(file.name);
      final backdrop = await tmdb.getBackdropUrl(file.name);
      if (mounted) {
        setState(() {
          if (poster != null) _tmdbPosters[parsed] = poster;
          if (backdrop != null) _tmdbBackdrops[parsed] = backdrop;
        });
      }
    }
  }

  String? _getTmdbPoster(_MediaFile file) {
    final parsed = TmdbService.parseMediaName(file.name);
    return _tmdbPosters[parsed];
  }

  String? _getTmdbBackdrop(_MediaFile file) {
    final parsed = TmdbService.parseMediaName(file.name);
    return _tmdbBackdrops[parsed];
  }

  Future<void> _loadShares() async {
    final api = SessionManager.instance.api;
    if (api == null) return;
    try {
      final resp = await api.listSharedFolders();
      if (resp['success'] == true) {
        final shares = (resp['data']?['shares'] as List? ?? []);
        setState(() {
          _shares = shares.map((s) {
            final m = s as Map<String, dynamic>;
            return _FolderEntry(
              path: m['path'] as String? ?? '/${m['name']}',
              name: m['name'] as String? ?? '',
            );
          }).toList();
          _sharesLoading = false;
        });
      } else {
        setState(() => _sharesLoading = false);
      }
    } catch (e) {
      setState(() => _sharesLoading = false);
    }
  }

  Future<void> _selectFolder(String path, String name) async {
    setState(() {
      _selectedFolder = path;
      _selectedFolderName = name;
    });
    Navigator.of(context).pop();
    await _scanFolder(path, name);
  }

  Future<void> _scanFolder(String rootPath, String rootName) async {
    final l = AppLocalizations.of(context)!;
    setState(() {
      _scanning = true;
      _scanStatus = l.startingScan;
      _scanCount = 0;
      _allMedia = [];
      _folderGroups = {};
      _error = null;
    });

    try {
      await _scanRecursive(rootPath, rootName, 0);
      // Sort all media by mtime descending (newest first)
      _allMedia.sort((a, b) => b.mtime.compareTo(a.mtime));
      if (mounted) setState(() => _scanning = false);
      // Fetch TMDB covers in background
      _fetchTmdbCovers();
    } catch (e) {
      if (mounted) {
        setState(() {
          _scanning = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _scanRecursive(
    String folderPath,
    String folderDisplayName,
    int depth,
  ) async {
    if (depth > 3 || !mounted) return;
    final api = SessionManager.instance.api;
    if (api == null) return;

    if (mounted) {
      setState(() => _scanStatus = folderDisplayName);
    }

    final resp = await api.listFiles(folderPath: folderPath, limit: 500);
    if (resp['success'] != true) return;

    final files = (resp['data']?['files'] as List? ?? []);
    final subFolders = <_SubFolder>[];

    for (final f in files) {
      final m = f as Map<String, dynamic>;
      if (m['isdir'] == true) {
        subFolders.add(
          _SubFolder(
            path: m['path'] as String? ?? '',
            name: m['name'] as String? ?? '',
          ),
        );
      } else {
        final entry = _parseMediaFile(m, folderDisplayName);
        if (entry != null && entry.isMedia) {
          _allMedia.add(entry);
          _folderGroups.putIfAbsent(folderDisplayName, () => []).add(entry);
          _scanCount++;
          // Update UI every 10 files to avoid excessive rebuilds
          if (_scanCount % 10 == 0 && mounted) {
            setState(() {});
          }
        }
      }
    }

    // Recurse into subfolders
    for (final sub in subFolders) {
      await _scanRecursive(sub.path, sub.name, depth + 1);
    }
  }

  _MediaFile? _parseMediaFile(Map<String, dynamic> m, String folderName) {
    final additional = m['additional'] is Map<String, dynamic>
        ? m['additional'] as Map<String, dynamic>
        : <String, dynamic>{};
    final sizeObj = additional['size'];
    int size = 0;
    if (sizeObj is Map<String, dynamic>) {
      size = (sizeObj['total'] as num?)?.toInt() ?? 0;
    } else if (sizeObj is num) {
      size = sizeObj.toInt();
    }
    final timeObj = additional['time'];
    int mtime = 0;
    if (timeObj is Map<String, dynamic>) {
      mtime = (timeObj['mtime'] as num?)?.toInt() ?? 0;
    } else if (timeObj is num) {
      mtime = timeObj.toInt();
    }
    final name = m['name'] as String? ?? '';
    if (name.isEmpty) return null;
    return _MediaFile(
      path: m['path'] as String? ?? '',
      name: name,
      folderName: folderName,
      isDir: false,
      size: size,
      mtime: mtime,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────

  String _formatSize(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  void _showTmdbKeyDialog() {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: TmdbService.instance.apiKey ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.movie_filter, color: AppColors.tertiary, size: 22),
            const SizedBox(width: 10),
            Text(
              l.tmdbApiKey,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.tmdbApiKeyInstructions,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l.tmdbApiKeyHelp,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.onSurface,
              ),
              decoration: InputDecoration(
                hintText: l.tmdbApiKeyHint,
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: AppColors.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l.cancel,
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
            ),
          ),
          FilledButton(
            onPressed: () {
              final key = controller.text.trim();
              _saveTmdbApiKey(key);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: AppColors.onPrimary,
            ),
            child: Text(
              l.save,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showFolderPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _FolderPickerSheet(
        shares: _shares,
        isLoading: _sharesLoading,
        onSelect: _selectFolder,
      ),
    );
  }

  void _playVideo(_MediaFile file) {
    final api = SessionManager.instance.api;
    if (api == null) return;
    final url = api.getDownloadUrl(file.path, mode: 'open');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(url: url, title: file.displayName),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_selectedFolder == null) {
      body = _buildNoFolderSelected();
    } else if (_scanning) {
      body = _buildScanningState();
    } else if (_error != null) {
      body = _buildErrorState();
    } else {
      body = _buildMediaLibrary();
    }

    return Stack(
      children: [
        body,
        // Floating settings button (top-right)
        if (_selectedFolder != null && !_scanning)
          Positioned(top: 8, right: 8, child: _buildMediaSettingsButton()),
      ],
    );
  }

  Widget _buildMediaSettingsButton() {
    final l = AppLocalizations.of(context)!;
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.15),
          ),
        ),
        child: const Icon(
          Icons.more_vert,
          size: 18,
          color: AppColors.onSurface,
        ),
      ),
      color: AppColors.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: const Offset(0, 42),
      onSelected: (value) {
        switch (value) {
          case 'folder':
            _showFolderPicker();
            break;
          case 'tmdb':
            _showTmdbKeyDialog();
            break;
          case 'rescan':
            if (_selectedFolder != null) {
              _scanFolder(_selectedFolder!, _selectedFolderName ?? '');
            }
            break;
        }
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(
          value: 'folder',
          child: Row(
            children: [
              const Icon(Icons.folder_open, size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                l.changeFolder,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'tmdb',
          child: Row(
            children: [
              Icon(
                Icons.movie_filter,
                size: 18,
                color: TmdbService.instance.isConfigured
                    ? AppColors.tertiary
                    : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Text(
                TmdbService.instance.isConfigured
                    ? l.tmdbKeyConfigured
                    : l.setTmdbApiKey,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'rescan',
          child: Row(
            children: [
              const Icon(Icons.refresh, size: 18, color: AppColors.secondary),
              const SizedBox(width: 10),
              Text(
                l.rescanFolder,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── No folder selected ──

  Widget _buildNoFolderSelected() {
    final l = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.video_library,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l.mediaHub,
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.selectFolderDescription,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _showFolderPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryContainer],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.folder_open,
                    color: AppColors.onPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l.chooseFolder,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // TMDB key hint
          if (!TmdbService.instance.isConfigured)
            GestureDetector(
              onTap: _showTmdbKeyDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.tertiary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.movie_filter,
                      size: 16,
                      color: AppColors.tertiary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l.addTmdbKeyHint,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Scanning progress ──

  Widget _buildScanningState() {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l.scanningMediaFiles,
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _scanStatus,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.mediaFilesFound(_scanCount),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Error state ──

  Widget _buildErrorState() {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  _scanFolder(_selectedFolder!, _selectedFolderName ?? ''),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
              ),
              child: Text(l.retry),
            ),
          ],
        ),
      ),
    );
  }

  // ── Netflix-style media library ──

  Widget _buildMediaLibrary() {
    final l = AppLocalizations.of(context)!;
    final videos = _allMedia.where((f) => f.isVideo).toList();
    final images = _allMedia.where((f) => f.isImage).toList();
    final audio = _allMedia.where((f) => f.isAudio).toList();
    final featured = videos.isNotEmpty ? videos.first : null;

    return RefreshIndicator(
      onRefresh: () => _scanFolder(_selectedFolder!, _selectedFolderName ?? ''),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero section
            if (featured != null) _buildHeroSection(featured),

            // Folder header + stats
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _buildFolderHeader(),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildStatsRow(videos.length, images.length, audio.length),
            ),

            // Recently Added (newest 15 media)
            if (_allMedia.isNotEmpty) ...[
              const SizedBox(height: 28),
              _buildHorizontalSection(
                l.recentlyAdded,
                l.newestFilesSubtitle,
                Icons.schedule,
                AppColors.tertiary,
                _allMedia.take(15).toList(),
              ),
            ],

            // Per-folder rows
            ..._folderGroups.entries.where((e) => e.value.length > 1).map((e) {
              return Padding(
                padding: const EdgeInsets.only(top: 28),
                child: _buildHorizontalSection(
                  e.key,
                  l.nFiles(e.value.length),
                  Icons.folder,
                  AppColors.primary,
                  e.value,
                ),
              );
            }),

            // All Videos section
            if (videos.length > 1) ...[
              const SizedBox(height: 28),
              _buildHorizontalSection(
                l.allVideos,
                l.nVideos(videos.length),
                Icons.play_circle,
                AppColors.primaryContainer,
                videos,
              ),
            ],

            // Images section
            if (images.isNotEmpty) ...[
              const SizedBox(height: 28),
              _buildHorizontalSection(
                l.imagesLabel,
                l.nImages(images.length),
                Icons.image,
                AppColors.secondary,
                images,
              ),
            ],

            // Audio section
            if (audio.isNotEmpty) ...[
              const SizedBox(height: 28),
              _buildHorizontalSection(
                l.audioLabel,
                l.nTracks(audio.length),
                Icons.music_note,
                AppColors.tertiary,
                audio,
              ),
            ],

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ── Hero section ──

  Widget _buildHeroSection(_MediaFile featured) {
    final l = AppLocalizations.of(context)!;
    final api = SessionManager.instance.api;
    final thumbUrl = api?.getThumbnailUrl(featured.path, size: 'large');
    // Prefer TMDB backdrop over NAS thumbnail for videos
    final backdropUrl = featured.isVideo ? _getTmdbBackdrop(featured) : null;
    final heroImageUrl = backdropUrl ?? thumbUrl;
    final sw = MediaQuery.of(context).size.width;
    final heroHeight = (sw * 1.2).clamp(360.0, 560.0);

    return SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image (TMDB backdrop or NAS thumbnail)
          if (heroImageUrl != null)
            Image.network(
              heroImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surfaceContainerHigh,
                child: const Center(
                  child: Icon(
                    Icons.movie,
                    size: 64,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryContainer.withValues(alpha: 0.3),
                    AppColors.surface,
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.movie,
                  size: 64,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),

          // Gradient overlays
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppColors.surface,
                  AppColors.surface.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.surface.withValues(alpha: 0.7),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Content
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: AppColors.tertiary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l.latest,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color: AppColors.tertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  featured.displayName,
                  style: GoogleFonts.manrope(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Meta info
                Row(
                  children: [
                    if (featured.size > 0) ...[
                      Text(
                        _formatSize(featured.size),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      _dot(),
                    ],
                    Text(
                      featured.folderName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    _dot(),
                    Text(
                      featured.name.split('.').last.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _playVideo(featured),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryContainer,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.play_arrow,
                                color: AppColors.onPrimary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l.play,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _showFolderPicker,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerHighest.withValues(
                            alpha: 0.6,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.outlineVariant.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: const Icon(
                          Icons.folder_open,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 4,
        height: 4,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.outlineVariant,
        ),
      ),
    );
  }

  // ── Compact folder header ──

  Widget _buildFolderHeader() {
    final l = AppLocalizations.of(context)!;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.folder, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedFolderName ?? '',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                l.mediaFilesFound(_allMedia.length),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _showTmdbKeyDialog,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: TmdbService.instance.isConfigured
                  ? AppColors.tertiary.withValues(alpha: 0.1)
                  : AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.movie_filter,
              size: 16,
              color: TmdbService.instance.isConfigured
                  ? AppColors.tertiary
                  : AppColors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _showFolderPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              l.change,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Stats row ──

  Widget _buildStatsRow(int vCount, int iCount, int aCount) {
    final l = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _statChip(
            Icons.play_circle,
            '$vCount',
            l.videosLabel,
            AppColors.primaryContainer,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statChip(
            Icons.image,
            '$iCount',
            l.imagesLabel,
            AppColors.secondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statChip(
            Icons.music_note,
            '$aCount',
            l.audioLabel,
            AppColors.tertiary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statChip(
            Icons.folder,
            '${_folderGroups.length}',
            l.foldersLabel,
            AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _statChip(IconData icon, String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            count,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── Horizontal media section (Netflix-style row) ──

  Widget _buildHorizontalSection(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    List<_MediaFile> files,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: files.length > 20 ? 20 : files.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) => _buildMediaCard(files[i]),
          ),
        ),
      ],
    );
  }

  // ── Media card (poster-style) ──

  Widget _buildMediaCard(_MediaFile file) {
    final api = SessionManager.instance.api;
    final thumbUrl = api?.getThumbnailUrl(file.path, size: 'small');
    // Prefer TMDB poster for videos
    final posterUrl = file.isVideo ? _getTmdbPoster(file) : null;
    final imageUrl = posterUrl ?? thumbUrl;

    return GestureDetector(
      onTap: file.isVideo ? () => _playVideo(file) : null,
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Thumbnail (TMDB poster or NAS thumbnail)
                    if (imageUrl != null && (file.isImage || file.isVideo))
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildMediaPlaceholder(file),
                      )
                    else
                      _buildMediaPlaceholder(file),

                    // Play overlay for videos
                    if (file.isVideo)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            size: 14,
                            color: AppColors.primaryContainer,
                          ),
                        ),
                      ),

                    // Size badge
                    if (file.size > 0)
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceDim.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _formatSize(file.size),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              file.displayName,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              file.folderName,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPlaceholder(_MediaFile file) {
    IconData icon;
    Color color;
    if (file.isVideo) {
      icon = Icons.movie;
      color = AppColors.primaryContainer;
    } else if (file.isAudio) {
      icon = Icons.music_note;
      color = AppColors.tertiary;
    } else {
      icon = Icons.image;
      color = AppColors.secondary;
    }
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: Center(
        child: Icon(icon, size: 32, color: color.withValues(alpha: 0.5)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Helper classes
// ═══════════════════════════════════════════════════════════════════
class _FolderEntry {
  final String path;
  final String name;
  const _FolderEntry({required this.path, required this.name});
}

class _SubFolder {
  final String path;
  final String name;
  const _SubFolder({required this.path, required this.name});
}

// ═══════════════════════════════════════════════════════════════════
// Folder Picker Bottom Sheet
// ═══════════════════════════════════════════════════════════════════
class _FolderPickerSheet extends StatefulWidget {
  final List<_FolderEntry> shares;
  final bool isLoading;
  final void Function(String path, String name) onSelect;

  const _FolderPickerSheet({
    required this.shares,
    required this.isLoading,
    required this.onSelect,
  });

  @override
  State<_FolderPickerSheet> createState() => _FolderPickerSheetState();
}

class _FolderPickerSheetState extends State<_FolderPickerSheet> {
  String? _currentPath;
  String? _currentName;
  List<_FolderEntry> _currentFolders = [];
  bool _loading = false;
  final List<_FolderEntry> _breadcrumbs = [];

  Future<void> _openFolder(String path, String name) async {
    setState(() {
      _loading = true;
      if (_currentPath != null) {
        _breadcrumbs.add(
          _FolderEntry(path: _currentPath!, name: _currentName ?? ''),
        );
      }
      _currentPath = path;
      _currentName = name;
    });

    final api = SessionManager.instance.api;
    if (api == null) return;

    try {
      final resp = await api.listFiles(folderPath: path, fileType: 'dir');
      if (resp['success'] == true) {
        final files = (resp['data']?['files'] as List? ?? []);
        setState(() {
          _currentFolders = files
              .where((f) => (f as Map<String, dynamic>)['isdir'] == true)
              .map((f) {
                final m = f as Map<String, dynamic>;
                return _FolderEntry(
                  path: m['path'] as String? ?? '',
                  name: m['name'] as String? ?? '',
                );
              })
              .toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _goBack() {
    if (_breadcrumbs.isEmpty) {
      setState(() {
        _currentPath = null;
        _currentName = null;
        _currentFolders = [];
      });
    } else {
      final prev = _breadcrumbs.removeLast();
      _currentPath = null;
      _currentName = null;
      _openFolder(prev.path, prev.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.65,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                if (_currentPath != null)
                  GestureDetector(
                    onTap: _goBack,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.arrow_back,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    _currentPath == null
                        ? l.selectMediaFolder
                        : _currentName ?? '',
                    style: GoogleFonts.manrope(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_currentPath != null)
                  GestureDetector(
                    onTap: () =>
                        widget.onSelect(_currentPath!, _currentName ?? ''),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primaryContainer,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        l.select,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(color: AppColors.outlineVariant, height: 1),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _currentPath == null
                ? _buildSharesList()
                : _buildFolderList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSharesList() {
    final l = AppLocalizations.of(context)!;
    if (widget.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.shares.length,
      itemBuilder: (ctx, i) {
        final share = widget.shares[i];
        return ListTile(
          leading: const Icon(Icons.folder_shared, color: AppColors.primary),
          title: Text(
            share.name,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          subtitle: Text(
            share.path,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => widget.onSelect(share.path, share.name),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l.select,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
          onTap: () => _openFolder(share.path, share.name),
        );
      },
    );
  }

  Widget _buildFolderList() {
    final l = AppLocalizations.of(context)!;
    if (_currentFolders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.folder_open,
              size: 48,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              l.noSubfolders,
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              l.tapSelectHint,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _currentFolders.length,
      itemBuilder: (ctx, i) {
        final folder = _currentFolders[i];
        return ListTile(
          leading: const Icon(Icons.folder, color: AppColors.primary),
          title: Text(
            folder.name,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => widget.onSelect(folder.path, folder.name),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l.select,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
          onTap: () => _openFolder(folder.path, folder.name),
        );
      },
    );
  }
}
