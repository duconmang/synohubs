import React, { useEffect, useState, useCallback, useRef } from 'react';
import { invoke } from '@tauri-apps/api/core';
import { openUrl } from '@tauri-apps/plugin-opener';
import mpegts from 'mpegts.js';
import {
  Film, FolderOpen, Search, Play, Clock, Star, Settings,
  RefreshCw, ChevronRight, X, Loader, FolderPlus, CheckCircle,
  Music
} from 'lucide-react';
import MusicTab from './MusicTab';
import { useNasStore } from '../../stores';
import './Media.css';
import './Music.css';

// Formats that need mpegts.js demuxer
const MPEGTS_FORMATS = ['ts', 'flv'];

// ── Types ──

interface MediaItem {
  id: string;
  path: string;
  name: string;
  cleanName: string;
  year?: string;
  size: number;
  mtime: number;
  folder: string;
  category: string;
  posterUrl?: string;
  backdropUrl?: string;
  overview?: string;
  rating?: number;
  thumbnailUrl?: string;
}

interface MediaLibrary {
  folders: string[];
  items: MediaItem[];
  lastScan: number;
}

const TMDB_IMAGE_BASE = 'https://image.tmdb.org/t/p';
const STORAGE_KEY_PREFIX = 'synohubs_media_library_';

// ── Filename Parser ──

function parseFilename(filename: string): { cleanName: string; year?: string } {
  // Remove extension
  let name = filename.replace(/\.[^/.]+$/, '');

  // Extract year from patterns like (2008), [2008], .2008.
  const yearMatch = name.match(/[\.\s\(\[]((?:19|20)\d{2})[\.\s\)\]]/);
  const year = yearMatch ? yearMatch[1] : undefined;

  // Remove year and everything after (quality tags etc.)
  if (yearMatch) {
    name = name.substring(0, yearMatch.index || 0);
  }

  // Remove season/episode patterns: S01E03, S1 EPS 6, Season 1, Episode 3, EP03
  name = name
    .replace(/[\.\s]S\d{1,2}[\.\s]?(?:EP?S?\s*\d+)?/gi, ' ')
    .replace(/[\.\s](?:Season|Series)\s*\d+/gi, ' ')
    .replace(/[\.\s](?:Episode|Ep|Eps|EP)\s*\d+/gi, ' ')
    .replace(/[\.\s]E\d{1,3}(?:\s|$|\.)/gi, ' ')
    .replace(/[\.\s](?:Part|Pt)\s*\d+/gi, ' ');

  // Remove quality/codec tags
  name = name
    .replace(/[\.\s](1080p|720p|480p|2160p|4K|UHD|HDR)/gi, ' ')
    .replace(/[\.\s](BluRay|BRRip|WEB[\-]?DL|WEBRip|HDTV|DVDRip|HDRip)/gi, ' ')
    .replace(/[\.\s](x264|x265|H\.?264|H\.?265|HEVC|AVC|AAC|DTS|AC3)/gi, ' ')
    .replace(/[\.\s](REMUX|PROPER|REPACK|EXTENDED|UNRATED|DUBBED)/gi, ' ');

  // Clean up separators
  name = name
    .replace(/[\.\-_]/g, ' ')
    .replace(/\s+/g, ' ')
    .replace(/\[.*?\]/g, '')
    .replace(/\(.*?\)/g, '')
    .trim();

  return { cleanName: name || filename, year };
}

function getCategoryFromPath(filePath: string, baseFolders: string[]): string {
  for (const base of baseFolders) {
    if (filePath.startsWith(base)) {
      const relative = filePath.substring(base.length + 1);
      const parts = relative.split('/');
      if (parts.length > 1) {
        return parts[0]; // First subfolder = category
      }
    }
  }
  return 'Uncategorized';
}

// ── Component ──

const Media: React.FC = () => {
  const { activeNas } = useNasStore();
  const nasId = activeNas?.id || 'default';
  const storageKey = `${STORAGE_KEY_PREFIX}${nasId}`;

  const [library, setLibrary] = useState<MediaLibrary>({ folders: [], items: [], lastScan: 0 });
  const [scanning, setScanning] = useState(false);
  const [scanProgress, setScanProgress] = useState('');
  const [showSetup, setShowSetup] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [activeSubTab, setActiveSubTab] = useState<'video' | 'music'>('video');

  // Folder picker state
  const [pickerPath, setPickerPath] = useState('');
  const [pickerFolders, setPickerFolders] = useState<{ path: string; name: string }[]>([]);
  const [pickerLoading, setPickerLoading] = useState(false);
  const [selectedFolders, setSelectedFolders] = useState<string[]>([]);

  // Load cached library — re-run when NAS changes
  useEffect(() => {
    const cached = localStorage.getItem(storageKey);
    if (cached) {
      try {
        const parsed = JSON.parse(cached);
        setLibrary(parsed);
        setShowSetup(parsed.folders.length === 0);
      } catch { setShowSetup(true); setLibrary({ folders: [], items: [], lastScan: 0 }); }
    } else {
      setShowSetup(true);
      setLibrary({ folders: [], items: [], lastScan: 0 });
    }
    setSearchQuery('');
  }, [nasId]);

  // Save library to local storage (NAS-scoped)
  const saveLibrary = (lib: MediaLibrary) => {
    setLibrary(lib);
    localStorage.setItem(storageKey, JSON.stringify(lib));
  };

  // ── Folder Picker ──

  const loadPickerFolders = useCallback(async (path: string) => {
    setPickerLoading(true);
    try {
      if (!path) {
        // Load shares
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
      console.error('Picker error:', err);
    } finally {
      setPickerLoading(false);
    }
  }, []);

  useEffect(() => {
    if (showSetup) {
      setSelectedFolders([...library.folders]);
      loadPickerFolders('');
    }
  }, [showSetup]);

  const toggleFolderSelection = (path: string) => {
    setSelectedFolders(prev =>
      prev.includes(path) ? prev.filter(p => p !== path) : [...prev, path]
    );
  };

  // ── Scan ──

  const startScan = async (folders: string[]) => {
    if (folders.length === 0) return;
    setScanning(true);
    setShowSetup(false);

    const allItems: MediaItem[] = [];

    for (let i = 0; i < folders.length; i++) {
      const folder = folders[i];
      setScanProgress(`Scanning ${folder.split('/').pop()} (${i + 1}/${folders.length})...`);

      try {
        const resp: any = await invoke('media_scan_folder', { folderPath: folder });
        if (resp.success && resp.videos) {
          for (const video of resp.videos) {
            const { cleanName, year } = parseFilename(video.name);
            const category = getCategoryFromPath(video.path, folders);

            allItems.push({
              id: video.path,
              path: video.path,
              name: video.name,
              cleanName,
              year,
              size: video.size || 0,
              mtime: video.mtime || 0,
              folder: video.folder,
              category,
            });
          }
        }
      } catch (err) {
        console.error(`Scan error for ${folder}:`, err);
      }
    }

    // Fetch TMDB metadata for each unique movie (batch)
    setScanProgress('Fetching movie metadata...');
    const uniqueNames = new Map<string, MediaItem[]>();
    for (const item of allItems) {
      const key = `${item.cleanName}__${item.year || ''}`;
      if (!uniqueNames.has(key)) uniqueNames.set(key, []);
      uniqueNames.get(key)!.push(item);
    }

    let tmdbCount = 0;
    for (const [, items] of uniqueNames) {
      const sample = items[0];
      tmdbCount++;
      if (tmdbCount % 5 === 0) {
        setScanProgress(`Fetching metadata... (${tmdbCount}/${uniqueNames.size})`);
      }

      try {
        const tmdbResp: any = await invoke('tmdb_search', {
          query: sample.cleanName,
          year: sample.year || null,
        });

        if (tmdbResp.results && tmdbResp.results.length > 0) {
          const movie = tmdbResp.results[0];
          for (const item of items) {
            item.posterUrl = movie.poster_path ? `${TMDB_IMAGE_BASE}/w300${movie.poster_path}` : undefined;
            item.backdropUrl = movie.backdrop_path ? `${TMDB_IMAGE_BASE}/w780${movie.backdrop_path}` : undefined;
            item.overview = movie.overview;
            item.rating = movie.vote_average;
            if (movie.release_date) {
              item.year = movie.release_date.substring(0, 4);
            }
            // Use TMDB title if available
            if (movie.title) {
              item.cleanName = movie.title;
            }
          }
        }
      } catch {
        // TMDB fetch failed, use parsed name
      }

      // Rate limit: small delay between requests
      if (tmdbCount % 10 === 0) {
        await new Promise(r => setTimeout(r, 200));
      }
    }

    // Get NAS thumbnails for items without poster
    setScanProgress('Loading thumbnails...');
    for (const item of allItems) {
      if (!item.posterUrl) {
        try {
          const thumbUrl: string = await invoke('media_get_thumbnail_url', { path: item.path });
          item.thumbnailUrl = thumbUrl;
        } catch { /* no thumbnail */ }
      }
    }

    const newLibrary: MediaLibrary = {
      folders,
      items: allItems,
      lastScan: Date.now(),
    };
    saveLibrary(newLibrary);
    setScanning(false);
    setScanProgress('');
  };

  // ── Play ──

  const [proxyPort, setProxyPort] = useState<number>(0);
  const [selectedItem, setSelectedItem] = useState<MediaItem | null>(null);
  const [playerUrl, setPlayerUrl] = useState<string | null>(null);
  const [playerType, setPlayerType] = useState<'native' | 'mpegts' | null>(null);
  const mpegtsPlayerRef = useRef<mpegts.Player | null>(null);
  const videoRef = useRef<HTMLVideoElement | null>(null);

  // Get local proxy server port on mount
  useEffect(() => {
    invoke<number>('get_proxy_port').then(port => {
      console.log(`[Media] Proxy server on port ${port}`);
      setProxyPort(port);
    }).catch(err => console.error('Failed to get proxy port:', err));
  }, []);

  const getFileExt = (name: string) => name.split('.').pop()?.toLowerCase() || '';

  const playVideo = async (item: MediaItem) => {
    // Clean up previous player
    destroyMpegtsPlayer();

    const ext = getFileExt(item.name);

    if (proxyPort > 0) {
      const streamUrl = `http://localhost:${proxyPort}/stream?path=${encodeURIComponent(item.path)}`;
      setSelectedItem(item);
      setPlayerUrl(streamUrl);

      if (MPEGTS_FORMATS.includes(ext)) {
        setPlayerType('mpegts');
      } else {
        setPlayerType('native');
      }
    } else {
      // Fallback: external browser
      try {
        const url: string = await invoke('media_get_stream_url', { path: item.path });
        await openUrl(url);
      } catch (err) {
        console.error('Play error:', err);
      }
    }
  };

  // Initialize mpegts.js player when modal opens with mpegts type
  useEffect(() => {
    if (playerType === 'mpegts' && playerUrl && videoRef.current) {
      if (mpegts.isSupported()) {
        const player = mpegts.createPlayer({
          type: 'mpegts',
          url: playerUrl,
        }, {
          enableWorker: false,
          enableStashBuffer: false,
        });
        player.attachMediaElement(videoRef.current);
        player.load();
        player.play();
        mpegtsPlayerRef.current = player;
        console.log('[Media] mpegts.js player initialized');
      } else {
        console.warn('[Media] mpegts.js not supported, falling back to native');
        setPlayerType('native');
      }
    }
  }, [playerType, playerUrl]);

  const destroyMpegtsPlayer = () => {
    if (mpegtsPlayerRef.current) {
      mpegtsPlayerRef.current.pause();
      mpegtsPlayerRef.current.unload();
      mpegtsPlayerRef.current.detachMediaElement();
      mpegtsPlayerRef.current.destroy();
      mpegtsPlayerRef.current = null;
    }
  };

  const closePlayer = () => {
    destroyMpegtsPlayer();
    setPlayerUrl(null);
    setSelectedItem(null);
    setPlayerType(null);
  };

  // Format file size
  const formatSize = (bytes: number) => {
    if (bytes <= 0) return '';
    const gb = bytes / (1024 * 1024 * 1024);
    if (gb >= 1) return `${gb.toFixed(1)} GB`;
    const mb = bytes / (1024 * 1024);
    return `${Math.round(mb)} MB`;
  };

  // ── Organize by categories ──

  const filteredItems = searchQuery
    ? library.items.filter(i =>
        i.cleanName.toLowerCase().includes(searchQuery.toLowerCase()) ||
        i.name.toLowerCase().includes(searchQuery.toLowerCase())
      )
    : library.items;

  const categories = new Map<string, MediaItem[]>();
  for (const item of filteredItems) {
    if (!categories.has(item.category)) categories.set(item.category, []);
    categories.get(item.category)!.push(item);
  }

  // Recently added
  const recentItems = [...filteredItems]
    .sort((a, b) => b.mtime - a.mtime)
    .slice(0, 20);

  // Random hero
  const heroItem = library.items.find(i => i.backdropUrl) || library.items[0];

  // ═══ RENDER ═══

  // Setup / First time
  if (showSetup) {
    return (
      <div className="media">
        <div className="media__setup-overlay">
          <div className="media__setup">
            <div className="media__setup-header">
              <Film size={28} className="media__setup-icon" />
              <h2>Setup Your Media Library</h2>
              <p>Select folders on your NAS that contain video files</p>
            </div>

            {/* Folder browser */}
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
                          onClick={() => toggleFolderSelection(f.path)}
                        >
                          {isSelected ? <><CheckCircle size={14} /> Selected</> : <><FolderPlus size={14} /> Select</>}
                        </button>
                      </div>
                    );
                  })
                )}
              </div>
            </div>

            {/* Selected folders */}
            {selectedFolders.length > 0 && (
              <div className="media__selected-folders">
                <span className="media__selected-label">{selectedFolders.length} folder(s) selected:</span>
                {selectedFolders.map(f => (
                  <div key={f} className="media__selected-tag">
                    <span>{f.split('/').pop()}</span>
                    <button onClick={() => toggleFolderSelection(f)}><X size={12} /></button>
                  </div>
                ))}
              </div>
            )}

            <div className="media__setup-actions">
              <button
                className="btn btn-primary media__scan-btn"
                onClick={() => startScan(selectedFolders)}
                disabled={selectedFolders.length === 0}
              >
                <Search size={16} /> Start Scanning
              </button>
              {library.items.length > 0 && (
                <button className="btn btn-ghost btn-sm" onClick={() => setShowSetup(false)}>Cancel</button>
              )}
            </div>
          </div>
        </div>
      </div>
    );
  }

  // Scanning progress
  if (scanning) {
    return (
      <div className="media">
        <div className="media__scanning">
          <div className="media__scanning-spinner">
            <div className="media__scanning-ring" />
          </div>
          <h3>Scanning Media Library</h3>
          <p>{scanProgress}</p>
        </div>
      </div>
    );
  }

  // ── Main Library View ──
  return (
    <div className="media">
      {/* Sub-tab toggle + Toolbar */}
      <div className="media__toolbar">
        <div className="media__tabs">
          <button
            className={`media__tab ${activeSubTab === 'video' ? 'media__tab--active' : ''}`}
            onClick={() => setActiveSubTab('video')}
          >
            <Film size={14} /> Video
          </button>
          <button
            className={`media__tab ${activeSubTab === 'music' ? 'media__tab--active' : ''}`}
            onClick={() => setActiveSubTab('music')}
          >
            <Music size={14} /> Music
          </button>
        </div>
        <div className="media__toolbar-spacer" />

        {activeSubTab === 'video' && (
          <>
            <div className="media__search">
              <Search size={14} />
              <input
                placeholder="Search movies..."
                value={searchQuery}
                onChange={e => setSearchQuery(e.target.value)}
              />
              {searchQuery && <button onClick={() => setSearchQuery('')}><X size={12} /></button>}
            </div>

            <button className="btn btn-ghost btn-sm" onClick={() => startScan(library.folders)} title="Rescan">
              <RefreshCw size={14} />
            </button>
            <button className="btn btn-ghost btn-sm" onClick={() => setShowSetup(true)} title="Settings">
              <Settings size={14} />
            </button>
          </>
        )}
      </div>

      {activeSubTab === 'music' ? <MusicTab /> : (
      <>
      {/* Video content below */}

      {/* Content */}
      <div className="media__content">
        {library.items.length === 0 ? (
          <div className="media__empty">
            <Film size={48} />
            <h3>No media found</h3>
            <p>Configure your media folders to get started</p>
            <button className="btn btn-primary" onClick={() => setShowSetup(true)}>Setup Library</button>
          </div>
        ) : (
          <>
            {/* Hero Banner */}
            {heroItem && !searchQuery && (
              <div
                className="media__hero"
                style={{
                  backgroundImage: heroItem.backdropUrl
                    ? `linear-gradient(to top, var(--color-bg) 0%, transparent 60%), url(${heroItem.backdropUrl})`
                    : undefined,
                }}
              >
                <div className="media__hero-content">
                  <h2 className="media__hero-title">{heroItem.cleanName}</h2>
                  {heroItem.year && <span className="media__hero-year">{heroItem.year}</span>}
                  {heroItem.rating && (
                    <span className="media__hero-rating">
                      <Star size={12} /> {heroItem.rating.toFixed(1)}
                    </span>
                  )}
                  {heroItem.overview && (
                    <p className="media__hero-overview">{heroItem.overview.substring(0, 150)}...</p>
                  )}
                  <button className="btn btn-primary media__hero-play" onClick={() => playVideo(heroItem)}>
                    <Play size={16} /> Play Now
                  </button>
                </div>
              </div>
            )}

            {/* Recently Added */}
            {!searchQuery && recentItems.length > 0 && (
              <MediaRow title="Recently Added" icon={<Clock size={16} />} items={recentItems} onPlay={playVideo} />
            )}

            {/* Category rows */}
            {Array.from(categories.entries()).map(([category, items]) => (
              <MediaRow key={category} title={category} icon={<Film size={16} />} items={items} onPlay={playVideo} />
            ))}
          </>
        )}
      </div>

      {/* ── Video Player Modal ── */}
      {playerUrl && selectedItem && (
        <div className="media__player-overlay" onClick={closePlayer}>
          <div className="media__player" onClick={e => e.stopPropagation()}>
            <div className="media__player-header">
              <h3>{selectedItem.cleanName} {selectedItem.year && `(${selectedItem.year})`}</h3>
              <div className="media__player-header-right">
                <span className="media__player-badge">
                  {playerType === 'mpegts' ? 'MPEGTS' : getFileExt(selectedItem.name).toUpperCase()}
                </span>
                <button className="media__player-close" onClick={closePlayer}>
                  <X size={18} />
                </button>
              </div>
            </div>
            <video
              ref={videoRef}
              src={playerType === 'native' ? playerUrl : undefined}
              controls
              autoPlay={playerType === 'native'}
              className="media__player-video"
            />
            <div className="media__player-info">
              <span>{formatSize(selectedItem.size)}</span>
              <span>{selectedItem.name}</span>
            </div>
          </div>
        </div>
      )}
      </>)}
    </div>
  );
};

// ── MediaRow Component ──

interface MediaRowProps {
  title: string;
  icon: React.ReactNode;
  items: MediaItem[];
  onPlay: (item: MediaItem) => void;
}

const MediaRow: React.FC<MediaRowProps> = ({ title, icon, items, onPlay }) => {
  const scrollRef = useRef<HTMLDivElement>(null);

  return (
    <div className="media-row">
      <div className="media-row__header">
        {icon}
        <span className="media-row__title">{title}</span>
        <span className="media-row__count">{items.length}</span>
      </div>
      <div className="media-row__scroll" ref={scrollRef}>
        {items.map(item => (
          <div key={item.id} className="media-card" onClick={() => onPlay(item)}>
            <div className="media-card__poster">
              {(item.posterUrl || item.thumbnailUrl) ? (
                <img
                  src={item.posterUrl || item.thumbnailUrl || ''}
                  alt={item.cleanName}
                  loading="lazy"
                  onError={(e) => { (e.target as HTMLImageElement).style.display = 'none'; (e.target as HTMLImageElement).nextElementSibling?.classList.add('media-card__no-poster--visible'); }}
                />
              ) : null}
              <div className={`media-card__no-poster ${!item.posterUrl && !item.thumbnailUrl ? 'media-card__no-poster--visible' : ''}`}>
                <Film size={28} />
                <span className="media-card__no-poster-name">{item.cleanName}</span>
              </div>
              <div className="media-card__overlay">
                <Play size={28} className="media-card__play-icon" />
              </div>
              {item.rating && item.rating > 0 && (
                <div className="media-card__rating">
                  <Star size={10} /> {item.rating.toFixed(1)}
                </div>
              )}
            </div>
            <div className="media-card__info">
              <span className="media-card__name">{item.cleanName}</span>
              {item.year && <span className="media-card__year">{item.year}</span>}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default Media;
