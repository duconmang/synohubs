import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_colors.dart';
import '../services/session_manager.dart';
import '../l10n/app_localizations.dart';
import 'photos_screen.dart';

class PhotoViewerScreen extends StatefulWidget {
  final List<SynoPhoto> photos;
  final int initialIndex;
  final bool isShared;
  final void Function(List<int> deletedIds)? onDeleted;
  final Set<int> favoriteIds;
  final void Function(int photoId, bool isFavorite)? onFavoriteToggle;

  const PhotoViewerScreen({
    super.key,
    required this.photos,
    required this.initialIndex,
    this.isShared = false,
    this.onDeleted,
    this.favoriteIds = const {},
    this.onFavoriteToggle,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late PageController _pageCtrl;
  late int _current;
  bool _showUI = true;
  bool _downloading = false;
  double _downloadProgress = 0;
  late Set<int> _localFavorites;

  // Video playback
  Player? _videoPlayer;
  VideoController? _videoController;
  int? _activeVideoIndex;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: _current);
    _localFavorites = Set<int>.from(widget.favoriteIds);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (widget.photos[_current].isVideo) {
      _initVideoPlayer(_current);
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _videoPlayer?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  SynoPhoto get _photo => widget.photos[_current];

  String? _imageUrl(SynoPhoto p) {
    final api = SessionManager.instance.api;
    if (api == null) return null;
    final key = p.thumbXlKey ?? p.thumbMKey ?? p.thumbSmKey;
    if (key == null) return null;
    return api.getPhotoThumbUrl(p.id, key, size: 'xl', shared: widget.isShared);
  }

  /// Full-resolution original image via download URL.
  String? _originalUrl(SynoPhoto p) {
    if (p.isVideo) return null;
    final api = SessionManager.instance.api;
    if (api == null) return null;
    return api.getPhotoDownloadUrl([p.id], shared: widget.isShared);
  }

  void _initVideoPlayer(int index) {
    final api = SessionManager.instance.api;
    if (api == null) return;
    final photo = widget.photos[index];
    if (!photo.isVideo) return;

    // Dispose previous player if switching videos
    if (_activeVideoIndex != index) {
      _videoPlayer?.dispose();
      _videoPlayer = Player();
      _videoController = VideoController(_videoPlayer!);
      _activeVideoIndex = index;

      // Disable TLS verification for self-signed NAS certs
      if (_videoPlayer!.platform is NativePlayer) {
        (_videoPlayer!.platform as NativePlayer).setProperty(
          'tls-verify',
          'no',
        );
      }

      final url = api.getPhotoDownloadUrl([photo.id], shared: widget.isShared);
      _videoPlayer!.open(Media(url));
    }
  }

  void _onPageChanged(int i) {
    setState(() => _current = i);
    if (widget.photos[i].isVideo) {
      _initVideoPlayer(i);
    } else {
      // Pause video when swiping away
      _videoPlayer?.pause();
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l.deletePhotosTitle(1),
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
      await api.deletePhotos(ids: [_photo.id], shared: widget.isShared);
      widget.onDeleted?.call([_photo.id]);
      if (mounted) {
        if (widget.photos.length <= 1) {
          Navigator.pop(context);
        } else {
          setState(() {
            widget.photos.removeAt(_current);
            if (_current >= widget.photos.length) {
              _current = widget.photos.length - 1;
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _downloadToDevice() async {
    if (_downloading) return;
    final api = SessionManager.instance.api;
    if (api == null) return;
    final l = AppLocalizations.of(context)!;

    setState(() {
      _downloading = true;
      _downloadProgress = 0;
    });

    try {
      final url = api.getPhotoDownloadUrl([_photo.id], shared: widget.isShared);
      final uri = Uri.parse(url);

      // Use HttpClient to support self-signed certs (handled by NasCertOverrides)
      final client = HttpClient()
        ..badCertificateCallback = (_, __, ___) => true;
      final request = await client.getUrl(uri);
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength;
      final chunks = <List<int>>[];
      int received = 0;

      await for (final chunk in response) {
        chunks.add(chunk);
        received += chunk.length;
        if (totalBytes > 0 && mounted) {
          setState(() => _downloadProgress = received / totalBytes);
        }
      }
      client.close();

      // Save to Downloads directory
      final dir =
          await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/${_photo.filename}';
      final file = File(savePath);
      final sink = file.openWrite();
      for (final chunk in chunks) {
        sink.add(chunk);
      }
      await sink.close();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.downloadSavedTo(savePath))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.downloadFailed(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  void _showInfo() {
    final l = AppLocalizations.of(context)!;
    final p = _photo;
    final taken = p.takenAt;
    final size = _formatSize(p.filesize);
    final res = (p.width != null && p.height != null)
        ? '${p.width} × ${p.height}'
        : l.unknown;

    // Fetch EXIF data asynchronously
    final api = SessionManager.instance.api;
    Future<Map<String, dynamic>?>? exifFuture;
    if (api != null) {
      exifFuture = api
          .getPhotoInfo(ids: [p.id], shared: widget.isShared)
          .then((resp) {
            if (resp['success'] == true) {
              final list = resp['data']?['list'] as List?;
              if (list != null && list.isNotEmpty) {
                final item = list[0] as Map<String, dynamic>;
                final add = item['additional'] as Map<String, dynamic>? ?? {};
                return add['exif'] as Map<String, dynamic>?;
              }
            }
            return null;
          })
          .catchError((_) => null);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
              const SizedBox(height: 20),
              Text(
                l.photoInfo,
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              _infoRow(Icons.image, l.filenameLabel, p.filename),
              _infoRow(
                Icons.calendar_today,
                l.takenOn,
                '${taken.year}-${taken.month.toString().padLeft(2, '0')}-${taken.day.toString().padLeft(2, '0')} ${taken.hour.toString().padLeft(2, '0')}:${taken.minute.toString().padLeft(2, '0')}',
              ),
              _infoRow(Icons.straighten, l.resolution, res),
              _infoRow(Icons.sd_storage, l.fileSize, size),
              _infoRow(Icons.category, l.type, p.isVideo ? l.video : l.photo),
              // EXIF data (loaded async)
              if (exifFuture != null)
                FutureBuilder<Map<String, dynamic>?>(
                  future: exifFuture,
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      );
                    }
                    final exif = snap.data;
                    if (exif == null || exif.isEmpty)
                      return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Divider(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (exif['camera_make'] != null ||
                            exif['camera_model'] != null)
                          _infoRow(
                            Icons.camera_alt,
                            'Camera',
                            [exif['camera_make'], exif['camera_model']]
                                .where(
                                  (s) => s != null && s.toString().isNotEmpty,
                                )
                                .join(' '),
                          ),
                        if (exif['focal_length'] != null)
                          _infoRow(
                            Icons.center_focus_strong,
                            'Focal Length',
                            '${exif['focal_length']}mm',
                          ),
                        if (exif['aperture'] != null)
                          _infoRow(
                            Icons.camera,
                            'Aperture',
                            'f/${(exif['aperture'] is int ? exif['aperture'] / 10.0 : exif['aperture'])}',
                          ),
                        if (exif['exposure_time'] != null)
                          _infoRow(
                            Icons.shutter_speed,
                            'Shutter',
                            '1/${exif['exposure_time']}s',
                          ),
                        if (exif['iso'] != null)
                          _infoRow(Icons.iso, 'ISO', '${exif['iso']}'),
                        if (exif['flash'] != null)
                          _infoRow(
                            Icons.flash_on,
                            'Flash',
                            exif['flash'] == 0 ? 'Off' : 'On',
                          ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) {
      return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
  }

  void _toggleFavorite() {
    final p = _photo;
    final isFav = _localFavorites.contains(p.id);
    setState(() {
      if (isFav) {
        _localFavorites.remove(p.id);
      } else {
        _localFavorites.add(p.id);
      }
    });
    widget.onFavoriteToggle?.call(p.id, !isFav);
    final api = SessionManager.instance.api;
    api
        ?.setPhotoRating(
          id: p.id,
          rating: isFav ? 0 : 1,
          shared: widget.isShared,
        )
        .catchError((_) {
          // Revert on failure
          if (mounted) {
            setState(() {
              if (isFav) {
                _localFavorites.add(p.id);
              } else {
                _localFavorites.remove(p.id);
              }
            });
            widget.onFavoriteToggle?.call(p.id, isFav);
          }
          return <String, dynamic>{};
        });
  }

  Future<void> _sharePhoto() async {
    final api = SessionManager.instance.api;
    if (api == null) return;
    final l = AppLocalizations.of(context)!;
    try {
      final resp = await api.createPhotoShareLink(
        itemIds: [_photo.id],
        shared: widget.isShared,
      );
      if (resp['success'] == true) {
        final passphrase = resp['data']?['passphrase'] as String?;
        if (passphrase != null && passphrase.isNotEmpty) {
          final link = '${api.baseUrl}/mo/sharing/$passphrase';
          await Clipboard.setData(ClipboardData(text: link));
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l.shareLinkCopied)));
          }
          return;
        }
      }
      // Fallback: copy download link
      final url = api.getPhotoDownloadUrl([_photo.id], shared: widget.isShared);
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l.shareLinkCopied)));
      }
    } catch (e) {
      // Fallback: copy download link
      try {
        final url = api.getPhotoDownloadUrl([
          _photo.id,
        ], shared: widget.isShared);
        await Clipboard.setData(ClipboardData(text: url));
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.shareLinkCopied)));
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l.failedToCreateShareLink)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showUI = !_showUI),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo/Video pages
            PageView.builder(
              controller: _pageCtrl,
              itemCount: widget.photos.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (ctx, i) {
                final photo = widget.photos[i];
                if (photo.isVideo &&
                    _activeVideoIndex == i &&
                    _videoController != null) {
                  return _buildVideoPage(photo);
                }
                return _buildPhotoPage(photo);
              },
            ),

            // Download progress indicator
            if (_downloading)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _downloadProgress > 0 ? _downloadProgress : null,
                  backgroundColor: Colors.black26,
                  color: AppColors.primary,
                  minHeight: 3,
                ),
              ),

            // Top bar
            if (_showUI)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _photo.filename,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${_current + 1} / ${widget.photos.length}',
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Bottom bar
            if (_showUI)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _actionBtn(
                            _localFavorites.contains(_photo.id)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            _toggleFavorite,
                          ),
                          _actionBtn(
                            _downloading ? Icons.hourglass_top : Icons.download,
                            _downloading ? null : () => _downloadToDevice(),
                          ),
                          _actionBtn(Icons.share, _sharePhoto),
                          _actionBtn(Icons.info_outline, _showInfo),
                          _actionBtn(Icons.delete_outline, _delete),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPage(SynoPhoto photo) {
    final thumbUrl = _imageUrl(photo);
    if (thumbUrl == null) {
      return const Center(
        child: Icon(Icons.image, color: AppColors.onSurfaceVariant, size: 64),
      );
    }
    // Show play icon overlay for videos that haven't been initialized
    if (photo.isVideo) {
      return GestureDetector(
        onTap: () {
          _initVideoPlayer(widget.photos.indexOf(photo));
          setState(() {});
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: thumbUrl,
              fit: BoxFit.contain,
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
              errorWidget: (_, __, ___) => const Center(
                child: Icon(
                  Icons.broken_image,
                  color: AppColors.onSurfaceVariant,
                  size: 64,
                ),
              ),
            ),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(36),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 48,
              ),
            ),
          ],
        ),
      );
    }
    // For photos: load full-res original with xl thumbnail as placeholder
    final origUrl = _originalUrl(photo);
    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 5.0,
      child: Center(
        child: origUrl != null
            ? Image.network(
                origUrl,
                fit: BoxFit.contain,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child; // original loaded
                  // While loading original, show xl thumbnail
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      CachedNetworkImage(
                        imageUrl: thumbUrl,
                        fit: BoxFit.contain,
                      ),
                      Positioned(
                        bottom: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                progress.expectedTotalBytes != null
                                    ? '${(progress.cumulativeBytesLoaded * 100 ~/ progress.expectedTotalBytes!)}%'
                                    : '...',
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
                errorBuilder: (_, __, ___) => CachedNetworkImage(
                  imageUrl: thumbUrl,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: AppColors.onSurfaceVariant,
                      size: 64,
                    ),
                  ),
                ),
              )
            : CachedNetworkImage(
                imageUrl: thumbUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
                errorWidget: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: AppColors.onSurfaceVariant,
                    size: 64,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildVideoPage(SynoPhoto photo) {
    return Center(
      child: Video(
        controller: _videoController!,
        controls: AdaptiveVideoControls,
      ),
    );
  }

  Widget _actionBtn(IconData icon, VoidCallback? onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 24),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
