import React, { useState, useCallback, useMemo, useEffect } from 'react';
import { invoke } from '@tauri-apps/api/core';
import {
  Music as MusicIcon, Search, Play, Loader, FolderOpen, FolderPlus,
  ChevronRight, CheckCircle, RefreshCw, User, Disc3, Bookmark,
  ListMusic
} from 'lucide-react';
import { useAudioStore, parseAudioFilename, AudioTrack } from '../../stores/audioStore';
import { useNasStore } from '../../stores';
import './Music.css';

const MusicTab: React.FC = () => {
  const { activeNas } = useNasStore();
  const nasId = activeNas?.id || 'default';

  const {
    tracks, folders, scanning, scanProgress, setTracks, setScanning,
    playTrack, playAll, currentTrack, isPlaying,
    musicView, setMusicView, bookmarks, loadForNas,
  } = useAudioStore();

  const [search, setSearch] = useState('');
  const [showSetup, setShowSetup] = useState(false);
  const [selectedFolders, setSelectedFolders] = useState<string[]>([]);
  const [pickerPath, setPickerPath] = useState('');
  const [pickerFolders, setPickerFolders] = useState<{ path: string; name: string }[]>([]);
  const [pickerLoading, setPickerLoading] = useState(false);

  // Load audio library for current NAS
  useEffect(() => {
    loadForNas(nasId);
  }, [nasId]);

  // Show setup if no folders configured
  useEffect(() => {
    if (folders.length === 0) setShowSetup(true);
    else setShowSetup(false);
  }, [folders]);

  // ── Folder Picker (reused from Media) ──
  const loadPickerFolders = useCallback(async (path: string) => {
    setPickerLoading(true);
    try {
      if (!path) {
        const resp: any = await invoke('file_list_shares');
        if (resp.success && resp.data?.shares) {
          setPickerFolders(resp.data.shares
            .filter((s: any) => s.isdir !== false)
            .map((s: any) => ({ path: s.path, name: s.name })));
        }
      } else {
        const resp: any = await invoke('file_list', { request: { folder_path: path } });
        if (resp.success && resp.data?.files) {
          setPickerFolders(resp.data.files
            .filter((f: any) => f.isdir)
            .map((f: any) => ({ path: f.path, name: f.name })));
        }
      }
    } catch (err) {
      console.error('Music picker error:', err);
    } finally {
      setPickerLoading(false);
    }
  }, []);

  useEffect(() => {
    if (showSetup) {
      setSelectedFolders([...folders]);
      loadPickerFolders('');
    }
  }, [showSetup]);

  const toggleFolder = (path: string) => {
    setSelectedFolders(prev =>
      prev.includes(path) ? prev.filter(p => p !== path) : [...prev, path]
    );
  };

  // ── Audio Scan ──
  const startScan = async (foldersToScan: string[]) => {
    setScanning(true, 'Starting audio scan...');
    setShowSetup(false);

    const allTracks: AudioTrack[] = [];

    for (let i = 0; i < foldersToScan.length; i++) {
      const folder = foldersToScan[i];
      setScanning(true, `Scanning ${folder.split('/').pop()} (${i + 1}/${foldersToScan.length})...`);

      try {
        const result: any = await invoke('audio_scan_folder', { folderPath: folder });
        if (result.success && result.files) {
          for (const f of result.files) {
            const { title, artist, album } = parseAudioFilename(f.name);
            allTracks.push({
              id: `audio-${f.path}`,
              path: f.path,
              name: f.name,
              title,
              artist,
              album,
              ext: f.ext || '',
              size: f.size || 0,
              mtime: f.mtime || 0,
              folder: f.folder || folder,
            });
          }
        }
      } catch (err) {
        console.error(`Scan error for ${folder}:`, err);
      }
    }

    // Derive album from folder name for tracks with Unknown Album
    for (const track of allTracks) {
      if (track.album === 'Unknown Album') {
        const folderName = track.folder.split('/').pop() || '';
        if (folderName && folderName !== track.artist) {
          track.album = folderName;
        }
      }
    }

    setTracks(allTracks, foldersToScan);
    setScanning(false);
  };

  // ── Filtered & Grouped Data ──
  const filtered = useMemo(() => {
    if (!search) return tracks;
    const q = search.toLowerCase();
    return tracks.filter(t =>
      t.title.toLowerCase().includes(q) ||
      t.artist.toLowerCase().includes(q) ||
      t.album.toLowerCase().includes(q) ||
      t.name.toLowerCase().includes(q)
    );
  }, [tracks, search]);

  const artistGroups = useMemo(() => {
    const map = new Map<string, AudioTrack[]>();
    filtered.forEach(t => {
      const key = t.artist;
      if (!map.has(key)) map.set(key, []);
      map.get(key)!.push(t);
    });
    return Array.from(map.entries()).sort((a, b) => a[0].localeCompare(b[0]));
  }, [filtered]);

  const albumGroups = useMemo(() => {
    const map = new Map<string, AudioTrack[]>();
    filtered.forEach(t => {
      const key = `${t.artist} — ${t.album}`;
      if (!map.has(key)) map.set(key, []);
      map.get(key)!.push(t);
    });
    return Array.from(map.entries()).sort((a, b) => a[0].localeCompare(b[0]));
  }, [filtered]);

  // ── Scanning Progress ──
  if (scanning) {
    return (
      <div className="music">
        <div className="music__setup">
          <div className="music__setup-icon">
            <Loader size={28} className="animate-spin" />
          </div>
          <h3>Scanning Audio Library</h3>
          <p>{scanProgress}</p>
        </div>
      </div>
    );
  }

  // ── Setup ──
  if (showSetup) {
    return (
      <div className="music">
        <div className="media__setup-overlay">
          <div className="media__setup">
            <div className="media__setup-header">
              <MusicIcon size={28} className="media__setup-icon" />
              <h2>Setup Your Music Library</h2>
              <p>Select folders on your NAS that contain audio files</p>
            </div>

            <div className="media__picker">
              <div className="media__picker-nav">
                <button className="btn btn-ghost btn-sm" onClick={() => { setPickerPath(''); loadPickerFolders(''); }}>
                  <FolderOpen size={14} /> Root
                </button>
                {pickerPath && (
                  <>
                    <ChevronRight size={12} />
                    <span className="media__picker-path">{pickerPath}</span>
                  </>
                )}
              </div>

              <div className="media__picker-list">
                {pickerLoading ? (
                  <div className="media__picker-loading"><Loader size={20} className="animate-spin" /></div>
                ) : (
                  pickerFolders.map(f => {
                    const isSelected = selectedFolders.includes(f.path);
                    return (
                      <div key={f.path} className={`media__picker-item ${isSelected ? 'media__picker-item--selected' : ''}`}>
                        <div className="media__picker-item-left" onClick={() => { setPickerPath(f.path); loadPickerFolders(f.path); }}>
                          <FolderOpen size={16} className="media__picker-folder-icon" />
                          <span>{f.name}</span>
                          <ChevronRight size={12} className="media__picker-chevron" />
                        </div>
                        <button
                          className={`media__picker-select-btn ${isSelected ? 'media__picker-select-btn--active' : ''}`}
                          onClick={() => toggleFolder(f.path)}
                        >
                          {isSelected ? <CheckCircle size={16} /> : <FolderPlus size={16} />}
                        </button>
                      </div>
                    );
                  })
                )}
              </div>

              {selectedFolders.length > 0 && (
                <div className="media__picker-selected">
                  <div className="media__picker-selected-label">Selected ({selectedFolders.length}):</div>
                  {selectedFolders.map(f => (
                    <div key={f} className="media__picker-selected-item">
                      <FolderOpen size={12} />
                      <span>{f}</span>
                    </div>
                  ))}
                </div>
              )}
            </div>

            <div className="media__setup-actions">
              <button
                className="btn btn-primary media__scan-btn"
                onClick={() => startScan(selectedFolders)}
                disabled={selectedFolders.length === 0}
              >
                <Search size={16} /> Start Scanning
              </button>
              {tracks.length > 0 && (
                <button className="btn btn-ghost btn-sm" onClick={() => setShowSetup(false)}>Cancel</button>
              )}
            </div>
          </div>
        </div>
      </div>
    );
  }

  // ── Main Music View ──
  return (
    <div className="music">
      {/* Header */}
      <div className="music__header">
        <div className="music__header-left">
          <h2><MusicIcon size={16} /> Music</h2>
          <div className="music__view-toggle">
            {(['all', 'artists', 'albums'] as const).map(v => (
              <button
                key={v}
                className={`music__view-btn ${musicView === v ? 'music__view-btn--active' : ''}`}
                onClick={() => setMusicView(v)}
              >
                {v === 'all' ? '♫ All' : v === 'artists' ? '👤 Artists' : '💿 Albums'}
              </button>
            ))}
          </div>
        </div>

        <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
          <div className="music__search">
            <Search size={13} />
            <input
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Search music..."
            />
          </div>
          <button className="btn btn-ghost btn-icon" onClick={() => setShowSetup(true)} title="Configure folders">
            <RefreshCw size={14} />
          </button>
        </div>
      </div>

      {/* Stats */}
      <div className="music__stats">
        <span>{filtered.length} tracks</span>
        <span>{artistGroups.length} artists</span>
        <span>{albumGroups.length} albums</span>
        {filtered.length > 0 && (
          <button className="music__play-all" onClick={() => playAll(filtered)}>
            <Play size={12} /> Play All
          </button>
        )}
      </div>

      {/* Content */}
      <div className="music__table">
        {musicView === 'all' && (
          <>
            <div className="music__table-header">
              <span>#</span>
              <span>Title</span>
              <span>Artist</span>
              <span>Album</span>
              <span style={{ textAlign: 'right' }}>Format</span>
            </div>
            {filtered.map((track, idx) => (
              <SongRow
                key={track.id}
                track={track}
                index={idx + 1}
                isPlaying={currentTrack?.id === track.id && isPlaying}
                isCurrent={currentTrack?.id === track.id}
                hasBookmark={!!bookmarks[track.id]}
                onPlay={() => playTrack(track, filtered)}
              />
            ))}
          </>
        )}

        {musicView === 'artists' && (
          artistGroups.map(([artist, artistTracks]) => (
            <ArtistGroup
              key={artist}
              name={artist}
              tracks={artistTracks}
              currentTrackId={currentTrack?.id}
              isPlaying={isPlaying}
              onPlayAll={() => playAll(artistTracks)}
              onPlayTrack={(t) => playTrack(t, artistTracks)}
              bookmarks={bookmarks}
            />
          ))
        )}

        {musicView === 'albums' && (
          albumGroups.map(([albumKey, albumTracks]) => (
            <AlbumGroup
              key={albumKey}
              name={albumKey}
              tracks={albumTracks}
              currentTrackId={currentTrack?.id}
              isPlaying={isPlaying}
              onPlayAll={() => playAll(albumTracks)}
              onPlayTrack={(t) => playTrack(t, albumTracks)}
              bookmarks={bookmarks}
            />
          ))
        )}

        {filtered.length === 0 && !scanning && (
          <div className="music__setup">
            <ListMusic size={32} style={{ opacity: 0.3 }} />
            <p>{search ? 'No tracks match your search' : 'No audio files found'}</p>
          </div>
        )}
      </div>
    </div>
  );
};

// ── Song Row ──
const SongRow: React.FC<{
  track: AudioTrack;
  index: number;
  isPlaying: boolean;
  isCurrent: boolean;
  hasBookmark: boolean;
  onPlay: () => void;
}> = ({ track, index, isPlaying, isCurrent, hasBookmark, onPlay }) => (
  <div
    className={`music__song ${isCurrent ? 'music__song--playing' : ''}`}
    onClick={onPlay}
    onDoubleClick={onPlay}
  >
    <div className="music__song-num">
      {isCurrent && isPlaying ? (
        <div className="music__song-equalizer">
          <span /><span /><span /><span />
        </div>
      ) : (
        index
      )}
    </div>
    <div className="music__song-title">
      {track.title}
      {hasBookmark && <Bookmark size={10} className="music__song-bookmark" />}
    </div>
    <div className="music__song-artist">{track.artist}</div>
    <div className="music__song-album">{track.album}</div>
    <div className="music__song-ext">{track.ext}</div>
  </div>
);

// ── Artist Group ──
const ArtistGroup: React.FC<{
  name: string;
  tracks: AudioTrack[];
  currentTrackId?: string;
  isPlaying: boolean;
  onPlayAll: () => void;
  onPlayTrack: (t: AudioTrack) => void;
  bookmarks: Record<string, any>;
}> = ({ name, tracks, currentTrackId, isPlaying, onPlayAll, onPlayTrack, bookmarks }) => {
  const [expanded, setExpanded] = useState(false);

  return (
    <div className="music__group">
      <div className="music__group-header" onClick={() => setExpanded(!expanded)}>
        <div className="music__group-icon">
          <User size={16} />
        </div>
        <div className="music__group-info">
          <div className="music__group-name">{name}</div>
          <div className="music__group-count">{tracks.length} tracks</div>
        </div>
        <button className="music__group-play" onClick={e => { e.stopPropagation(); onPlayAll(); }}>
          <Play size={14} />
        </button>
      </div>
      {expanded && tracks.map((t, i) => (
        <SongRow
          key={t.id}
          track={t}
          index={i + 1}
          isPlaying={currentTrackId === t.id && isPlaying}
          isCurrent={currentTrackId === t.id}
          hasBookmark={!!bookmarks[t.id]}
          onPlay={() => onPlayTrack(t)}
        />
      ))}
    </div>
  );
};

// ── Album Group ──
const AlbumGroup: React.FC<{
  name: string;
  tracks: AudioTrack[];
  currentTrackId?: string;
  isPlaying: boolean;
  onPlayAll: () => void;
  onPlayTrack: (t: AudioTrack) => void;
  bookmarks: Record<string, any>;
}> = ({ name, tracks, currentTrackId, isPlaying, onPlayAll, onPlayTrack, bookmarks }) => {
  const [expanded, setExpanded] = useState(false);

  return (
    <div className="music__group">
      <div className="music__group-header" onClick={() => setExpanded(!expanded)}>
        <div className="music__group-icon music__group-album-icon">
          <Disc3 size={16} />
        </div>
        <div className="music__group-info">
          <div className="music__group-name">{name}</div>
          <div className="music__group-count">{tracks.length} tracks</div>
        </div>
        <button className="music__group-play" onClick={e => { e.stopPropagation(); onPlayAll(); }}>
          <Play size={14} />
        </button>
      </div>
      {expanded && tracks.map((t, i) => (
        <SongRow
          key={t.id}
          track={t}
          index={i + 1}
          isPlaying={currentTrackId === t.id && isPlaying}
          isCurrent={currentTrackId === t.id}
          hasBookmark={!!bookmarks[t.id]}
          onPlay={() => onPlayTrack(t)}
        />
      ))}
    </div>
  );
};

export default MusicTab;
