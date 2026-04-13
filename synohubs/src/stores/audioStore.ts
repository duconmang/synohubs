import { create } from 'zustand';

// ── Types ──

export interface AudioTrack {
  id: string;
  path: string;
  name: string;
  title: string;
  artist: string;
  album: string;
  ext: string;
  size: number;
  mtime: number;
  folder: string;
  duration?: number;       // seconds (set after play)
  coverUrl?: string;
}

export interface AudioBookmark {
  trackId: string;
  position: number;  // seconds
  timestamp: number; // when bookmarked
}

export type RepeatMode = 'off' | 'all' | 'one';

export interface AudioState {
  // Current NAS context
  nasId: string;

  // Library
  tracks: AudioTrack[];
  folders: string[];
  lastScan: number;
  scanning: boolean;
  scanProgress: string;

  // Player
  currentTrack: AudioTrack | null;
  isPlaying: boolean;
  volume: number;         // 0-1
  currentTime: number;
  duration: number;

  // Queue
  queue: AudioTrack[];
  queueIndex: number;
  shuffled: boolean;
  repeatMode: RepeatMode;

  // Bookmarks
  bookmarks: Record<string, AudioBookmark>;

  // UI
  musicView: 'all' | 'artists' | 'albums';

  // Actions
  loadForNas: (nasId: string) => void;
  setTracks: (tracks: AudioTrack[], folders: string[]) => void;
  setScanning: (scanning: boolean, progress?: string) => void;
  
  // Player actions
  playTrack: (track: AudioTrack, queue?: AudioTrack[]) => void;
  playAll: (tracks: AudioTrack[], startIndex?: number) => void;
  togglePlay: () => void;
  nextTrack: () => void;
  prevTrack: () => void;
  seek: (time: number) => void;
  setVolume: (vol: number) => void;
  setCurrentTime: (time: number) => void;
  setDuration: (dur: number) => void;
  setIsPlaying: (playing: boolean) => void;

  // Queue
  toggleShuffle: () => void;
  cycleRepeat: () => void;
  addToQueue: (track: AudioTrack) => void;
  removeFromQueue: (index: number) => void;
  clearQueue: () => void;

  // Bookmarks
  saveBookmark: (trackId: string, position: number) => void;
  getBookmark: (trackId: string) => number | undefined;
  clearBookmark: (trackId: string) => void;

  // UI
  setMusicView: (view: 'all' | 'artists' | 'albums') => void;
}

// Storage key helpers — all per-NAS
const audioKey     = (nasId: string) => `synohubs_audio_library_${nasId}`;
const bookmarkKey  = (nasId: string) => `synohubs_audio_bookmarks_${nasId}`;
const VOLUME_KEY = 'synohubs_audio_volume'; // volume is global, not per-NAS

// Load persisted data for a specific NAS
function loadLibrary(nasId: string): { tracks: AudioTrack[]; folders: string[]; lastScan: number } {
  try {
    const raw = localStorage.getItem(audioKey(nasId));
    if (raw) return JSON.parse(raw);
  } catch {}
  return { tracks: [], folders: [], lastScan: 0 };
}

function loadBookmarks(nasId: string): Record<string, AudioBookmark> {
  try {
    const raw = localStorage.getItem(bookmarkKey(nasId));
    if (raw) return JSON.parse(raw);
  } catch {}
  return {};
}

function loadVolume(): number {
  try {
    const v = localStorage.getItem(VOLUME_KEY);
    if (v) return parseFloat(v);
  } catch {}
  return 0.7;
}

// Shuffle helper
function shuffleArray<T>(arr: T[]): T[] {
  const shuffled = [...arr];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }
  return shuffled;
}

// Parse filename into title/artist/album
export function parseAudioFilename(filename: string): { title: string; artist: string; album: string } {
  // Remove extension
  let name = filename.replace(/\.[^/.]+$/, '');
  
  let artist = 'Unknown Artist';
  let album = 'Unknown Album';
  let title = name;

  // Pattern: "Artist - Title"
  const dashMatch = name.match(/^(.+?)\s*[-–—]\s*(.+)$/);
  if (dashMatch) {
    artist = dashMatch[1].trim();
    title = dashMatch[2].trim();
  }

  // Pattern: "01. Title" or "01 - Title" (track number)
  title = title.replace(/^\d{1,3}[\.\s\-]+/, '').trim();

  // Clean underscores/dots
  title = title.replace(/[_]/g, ' ').replace(/\s+/g, ' ').trim();
  artist = artist.replace(/[_]/g, ' ').replace(/\s+/g, ' ').trim();

  return { title: title || name, artist, album };
}

export const useAudioStore = create<AudioState>((set, get) => ({
  // NAS context
  nasId: '',

  // Library (empty until loadForNas is called)
  tracks: [],
  folders: [],
  lastScan: 0,
  scanning: false,
  scanProgress: '',

  // Player
  currentTrack: null,
  isPlaying: false,
  volume: loadVolume(),
  currentTime: 0,
  duration: 0,

  // Queue
  queue: [],
  queueIndex: -1,
  shuffled: false,
  repeatMode: 'off' as RepeatMode,

  // Bookmarks
  bookmarks: {},

  // UI
  musicView: 'all' as const,

  // ── Actions ──

  /**
   * Switch to a different NAS context.
   * Loads that NAS's library + bookmarks from localStorage.
   * Stops current playback since tracks belong to a different NAS.
   */
  loadForNas: (nasId: string) => {
    const current = get().nasId;
    if (nasId === current) return; // Same NAS, no-op

    const lib = loadLibrary(nasId);
    const bk = loadBookmarks(nasId);
    set({
      nasId,
      tracks: lib.tracks,
      folders: lib.folders,
      lastScan: lib.lastScan,
      bookmarks: bk,
      // Stop playback when switching NAS
      currentTrack: null,
      isPlaying: false,
      queue: [],
      queueIndex: -1,
      currentTime: 0,
      duration: 0,
      scanning: false,
      scanProgress: '',
    });
  },

  setTracks: (tracks, folders) => {
    const { nasId } = get();
    set({ tracks, folders, lastScan: Date.now() });
    localStorage.setItem(audioKey(nasId), JSON.stringify({ tracks, folders, lastScan: Date.now() }));
  },

  setScanning: (scanning, progress) => set({ scanning, scanProgress: progress || '' }),

  playTrack: (track, queue) => {
    const state = get();
    const newQueue = queue || state.tracks;
    const idx = newQueue.findIndex(t => t.id === track.id);
    set({
      currentTrack: track,
      queue: newQueue,
      queueIndex: idx >= 0 ? idx : 0,
      isPlaying: true,
      currentTime: 0,
    });
  },

  playAll: (tracks, startIndex = 0) => {
    const state = get();
    const ordered = state.shuffled ? shuffleArray(tracks) : tracks;
    set({
      currentTrack: ordered[startIndex] || null,
      queue: ordered,
      queueIndex: startIndex,
      isPlaying: true,
      currentTime: 0,
    });
  },

  togglePlay: () => set(s => ({ isPlaying: !s.isPlaying })),

  nextTrack: () => {
    const { queue, queueIndex, repeatMode, shuffled } = get();
    if (queue.length === 0) return;

    let nextIdx = queueIndex + 1;
    
    if (repeatMode === 'one') {
      set({ currentTime: 0 }); // restart same track
      return;
    }

    if (nextIdx >= queue.length) {
      if (repeatMode === 'all') {
        const newQueue = shuffled ? shuffleArray(queue) : queue;
        set({ queue: newQueue, queueIndex: 0, currentTrack: newQueue[0], currentTime: 0 });
      } else {
        set({ isPlaying: false }); // end of queue
      }
      return;
    }

    set({ queueIndex: nextIdx, currentTrack: queue[nextIdx], currentTime: 0 });
  },

  prevTrack: () => {
    const { queue, queueIndex, currentTime } = get();
    if (queue.length === 0) return;

    // If > 3 seconds in, restart current track
    if (currentTime > 3) {
      set({ currentTime: 0 });
      return;
    }

    const prevIdx = Math.max(0, queueIndex - 1);
    set({ queueIndex: prevIdx, currentTrack: queue[prevIdx], currentTime: 0 });
  },

  seek: (time) => set({ currentTime: time }),
  setVolume: (vol) => {
    set({ volume: vol });
    localStorage.setItem(VOLUME_KEY, vol.toString());
  },
  setCurrentTime: (time) => set({ currentTime: time }),
  setDuration: (dur) => set({ duration: dur }),
  setIsPlaying: (playing) => set({ isPlaying: playing }),

  // Queue
  toggleShuffle: () => {
    const { shuffled, queue, currentTrack } = get();
    if (!shuffled) {
      const newQueue = shuffleArray(queue);
      const idx = newQueue.findIndex(t => t.id === currentTrack?.id);
      set({ shuffled: true, queue: newQueue, queueIndex: idx >= 0 ? idx : 0 });
    } else {
      set({ shuffled: false });
    }
  },

  cycleRepeat: () => {
    const modes: RepeatMode[] = ['off', 'all', 'one'];
    const { repeatMode } = get();
    const nextIdx = (modes.indexOf(repeatMode) + 1) % modes.length;
    set({ repeatMode: modes[nextIdx] });
  },

  addToQueue: (track) => set(s => ({ queue: [...s.queue, track] })),
  removeFromQueue: (index) => set(s => ({
    queue: s.queue.filter((_, i) => i !== index),
    queueIndex: index < s.queueIndex ? s.queueIndex - 1 : s.queueIndex,
  })),
  clearQueue: () => set({ queue: [], queueIndex: -1, currentTrack: null, isPlaying: false }),

  // Bookmarks (per-NAS)
  saveBookmark: (trackId, position) => {
    const { nasId } = get();
    const bookmarks = { ...get().bookmarks };
    bookmarks[trackId] = { trackId, position, timestamp: Date.now() };
    set({ bookmarks });
    localStorage.setItem(bookmarkKey(nasId), JSON.stringify(bookmarks));
  },

  getBookmark: (trackId) => {
    return get().bookmarks[trackId]?.position;
  },

  clearBookmark: (trackId) => {
    const { nasId } = get();
    const bookmarks = { ...get().bookmarks };
    delete bookmarks[trackId];
    set({ bookmarks });
    localStorage.setItem(bookmarkKey(nasId), JSON.stringify(bookmarks));
  },

  // UI
  setMusicView: (view) => set({ musicView: view }),
}));
