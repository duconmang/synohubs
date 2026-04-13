import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_colors.dart';
import '../services/session_manager.dart';
import '../services/synology_api.dart';
import '../l10n/app_localizations.dart';

/// Represents a file/folder entry from FileStation.
class _FsEntry {
  final String path;
  final String name;
  final bool isDir;
  final int size;
  final int mtime;

  const _FsEntry({
    required this.path,
    required this.name,
    required this.isDir,
    this.size = 0,
    this.mtime = 0,
  });
}

class FileManagerScreen extends StatefulWidget {
  const FileManagerScreen({super.key});

  @override
  State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen> {
  /// Current entries in the view
  List<_FsEntry> _entries = [];

  /// Navigation path stack — empty means root (shared folders)
  final List<String> _pathStack = [];

  /// For multi-select mode
  final Set<String> _selected = {};
  bool _selectMode = false;

  /// Clipboard for copy/move operations
  String? _clipboardPath;
  bool _clipboardIsCut = false;

  bool _loading = true;
  String? _error;

  /// Search
  bool _searchActive = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String? _searchTaskId;
  Timer? _searchPollTimer;
  bool _searchLoading = false;

  /// Sort
  String _sortBy = 'name';
  String _sortDir = 'asc';

  /// View mode
  bool _gridView = false;

  SynologyApi? get _api => SessionManager.instance.api;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _cancelSearch();
    super.dispose();
  }

  // ── Current folder path ─────────────────────────────────────────

  String? get _currentPath => _pathStack.isEmpty ? null : _pathStack.last;

  String get _currentFolderName {
    if (_pathStack.isEmpty) return AppLocalizations.of(context)!.fileManager;
    final p = _pathStack.last;
    final i = p.lastIndexOf('/');
    return i >= 0 ? p.substring(i + 1) : p;
  }

  // ── Data loading ────────────────────────────────────────────────

  Future<void> _loadCurrent() async {
    if (_api == null || !_api!.isAuthenticated) {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context)!.notConnected;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_pathStack.isEmpty) {
        await _loadShares();
      } else {
        await _loadFolder(_pathStack.last);
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadShares() async {
    final resp = await _api!.listSharedFolders();
    if (resp['success'] == true) {
      final shares = (resp['data']?['shares'] as List? ?? []);
      setState(() {
        _entries = shares.map((s) {
          final m = s as Map<String, dynamic>;
          final additional = _extractAdditional(m);
          return _FsEntry(
            path: m['path'] as String? ?? '/${m['name']}',
            name: m['name'] as String? ?? '',
            isDir: true,
            size: _extractSize(additional),
          );
        }).toList();
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(
          context,
        )!.errorCode(resp['error']?['code']?.toString() ?? 'unknown');
      });
    }
  }

  Future<void> _loadFolder(String folderPath) async {
    final resp = await _api!.listFiles(
      folderPath: folderPath,
      sortBy: _sortBy,
      sortDirection: _sortDir,
    );
    if (resp['success'] == true) {
      final files = (resp['data']?['files'] as List? ?? []);
      final entries = files.map((f) {
        final m = f as Map<String, dynamic>;
        final additional = _extractAdditional(m);
        return _FsEntry(
          path: m['path'] as String? ?? '',
          name: m['name'] as String? ?? '',
          isDir: m['isdir'] as bool? ?? false,
          size: _extractSize(additional),
          mtime: _extractMtime(additional),
        );
      }).toList();
      // Folders first, then sorted
      entries.sort((a, b) {
        if (a.isDir != b.isDir) return a.isDir ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(
          context,
        )!.errorCode(resp['error']?['code']?.toString() ?? 'unknown');
      });
    }
  }

  Map<String, dynamic> _extractAdditional(Map<String, dynamic> m) {
    return m['additional'] is Map<String, dynamic>
        ? m['additional'] as Map<String, dynamic>
        : <String, dynamic>{};
  }

  int _extractSize(Map<String, dynamic> additional) {
    final s = additional['size'];
    if (s is Map<String, dynamic>) return (s['total'] as num?)?.toInt() ?? 0;
    if (s is num) return s.toInt();
    return 0;
  }

  int _extractMtime(Map<String, dynamic> additional) {
    final t = additional['time'];
    if (t is Map<String, dynamic>) return (t['mtime'] as num?)?.toInt() ?? 0;
    if (t is num) return t.toInt();
    return 0;
  }

  // ── Navigation ──────────────────────────────────────────────────

  void _navigateInto(_FsEntry entry) {
    if (!entry.isDir) return;
    _exitSelectMode();
    setState(() {
      _pathStack.add(entry.path);
    });
    _loadCurrent();
  }

  void _navigateBack() {
    if (_pathStack.isEmpty) return;
    _exitSelectMode();
    setState(() {
      _pathStack.removeLast();
    });
    _loadCurrent();
  }

  void _navigateTo(int breadcrumbIndex) {
    // -1 = root
    _exitSelectMode();
    if (breadcrumbIndex < 0) {
      setState(() => _pathStack.clear());
    } else {
      setState(() {
        while (_pathStack.length > breadcrumbIndex + 1) {
          _pathStack.removeLast();
        }
      });
    }
    _loadCurrent();
  }

  // ── Select mode ─────────────────────────────────────────────────

  void _toggleSelect(String path) {
    setState(() {
      if (_selected.contains(path)) {
        _selected.remove(path);
        if (_selected.isEmpty) _selectMode = false;
      } else {
        _selected.add(path);
        _selectMode = true;
      }
    });
  }

  void _exitSelectMode() {
    setState(() {
      _selected.clear();
      _selectMode = false;
    });
  }

  // ── File operations ─────────────────────────────────────────────

  Future<void> _createFolder() async {
    final l = AppLocalizations.of(context)!;
    final name = await _showInputDialog(l.newFolder, l.folderName);
    if (name == null || name.trim().isEmpty) return;
    final target = _currentPath;
    if (target == null) return;

    setState(() => _loading = true);
    try {
      final resp = await _api!.createFolder(
        folderPath: target,
        name: name.trim(),
      );
      if (resp['success'] != true) {
        _showError(l.failedToCreateFolder);
      }
    } catch (e) {
      _showError(e.toString());
    }
    _loadCurrent();
  }

  Future<void> _renameItem(_FsEntry entry) async {
    final l = AppLocalizations.of(context)!;
    final name = await _showInputDialog(
      l.rename,
      l.newName,
      initial: entry.name,
    );
    if (name == null || name.trim().isEmpty || name.trim() == entry.name)
      return;

    setState(() => _loading = true);
    try {
      final resp = await _api!.rename(path: entry.path, name: name.trim());
      if (resp['success'] != true) {
        _showError(l.failedToRename);
      }
    } catch (e) {
      _showError(e.toString());
    }
    _loadCurrent();
  }

  Future<void> _deleteItems(List<String> paths) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await _showConfirmDialog(
      l.deleteItemsTitle(paths.length, paths.length > 1 ? 's' : ''),
      l.cannotBeUndone,
    );
    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      // Delete each path (API accepts one path per call)
      for (final p in paths) {
        final resp = await _api!.deleteItem(p);
        if (resp['success'] != true) {
          _showError(l.failedToDelete(p.split('/').last));
        }
      }
    } catch (e) {
      _showError(e.toString());
    }
    _exitSelectMode();
    // Small delay for async delete to process
    await Future.delayed(const Duration(milliseconds: 500));
    _loadCurrent();
  }

  void _copyItems(List<String> paths, {bool cut = false}) {
    setState(() {
      _clipboardPath = paths.join(',');
      _clipboardIsCut = cut;
    });
    _exitSelectMode();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.copiedItems(
            cut
                ? AppLocalizations.of(context)!.cut
                : AppLocalizations.of(context)!.copied,
            paths.length,
            paths.length > 1 ? 's' : '',
          ),
          style: GoogleFonts.inter(),
        ),
        backgroundColor: AppColors.surfaceContainerHigh,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pasteItems() async {
    if (_clipboardPath == null || _currentPath == null) return;

    setState(() => _loading = true);
    try {
      final resp = await _api!.copyMove(
        path: _clipboardPath!,
        destFolderPath: _currentPath!,
        removeSource: _clipboardIsCut,
      );
      if (resp['success'] != true) {
        _showError(
          AppLocalizations.of(
            context,
          )!.failedToCopyMove(_clipboardIsCut ? 'move' : 'copy'),
        );
      }
      if (_clipboardIsCut) {
        setState(() {
          _clipboardPath = null;
          _clipboardIsCut = false;
        });
      }
    } catch (e) {
      _showError(e.toString());
    }
    await Future.delayed(const Duration(milliseconds: 500));
    _loadCurrent();
  }

  Future<void> _createShareLink(_FsEntry entry) async {
    setState(() => _loading = true);
    try {
      final resp = await _api!.createShareLink(path: entry.path);
      setState(() => _loading = false);
      if (resp['success'] == true) {
        final links = resp['data']?['links'] as List?;
        final url = links?.isNotEmpty == true
            ? (links!.first as Map<String, dynamic>)['url'] ?? ''
            : '';
        if (url.toString().isNotEmpty) {
          await Clipboard.setData(ClipboardData(text: url.toString()));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.shareLinkCopied,
                  style: GoogleFonts.inter(),
                ),
                backgroundColor: AppColors.surfaceContainerHigh,
              ),
            );
          }
        } else {
          _showError(AppLocalizations.of(context)!.couldNotGenerateLink);
        }
      } else {
        _showError(AppLocalizations.of(context)!.failedToCreateShareLink);
      }
    } catch (e) {
      setState(() => _loading = false);
      _showError(e.toString());
    }
  }

  /// Create a share link then show it as a QR code.
  Future<void> _showQrCode(_FsEntry entry) async {
    setState(() => _loading = true);
    try {
      final resp = await _api!.createShareLink(path: entry.path);
      setState(() => _loading = false);
      if (resp['success'] == true) {
        final links = resp['data']?['links'] as List?;
        final url = links?.isNotEmpty == true
            ? (links!.first as Map<String, dynamic>)['url']?.toString() ?? ''
            : '';
        if (url.isNotEmpty && mounted) {
          showDialog(
            context: context,
            builder: (ctx) => Dialog(
              backgroundColor: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // QR card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              entry.isDir
                                  ? Icons.folder
                                  : _fileIcon(entry.name),
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                entry.name,
                                style: GoogleFonts.inter(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // QR code with white background
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: QrImageView(
                            data: url,
                            version: QrVersions.auto,
                            size: 220,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF0B1326),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF0B1326),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Link text (truncated)
                        Text(
                          url,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        // Copy button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: url));
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(context)!.linkCopied,
                                    style: GoogleFonts.inter(),
                                  ),
                                  backgroundColor:
                                      AppColors.surfaceContainerHigh,
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 18),
                            label: Text(
                              AppLocalizations.of(context)!.copyLink,
                              style: GoogleFonts.inter(),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              foregroundColor: AppColors.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Close button
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.onSurface,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceContainer.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          _showError(AppLocalizations.of(context)!.couldNotGenerateShareLink);
        }
      } else {
        _showError(AppLocalizations.of(context)!.failedToCreateShareLink);
      }
    } catch (e) {
      setState(() => _loading = false);
      _showError(e.toString());
    }
  }

  Future<void> _uploadFile() async {
    final target = _currentPath;
    if (target == null || _api == null) return;

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true, // get bytes directly — more reliable on emulators
    );
    if (result == null || result.files.isEmpty) return;

    int success = 0;
    int failed = 0;
    String lastError = '';
    setState(() => _loading = true);

    for (final pf in result.files) {
      try {
        // Prefer in-memory bytes, fallback to reading from path
        List<int>? bytes = pf.bytes;
        if (bytes == null && pf.path != null) {
          bytes = await File(pf.path!).readAsBytes();
        }
        if (bytes == null || bytes.isEmpty) {
          failed++;
          lastError = AppLocalizations.of(context)!.couldNotReadFile(pf.name);
          continue;
        }
        final resp = await _api!.uploadFile(
          destFolderPath: target,
          fileName: pf.name,
          fileBytes: bytes,
        );
        if (resp['success'] == true) {
          success++;
        } else {
          failed++;
          final errCode = resp['error']?['code'];
          final errDetail = resp['error']?['detail'] ?? '';
          lastError =
              'Error $errCode${errDetail.toString().isNotEmpty ? ': ${errDetail.toString().substring(0, errDetail.toString().length.clamp(0, 100))}' : ''}';
        }
      } catch (e) {
        failed++;
        lastError = e.toString();
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failed == 0
                ? AppLocalizations.of(
                    context,
                  )!.uploadedFiles(success, success > 1 ? 's' : '')
                : AppLocalizations.of(context)!.failedError(lastError),
            style: GoogleFonts.inter(),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: failed == 0
              ? AppColors.surfaceContainerHigh
              : AppColors.error,
          duration: Duration(seconds: failed > 0 ? 5 : 2),
        ),
      );
    }
    _loadCurrent();
  }

  // ── Search ──────────────────────────────────────────────────────

  Future<void> _startSearch(String query) async {
    if (query.trim().isEmpty || _api == null) return;
    _cancelSearch();

    final folder = _currentPath ?? '/';
    setState(() {
      _searchLoading = true;
      _searchActive = true;
    });

    try {
      final resp = await _api!.searchStart(
        folderPath: folder,
        pattern: query.trim(),
      );
      if (resp['success'] == true) {
        _searchTaskId = resp['data']?['taskid'] as String?;
        if (_searchTaskId != null) {
          // Poll for results after a short delay
          _searchPollTimer = Timer(const Duration(seconds: 1), _pollSearch);
        }
      } else {
        setState(() => _searchLoading = false);
        _showError(AppLocalizations.of(context)!.searchFailed);
      }
    } catch (e) {
      setState(() => _searchLoading = false);
    }
  }

  Future<void> _pollSearch() async {
    if (_searchTaskId == null) return;
    try {
      final resp = await _api!.searchList(taskId: _searchTaskId!);
      if (resp['success'] == true) {
        final files = (resp['data']?['files'] as List? ?? []);
        final finished = resp['data']?['finished'] as bool? ?? false;
        final entries = files.map((f) {
          final m = f as Map<String, dynamic>;
          final additional = _extractAdditional(m);
          return _FsEntry(
            path: m['path'] as String? ?? '',
            name: m['name'] as String? ?? '',
            isDir: m['isdir'] as bool? ?? false,
            size: _extractSize(additional),
            mtime: _extractMtime(additional),
          );
        }).toList();
        entries.sort((a, b) {
          if (a.isDir != b.isDir) return a.isDir ? -1 : 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        setState(() {
          _entries = entries;
          _searchLoading = !finished;
        });
        if (!finished) {
          _searchPollTimer = Timer(const Duration(seconds: 1), _pollSearch);
        } else {
          // Clean up task
          _api!.searchStop(_searchTaskId!);
          _searchTaskId = null;
        }
      }
    } catch (_) {
      setState(() => _searchLoading = false);
    }
  }

  void _cancelSearch() {
    _searchPollTimer?.cancel();
    _searchPollTimer = null;
    if (_searchTaskId != null) {
      _api?.searchStop(_searchTaskId!);
      _searchTaskId = null;
    }
  }

  void _exitSearch() {
    _cancelSearch();
    setState(() {
      _searchActive = false;
      _searchLoading = false;
      _searchCtrl.clear();
    });
    _loadCurrent();
  }

  // ── Dialogs ─────────────────────────────────────────────────────

  Future<String?> _showInputDialog(
    String title,
    String hint, {
    String? initial,
  }) async {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        title: Text(
          title,
          style: GoogleFonts.manrope(color: AppColors.onSurface),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: GoogleFonts.inter(color: AppColors.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.outline),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: Text(
              AppLocalizations.of(context)!.ok,
              style: GoogleFonts.inter(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        title: Text(
          title,
          style: GoogleFonts.manrope(color: AppColors.onSurface),
        ),
        content: Text(
          message,
          style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: GoogleFonts.inter(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showContextMenu(_FsEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        entry.isDir ? Icons.folder : _fileIcon(entry.name),
                        color: entry.isDir
                            ? AppColors.primary
                            : _fileIconColor(entry.name),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.name,
                          style: GoogleFonts.inter(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.outlineVariant, height: 16),
                _menuItem(Icons.edit, AppLocalizations.of(context)!.rename, () {
                  Navigator.pop(ctx);
                  _renameItem(entry);
                }),
                _menuItem(
                  Icons.content_copy,
                  AppLocalizations.of(context)!.copy,
                  () {
                    Navigator.pop(ctx);
                    _copyItems([entry.path]);
                  },
                ),
                _menuItem(
                  Icons.content_cut,
                  AppLocalizations.of(context)!.cut,
                  () {
                    Navigator.pop(ctx);
                    _copyItems([entry.path], cut: true);
                  },
                ),
                _menuItem(
                  Icons.link,
                  AppLocalizations.of(context)!.shareLink,
                  () {
                    Navigator.pop(ctx);
                    _createShareLink(entry);
                  },
                ),
                _menuItem(
                  Icons.qr_code_2,
                  AppLocalizations.of(context)!.qrCode,
                  () {
                    Navigator.pop(ctx);
                    _showQrCode(entry);
                  },
                ),
                _menuItem(
                  Icons.delete_outline,
                  AppLocalizations.of(context)!.delete,
                  () {
                    Navigator.pop(ctx);
                    _deleteItems([entry.path]);
                  },
                  color: AppColors.error,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuItem(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.onSurface, size: 22),
      title: Text(
        label,
        style: GoogleFonts.inter(
          color: color ?? AppColors.onSurface,
          fontSize: 14,
        ),
      ),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────

  String _formatSize(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatDate(int timestamp) {
    if (timestamp <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final months = [
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
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  IconData _fileIcon(String name) {
    final lower = name.toLowerCase();
    if (_isImage(lower)) return Icons.image;
    if (_isVideo(lower)) return Icons.play_circle;
    if (_isAudio(lower)) return Icons.music_note;
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (_isDocument(lower)) return Icons.description;
    if (_isArchive(lower)) return Icons.archive;
    return Icons.insert_drive_file;
  }

  Color _fileIconColor(String name) {
    final lower = name.toLowerCase();
    if (_isImage(lower)) return AppColors.secondary;
    if (_isVideo(lower)) return AppColors.primaryContainer;
    if (_isAudio(lower)) return AppColors.tertiary;
    if (lower.endsWith('.pdf')) return const Color(0xFFFF6B6B);
    if (_isDocument(lower)) return AppColors.primaryFixed;
    if (_isArchive(lower)) return AppColors.tertiaryContainer;
    return AppColors.onSurfaceVariant;
  }

  bool _isImage(String l) =>
      l.endsWith('.jpg') ||
      l.endsWith('.jpeg') ||
      l.endsWith('.png') ||
      l.endsWith('.gif') ||
      l.endsWith('.bmp') ||
      l.endsWith('.webp');
  bool _isVideo(String l) =>
      l.endsWith('.mp4') ||
      l.endsWith('.mkv') ||
      l.endsWith('.avi') ||
      l.endsWith('.mov') ||
      l.endsWith('.wmv') ||
      l.endsWith('.flv');
  bool _isAudio(String l) =>
      l.endsWith('.mp3') ||
      l.endsWith('.flac') ||
      l.endsWith('.wav') ||
      l.endsWith('.aac') ||
      l.endsWith('.ogg');
  bool _isDocument(String l) =>
      l.endsWith('.doc') ||
      l.endsWith('.docx') ||
      l.endsWith('.txt') ||
      l.endsWith('.md') ||
      l.endsWith('.xls') ||
      l.endsWith('.xlsx');
  bool _isArchive(String l) =>
      l.endsWith('.zip') ||
      l.endsWith('.rar') ||
      l.endsWith('.7z') ||
      l.endsWith('.tar') ||
      l.endsWith('.gz');

  // ── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PopScope(
      canPop: _pathStack.isEmpty && !_searchActive && !_selectMode,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_selectMode) {
          _exitSelectMode();
        } else if (_searchActive) {
          _exitSearch();
        } else if (_pathStack.isNotEmpty) {
          _navigateBack();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            _buildHeader(),
            if (_pathStack.isNotEmpty || _searchActive) _buildBreadcrumbs(),
            Expanded(child: _buildBody()),
          ],
        ),
        floatingActionButton: _currentPath != null && !_selectMode
            ? _buildFab()
            : null,
      ),
    );
  }

  Widget _buildHeader() {
    if (_selectMode) {
      return _buildSelectHeader();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Row(
        children: [
          if (!_searchActive)
            Expanded(child: _buildSearchBar())
          else
            Expanded(child: _buildActiveSearchBar()),
          const SizedBox(width: 4),
          _buildSortButton(),
          _buildViewToggle(),
        ],
      ),
    );
  }

  Widget _buildSelectHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      color: AppColors.primaryContainer.withValues(alpha: 0.15),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.onSurface),
            onPressed: _exitSelectMode,
          ),
          Text(
            AppLocalizations.of(context)!.nSelected(_selected.length),
            style: GoogleFonts.inter(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.content_copy,
              color: AppColors.onSurface,
              size: 22,
            ),
            tooltip: AppLocalizations.of(context)!.copy,
            onPressed: () => _copyItems(_selected.toList()),
          ),
          IconButton(
            icon: const Icon(
              Icons.content_cut,
              color: AppColors.onSurface,
              size: 22,
            ),
            tooltip: AppLocalizations.of(context)!.cut,
            onPressed: () => _copyItems(_selected.toList(), cut: true),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: AppColors.error,
              size: 22,
            ),
            tooltip: AppLocalizations.of(context)!.delete,
            onPressed: () => _deleteItems(_selected.toList()),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => setState(() => _searchActive = true),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(
              Icons.search,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.searchFiles,
              style: GoogleFonts.inter(
                color: AppColors.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSearchBar() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: _searchCtrl,
        autofocus: true,
        style: GoogleFonts.inter(color: AppColors.onSurface, fontSize: 13),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(
            context,
          )!.searchInFolder(_currentFolderName),
          hintStyle: GoogleFonts.inter(
            color: AppColors.onSurfaceVariant,
            fontSize: 13,
          ),
          prefixIcon: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              size: 20,
              color: AppColors.onSurfaceVariant,
            ),
            onPressed: _exitSearch,
          ),
          suffixIcon: _searchLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(
                    Icons.search,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _startSearch(_searchCtrl.text),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onSubmitted: _startSearch,
      ),
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort, color: AppColors.onSurfaceVariant, size: 22),
      color: AppColors.surfaceContainer,
      tooltip: AppLocalizations.of(context)!.sort,
      onSelected: (val) {
        if (val == _sortBy) {
          setState(() => _sortDir = _sortDir == 'asc' ? 'desc' : 'asc');
        } else {
          setState(() {
            _sortBy = val;
            _sortDir = 'asc';
          });
        }
        _loadCurrent();
      },
      itemBuilder: (_) => [
        _sortMenuItem('name', AppLocalizations.of(context)!.sortByName),
        _sortMenuItem('size', AppLocalizations.of(context)!.sortBySize),
        _sortMenuItem('mtime', AppLocalizations.of(context)!.sortByDate),
        _sortMenuItem('type', AppLocalizations.of(context)!.sortByType),
      ],
    );
  }

  PopupMenuItem<String> _sortMenuItem(String value, String label) {
    final isActive = _sortBy == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: isActive ? AppColors.primary : AppColors.onSurface,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13,
            ),
          ),
          if (isActive) ...[
            const Spacer(),
            Icon(
              _sortDir == 'asc' ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: AppColors.primary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return IconButton(
      icon: Icon(
        _gridView ? Icons.view_list : Icons.grid_view,
        color: AppColors.onSurfaceVariant,
        size: 22,
      ),
      tooltip: _gridView
          ? AppLocalizations.of(context)!.listView
          : AppLocalizations.of(context)!.gridView,
      onPressed: () => setState(() => _gridView = !_gridView),
    );
  }

  Widget _buildBreadcrumbs() {
    // Build path segments
    final segments = <MapEntry<String, String>>[]; // <path, name>
    for (int i = 0; i < _pathStack.length; i++) {
      final p = _pathStack[i];
      final lastSlash = p.lastIndexOf('/');
      final name = lastSlash >= 0 ? p.substring(lastSlash + 1) : p;
      segments.add(MapEntry(p, name));
    }

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _breadcrumbChip(
            Icons.home,
            AppLocalizations.of(context)!.root,
            onTap: () => _navigateTo(-1),
            isLast: segments.isEmpty,
          ),
          ...segments.asMap().entries.map((e) {
            final idx = e.key;
            final seg = e.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.outline,
                ),
                _breadcrumbChip(
                  null,
                  seg.value,
                  onTap: () => _navigateTo(idx),
                  isLast: idx == segments.length - 1,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _breadcrumbChip(
    IconData? icon,
    String label, {
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return GestureDetector(
      onTap: isLast ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Icon(
                icon,
                size: 16,
                color: isLast ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
            if (icon != null) const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
                color: isLast ? AppColors.primary : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCurrent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                ),
                child: Text(AppLocalizations.of(context)!.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _pathStack.isEmpty ? Icons.folder_off : Icons.folder_open,
              size: 56,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              _searchActive
                  ? AppLocalizations.of(context)!.noResultsFound
                  : AppLocalizations.of(context)!.emptyFolder,
              style: GoogleFonts.inter(
                color: AppColors.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // Show paste banner
    final showPaste = _clipboardPath != null && _currentPath != null;

    return Column(
      children: [
        if (showPaste) _buildPasteBanner(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _loadCurrent(),
            color: AppColors.primary,
            child: _gridView ? _buildGridView() : _buildListView(),
          ),
        ),
      ],
    );
  }

  Widget _buildPasteBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _clipboardIsCut ? Icons.content_cut : Icons.content_copy,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _clipboardIsCut
                  ? AppLocalizations.of(context)!.clipboardMove
                  : AppLocalizations.of(context)!.clipboardCopy,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.onSurface,
              ),
            ),
          ),
          TextButton(
            onPressed: _pasteItems,
            child: Text(
              AppLocalizations.of(context)!.pasteHere,
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.outline),
            onPressed: () => setState(() {
              _clipboardPath = null;
              _clipboardIsCut = false;
            }),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _entries.length,
      itemBuilder: (ctx, i) => _buildListTile(_entries[i]),
    );
  }

  Widget _buildListTile(_FsEntry entry) {
    final isSelected = _selected.contains(entry.path);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: _selectMode
            ? Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleSelect(entry.path),
                activeColor: AppColors.primary,
                checkColor: AppColors.onPrimary,
                side: const BorderSide(color: AppColors.outline),
              )
            : Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      (entry.isDir
                              ? AppColors.primary
                              : _fileIconColor(entry.name))
                          .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  entry.isDir ? Icons.folder : _fileIcon(entry.name),
                  color: entry.isDir
                      ? AppColors.primary
                      : _fileIconColor(entry.name),
                  size: 22,
                ),
              ),
        title: Text(
          entry.name,
          style: GoogleFonts.inter(
            color: AppColors.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: entry.isDir
            ? null
            : Text(
                [
                  if (entry.size > 0) _formatSize(entry.size),
                  if (entry.mtime > 0) _formatDate(entry.mtime),
                ].join(' · '),
                style: GoogleFonts.inter(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
        trailing: !_selectMode
            ? IconButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.onSurfaceVariant,
                  size: 20,
                ),
                onPressed: () => _showContextMenu(entry),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              )
            : null,
        onTap: () {
          if (_selectMode) {
            _toggleSelect(entry.path);
          } else if (entry.isDir) {
            _navigateInto(entry);
          } else {
            _showContextMenu(entry);
          }
        },
        onLongPress: () {
          if (!_selectMode) {
            _toggleSelect(entry.path);
          }
        },
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemCount: _entries.length,
      itemBuilder: (ctx, i) => _buildGridTile(_entries[i]),
    );
  }

  Widget _buildGridTile(_FsEntry entry) {
    final isSelected = _selected.contains(entry.path);
    final isImage = !entry.isDir && _isImage(entry.name.toLowerCase());

    return GestureDetector(
      onTap: () {
        if (_selectMode) {
          _toggleSelect(entry.path);
        } else if (entry.isDir) {
          _navigateInto(entry);
        } else {
          _showContextMenu(entry);
        }
      },
      onLongPress: () {
        if (!_selectMode) {
          _toggleSelect(entry.path);
        } else {
          _showContextMenu(entry);
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.surfaceContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_selectMode)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4, top: 4),
                      child: Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.outline,
                        size: 20,
                      ),
                    ),
                  ),
                if (isImage)
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(
                          _api!.getThumbnailUrl(entry.path, size: 'small'),
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Icon(
                    entry.isDir ? Icons.folder : _fileIcon(entry.name),
                    size: 42,
                    color: entry.isDir
                        ? AppColors.primary
                        : _fileIconColor(entry.name),
                  ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    entry.name,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (!entry.isDir && entry.size > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _formatSize(entry.size),
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_clipboardPath != null) ...[
          FloatingActionButton.small(
            heroTag: 'paste',
            onPressed: _pasteItems,
            backgroundColor: AppColors.secondaryContainer,
            child: const Icon(Icons.paste, color: AppColors.onSecondary),
          ),
          const SizedBox(height: 8),
        ],
        FloatingActionButton.small(
          heroTag: 'upload',
          onPressed: _uploadFile,
          backgroundColor: AppColors.tertiaryContainer,
          child: const Icon(Icons.upload_file, color: AppColors.onPrimary),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'add',
          onPressed: _createFolder,
          backgroundColor: AppColors.primaryContainer,
          child: const Icon(
            Icons.create_new_folder,
            color: AppColors.onPrimary,
          ),
        ),
      ],
    );
  }
}
