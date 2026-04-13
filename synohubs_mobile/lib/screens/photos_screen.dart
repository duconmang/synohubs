import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_colors.dart';
import '../services/session_manager.dart';
import '../l10n/app_localizations.dart';
import 'photo_viewer_screen.dart';

// Data models
class SynoPhoto {
  final int id;
  final String filename;
  final int filesize;
  final int time;
  final String type;
  final int? folderId;
  final int? ownerUserId;
  final String? thumbSmKey;
  final String? thumbMKey;
  final String? thumbXlKey;
  final int? width;
  final int? height;
  final int? orientation;

  SynoPhoto({
    required this.id,
    required this.filename,
    required this.filesize,
    required this.time,
    required this.type,
    this.folderId,
    this.ownerUserId,
    this.thumbSmKey,
    this.thumbMKey,
    this.thumbXlKey,
    this.width,
    this.height,
    this.orientation,
  });

  DateTime get takenAt => DateTime.fromMillisecondsSinceEpoch(time * 1000);
  bool get isVideo => type == 'video';

  factory SynoPhoto.fromJson(Map<String, dynamic> j) {
    final add = j['additional'] as Map<String, dynamic>? ?? {};
    final thumb = add['thumbnail'] as Map<String, dynamic>? ?? {};
    final res = add['resolution'] as Map<String, dynamic>? ?? {};
    return SynoPhoto(
      id: j['id'] as int? ?? 0,
      filename: j['filename'] as String? ?? '',
      filesize: j['filesize'] as int? ?? 0,
      time: j['time'] as int? ?? 0,
      type: j['type'] as String? ?? 'photo',
      folderId: j['folder_id'] as int?,
      ownerUserId: j['owner_user_id'] as int?,
      thumbSmKey: thumb['sm'] as String?,
      thumbMKey: thumb['m'] as String?,
      thumbXlKey: thumb['xl'] as String?,
      width: res['width'] as int?,
      height: res['height'] as int?,
      orientation: add['orientation'] as int?,
    );
  }
}

class SynoAlbum {
  final int id;
  final String name;
  final int itemCount;
  final int? coverItemId;
  final String? coverCacheKey;
  final bool isShared;

  SynoAlbum({
    required this.id,
    required this.name,
    required this.itemCount,
    this.coverItemId,
    this.coverCacheKey,
    this.isShared = false,
  });

  factory SynoAlbum.fromJson(Map<String, dynamic> j, {bool shared = false}) {
    final add = j['additional'] as Map<String, dynamic>? ?? {};
    final thumb = add['thumbnail'] as Map<String, dynamic>? ?? {};
    int? coverId;
    String? coverKey;
    if (add['cover_item'] is Map) {
      final ci = add['cover_item'] as Map;
      coverId = ci['id'] as int?;
      final ct = ci['additional'] is Map
          ? ((ci['additional'] as Map)['thumbnail'] as Map?) ?? {}
          : {};
      coverKey = ct['m'] as String? ?? ct['sm'] as String?;
    }
    return SynoAlbum(
      id: j['id'] as int? ?? 0,
      name: j['name'] as String? ?? '',
      itemCount: j['item_count'] as int? ?? 0,
      coverItemId: coverId,
      coverCacheKey:
          coverKey ?? thumb['m'] as String? ?? thumb['sm'] as String?,
      isShared: shared,
    );
  }
}

// Photos Screen
class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});
  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabCtrl;

  // Timeline
  final List<SynoPhoto> _photos = [];
  bool _loading = false;
  bool _hasMore = true;
  int _offset = 0;
  String? _error;
  int _totalCount = 0;

  // Filter
  String _filterMode = 'all'; // 'all', 'photos', 'videos'

  // Recently Added
  final List<SynoPhoto> _recentPhotos = [];

  // Favorites (tracked by photo id)
  final Set<int> _favoriteIds = {};

  // Albums
  final List<SynoAlbum> _albums = [];
  bool _albumsLoading = false;
  String? _albumsError;

  // Cached date groups (M2: avoid re-grouping on every build)
  Map<String, List<SynoPhoto>>? _cachedGroups;
  int _cachedGroupsLength = -1;

  // Selection
  bool _selectionMode = false;
  final Set<int> _selectedIds = {};

  // Search
  bool _showSearch = false;
  final TextEditingController _searchCtrl = TextEditingController();
  final List<SynoPhoto> _searchResults = [];
  bool _searchLoading = false;
  Timer? _searchDebounce;

  // Space
  bool _isShared = false;

  // Upload
  bool _uploading = false;
  int _uploadProgress = 0;
  int _uploadTotal = 0;
  String _uploadDest = '/photo/Upload';
  String _currentUploadFile = '';
  int _lastUploadSuccess = 0;

  final ScrollController _scrollCtrl = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _scrollCtrl.addListener(_onScroll);
    _loadPhotos();
    _loadAlbums();
    _loadRecentlyAdded();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 600) {
      _loadMore();
    }
  }

  List<SynoPhoto> get _filteredPhotos {
    if (_filterMode == 'photos')
      return _photos.where((p) => !p.isVideo).toList();
    if (_filterMode == 'videos')
      return _photos.where((p) => p.isVideo).toList();
    return _photos;
  }

  Future<void> _loadRecentlyAdded() async {
    final api = SessionManager.instance.api;
    if (api == null) return;
    try {
      final resp = await api.listPhotos(
        offset: 0,
        limit: 20,
        sortBy: 'takentime',
        sortDirection: 'desc',
        shared: _isShared,
      );
      if (resp['success'] == true) {
        final list = resp['data']?['list'] as List? ?? [];
        setState(() {
          _recentPhotos
            ..clear()
            ..addAll(
              list.map((e) => SynoPhoto.fromJson(e as Map<String, dynamic>)),
            );
        });
      }
    } catch (_) {}
  }

  Future<void> _loadPhotos() async {
    final api = SessionManager.instance.api;
    if (api == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _offset = 0;
      _photos.clear();
      _hasMore = true;
      _cachedGroups = null;
      _cachedGroupsLength = -1;
    });
    try {
      final countResp = await api.countPhotos(shared: _isShared);
      if (countResp['success'] == true) {
        _totalCount = (countResp['data']?['count'] as int?) ?? 0;
      }
      final resp = await api.listPhotos(
        offset: 0,
        limit: 100,
        shared: _isShared,
      );
      if (resp['success'] == true) {
        final list = resp['data']?['list'] as List? ?? [];
        final items = list
            .map((e) => SynoPhoto.fromJson(e as Map<String, dynamic>))
            .toList();
        setState(() {
          _photos.addAll(items);
          _offset = items.length;
          _hasMore = items.length >= 100;
          _loading = false;
        });
      } else {
        final code = resp['error']?['code'];
        setState(() {
          _error = 'Error $code';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    final api = SessionManager.instance.api;
    if (api == null) return;
    setState(() => _loading = true);
    try {
      final resp = await api.listPhotos(
        offset: _offset,
        limit: 100,
        shared: _isShared,
      );
      if (resp['success'] == true) {
        final list = resp['data']?['list'] as List? ?? [];
        final items = list
            .map((e) => SynoPhoto.fromJson(e as Map<String, dynamic>))
            .toList();
        setState(() {
          _photos.addAll(items);
          _offset += items.length;
          _hasMore = items.length >= 100;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _loadAlbums() async {
    final api = SessionManager.instance.api;
    if (api == null) return;
    setState(() => _albumsLoading = true);
    try {
      final resp = await api.listAlbums(shared: _isShared);
      if (resp['success'] == true) {
        final list = resp['data']?['list'] as List? ?? [];
        setState(() {
          _albums
            ..clear()
            ..addAll(
              list.map(
                (e) => SynoAlbum.fromJson(
                  e as Map<String, dynamic>,
                  shared: _isShared,
                ),
              ),
            );
          _albumsLoading = false;
          _albumsError = null;
        });
      } else {
        setState(() {
          _albumsLoading = false;
          _albumsError = 'Error';
        });
      }
    } catch (e) {
      setState(() {
        _albumsLoading = false;
        _albumsError = e.toString();
      });
    }
  }

  Future<void> _doSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults.clear());
      return;
    }
    final api = SessionManager.instance.api;
    if (api == null) return;
    setState(() => _searchLoading = true);
    try {
      final resp = await api.searchPhotos(
        keyword: query.trim(),
        shared: _isShared,
      );
      if (resp['success'] == true) {
        final list = resp['data']?['list'] as List? ?? [];
        setState(() {
          _searchResults
            ..clear()
            ..addAll(
              list.map((e) => SynoPhoto.fromJson(e as Map<String, dynamic>)),
            );
          _searchLoading = false;
        });
      } else {
        setState(() => _searchLoading = false);
      }
    } catch (e) {
      setState(() => _searchLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _onSearchChanged(String q) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 500),
      () => _doSearch(q),
    );
  }

  String? _thumbUrl(SynoPhoto p, {String size = 'm'}) {
    final api = SessionManager.instance.api;
    if (api == null) return null;
    final key = size == 'sm'
        ? p.thumbSmKey
        : size == 'xl'
        ? p.thumbXlKey
        : p.thumbMKey;
    if (key == null) return null;
    return api.getPhotoThumbUrl(p.id, key, size: size, shared: _isShared);
  }

  void _openViewer(List<SynoPhoto> photos, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PhotoViewerScreen(
          photos: photos,
          initialIndex: index,
          isShared: _isShared,
          favoriteIds: _favoriteIds,
          onFavoriteToggle: (id, isFav) {
            setState(() {
              if (isFav) {
                _favoriteIds.add(id);
              } else {
                _favoriteIds.remove(id);
              }
            });
          },
          onDeleted: (ids) {
            setState(() {
              _photos.removeWhere((p) => ids.contains(p.id));
              _totalCount -= ids.length;
            });
          },
        ),
      ),
    );
  }

  Future<void> _deleteSelected() async {
    final l = AppLocalizations.of(context)!;
    if (_selectedIds.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l.deletePhotosTitle(_selectedIds.length),
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        content: Text(
          l.deletePhotosMessage,
          style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l.delete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final api = SessionManager.instance.api;
    if (api == null) return;
    try {
      await api.deletePhotos(ids: _selectedIds.toList(), shared: _isShared);
      setState(() {
        _photos.removeWhere((p) => _selectedIds.contains(p.id));
        _totalCount -= _selectedIds.length;
        _selectedIds.clear();
        _selectionMode = false;
      });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _addSelectedToAlbum() async {
    final l = AppLocalizations.of(context)!;
    if (_selectedIds.isEmpty || _albums.isEmpty) return;
    final album = await showDialog<SynoAlbum>(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l.addToAlbum,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        children: _albums
            .map(
              (a) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, a),
                child: Text(
                  a.name,
                  style: GoogleFonts.inter(color: AppColors.onSurface),
                ),
              ),
            )
            .toList(),
      ),
    );
    if (album == null) return;
    final api = SessionManager.instance.api;
    if (api == null) return;
    try {
      await api.addItemsToAlbum(
        albumId: album.id,
        itemIds: _selectedIds.toList(),
      );
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.addedToAlbumN(album.name))));
      setState(() {
        _selectedIds.clear();
        _selectionMode = false;
      });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _uploadPhotos() async {
    final l = AppLocalizations.of(context)!;
    final api = SessionManager.instance.api;
    if (api == null) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.media,
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _uploading = true;
      _uploadProgress = 0;
      _uploadTotal = result.files.length;
      _currentUploadFile = '';
      _lastUploadSuccess = 0;
    });
    int success = 0;
    for (final file in result.files) {
      if (file.bytes == null || file.name.isEmpty) continue;
      setState(() => _currentUploadFile = file.name);
      try {
        await api.uploadPhotoViaFS(
          destFolder: _uploadDest,
          fileName: file.name,
          fileBytes: file.bytes!,
        );
        success++;
      } catch (_) {
        // Individual file upload failure — continue with remaining files
      }
      setState(() => _uploadProgress++);
    }
    setState(() {
      _uploading = false;
      _lastUploadSuccess = success;
    });
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.uploadedNPhotos(success))));
    _loadPhotos();
  }

  Future<void> _pickUploadDest() async {
    final api = SessionManager.instance.api;
    if (api == null) return;
    final l = AppLocalizations.of(context)!;

    List<Map<String, dynamic>> folders = [];
    try {
      final resp = await api.listPhotoFolders();
      if (resp['success'] == true) {
        folders = ((resp['data']?['list'] as List?) ?? [])
            .cast<Map<String, dynamic>>();
      }
    } catch (_) {}

    if (!mounted) return;

    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l.selectUploadDest,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.folder, color: AppColors.primary),
                title: Text(
                  '/photo/Upload',
                  style: GoogleFonts.inter(
                    color: AppColors.onSurface,
                    fontSize: 14,
                  ),
                ),
                trailing: _uploadDest == '/photo/Upload'
                    ? const Icon(
                        Icons.check_circle,
                        color: AppColors.primary,
                        size: 20,
                      )
                    : null,
                onTap: () => Navigator.pop(ctx, '/photo/Upload'),
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              ...folders.take(10).map((f) {
                final name = f['name'] as String? ?? '';
                final path = '/photo/$name';
                return ListTile(
                  leading: const Icon(
                    Icons.folder_outlined,
                    color: AppColors.secondary,
                  ),
                  title: Text(
                    path,
                    style: GoogleFonts.inter(
                      color: AppColors.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  trailing: _uploadDest == path
                      ? const Icon(
                          Icons.check_circle,
                          color: AppColors.primary,
                          size: 20,
                        )
                      : null,
                  onTap: () => Navigator.pop(ctx, path),
                  dense: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );

    if (picked != null && mounted) {
      setState(() => _uploadDest = picked);
    }
  }

  Future<void> _createAlbum() async {
    final l = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l.createAlbum,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: GoogleFonts.inter(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: l.albumName,
            hintStyle: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
            child: Text(l.create),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final api = SessionManager.instance.api;
    if (api == null) return;
    try {
      await api.createPhotoAlbum(name);
      _loadAlbums();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _toggleSpace() {
    setState(() {
      _isShared = !_isShared;
      _selectedIds.clear();
      _selectionMode = false;
      _favoriteIds.clear();
    });
    _loadPhotos();
    _loadAlbums();
    _loadRecentlyAdded();
  }

  // Date grouping with cache (M2: avoid re-grouping on every build)
  Map<String, List<SynoPhoto>> _groupByDate(List<SynoPhoto> photos) {
    if (_cachedGroupsLength == photos.length && _cachedGroups != null) {
      return _cachedGroups!;
    }
    final groups = <String, List<SynoPhoto>>{};
    for (final p in photos) {
      final d = p.takenAt;
      final key =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      groups.putIfAbsent(key, () => []).add(p);
    }
    _cachedGroups = groups;
    _cachedGroupsLength = photos.length;
    return groups;
  }

  String _formatDateHeader(String key, AppLocalizations l) {
    final parts = key.split('-');
    if (parts.length != 3) return key;
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return l.today;
    if (d == yesterday) return l.yesterday;
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (d.year == now.year) return '${months[d.month]} ${d.day}';
    return '${months[d.month]} ${d.day}, ${d.year}';
  }

  // Build
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        if (_showSearch) _buildSearchBar(l),
        _buildTopBar(l),
        if (_selectionMode) _buildSelectionBar(l),
        if (_uploading) _buildUploadProgress(l),
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabCtrl,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.onSurfaceVariant,
            indicatorColor: AppColors.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
            tabs: [
              Tab(text: l.timeline),
              Tab(text: l.albumsTab),
              Tab(text: l.backup),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildTimelineTab(l),
              _buildAlbumsTab(l),
              _buildBackupTab(l),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.photos,
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                Text(
                  _isShared ? l.sharedSpace : l.personalSpace,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _toggleSpace,
            tooltip: _isShared ? l.personalSpace : l.sharedSpace,
            icon: Icon(
              _isShared ? Icons.people : Icons.person,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _showSearch = !_showSearch),
            icon: Icon(
              _showSearch ? Icons.close : Icons.search,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
          ),
          IconButton(
            onPressed: _uploading ? null : _uploadPhotos,
            icon: const Icon(
              Icons.cloud_upload_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        autofocus: true,
        style: GoogleFonts.inter(color: AppColors.onSurface, fontSize: 14),
        decoration: InputDecoration(
          hintText: l.searchPhotos,
          hintStyle: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.onSurfaceVariant,
          ),
          filled: true,
          fillColor: AppColors.surfaceContainerHigh,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildSelectionBar(AppLocalizations l) {
    return Container(
      color: AppColors.primaryContainer.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Text(
            l.nSelected(_selectedIds.length),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          if (_albums.isNotEmpty)
            IconButton(
              onPressed: _addSelectedToAlbum,
              icon: const Icon(
                Icons.photo_album_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              tooltip: l.addToAlbum,
            ),
          IconButton(
            onPressed: _deleteSelected,
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.error,
              size: 20,
            ),
            tooltip: l.delete,
          ),
          IconButton(
            onPressed: () => setState(() {
              _selectionMode = false;
              _selectedIds.clear();
            }),
            icon: const Icon(
              Icons.close,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadProgress(AppLocalizations l) {
    return Container(
      color: AppColors.surfaceContainerHigh,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l.uploadingProgress(_uploadProgress, _uploadTotal),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Timeline Tab
  Widget _buildTimelineTab(AppLocalizations l) {
    if (_showSearch && _searchCtrl.text.isNotEmpty)
      return _buildSearchResults(l);
    if (_error != null && _photos.isEmpty) return _buildErrorState(l);
    if (_photos.isEmpty && !_loading) return _buildEmptyState(l);

    final displayPhotos = _filteredPhotos;
    final groups = _groupByDate(displayPhotos);
    final keys = groups.keys.toList();

    return RefreshIndicator(
      onRefresh: () async {
        _loadPhotos();
        _loadRecentlyAdded();
      },
      color: AppColors.primary,
      child: CustomScrollView(
        controller: _scrollCtrl,
        cacheExtent: 800,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Filter chips
          SliverToBoxAdapter(child: _buildFilterChips(l)),
          // Recently Added section
          if (_recentPhotos.isNotEmpty && _filterMode == 'all')
            SliverToBoxAdapter(child: _buildRecentlyAdded(l)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                l.photoCount(_totalCount),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          for (final key in keys) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                child: Text(
                  _formatDateHeader(key, l),
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                ),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _buildPhotoTile(groups[key]![i], displayPhotos),
                  childCount: groups[key]!.length,
                ),
              ),
            ),
          ],
          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildFilterChips(AppLocalizations l) {
    Widget chip(String mode, String label) {
      final active = _filterMode == mode;
      return GestureDetector(
        onTap: () => setState(() {
          _filterMode = mode;
          _cachedGroups = null;
          _cachedGroupsLength = -1;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : AppColors.outlineVariant.withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: active ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          chip('all', l.allPhotos),
          const SizedBox(width: 8),
          chip('photos', l.photo),
          const SizedBox(width: 8),
          chip('videos', l.video),
        ],
      ),
    );
  }

  Widget _buildRecentlyAdded(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Text(
            l.recentlyAddedPhotos,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
              letterSpacing: 1.5,
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recentPhotos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) {
              final p = _recentPhotos[i];
              final url = _thumbUrl(p, size: 'xl');
              return GestureDetector(
                onTap: () => _openViewer(_recentPhotos, i),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 130,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (url != null)
                          CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: AppColors.surfaceContainerHigh,
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.surfaceContainerHigh,
                            ),
                          )
                        else
                          Container(color: AppColors.surfaceContainerHigh),
                        // Gradient overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 48,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Colors.black54, Colors.transparent],
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              p.filename,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (p.isVideo)
                          const Positioned(
                            top: 6,
                            right: 6,
                            child: Icon(
                              Icons.play_circle_filled,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(AppLocalizations l) {
    if (_searchLoading)
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    if (_searchResults.isEmpty)
      return Center(
        child: Text(
          l.noResultsFound,
          style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
        ),
      );
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (ctx, i) =>
          _buildPhotoTile(_searchResults[i], _searchResults),
    );
  }

  Widget _buildPhotoTile(SynoPhoto photo, List<SynoPhoto> allPhotos) {
    final url = _thumbUrl(photo, size: 'sm');
    final isSelected = _selectedIds.contains(photo.id);
    final idx = allPhotos.indexOf(photo);

    return GestureDetector(
      onTap: () {
        if (_selectionMode) {
          setState(() {
            if (isSelected) {
              _selectedIds.remove(photo.id);
              if (_selectedIds.isEmpty) _selectionMode = false;
            } else {
              _selectedIds.add(photo.id);
            }
          });
        } else {
          _openViewer(allPhotos, idx >= 0 ? idx : 0);
        }
      },
      onLongPress: () {
        if (!_selectionMode) {
          HapticFeedback.mediumImpact();
          setState(() {
            _selectionMode = true;
            _selectedIds.add(photo.id);
          });
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url != null)
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(color: AppColors.surfaceContainerHigh),
              errorWidget: (_, __, ___) => _photoPlaceholder(photo),
            )
          else
            _photoPlaceholder(photo),
          if (photo.isVideo)
            const Positioned(
              bottom: 4,
              right: 4,
              child: Icon(
                Icons.play_circle_filled,
                color: Colors.white,
                size: 18,
              ),
            ),
          if (_favoriteIds.contains(photo.id) && !_selectionMode)
            const Positioned(
              top: 4,
              right: 4,
              child: Icon(Icons.favorite, color: Colors.white, size: 14),
            ),
          if (_selectionMode)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : Colors.black38,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder(SynoPhoto p) {
    return Container(
      color: AppColors.surfaceContainerHigh,
      child: Center(
        child: Icon(
          p.isVideo ? Icons.videocam : Icons.image,
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations l) {
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
            Text(
              l.photosApiHint,
              style: GoogleFonts.inter(
                color: AppColors.onSurfaceVariant,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPhotos,
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

  Widget _buildEmptyState(AppLocalizations l) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.photo_library,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l.noPhotosTitle,
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.noPhotosSubtitle,
              style: GoogleFonts.inter(
                color: AppColors.onSurfaceVariant,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _uploadPhotos,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryContainer],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_upload,
                      color: AppColors.onPrimary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l.uploadPhotos,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Albums Tab
  Widget _buildAlbumsTab(AppLocalizations l) {
    if (_albumsLoading && _albums.isEmpty)
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    if (_albumsError != null && _albums.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                _albumsError!,
                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAlbums,
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
    return RefreshIndicator(
      onRefresh: () async => _loadAlbums(),
      color: AppColors.primary,
      child: _albums.isEmpty
          ? _buildEmptyAlbums(l)
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: _albums.length + 1,
              itemBuilder: (ctx, i) => i == 0
                  ? _buildCreateAlbumCard(l)
                  : _buildAlbumCard(_albums[i - 1], l),
            ),
    );
  }

  Widget _buildCreateAlbumCard(AppLocalizations l) {
    return GestureDetector(
      onTap: _createAlbum,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.add, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              l.createAlbum,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumCard(SynoAlbum album, AppLocalizations l) {
    final api = SessionManager.instance.api;
    String? coverUrl;
    if (api != null &&
        album.coverItemId != null &&
        album.coverCacheKey != null) {
      coverUrl = api.getPhotoThumbUrl(
        album.coverItemId!,
        album.coverCacheKey!,
        size: 'm',
        shared: album.isShared,
      );
    }
    return GestureDetector(
      onTap: () => _openAlbum(album),
      onLongPress: () => _showAlbumOptions(album, l),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.surfaceContainerLow,
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.1),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: AppColors.surfaceContainerHigh,
                child: coverUrl != null
                    ? CachedNetworkImage(
                        imageUrl: coverUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.photo_album,
                            color: AppColors.onSurfaceVariant,
                            size: 32,
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.photo_album,
                          color: AppColors.onSurfaceVariant,
                          size: 32,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.name,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.photoCount(album.itemCount),
                    style: GoogleFonts.inter(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAlbum(SynoAlbum album) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AlbumDetailScreen(
          album: album,
          isShared: _isShared,
          onChanged: _loadAlbums,
        ),
      ),
    );
  }

  void _showAlbumOptions(SynoAlbum album, AppLocalizations l) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: AppColors.primary,
              ),
              title: Text(
                l.renameAlbum,
                style: GoogleFonts.inter(color: AppColors.onSurface),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _renameAlbum(album, l);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: Text(
                l.deleteAlbum,
                style: GoogleFonts.inter(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteAlbum(album, l);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _renameAlbum(SynoAlbum album, AppLocalizations l) async {
    final nameCtrl = TextEditingController(text: album.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l.renameAlbum,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: GoogleFonts.inter(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: l.albumName,
            hintStyle: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()),
            child: Text(l.save),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == album.name) return;
    final api = SessionManager.instance.api;
    if (api == null) return;
    try {
      await api.renamePhotoAlbum(id: album.id, name: newName);
      _loadAlbums();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _confirmDeleteAlbum(SynoAlbum album, AppLocalizations l) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l.deleteAlbum,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        content: Text(
          l.deleteAlbumMessage(album.name),
          style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l.delete,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final api = SessionManager.instance.api;
    if (api == null) return;
    try {
      await api.deletePhotoAlbum(album.id);
      _loadAlbums();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Widget _buildEmptyAlbums(AppLocalizations l) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              const Icon(
                Icons.photo_album_outlined,
                size: 48,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                l.noAlbums,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.createAlbumHint,
                style: GoogleFonts.inter(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _createAlbum,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    l.createAlbum,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Backup Tab
  Widget _buildBackupTab(AppLocalizations l) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.08),
                  AppColors.primaryContainer.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.cloud_upload,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.backupPhotos,
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l.backupPhotosDesc,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Upload progress card
          if (_uploading) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l.uploadingProgress(_uploadProgress, _uploadTotal),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_currentUploadFile.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _currentUploadFile,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _uploadTotal > 0
                          ? _uploadProgress / _uploadTotal
                          : null,
                      backgroundColor: AppColors.outlineVariant.withValues(
                        alpha: 0.2,
                      ),
                      color: AppColors.primary,
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Destination folder picker
          const SizedBox(height: 24),
          Text(
            l.uploadDestination,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _uploading ? null : _pickUploadDest,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _uploadDest,
                      style: GoogleFonts.inter(
                        color: AppColors.onSurface,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    l.change,
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Manual upload section
          const SizedBox(height: 24),
          Text(
            l.manualUpload,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          // Upload photos/videos button
          GestureDetector(
            onTap: _uploading ? null : _uploadPhotos,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate,
                      color: AppColors.secondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.selectMediaToUpload,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l.uploadToNasDest(_uploadDest),
                          style: GoogleFonts.inter(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Last upload result
          if (_lastUploadSuccess > 0 && !_uploading) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.lastUploadResult(_lastUploadSuccess),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Info hint
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.tertiary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.tertiary.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.tertiary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l.backupInfoHint,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Album Detail Screen
class AlbumDetailScreen extends StatefulWidget {
  final SynoAlbum album;
  final bool isShared;
  final VoidCallback onChanged;
  const AlbumDetailScreen({
    super.key,
    required this.album,
    required this.isShared,
    required this.onChanged,
  });
  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  final List<SynoPhoto> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = SessionManager.instance.api;
    if (api == null) return;
    try {
      final resp = await api.listPhotos(
        albumId: widget.album.id,
        shared: widget.isShared,
      );
      if (resp['success'] == true) {
        final list = resp['data']?['list'] as List? ?? [];
        setState(() {
          _items
            ..clear()
            ..addAll(
              list.map((e) => SynoPhoto.fromJson(e as Map<String, dynamic>)),
            );
          _loading = false;
          _error = null;
        });
      } else {
        setState(() {
          _loading = false;
          _error = 'Error loading album';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String? _thumbUrl(SynoPhoto p) {
    final api = SessionManager.instance.api;
    if (api == null || p.thumbSmKey == null) return null;
    return api.getPhotoThumbUrl(
      p.id,
      p.thumbSmKey!,
      size: 'sm',
      shared: widget.isShared,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.album.name,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            Text(
              l.photoCount(widget.album.itemCount),
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null && _items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _loading = true;
                        _error = null;
                      });
                      _load();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                    ),
                    child: Text(
                      l.retry,
                      style: GoogleFonts.inter(
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : _items.isEmpty
          ? Center(
              child: Text(
                l.noPhotosInAlbum,
                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: _items.length,
              itemBuilder: (ctx, i) {
                final p = _items[i];
                final url = _thumbUrl(p);
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PhotoViewerScreen(
                        photos: _items,
                        initialIndex: i,
                        isShared: widget.isShared,
                        onDeleted: (ids) {
                          setState(
                            () => _items.removeWhere((p) => ids.contains(p.id)),
                          );
                          widget.onChanged();
                        },
                      ),
                    ),
                  ),
                  child: url != null
                      ? CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.surfaceContainerHigh),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.surfaceContainerHigh,
                            child: const Center(
                              child: Icon(
                                Icons.image,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.surfaceContainerHigh,
                          child: const Center(
                            child: Icon(
                              Icons.image,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                );
              },
            ),
    );
  }
}
