import React, { useEffect, useState, useMemo } from 'react';
import { invoke } from '@tauri-apps/api/core';
import {
  Package, RefreshCw, Search, Play, Square, AlertCircle,
  Download, Trash2, Grid3X3, Loader,
  CheckCircle, StopCircle, PlayCircle
} from 'lucide-react';
import { useConfirmDialog } from '../../components/ConfirmDialog/ConfirmDialog';
import './Packages.css';

// ── Types ──

interface PackageItem {
  id: string;
  name: string;
  dname?: string;
  version: string;
  desc?: string;
  additional?: {
    status?: string;
    running_status?: string;
    is_running?: boolean;
    dsm_apps?: string;
    install_type?: string;
    description?: string;
    startable?: boolean;
  };
  status?: string;
  is_running?: boolean;
}

interface ServerPackage {
  id: string;
  dname: string;
  desc: string;
  version: string;
  link: string;
  thumbnail: string[];
  icon: string;
  price: number;
  category?: string;
  subcategory?: string;
  type?: number;
  size?: number;
  qinst?: boolean;
  depsers?: string;
  is_security_version?: boolean;
  download_count?: number;
  recent_download_count?: number;
  beta?: boolean;
}

type TabType = 'installed' | 'available';

const Packages: React.FC = () => {
  const [tab, setTab] = useState<TabType>('installed');
  const [installedPkgs, setInstalledPkgs] = useState<PackageItem[]>([]);
  const [serverPkgs, setServerPkgs] = useState<ServerPackage[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadingServer, setLoadingServer] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [actionLoading, setActionLoading] = useState<string | null>(null);
  const [selectedCategory, setSelectedCategory] = useState('all');
  const { showDialog, DialogComponent } = useConfirmDialog();

  // ── Fetch installed packages ──
  const fetchInstalled = async () => {
    setLoading(true);
    setError(null);
    try {
      const result: any = await invoke('nas_get_system_info');
      const pkgList = result?.packages?.packages || [];
      setInstalledPkgs(pkgList);
    } catch (err: any) {
      setError(err?.toString() || 'Failed to load packages');
    } finally {
      setLoading(false);
    }
  };

  // ── Fetch available packages ──
  const fetchServer = async () => {
    setLoadingServer(true);
    try {
      const result: any = await invoke('package_list_server');
      const pkgs = result?.data?.packages || [];
      // Filter out beta packages
      const nonBeta = pkgs.filter((p: ServerPackage) => !p.beta);
      setServerPkgs(nonBeta);
    } catch (err: any) {
      console.error('Server packages error:', err);
    } finally {
      setLoadingServer(false);
    }
  };

  useEffect(() => {
    fetchInstalled();
    fetchServer();
  }, []);

  // ── Package actions ──
  const isRunning = (pkg: PackageItem): boolean => {
    return (
      pkg?.additional?.status === 'running' ||
      pkg?.additional?.running_status === 'running' ||
      pkg?.status === 'running' ||
      pkg?.additional?.is_running === true ||
      pkg?.is_running === true
    );
  };

  const installedIds = useMemo(() =>
    new Set(installedPkgs.map(p => p.id || p.name)),
  [installedPkgs]);

  const handleStartStop = async (id: string, running: boolean) => {
    setActionLoading(id);
    try {
      if (running) {
        await invoke('package_stop', { id });
      } else {
        await invoke('package_start', { id });
      }
      await fetchInstalled();
    } catch (err: any) {
      setError(err?.toString());
    } finally {
      setActionLoading(null);
    }
  };

  const handleInstall = async (pkg: ServerPackage) => {
    const confirmed = await showDialog({
      title: `Install ${pkg.dname}?`,
      message: pkg.desc || 'This package will be downloaded and installed on your NAS.',
      variant: 'info',
      confirmText: 'Install',
    });
    if (!confirmed) return;

    setActionLoading(pkg.id);
    try {
      await invoke('package_install', { id: pkg.id, volume: '/volume1' });
      await fetchInstalled();
    } catch (err: any) {
      await showDialog({
        title: 'Installation Failed',
        message: err?.toString() || 'Could not install the package.',
        variant: 'danger',
        showCancel: false,
        confirmText: 'OK',
      });
    } finally {
      setActionLoading(null);
    }
  };

  const handleUninstall = async (id: string, name: string) => {
    const confirmed = await showDialog({
      title: `Uninstall ${name}?`,
      message: 'The package and its configuration may be removed. This action cannot be undone.',
      variant: 'danger',
      confirmText: 'Uninstall',
    });
    if (!confirmed) return;

    setActionLoading(id);
    try {
      await invoke('package_uninstall', { id });
      await fetchInstalled();
    } catch (err: any) {
      setError(err?.toString());
    } finally {
      setActionLoading(null);
    }
  };

  // ── Filtered data ──
  const filteredInstalled = useMemo(() => {
    const q = search.toLowerCase();
    return installedPkgs.filter(p => {
      const name = (p.dname || p.name || p.id || '').toLowerCase();
      return name.includes(q);
    });
  }, [installedPkgs, search]);

  const categories = useMemo(() => {
    const cats = new Set<string>();
    serverPkgs.forEach(p => {
      if (p.category) cats.add(p.category);
    });
    return Array.from(cats).sort();
  }, [serverPkgs]);

  const filteredServer = useMemo(() => {
    const q = search.toLowerCase();
    return serverPkgs.filter(p => {
      const matchSearch = (p.dname || p.id || '').toLowerCase().includes(q) ||
                          (p.desc || '').toLowerCase().includes(q);
      const matchCat = selectedCategory === 'all' || p.category === selectedCategory;
      return matchSearch && matchCat;
    });
  }, [serverPkgs, search, selectedCategory]);

  const runningCount = filteredInstalled.filter(isRunning).length;
  const stoppedCount = filteredInstalled.length - runningCount;

  return (
    <div className="packages">
      {/* Header */}
      <div className="packages__header">
        <div className="packages__tabs">
          <button
            className={`packages__tab ${tab === 'installed' ? 'packages__tab--active' : ''}`}
            onClick={() => setTab('installed')}
          >
            <Package size={14} /> Installed
            <span className="packages__tab-count">{installedPkgs.length}</span>
          </button>
          <button
            className={`packages__tab ${tab === 'available' ? 'packages__tab--active' : ''}`}
            onClick={() => setTab('available')}
          >
            <Grid3X3 size={14} /> All Packages
            <span className="packages__tab-count">{serverPkgs.length}</span>
          </button>
        </div>

        <div className="packages__header-actions">
          <div className="packages__search">
            <Search size={13} />
            <input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder={tab === 'installed' ? 'Search installed...' : 'Search all packages...'}
            />
          </div>
          {tab === 'available' && (
            <select
              className="packages__category"
              value={selectedCategory}
              onChange={e => setSelectedCategory(e.target.value)}
            >
              <option value="all">All Categories</option>
              {categories.map(c => (
                <option key={c} value={c}>{c}</option>
              ))}
            </select>
          )}
          <button
            className="btn btn-ghost btn-icon"
            onClick={() => { fetchInstalled(); fetchServer(); }}
            title="Refresh"
          >
            <RefreshCw size={14} className={loading || loadingServer ? 'animate-spin' : ''} />
          </button>
        </div>
      </div>

      {error && (
        <div className="packages__error">
          <AlertCircle size={14} /> {error}
          <button onClick={() => setError(null)} style={{ marginLeft: 'auto', opacity: 0.6, cursor: 'pointer', background: 'none', border: 'none', color: 'inherit' }}>✕</button>
        </div>
      )}

      {/* ── INSTALLED TAB ── */}
      {tab === 'installed' && (
        <>
          <div className="packages__stats">
            <div className="packages__stat">
              <span className="packages__stat-value">{filteredInstalled.length}</span>
              <span className="packages__stat-label">Total</span>
            </div>
            <div className="packages__stat packages__stat--running">
              <span className="packages__stat-value">{runningCount}</span>
              <span className="packages__stat-label">Running</span>
            </div>
            <div className="packages__stat packages__stat--stopped">
              <span className="packages__stat-value">{stoppedCount}</span>
              <span className="packages__stat-label">Stopped</span>
            </div>
          </div>

          <div className="packages__list">
            {filteredInstalled.filter(isRunning).length > 0 && (
              <>
                <div className="packages__section-label">Running ({filteredInstalled.filter(isRunning).length})</div>
                {filteredInstalled.filter(isRunning).map(pkg => (
                  <InstalledCard
                    key={pkg.id || pkg.name}
                    pkg={pkg}
                    running
                    actionLoading={actionLoading}
                    onStartStop={() => handleStartStop(pkg.id || pkg.name, true)}
                    onUninstall={() => handleUninstall(pkg.id || pkg.name, pkg.dname || pkg.name)}
                  />
                ))}
              </>
            )}

            {filteredInstalled.filter(p => !isRunning(p)).length > 0 && (
              <>
                <div className="packages__section-label">Stopped ({filteredInstalled.filter(p => !isRunning(p)).length})</div>
                {filteredInstalled.filter(p => !isRunning(p)).map(pkg => (
                  <InstalledCard
                    key={pkg.id || pkg.name}
                    pkg={pkg}
                    running={false}
                    actionLoading={actionLoading}
                    onStartStop={() => handleStartStop(pkg.id || pkg.name, false)}
                    onUninstall={() => handleUninstall(pkg.id || pkg.name, pkg.dname || pkg.name)}
                  />
                ))}
              </>
            )}

            {!loading && filteredInstalled.length === 0 && (
              <div className="packages__empty">
                {search ? 'No packages match your search' : 'No packages installed'}
              </div>
            )}
          </div>
        </>
      )}

      {/* ── ALL PACKAGES TAB ── */}
      {tab === 'available' && (
        <div className="packages__grid">
          {loadingServer ? (
            <div className="packages__loading">
              <Loader size={24} className="animate-spin" />
              <span>Loading packages from Synology server...</span>
            </div>
          ) : filteredServer.length === 0 ? (
            <div className="packages__empty">
              {search ? 'No packages match your search' : 'No packages available'}
            </div>
          ) : (
            filteredServer.map(pkg => (
              <ServerCard
                key={pkg.id}
                pkg={pkg}
                isInstalled={installedIds.has(pkg.id)}
                actionLoading={actionLoading}
                onInstall={() => handleInstall(pkg)}
              />
            ))
          )}
        </div>
      )}

      {DialogComponent}
    </div>
  );
};

// ── Installed Package Card ──
const InstalledCard: React.FC<{
  pkg: PackageItem;
  running: boolean;
  actionLoading: string | null;
  onStartStop: () => void;
  onUninstall: () => void;
}> = ({ pkg, running, actionLoading, onStartStop, onUninstall }) => {
  const displayName = pkg.dname || pkg.name || pkg.id;
  const isLoading = actionLoading === (pkg.id || pkg.name);

  return (
    <div className={`package-card ${running ? 'package-card--running' : ''}`}>
      <div className="package-card__icon">
        <Package size={20} />
      </div>
      <div className="package-card__info">
        <div className="package-card__name">{displayName}</div>
        <div className="package-card__version">v{pkg.version || '?'}</div>
        {pkg.desc && <div className="package-card__desc">{pkg.desc}</div>}
      </div>
      <div className="package-card__actions">
        <div className="package-card__status">
          {running ? (
            <span className="package-card__badge package-card__badge--running">
              <Play size={10} /> Running
            </span>
          ) : (
            <span className="package-card__badge package-card__badge--stopped">
              <Square size={10} /> Stopped
            </span>
          )}
        </div>
        <div className="package-card__btns">
          <button
            className={`package-card__action-btn ${running ? 'package-card__action-btn--stop' : 'package-card__action-btn--start'}`}
            onClick={onStartStop}
            disabled={isLoading}
            title={running ? 'Stop' : 'Start'}
          >
            {isLoading ? <Loader size={12} className="animate-spin" /> :
              running ? <StopCircle size={14} /> : <PlayCircle size={14} />}
          </button>
          <button
            className="package-card__action-btn package-card__action-btn--uninstall"
            onClick={onUninstall}
            disabled={isLoading}
            title="Uninstall"
          >
            <Trash2 size={13} />
          </button>
        </div>
      </div>
    </div>
  );
};

// ── Server Package Card (Available) ──
const ServerCard: React.FC<{
  pkg: ServerPackage;
  isInstalled: boolean;
  actionLoading: string | null;
  onInstall: () => void;
}> = ({ pkg, isInstalled, actionLoading, onInstall }) => {
  const isLoading = actionLoading === pkg.id;
  const iconUrl = pkg.icon || (pkg.thumbnail && pkg.thumbnail[0]) || '';

  return (
    <div className="server-card">
      <div className="server-card__icon">
        {iconUrl ? (
          <img
            src={iconUrl}
            alt={pkg.dname}
            onError={(e) => {
              (e.target as HTMLImageElement).style.display = 'none';
              (e.target as HTMLImageElement).nextElementSibling?.classList.remove('server-card__icon-fallback--hidden');
            }}
          />
        ) : null}
        <div className={`server-card__icon-fallback ${iconUrl ? 'server-card__icon-fallback--hidden' : ''}`}>
          <Package size={22} />
        </div>
      </div>
      <div className="server-card__info">
        <div className="server-card__name">{pkg.dname || pkg.id}</div>
        <div className="server-card__version">v{pkg.version}</div>
        {pkg.desc && <div className="server-card__desc">{pkg.desc}</div>}
        {pkg.category && (
          <div className="server-card__category">{pkg.category}</div>
        )}
      </div>
      <div className="server-card__action">
        {isInstalled ? (
          <span className="server-card__installed-badge">
            <CheckCircle size={12} /> Installed
          </span>
        ) : (
          <button
            className="server-card__install-btn"
            onClick={onInstall}
            disabled={isLoading}
          >
            {isLoading ? <Loader size={12} className="animate-spin" /> : <Download size={13} />}
            {isLoading ? 'Installing...' : 'Install'}
          </button>
        )}
      </div>
    </div>
  );
};

export default Packages;
