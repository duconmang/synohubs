import React, { useEffect, useState, useRef } from 'react';
import { invoke } from '@tauri-apps/api/core';
import {
  Cpu, MemoryStick, Wifi, HardDrive, Server, Search,
  Bell, RefreshCw, Shield, CheckCircle, AlertTriangle
} from 'lucide-react';
import { useNasStore } from '../../stores';
import { getNasModelImage } from '../../utils/nasModels';
import './Dashboard.css';

interface SystemData {
  dsm: any;
  utilization: any;
  storage: any;
  packages: any;
}

const Dashboard: React.FC = () => {
  const { activeNas } = useNasStore();
  const [data, setData] = useState<SystemData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const refreshTimer = useRef<NodeJS.Timeout | null>(null);

  const fetchData = async () => {
    try {
      const result: SystemData = await invoke('nas_get_system_info');
      setData(result);
      setError(null);
    } catch (err: any) {
      setError(err?.toString() || 'Failed to fetch data');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
    refreshTimer.current = setInterval(fetchData, 10000);
    return () => { if (refreshTimer.current) clearInterval(refreshTimer.current); };
  }, []);

  // ── Parse Data ──

  // CPU
  const cpu = data?.utilization?.cpu || {};
  const cpuUser = (cpu.user_load || 0) as number;
  const cpuSys = (cpu.system_load || 0) as number;
  const cpuUsage = Math.min(cpuUser + cpuSys, 100);

  // RAM
  const mem = data?.utilization?.memory || {};
  const ramTotal = (mem.total_real || 0) as number;
  const ramAvail = (mem.avail_real || 0) as number;
  const ramBuffer = (mem.buffer || 0) as number;
  const ramCached = (mem.cached || 0) as number;
  const ramUsed = ramTotal - ramAvail - ramBuffer - ramCached;
  const ramUsedMb = Math.round(ramUsed / 1024);
  const ramTotalMb = Math.round(ramTotal / 1024);
  const ramPercent = ramTotal > 0 ? Math.round((ramUsed / ramTotal) * 100) : 0;

  // Network
  const network = data?.utilization?.network || [];
  const netTotal = Array.isArray(network)
    ? network.reduce((acc: any, n: any) => ({ tx: acc.tx + (n.tx || 0), rx: acc.rx + (n.rx || 0) }), { tx: 0, rx: 0 })
    : { tx: 0, rx: 0 };
  const netUpKbps = Math.round(netTotal.tx / 1024);
  const netDownKbps = Math.round(netTotal.rx / 1024);

  // Volumes
  const volumes: any[] = data?.storage?.volumes || [];
  const parsedVolumes = volumes.map((v: any) => {
    const totalBytes = parseSize(v.size?.total);
    const usedBytes = parseSize(v.size?.used);
    return {
      id: v.id || v.vol_path || 'Volume',
      name: (v.id || v.vol_path || 'Volume').replace('/volume', 'volume_'),
      totalBytes,
      usedBytes,
      total: formatStorageSize(totalBytes),
      used: formatStorageSize(usedBytes),
      percent: totalBytes > 0 ? Math.round((usedBytes / totalBytes) * 100) : 0,
      status: v.status || 'normal',
      fs_type: v.fs_type || '',
    };
  });

  // Total storage
  const totalStorageBytes = parsedVolumes.reduce((sum, v) => sum + v.totalBytes, 0);
  const usedStorageBytes = parsedVolumes.reduce((sum, v) => sum + v.usedBytes, 0);
  const totalStoragePercent = totalStorageBytes > 0 ? Math.round((usedStorageBytes / totalStorageBytes) * 100) : 0;

  // Disks
  const disks: any[] = data?.storage?.disks || [];
  const parsedDisks = disks.map((d: any, i: number) => ({
    id: d.id || `disk_${i + 1}`,
    name: d.name || `Bay ${i + 1}`,
    model: d.model || 'Unknown',
    vendor: d.vendor || '',
    status: d.status || d.smart_status || 'normal',
    temp: d.temp || d.temperature || 0,
    size: parseSize(d.size_total),
    slot: i + 1,
  }));

  // FS type from first volume
  const fsType = parsedVolumes[0]?.fs_type?.toUpperCase() || '';

  // DSM info
  const model = data?.dsm?.model || activeNas?.model || 'Unknown';
  const dsmVersion = data?.dsm?.version_string ||
    (data?.dsm?.version ? `DSM ${data.dsm.version}` : activeNas?.dsm_version || 'Unknown');
  const hostname = data?.dsm?.hostname || activeNas?.name || '';
  const uptime = formatUptime(data?.dsm?.uptime || 0);
  const temperature = data?.dsm?.temperature || 0;
  const serial = data?.dsm?.serial || activeNas?.serial || '';

  // NAS image
  const nasImage = getNasModelImage(model);

  // Net history
  const [netHistory, setNetHistory] = useState<number[]>(Array(30).fill(0));
  useEffect(() => {
    setNetHistory((prev) => [...prev.slice(1), netUpKbps + netDownKbps]);
  }, [data]);
  const maxNet = Math.max(...netHistory, 1);

  // Packages
  const packages: any[] = data?.packages?.packages || [];

  return (
    <div className="dashboard">
      {/* Top bar */}
      <div className="dashboard__topbar">
        <h1>Dashboard</h1>
        <select className="select" style={{ minWidth: '120px' }}>
          <option>{hostname || model}</option>
        </select>
        <Search size={16} color="var(--color-text-dim)" style={{ cursor: 'pointer' }} />
        <Bell size={16} color="var(--color-text-dim)" style={{ cursor: 'pointer' }} />
        <div className="dashboard__topbar-spacer" />
        <button className="btn btn-ghost btn-sm" onClick={fetchData} title="Refresh">
          <RefreshCw size={14} className={loading ? 'animate-spin' : ''} />
        </button>
      </div>

      {/* Content */}
      <div className="dashboard__content">
        {error && (
          <div className="nas-login__status nas-login__status--error" style={{ marginBottom: '16px' }}>
            {error}
          </div>
        )}

        <div className="dashboard__grid">

          {/* ═══════ ROW 1: NAS Hero + NAS Info ═══════ */}

          {/* NAS Hero Card — spans 2 columns */}
          <div className="metric-card hero-card">
            <div className="hero-card__image-area">
              {nasImage ? (
                <img src={nasImage} alt={model} className="hero-card__nas-image" />
              ) : (
                <div className="hero-card__nas-placeholder">
                  <Server size={64} />
                </div>
              )}
            </div>
            <div className="hero-card__name">Synology {model}</div>
            <div className={`hero-card__badge ${temperature > 60 ? 'hero-card__badge--warn' : ''}`}>
              <Shield size={12} />
              {temperature > 60 ? 'WARNING' : 'HEALTHY'}
            </div>
          </div>

          {/* NAS Info Card */}
          <div className="metric-card info-card">
            <div className="metric-card__header">
              <span className="metric-card__title">DEVICE INFO</span>
              <div className="metric-card__icon metric-card__icon--blue">
                <Server size={14} />
              </div>
            </div>
            <div className="info-card__details">
              <div className="info-card__row">
                <span className="info-card__label">DSM VERSION</span>
                <span className="info-card__value">{dsmVersion}</span>
              </div>
              <div className="info-card__row">
                <span className="info-card__label">UPTIME</span>
                <span className="info-card__value">{uptime || '—'}</span>
              </div>
              <div className="info-card__row">
                <span className="info-card__label">LAN IP</span>
                <span className="info-card__value">{activeNas?.host || '—'}</span>
              </div>
              <div className="info-card__row">
                <span className="info-card__label">SERIAL</span>
                <span className="info-card__value">{serial || '—'}</span>
              </div>
              <div className="info-card__row">
                <span className="info-card__label">TEMPERATURE</span>
                <span className="info-card__value">{temperature > 0 ? `${temperature}°C` : '—'}</span>
              </div>
              <div className="info-card__row">
                <span className="info-card__label">STATUS</span>
                <span className="badge badge-success">ONLINE</span>
              </div>
            </div>
          </div>

          {/* ═══════ ROW 2: CPU / Memory / Network ═══════ */}

          {/* CPU */}
          <div className="metric-card">
            <div className="metric-card__header">
              <span className="metric-card__title">CPU USAGE</span>
              <div className="metric-card__icon metric-card__icon--green"><Cpu size={14} /></div>
            </div>
            <div className="gauge">
              <div className="gauge__circle">
                <svg viewBox="0 0 110 110">
                  <circle cx="55" cy="55" r="48" fill="none" stroke="var(--color-surface-3)" strokeWidth="6" />
                  <circle cx="55" cy="55" r="48" fill="none" stroke="var(--color-accent)" strokeWidth="6"
                    strokeDasharray={`${cpuUsage * 3.016} ${301.6 - cpuUsage * 3.016}`} strokeLinecap="round" />
                </svg>
                <div className="gauge__value">
                  <span className="gauge__percent" style={{ color: 'var(--color-accent)' }}>{cpuUsage}%</span>
                  <span className="gauge__label">Usage</span>
                </div>
              </div>
              <span className="gauge__sublabel">{model}</span>
            </div>
          </div>

          {/* Memory */}
          <div className="metric-card">
            <div className="metric-card__header">
              <span className="metric-card__title">MEMORY</span>
              <div className="metric-card__icon metric-card__icon--amber"><MemoryStick size={14} /></div>
            </div>
            <div className="gauge">
              <div className="gauge__circle">
                <svg viewBox="0 0 110 110">
                  <circle cx="55" cy="55" r="48" fill="none" stroke="var(--color-surface-3)" strokeWidth="6" />
                  <circle cx="55" cy="55" r="48" fill="none" stroke="var(--color-warning)" strokeWidth="6"
                    strokeDasharray={`${ramPercent * 3.016} ${301.6 - ramPercent * 3.016}`} strokeLinecap="round" />
                </svg>
                <div className="gauge__value">
                  <span className="gauge__percent" style={{ color: 'var(--color-warning)' }}>{ramPercent}%</span>
                  <span className="gauge__label">Used</span>
                </div>
              </div>
              <span className="gauge__sublabel">
                {ramUsedMb > 0 ? `${(ramUsedMb / 1024).toFixed(1)} / ${(ramTotalMb / 1024).toFixed(0)} GB` : '— / — GB'}
              </span>
            </div>
          </div>

          {/* Network */}
          <div className="metric-card">
            <div className="metric-card__header">
              <span className="metric-card__title">NETWORK</span>
              <div className="metric-card__icon metric-card__icon--blue"><Wifi size={14} /></div>
            </div>
            <div className="network-chart">
              <div className="network-chart__bars">
                {netHistory.map((val, i) => (
                  <div key={i} className="network-chart__bar network-chart__bar--up"
                    style={{ height: `${Math.max((val / maxNet) * 100, 3)}%` }} />
                ))}
              </div>
              <div className="network-chart__legend">
                <div className="network-chart__legend-item">
                  <span className="network-chart__legend-dot network-chart__legend-dot--up" />
                  Upload <span className="network-chart__legend-value">{netUpKbps} KB/s</span>
                </div>
                <div className="network-chart__legend-item">
                  <span className="network-chart__legend-dot network-chart__legend-dot--down" />
                  Download <span className="network-chart__legend-value">{netDownKbps} KB/s</span>
                </div>
              </div>
            </div>
          </div>

          {/* ═══════ ROW 3: Storage Capacity + Disk Health ═══════ */}

          {/* Storage Capacity — spans 2 columns */}
          <div className="metric-card storage-capacity-card">
            <div className="metric-card__header">
              <span className="metric-card__title">STORAGE CAPACITY</span>
              <div className="metric-card__icon metric-card__icon--green"><HardDrive size={14} /></div>
            </div>
            <div className="storage-capacity">
              {/* Ring chart */}
              <div className="storage-ring">
                <svg viewBox="0 0 160 160">
                  {/* Background ring */}
                  <circle cx="80" cy="80" r="68" fill="none" stroke="rgba(100,100,100,0.2)" strokeWidth="12" />
                  {/* Used ring */}
                  <circle cx="80" cy="80" r="68" fill="none"
                    stroke="url(#storageGrad)" strokeWidth="12"
                    strokeDasharray={`${totalStoragePercent * 4.273} ${427.3 - totalStoragePercent * 4.273}`}
                    strokeLinecap="round"
                    transform="rotate(-90 80 80)" />
                  <defs>
                    <linearGradient id="storageGrad" x1="0%" y1="0%" x2="100%" y2="100%">
                      <stop offset="0%" stopColor="#22C55E" />
                      <stop offset="100%" stopColor="#06B6D4" />
                    </linearGradient>
                  </defs>
                </svg>
                <div className="storage-ring__center">
                  <span className="storage-ring__percent">{totalStoragePercent}%</span>
                  <span className="storage-ring__size">
                    {formatStorageSize(usedStorageBytes)} / {formatStorageSize(totalStorageBytes)}
                  </span>
                </div>
              </div>

              {/* Volume list */}
              <div className="storage-volumes">
                {parsedVolumes.length > 0 ? parsedVolumes.map((vol) => (
                  <div key={vol.id} className="storage-vol-row">
                    <span className="storage-vol-row__name">{vol.name}</span>
                    <span className="storage-vol-row__size">{vol.used} / {vol.total}</span>
                    <div className="storage-vol-row__bar">
                      <div className={`storage-vol-row__fill ${
                        vol.percent > 90 ? 'storage-vol-row__fill--red' :
                        vol.percent > 70 ? 'storage-vol-row__fill--amber' : ''
                      }`} style={{ width: `${vol.percent}%` }} />
                    </div>
                  </div>
                )) : (
                  <div style={{ color: 'var(--color-text-dim)', fontSize: '12px' }}>
                    {loading ? 'Loading...' : 'No storage data'}
                  </div>
                )}
              </div>
            </div>
          </div>

          {/* Disk Health */}
          <div className="metric-card disk-health-card">
            <div className="metric-card__header">
              <span className="metric-card__title">DISK HEALTH</span>
              {fsType && <span className="disk-health__fs-badge">{fsType}</span>}
            </div>
            <div className="disk-health__list">
              {parsedDisks.length > 0 ? parsedDisks.map((disk) => {
                const isNormal = disk.status === 'normal' || disk.status === 'initialized';
                return (
                  <div key={disk.id} className="disk-health__item">
                    <div className={`disk-health__status-icon ${isNormal ? '' : 'disk-health__status-icon--warn'}`}>
                      {isNormal ? <CheckCircle size={18} /> : <AlertTriangle size={18} />}
                    </div>
                    <div className="disk-health__info">
                      <span className="disk-health__bay">Bay {disk.slot}</span>
                      <span className="disk-health__model">{disk.vendor} {disk.model}</span>
                    </div>
                    <span className={`disk-health__badge ${isNormal ? '' : 'disk-health__badge--warn'}`}>
                      {isNormal ? 'Normal' : disk.status}
                    </span>
                  </div>
                );
              }) : (
                <div style={{ color: 'var(--color-text-dim)', fontSize: '12px', padding: '12px 0' }}>
                  {loading ? 'Loading...' : 'No disk data'}
                </div>
              )}
            </div>
          </div>

          {/* ═══════ ROW 4: Packages ═══════ */}
          <div className="metric-card activity-card">
            <div className="metric-card__header">
              <span className="metric-card__title">INSTALLED PACKAGES</span>
            </div>
            <table className="activity-table">
              <thead>
                <tr><th>Name</th><th>Version</th><th>Status</th></tr>
              </thead>
              <tbody>
                {packages.slice(0, 10).map((pkg: any, i: number) => {
                  const isRunning = pkg?.additional?.status === 'running' ||
                    pkg?.additional?.running_status === 'running' ||
                    pkg?.status === 'running' ||
                    pkg?.additional?.is_running === true ||
                    pkg?.is_running === true;
                  return (
                    <tr key={i}>
                      <td>{pkg.dname || pkg.name || pkg.id}</td>
                      <td>{pkg.version || '—'}</td>
                      <td>
                        <span className={`badge ${isRunning ? 'badge-success' : 'badge-warning'}`}>
                          {isRunning ? 'Running' : 'Stopped'}
                        </span>
                      </td>
                    </tr>
                  );
                })}
                {packages.length === 0 && (
                  <tr><td colSpan={3} style={{ textAlign: 'center', color: 'var(--color-text-dim)' }}>
                    {loading ? 'Loading...' : 'No package data'}
                  </td></tr>
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
};

// ── Helpers ──

function parseSize(value: any): number {
  if (!value) return 0;
  if (typeof value === 'number') return value;
  if (typeof value === 'string') return parseInt(value) || 0;
  return 0;
}

function formatStorageSize(bytes: number): string {
  if (bytes <= 0) return '0 B';
  const tb = bytes / (1024 * 1024 * 1024 * 1024);
  if (tb >= 1) return `${tb.toFixed(1)} TB`;
  const gb = bytes / (1024 * 1024 * 1024);
  if (gb >= 1) return `${Math.round(gb)} GB`;
  const mb = bytes / (1024 * 1024);
  return `${Math.round(mb)} MB`;
}

function formatUptime(seconds: number): string {
  if (seconds <= 0) return '';
  const d = Math.floor(seconds / 86400);
  const h = Math.floor((seconds % 86400) / 3600);
  if (d > 0) return `${d} Days, ${h} Hours`;
  return `${h} Hours`;
}

export default Dashboard;
