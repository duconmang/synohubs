import React, { useRef, useEffect, useCallback } from 'react';
import { invoke } from '@tauri-apps/api/core';
import {
  Play, Pause, SkipBack, SkipForward, Shuffle, Repeat, Repeat1,
  Volume2, VolumeX, Music, Bookmark, BookmarkCheck
} from 'lucide-react';
import { useAudioStore } from '../../stores/audioStore';
import '../../screens/Media/Music.css';

// Mini Player — persistent playback controls
// Renders at App level so music continues across all tabs.
// Uses a hidden <audio> element for actual playback.
const MiniPlayer: React.FC = () => {
  const {
    currentTrack, isPlaying, volume, currentTime, duration,
    queue, queueIndex, shuffled, repeatMode,
    togglePlay, nextTrack, prevTrack, seek, setVolume,
    setCurrentTime, setDuration,
    toggleShuffle, cycleRepeat,
    saveBookmark, getBookmark, clearBookmark, bookmarks,
  } = useAudioStore();

  const audioRef = useRef<HTMLAudioElement>(null);
  const progressRef = useRef<HTMLDivElement>(null);
  const volumeRef = useRef<HTMLDivElement>(null);

  // ── Build stream URL via proxy ──
  const getStreamUrl = useCallback(async (path: string): Promise<string> => {
    try {
      const proxyPort: number = await invoke('get_proxy_port');
      return `http://localhost:${proxyPort}/stream?path=${encodeURIComponent(path)}`;
    } catch {
      // Fallback to direct stream URL
      const url: string = await invoke('media_get_stream_url', { path });
      return url;
    }
  }, []);

  // ── Track change → load audio ──
  useEffect(() => {
    if (!currentTrack || !audioRef.current) return;

    const loadTrack = async () => {
      const url = await getStreamUrl(currentTrack.path);
      const audio = audioRef.current!;
      audio.src = url;
      audio.volume = volume;

      // Check for bookmark → resume
      const bookmark = getBookmark(currentTrack.id);
      if (bookmark && bookmark > 0) {
        audio.currentTime = bookmark;
      }

      if (isPlaying) {
        audio.play().catch(e => console.warn('Autoplay error:', e));
      }
    };

    loadTrack();
  }, [currentTrack?.id]);

  // ── Play/Pause sync ──
  useEffect(() => {
    if (!audioRef.current || !currentTrack) return;
    if (isPlaying) {
      audioRef.current.play().catch(() => {});
    } else {
      audioRef.current.pause();
    }
  }, [isPlaying]);

  // ── Volume sync ──
  useEffect(() => {
    if (audioRef.current) audioRef.current.volume = volume;
  }, [volume]);

  // ── Seek sync ──
  useEffect(() => {
    if (!audioRef.current) return;
    const diff = Math.abs(audioRef.current.currentTime - currentTime);
    if (diff > 1.5) {
      audioRef.current.currentTime = currentTime;
    }
  }, [currentTime]);

  // ── Audio event handlers ──
  const handleTimeUpdate = () => {
    if (audioRef.current) {
      setCurrentTime(audioRef.current.currentTime);
    }
  };

  const handleLoadedMetadata = () => {
    if (audioRef.current) {
      setDuration(audioRef.current.duration);
    }
  };

  const handleEnded = () => {
    // Auto-save bookmark when track ends (clear it = completed)
    if (currentTrack) clearBookmark(currentTrack.id);
    nextTrack();
  };

  const handleError = () => {
    console.warn('Audio playback error for:', currentTrack?.name);
    // Try next track
    setTimeout(nextTrack, 500);
  };

  // ── Progress bar click ──
  const handleProgressClick = (e: React.MouseEvent<HTMLDivElement>) => {
    if (!progressRef.current || !duration) return;
    const rect = progressRef.current.getBoundingClientRect();
    const pct = (e.clientX - rect.left) / rect.width;
    seek(pct * duration);
  };

  // ── Volume bar click ──
  const handleVolumeClick = (e: React.MouseEvent<HTMLDivElement>) => {
    if (!volumeRef.current) return;
    const rect = volumeRef.current.getBoundingClientRect();
    const pct = Math.max(0, Math.min(1, (e.clientX - rect.left) / rect.width));
    setVolume(pct);
  };

  // ── Format time ──
  const formatTime = (s: number): string => {
    if (!s || isNaN(s)) return '0:00';
    const m = Math.floor(s / 60);
    const sec = Math.floor(s % 60);
    return `${m}:${sec.toString().padStart(2, '0')}`;
  };

  // ── Bookmark toggle ──
  const toggleBookmark = () => {
    if (!currentTrack) return;
    if (bookmarks[currentTrack.id]) {
      clearBookmark(currentTrack.id);
    } else {
      saveBookmark(currentTrack.id, audioRef.current?.currentTime || currentTime);
    }
  };

  // ── Auto-bookmark on pause (save position) ──
  useEffect(() => {
    if (!currentTrack || !audioRef.current) return;
    if (!isPlaying && currentTime > 5 && duration > 0 && currentTime < duration - 5) {
      saveBookmark(currentTrack.id, currentTime);
    }
  }, [isPlaying]);

  // Don't render if no track loaded
  if (!currentTrack) return null;

  const progressPct = duration > 0 ? (currentTime / duration) * 100 : 0;
  const hasBookmark = !!bookmarks[currentTrack.id];

  return (
    <>
      {/* Hidden audio element */}
      <audio
        ref={audioRef}
        onTimeUpdate={handleTimeUpdate}
        onLoadedMetadata={handleLoadedMetadata}
        onEnded={handleEnded}
        onError={handleError}
        preload="auto"
      />

      <div className={`mini-player ${isPlaying ? 'mini-player--playing' : ''}`}>
        {/* Left: Track info */}
        <div className="mini-player__track">
          <div className="mini-player__cover">
            <Music size={18} />
            <div className="mini-player__cover-pulse" />
          </div>
          <div className="mini-player__info">
            <div className="mini-player__title">{currentTrack.title}</div>
            <div className="mini-player__artist">{currentTrack.artist}</div>
          </div>
        </div>

        {/* Center: Controls + Progress */}
        <div className="mini-player__controls">
          <div className="mini-player__buttons">
            <button
              className={`mini-player__btn ${shuffled ? 'mini-player__btn--active' : ''}`}
              onClick={toggleShuffle}
              title={shuffled ? 'Shuffle: On' : 'Shuffle: Off'}
            >
              <Shuffle size={14} />
            </button>
            <button className="mini-player__btn" onClick={prevTrack} title="Previous">
              <SkipBack size={16} />
            </button>
            <button className="mini-player__btn mini-player__btn--play" onClick={togglePlay}>
              {isPlaying ? <Pause size={18} /> : <Play size={18} style={{ marginLeft: 2 }} />}
            </button>
            <button className="mini-player__btn" onClick={nextTrack} title="Next">
              <SkipForward size={16} />
            </button>
            <button
              className={`mini-player__btn ${repeatMode !== 'off' ? 'mini-player__btn--active' : ''}`}
              onClick={cycleRepeat}
              title={`Repeat: ${repeatMode}`}
            >
              {repeatMode === 'one' ? <Repeat1 size={14} /> : <Repeat size={14} />}
            </button>
          </div>

          <div className="mini-player__progress">
            <span className="mini-player__time">{formatTime(currentTime)}</span>
            <div
              className="mini-player__progress-bar"
              ref={progressRef}
              onClick={handleProgressClick}
            >
              <div
                className="mini-player__progress-fill"
                style={{ width: `${progressPct}%` }}
              />
            </div>
            <span className="mini-player__time">{formatTime(duration)}</span>
          </div>
        </div>

        {/* Right: Volume + Bookmark */}
        <div className="mini-player__right">
          <button
            className={`mini-player__bookmark-btn ${hasBookmark ? 'mini-player__bookmark-btn--active' : ''}`}
            onClick={toggleBookmark}
            title={hasBookmark ? 'Remove bookmark' : 'Bookmark position'}
          >
            {hasBookmark ? <BookmarkCheck size={14} /> : <Bookmark size={14} />}
          </button>

          <div className="mini-player__volume">
            <button
              className="mini-player__btn"
              onClick={() => setVolume(volume > 0 ? 0 : 0.7)}
              title={volume === 0 ? 'Unmute' : 'Mute'}
            >
              {volume === 0 ? <VolumeX size={14} /> : <Volume2 size={14} />}
            </button>
            <div
              className="mini-player__volume-bar"
              ref={volumeRef}
              onClick={handleVolumeClick}
            >
              <div
                className="mini-player__volume-fill"
                style={{ width: `${volume * 100}%` }}
              />
            </div>
          </div>

          <span style={{ fontSize: 9, color: 'var(--color-text-dim)', minWidth: 40, textAlign: 'right' }}>
            {queueIndex + 1}/{queue.length}
          </span>
        </div>
      </div>
    </>
  );
};

export default MiniPlayer;
