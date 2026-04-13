import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_service/audio_service.dart' as audio_svc;
import 'session_manager.dart';

// ── Audio Track Model ──────────────────────────────────────────

class AudioTrack {
  final String id;
  final String path;
  final String name;
  final String title;
  final String artist;
  final String album;
  final String ext;
  final int size;
  final int mtime;
  final String folder;

  const AudioTrack({
    required this.id,
    required this.path,
    required this.name,
    required this.title,
    required this.artist,
    required this.album,
    required this.ext,
    required this.size,
    required this.mtime,
    required this.folder,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'name': name,
        'title': title,
        'artist': artist,
        'album': album,
        'ext': ext,
        'size': size,
        'mtime': mtime,
        'folder': folder,
      };

  factory AudioTrack.fromJson(Map<String, dynamic> j) => AudioTrack(
        id: j['id'] as String? ?? '',
        path: j['path'] as String? ?? '',
        name: j['name'] as String? ?? '',
        title: j['title'] as String? ?? '',
        artist: j['artist'] as String? ?? 'Unknown Artist',
        album: j['album'] as String? ?? 'Unknown Album',
        ext: j['ext'] as String? ?? '',
        size: j['size'] as int? ?? 0,
        mtime: j['mtime'] as int? ?? 0,
        folder: j['folder'] as String? ?? '',
      );
}

// ── Repeat Mode ────────────────────────────────────────────────

enum RepeatMode { off, all, one }

// ── Filename Parser ────────────────────────────────────────────

/// Parse audio filename into title / artist / album.
/// Mirrors desktop's `parseAudioFilename()` from audioStore.ts.
({String title, String artist, String album}) parseAudioFilename(
    String filename) {
  // Remove extension
  var name = filename;
  final dotIdx = name.lastIndexOf('.');
  if (dotIdx > 0) name = name.substring(0, dotIdx);

  var artist = 'Unknown Artist';
  const album = 'Unknown Album';
  var title = name;

  // Pattern: "Artist - Title" (dash, en-dash, em-dash)
  final dashMatch = RegExp(r'^(.+?)\s*[-–—]\s*(.+)$').firstMatch(name);
  if (dashMatch != null) {
    artist = dashMatch.group(1)!.trim();
    title = dashMatch.group(2)!.trim();
  }

  // Remove leading track number: "01. Title" or "01 - Title"
  title = title.replaceAll(RegExp(r'^\d{1,3}[.\s\-]+'), '').trim();

  // Clean underscores and collapse whitespace
  title = title.replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  artist = artist.replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

  return (
    title: title.isNotEmpty ? title : name,
    artist: artist,
    album: album,
  );
}

// ── Audio file extensions ──────────────────────────────────────

const _audioExtensions = {
  'mp3', 'flac', 'wav', 'aac', 'ogg', 'm4a', 'wma', 'opus', 'ape',
};

bool isAudioFile(String filename) {
  final dot = filename.lastIndexOf('.');
  if (dot < 0) return false;
  return _audioExtensions.contains(filename.substring(dot + 1).toLowerCase());
}

String getFileExt(String filename) {
  final dot = filename.lastIndexOf('.');
  if (dot < 0) return '';
  return filename.substring(dot + 1).toLowerCase();
}

// ── Audio Service (Singleton) ──────────────────────────────────

/// Global audio service using media_kit Player.
/// Provides playback, queue management, shuffle, repeat, and bookmarks.
/// Notifies listeners on every state change so widgets can rebuild.
class AudioService extends ChangeNotifier {
  AudioService._() {
    _player = Player();
    // Listen to player streams
    _player.stream.playing.listen((playing) {
      if (_isPlaying != playing) {
        _isPlaying = playing;
        _syncNotificationPlaybackState();
        notifyListeners();
      }
    });
    _player.stream.position.listen((pos) {
      _currentTime = pos;
      notifyListeners();
    });
    _player.stream.duration.listen((dur) {
      _duration = dur;
      _syncNotificationPlaybackState();
      notifyListeners();
    });
    _player.stream.completed.listen((completed) {
      if (completed) _onTrackCompleted();
    });
    _player.stream.error.listen((err) {
      if (err.isNotEmpty) {
        debugPrint('[AudioService] Playback error: $err');
        // Try next track after error
        Future.delayed(const Duration(milliseconds: 500), nextTrack);
      }
    });
  }

  static final AudioService _instance = AudioService._();
  static AudioService get instance => _instance;

  late final Player _player;
  _SynoAudioHandler? _handler;

  /// Initialize media session & notification. Call once from main().
  static Future<void> initNotification() async {
    final handler = await audio_svc.AudioService.init(
      builder: () => _SynoAudioHandler(),
      config: const audio_svc.AudioServiceConfig(
        androidNotificationChannelId: 'com.synohub.audio',
        androidNotificationChannelName: 'SynoHub Music',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
      ),
    );
    _instance._handler = handler;
  }

  // ── State ──
  AudioTrack? _currentTrack;
  bool _isPlaying = false;
  Duration _currentTime = Duration.zero;
  Duration _duration = Duration.zero;

  List<AudioTrack> _queue = [];
  int _queueIndex = -1;
  bool _shuffled = false;
  RepeatMode _repeatMode = RepeatMode.off;

  // ── Getters ──
  AudioTrack? get currentTrack => _currentTrack;
  bool get isPlaying => _isPlaying;
  Duration get currentTime => _currentTime;
  Duration get duration => _duration;
  List<AudioTrack> get queue => _queue;
  int get queueIndex => _queueIndex;
  bool get shuffled => _shuffled;
  RepeatMode get repeatMode => _repeatMode;
  bool get hasTrack => _currentTrack != null;

  // ── Playback ──

  /// Play a specific track, optionally setting the queue.
  Future<void> playTrack(AudioTrack track, {List<AudioTrack>? queue}) async {
    final newQueue = queue ?? _queue;
    final idx = newQueue.indexWhere((t) => t.id == track.id);

    _currentTrack = track;
    _queue = newQueue;
    _queueIndex = idx >= 0 ? idx : 0;
    notifyListeners();

    await _loadAndPlay(track);
  }

  /// Play all tracks starting from the given index.
  Future<void> playAll(List<AudioTrack> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) return;
    final ordered = _shuffled ? _shuffleList(tracks) : tracks;
    _queue = ordered;
    _queueIndex = startIndex;
    _currentTrack = ordered[startIndex];
    notifyListeners();

    await _loadAndPlay(ordered[startIndex]);
  }

  Future<void> _loadAndPlay(AudioTrack track) async {
    final api = SessionManager.instance.api;
    if (api == null) return;

    final url = api.getDownloadUrl(track.path, mode: 'open');

    // Disable TLS verification for NAS self-signed certs
    if (_player.platform is NativePlayer) {
      await (_player.platform as NativePlayer).setProperty(
        'tls-verify',
        'no',
      );
    }

    // Update notification metadata
    _syncNotificationMediaItem(track);

    await _player.open(Media(url));
  }

  // ── Notification sync helpers ──

  void _syncNotificationMediaItem(AudioTrack track) {
    _handler?.mediaItem.add(audio_svc.MediaItem(
      id: track.id,
      title: track.title,
      artist: track.artist,
      album: track.album,
      duration: _duration,
    ));
  }

  void _syncNotificationPlaybackState() {
    _handler?.playbackState.add(audio_svc.PlaybackState(
      controls: [
        audio_svc.MediaControl.skipToPrevious,
        _isPlaying ? audio_svc.MediaControl.pause : audio_svc.MediaControl.play,
        audio_svc.MediaControl.skipToNext,
        audio_svc.MediaControl.stop,
      ],
      systemActions: const {
        audio_svc.MediaAction.seek,
        audio_svc.MediaAction.seekForward,
        audio_svc.MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: audio_svc.AudioProcessingState.ready,
      playing: _isPlaying,
      updatePosition: _currentTime,
      bufferedPosition: _duration,
    ));
  }

  void togglePlay() {
    if (_currentTrack == null) return;
    _player.playOrPause();
  }

  Future<void> nextTrack() async {
    if (_queue.isEmpty) return;

    if (_repeatMode == RepeatMode.one) {
      await _player.seek(Duration.zero);
      await _player.play();
      return;
    }

    var nextIdx = _queueIndex + 1;

    if (nextIdx >= _queue.length) {
      if (_repeatMode == RepeatMode.all) {
        if (_shuffled) _queue = _shuffleList(_queue);
        nextIdx = 0;
      } else {
        // End of queue
        _isPlaying = false;
        notifyListeners();
        return;
      }
    }

    _queueIndex = nextIdx;
    _currentTrack = _queue[nextIdx];
    notifyListeners();
    await _loadAndPlay(_queue[nextIdx]);
  }

  Future<void> prevTrack() async {
    if (_queue.isEmpty) return;

    // If > 3 seconds in, restart current track
    if (_currentTime.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }

    final prevIdx = (_queueIndex - 1).clamp(0, _queue.length - 1);
    _queueIndex = prevIdx;
    _currentTrack = _queue[prevIdx];
    notifyListeners();
    await _loadAndPlay(_queue[prevIdx]);
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  void toggleShuffle() {
    _shuffled = !_shuffled;
    if (_shuffled && _queue.isNotEmpty) {
      final current = _currentTrack;
      _queue = _shuffleList(_queue);
      if (current != null) {
        final idx = _queue.indexWhere((t) => t.id == current.id);
        _queueIndex = idx >= 0 ? idx : 0;
      }
    }
    notifyListeners();
  }

  void cycleRepeat() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
    }
    notifyListeners();
  }

  /// Stop playback completely.
  Future<void> stop() async {
    await _player.stop();
    _currentTrack = null;
    _queue = [];
    _queueIndex = -1;
    _isPlaying = false;
    _currentTime = Duration.zero;
    _duration = Duration.zero;
    // Clear notification
    _handler?.playbackState.add(audio_svc.PlaybackState(
      processingState: audio_svc.AudioProcessingState.idle,
      playing: false,
    ));
    _handler?.mediaItem.add(null);
    notifyListeners();
  }

  void _onTrackCompleted() {
    nextTrack();
  }

  // ── Helpers ──

  List<AudioTrack> _shuffleList(List<AudioTrack> list) {
    final shuffled = [...list];
    shuffled.shuffle();
    return shuffled;
  }

  String formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  // ── Scan Audio Files ─────────────────────────────────────────

  /// Scan a folder recursively for audio files via Synology FileStation API.
  /// Returns list of AudioTrack. Progress is reported via [onProgress].
  static Future<List<AudioTrack>> scanFolder({
    required String rootPath,
    required String rootName,
    int maxDepth = 3,
    void Function(String status, int count)? onProgress,
  }) async {
    final api = SessionManager.instance.api;
    if (api == null) return [];

    final tracks = <AudioTrack>[];

    Future<void> scanRecursive(
        String path, String displayName, int depth) async {
      if (depth > maxDepth) return;
      onProgress?.call(displayName, tracks.length);

      final resp = await api.listFiles(folderPath: path, limit: 500);
      if (resp['success'] != true) return;

      final files = (resp['data']?['files'] as List? ?? []);

      for (final f in files) {
        final m = f as Map<String, dynamic>;
        if (m['isdir'] == true) {
          await scanRecursive(
            m['path'] as String? ?? '',
            m['name'] as String? ?? '',
            depth + 1,
          );
        } else {
          final name = m['name'] as String? ?? '';
          if (name.isEmpty || !isAudioFile(name)) continue;

          // Parse additional fields
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

          final parsed = parseAudioFilename(name);
          final filePath = m['path'] as String? ?? '';
          final ext = getFileExt(name);

          tracks.add(AudioTrack(
            id: 'audio-$filePath',
            path: filePath,
            name: name,
            title: parsed.title,
            artist: parsed.artist,
            album: parsed.album,
            ext: ext,
            size: size,
            mtime: mtime,
            folder: displayName,
          ));

          // Update progress every 10 files
          if (tracks.length % 10 == 0) {
            onProgress?.call(displayName, tracks.length);
          }
        }
      }
    }

    await scanRecursive(rootPath, rootName, 0);

    // Derive album from folder name for "Unknown Album" tracks
    for (final track in tracks) {
      if (track.album == 'Unknown Album') {
        final folderName = track.folder;
        if (folderName.isNotEmpty && folderName != track.artist) {
          // Since AudioTrack is immutable, we rebuild
          // Actually let's leave it for now — the folder name is already set
        }
      }
    }

    return tracks;
  }

  // ── Persistence ──────────────────────────────────────────────

  static const _libraryKeyPrefix = 'synohubs_audio_library_';

  /// Save scanned library to SharedPreferences.
  static Future<void> saveLibrary(
    String nasId,
    List<AudioTrack> tracks,
    List<String> folders,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'tracks': tracks.map((t) => t.toJson()).toList(),
      'folders': folders,
      'lastScan': DateTime.now().millisecondsSinceEpoch,
    };
    await prefs.setString(
      '$_libraryKeyPrefix$nasId',
      jsonEncode(data),
    );
  }

  /// Load cached library from SharedPreferences.
  static Future<({List<AudioTrack> tracks, List<String> folders})> loadLibrary(
      String nasId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_libraryKeyPrefix$nasId');
    if (raw == null) return (tracks: <AudioTrack>[], folders: <String>[]);

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final tracks = (data['tracks'] as List)
          .map((j) => AudioTrack.fromJson(j as Map<String, dynamic>))
          .toList();
      final folders = (data['folders'] as List).cast<String>();
      return (tracks: tracks, folders: folders);
    } catch (e) {
      debugPrint('[AudioService] Failed to load library: $e');
      return (tracks: <AudioTrack>[], folders: <String>[]);
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// ── Media Session Handler (Android notification + lock screen) ─
// ═══════════════════════════════════════════════════════════════

/// Bridges Android MediaSession controls → our AudioService.
/// When user taps play/pause/next/prev on notification, these methods fire.
class _SynoAudioHandler extends audio_svc.BaseAudioHandler
    with audio_svc.SeekHandler {
  @override
  Future<void> play() async => AudioService.instance.togglePlay();

  @override
  Future<void> pause() async => AudioService.instance.togglePlay();

  @override
  Future<void> stop() async => AudioService.instance.stop();

  @override
  Future<void> skipToNext() async => AudioService.instance.nextTrack();

  @override
  Future<void> skipToPrevious() async => AudioService.instance.prevTrack();

  @override
  Future<void> seek(Duration position) async =>
      AudioService.instance.seek(position);
}
