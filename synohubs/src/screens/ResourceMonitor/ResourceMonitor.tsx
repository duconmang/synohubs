import React, { useEffect, useState, useRef, useMemo } from 'react';
import { invoke } from '@tauri-apps/api/core';
import {
  Cpu, MemoryStick, Wifi, HardDrive, Activity,
  RefreshCw, ArrowDown, ArrowUp, Thermometer,
  AlertCircle, Disc, Server
} from 'lucide-react';
import './ResourceMonitor.css';

// ── Types ──

interface HistoryPoint {
  time: number;
  value: number;
}

interface NetworkHistory {
  time: number;
  rx: number;
  tx: number;
}

const MAX_HISTORY = 60; // 60 data points (~5 min at 5s interval)
const POLL_INTERVAL = 5000;

// ── Component ──

const ResourceMonitor: React.FC = () => {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // History
  const [cpuHistory, setCpuHistory] = useState<HistoryPoint[]>([]);
  const [ramHistory, setRamHistory] = useState<HistoryPoint[]>([]);
  const [netHistory, setNetHistory] = useState<NetworkHistory[]>([]);

  const prevNet = useRef<{ rx: number; tx: number; time: number } | null>(null);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const fetchData = async () => {
    try {
      const result: any = await invoke('nas_get_system_info');
      setData(result);
      setError(null);

      const now = Date.now();
      const cpu = result?.utilization?.cpu || {};
      const cpuTotal = Math.min((cpu.user_load || 0) + (cpu.system_load || 0), 100);

      const mem = result?.utilization?.memory || {};
      const totalReal = (mem.total_real || 0) as number; // KB
      const availReal = (mem.avail_real || 0) as number; // KB
      const bufferKB = (mem.buffer || 0) as number;
      const cachedKB = (mem.cached || 0) as number;
      const usedKB = totalReal - availReal - bufferKB - cachedKB;
      const memUsedPct = totalReal > 0 ? (usedKB / totalReal) * 100 : 0;

      setCpuHistory(prev => [...prev.slice(-(MAX_HISTORY - 1)), { time: now, value: cpuTotal }]);
      setRamHistory(prev => [...prev.slice(-(MAX_HISTORY - 1)), { time: now, value: Math.max(0, memUsedPct) }]);

      // Network — calculate delta
      const netArr = result?.utilization?.network || [];
      let totalRx = 0, totalTx = 0;
      netArr.forEach((n: any) => {
        totalRx += (n.rx || 0);
        totalTx += (n.tx || 0);
      });

      if (prevNet.current) {
        const dt = (now - prevNet.current.time) / 1000;
        if (dt > 0) {
          const rxSpeed = Math.max(0, (totalRx - prevNet.current.rx) / dt);
          const txSpeed = Math.max(0, (totalTx - prevNet.current.tx) / dt);
          setNetHistory(prev => [...prev.slice(-(MAX_HISTORY - 1)), { time: now, rx: rxSpeed, tx: txSpeed }]);
        }
      }
      prevNet.current = { rx: totalRx, tx: totalTx, time: now };
    } catch (err: any) {
      setError(err?.toString());
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
    timerRef.current = setInterval(fetchData, POLL_INTERVAL);
    return () => { if (timerRef.current) clearInterval(timerRef.current); };
  }, []);

  // ── Parse data ──
  const cpu = data?.utilization?.cpu || {};
  const cpuUser = (cpu.user_load || 0) as number;
  const cpuSys = (cpu.system_load || 0) as number;
  const cpuTotal = Math.min(cpuUser + cpuSys, 100);

  const mem = data?.utilization?.memory || {};
  // All values in KB from Synology API
  const memTotalKB = (mem.total_real || 0) as number;
  const memAvailKB = (mem.avail_real || 0) as number;
  const memCachedKB = (mem.cached || 0) as number;
  const memBufferKB = (mem.buffer || 0) as number;
  const memUsedKB = memTotalKB - memAvailKB - memBufferKB - memCachedKB;
  const swapTotal = (mem.total_swap || mem.swap_total || 0) as number; // KB
  const swapUsed = (mem.used_swap || mem.swap_used || 0) as number;   // KB
  const memPercent = memTotalKB > 0 ? (memUsedKB / memTotalKB) * 100 : 0;

  const netArr = data?.utilization?.network || [];
  const diskArr = data?.utilization?.disk || [];

  // Latest network speed

  // Storage
  const volumes = data?.storage?.volumes || data?.storage?.vol_info || [];
  const disks = data?.storage?.disks || data?.storage?.disk_info || [];

  if (loading && !data) {
    return (
      <div className="resmon">
        <div className="resmon__loading">
          <Activity size={24} className="animate-spin" />
          <span>Loading Resource Monitor...</span>
        </div>
      </div>
    );
  }

  return (
    <div className="resmon">
      <div className="resmon__header">
        <h1><Activity size={16} /> Resource Monitor</h1>
        <button className="btn btn-ghost btn-icon" onClick={fetchData} title="Refresh">
          <RefreshCw size={14} />
        </button>
      </div>

      {error && (
        <div className="resmon__error"><AlertCircle size={14} /> {error}</div>
      )}

      {/* ── TOP ROW: CPU + RAM Gauges ── */}
      <div className="resmon__gauges">
        <GaugeCard
          icon={<Cpu size={16} />}
          label="CPU"
          value={cpuTotal}
          color="#38bdf8"
          details={[
            { label: 'User', value: `${cpuUser.toFixed(1)}%` },
            { label: 'System', value: `${cpuSys.toFixed(1)}%` },
            { label: 'Idle', value: `${(100 - cpuTotal).toFixed(1)}%` },
          ]}
        />
        <GaugeCard
          icon={<MemoryStick size={16} />}
          label="Memory"
          value={memPercent}
          color="#a78bfa"
          details={[
            { label: 'Used', value: formatBytes(memUsedKB * 1024) },
            { label: 'Total', value: formatBytes(memTotalKB * 1024) },
            { label: 'Cached', value: formatBytes(memCachedKB * 1024) },
            { label: 'Buffer', value: formatBytes(memBufferKB * 1024) },
            ...(swapTotal > 0 ? [{ label: 'Swap', value: `${formatBytes(swapUsed * 1024)} / ${formatBytes(swapTotal * 1024)}` }] : []),
          ]}
        />
      </div>

      {/* ── CHARTS ── */}
      <div className="resmon__charts">
        <MiniChart
          title="CPU Usage"
          data={cpuHistory.map(p => p.value)}
          color="#38bdf8"
          suffix="%"
          max={100}
        />
        <MiniChart
          title="RAM Usage"
          data={ramHistory.map(p => p.value)}
          color="#a78bfa"
          suffix="%"
          max={100}
        />
        <DualChart
          title="Network I/O"
          dataUp={netHistory.map(p => p.tx)}
          dataDown={netHistory.map(p => p.rx)}
          colorUp="#f472b6"
          colorDown="#22d3ee"
        />
      </div>

      {/* ── NETWORK + DISK DETAIL ── */}
      <div className="resmon__details">
        {/* Network interfaces */}
        <div className="resmon__section">
          <h3><Wifi size={14} /> Network Interfaces</h3>
          <div className="resmon__net-grid">
            {netArr.length > 0 ? netArr.map((n: any, i: number) => (
              <div key={n.device || i} className="resmon__net-card">
                <div className="resmon__net-device">{n.device || `eth${i}`}</div>
                <div className="resmon__net-flows">
                  <div className="resmon__net-flow resmon__net-flow--rx">
                    <ArrowDown size={11} />
                    <span>RX</span>
                    <strong>{formatSpeed(n.rx || 0)}</strong>
                  </div>
                  <div className="resmon__net-flow resmon__net-flow--tx">
                    <ArrowUp size={11} />
                    <span>TX</span>
                    <strong>{formatSpeed(n.tx || 0)}</strong>
                  </div>
                </div>
              </div>
            )) : (
              <div className="resmon__empty">No network data</div>
            )}
          </div>
        </div>

        {/* Disk I/O */}
        <div className="resmon__section">
          <h3><HardDrive size={14} /> Disk Activity</h3>
          <div className="resmon__disk-grid">
            {diskArr.length > 0 ? diskArr.map((d: any, i: number) => (
              <div key={d.device || i} className="resmon__disk-card">
                <div className="resmon__disk-name">
                  <Disc size={14} />
                  {d.device || d.display_name || `disk${i + 1}`}
                </div>
                <div className="resmon__disk-io">
                  <div className="resmon__disk-stat">
                    <span>Read</span>
                    <strong>{formatSpeed(d.read_access || d.read_byte || 0)}</strong>
                  </div>
                  <div className="resmon__disk-stat">
                    <span>Write</span>
                    <strong>{formatSpeed(d.write_access || d.write_byte || 0)}</strong>
                  </div>
                  {d.utilization != null && (
                    <div className="resmon__disk-bar-wrap">
                      <div className="resmon__disk-bar" style={{ width: `${Math.min(d.utilization, 100)}%` }} />
                      <span>{d.utilization?.toFixed(0)}% busy</span>
                    </div>
                  )}
                </div>
              </div>
            )) : (
              <div className="resmon__empty">No disk I/O data</div>
            )}
          </div>
        </div>
      </div>

      {/* ── STORAGE VOLUMES ── */}
      {volumes.length > 0 && (
        <div className="resmon__section resmon__section--volumes">
          <h3><Server size={14} /> Storage Volumes</h3>
          <div className="resmon__vol-grid">
            {volumes.map((v: any, i: number) => {
              const total = parseInt(v.size?.total || v.total_size || '0');
              const used = parseInt(v.size?.used || v.used_size || '0');
              const pct = total > 0 ? (used / total) * 100 : 0;
              const status = v.status || 'normal';
              return (
                <VolumeCard
                  key={v.id || v.vol_path || i}
                  name={v.display_name || v.vol_path || v.id || `Volume ${i + 1}`}
                  usedBytes={used}
                  totalBytes={total}
                  percent={pct}
                  status={status}
                  raidType={v.raid_type || v.fs_type || ''}
                />
              );
            })}
          </div>
        </div>
      )}

      {/* ── PHYSICAL DISKS ── */}
      {disks.length > 0 && (
        <div className="resmon__section resmon__section--disks">
          <h3><HardDrive size={14} /> Physical Disks</h3>
          <div className="resmon__phys-grid">
            {disks.map((d: any, i: number) => (
              <div key={d.id || i} className="resmon__phys-card">
                <div className="resmon__phys-header">
                  <span className="resmon__phys-name">{d.name || d.id || `Disk ${i + 1}`}</span>
                  <span className={`resmon__phys-status resmon__phys-status--${(d.status || 'normal').toLowerCase()}`}>
                    {d.status || 'Normal'}
                  </span>
                </div>
                <div className="resmon__phys-model">{d.model || 'Unknown'}</div>
                <div className="resmon__phys-details">
                  {d.size_total != null && <span>{formatBytes(d.size_total)}</span>}
                  {d.temp != null && (
                    <span className={`resmon__phys-temp ${d.temp > 55 ? 'resmon__phys-temp--hot' : ''}`}>
                      <Thermometer size={11} /> {d.temp}°C
                    </span>
                  )}
                  {d.smart_status != null && (
                    <span className={d.smart_status === 'normal' ? 'resmon__phys-smart--ok' : 'resmon__phys-smart--warn'}>
                      S.M.A.R.T. {d.smart_status}
                    </span>
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

// ── Gauge Card ──
const GaugeCard: React.FC<{
  icon: React.ReactNode;
  label: string;
  value: number;
  color: string;
  details: { label: string; value: string }[];
}> = ({ icon, label, value, color, details }) => {
  const radius = 52;
  const circumference = 2 * Math.PI * radius;
  const offset = circumference - (Math.min(value, 100) / 100) * circumference;
  const getStatusColor = (v: number) => {
    if (v > 90) return '#ef4444';
    if (v > 70) return '#fbbf24';
    return color;
  };
  const currentColor = getStatusColor(value);

  return (
    <div className="gauge-card">
      <div className="gauge-card__ring">
        <svg viewBox="0 0 120 120" className="gauge-card__svg">
          <circle cx="60" cy="60" r={radius} fill="none" stroke="rgba(255,255,255,0.04)" strokeWidth="7" />
          <circle
            cx="60" cy="60" r={radius}
            fill="none"
            stroke={currentColor}
            strokeWidth="7"
            strokeLinecap="round"
            strokeDasharray={circumference}
            strokeDashoffset={offset}
            transform="rotate(-90, 60, 60)"
            className="gauge-card__progress"
          />
        </svg>
        <div className="gauge-card__center">
          <span className="gauge-card__value" style={{ color: currentColor }}>{value.toFixed(1)}<small>%</small></span>
        </div>
      </div>
      <div className="gauge-card__meta">
        <div className="gauge-card__label">{icon} {label}</div>
        <div className="gauge-card__details">
          {details.map(d => (
            <div key={d.label} className="gauge-card__detail">
              <span>{d.label}</span>
              <span>{d.value}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

// ── Mini Line Chart ──
const MiniChart: React.FC<{
  title: string;
  data: number[];
  color: string;
  suffix?: string;
  max?: number;
}> = ({ title, data, color, suffix = '', max = 100 }) => {
  const latest = data.length > 0 ? data[data.length - 1] : 0;
  const points = useMemo(() => {
    if (data.length === 0) return '';
    const w = 200;
    const h = 50;
    const step = w / (MAX_HISTORY - 1);
    const pts = data.map((v, i) => {
      const x = (MAX_HISTORY - data.length + i) * step;
      const y = h - (Math.min(v, max) / max) * h;
      return `${x},${y}`;
    });
    return pts.join(' ');
  }, [data, max]);

  const areaPath = useMemo(() => {
    if (data.length === 0) return '';
    const w = 200;
    const h = 50;
    const step = w / (MAX_HISTORY - 1);
    let path = `M ${(MAX_HISTORY - data.length) * step},${h}`;
    data.forEach((v, i) => {
      const x = (MAX_HISTORY - data.length + i) * step;
      const y = h - (Math.min(v, max) / max) * h;
      path += ` L ${x},${y}`;
    });
    path += ` L ${(MAX_HISTORY - 1) * step},${h} Z`;
    return path;
  }, [data, max]);

  return (
    <div className="mini-chart">
      <div className="mini-chart__header">
        <span className="mini-chart__title">{title}</span>
        <span className="mini-chart__value" style={{ color }}>{latest.toFixed(1)}{suffix}</span>
      </div>
      <svg viewBox="0 0 200 50" preserveAspectRatio="none" className="mini-chart__svg">
        <defs>
          <linearGradient id={`grad-${title.replace(/\s/g, '')}`} x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor={color} stopOpacity={0.3} />
            <stop offset="100%" stopColor={color} stopOpacity={0.02} />
          </linearGradient>
        </defs>
        {areaPath && <path d={areaPath} fill={`url(#grad-${title.replace(/\s/g, '')})`} />}
        {points && <polyline points={points} fill="none" stroke={color} strokeWidth="1.5" strokeLinejoin="round" />}
      </svg>
    </div>
  );
};

// ── Dual Line Chart (Network) ──
const DualChart: React.FC<{
  title: string;
  dataUp: number[];
  dataDown: number[];
  colorUp: string;
  colorDown: string;
}> = ({ title, dataUp, dataDown, colorUp, colorDown }) => {
  const latestUp = dataUp.length > 0 ? dataUp[dataUp.length - 1] : 0;
  const latestDown = dataDown.length > 0 ? dataDown[dataDown.length - 1] : 0;
  const allVals = [...dataUp, ...dataDown];
  const max = Math.max(1, ...allVals) * 1.15;

  const makePoints = (data: number[]) => {
    if (data.length === 0) return '';
    const w = 200;
    const h = 50;
    const step = w / (MAX_HISTORY - 1);
    return data.map((v, i) => {
      const x = (MAX_HISTORY - data.length + i) * step;
      const y = h - (Math.min(v, max) / max) * h;
      return `${x},${y}`;
    }).join(' ');
  };

  return (
    <div className="mini-chart">
      <div className="mini-chart__header">
        <span className="mini-chart__title">{title}</span>
        <div className="mini-chart__net-labels">
          <span style={{ color: colorDown }}><ArrowDown size={9} /> {formatSpeed(latestDown)}</span>
          <span style={{ color: colorUp }}><ArrowUp size={9} /> {formatSpeed(latestUp)}</span>
        </div>
      </div>
      <svg viewBox="0 0 200 50" preserveAspectRatio="none" className="mini-chart__svg">
        <polyline points={makePoints(dataDown)} fill="none" stroke={colorDown} strokeWidth="1.5" strokeLinejoin="round" />
        <polyline points={makePoints(dataUp)} fill="none" stroke={colorUp} strokeWidth="1.5" strokeLinejoin="round" />
      </svg>
    </div>
  );
};

// ── Volume Card ──
const VolumeCard: React.FC<{
  name: string;
  usedBytes: number;
  totalBytes: number;
  percent: number;
  status: string;
  raidType: string;
}> = ({ name, usedBytes, totalBytes, percent, status, raidType }) => {
  const getBarColor = (p: number) => {
    if (p > 90) return '#ef4444';
    if (p > 75) return '#fbbf24';
    return '#4ade80';
  };

  return (
    <div className="vol-card">
      <div className="vol-card__header">
        <span className="vol-card__name">{name}</span>
        <span className={`vol-card__status vol-card__status--${status.toLowerCase()}`}>{status}</span>
      </div>
      <div className="vol-card__bar-track">
        <div className="vol-card__bar-fill" style={{ width: `${Math.min(percent, 100)}%`, background: getBarColor(percent) }} />
      </div>
      <div className="vol-card__info">
        <span>{formatBytes(usedBytes)} / {formatBytes(totalBytes)}</span>
        <span className="vol-card__pct" style={{ color: getBarColor(percent) }}>{percent.toFixed(1)}%</span>
      </div>
      {raidType && <div className="vol-card__raid">{raidType}</div>}
    </div>
  );
};

// ── Helpers ──

function formatBytes(bytes: number): string {
  if (!bytes || bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
  const i = Math.floor(Math.log(bytes) / Math.log(1024));
  return `${(bytes / Math.pow(1024, i)).toFixed(i > 1 ? 1 : 0)} ${units[i]}`;
}

function formatSpeed(bytesPerSec: number): string {
  if (!bytesPerSec || bytesPerSec <= 0) return '0 B/s';
  const units = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
  const i = Math.floor(Math.log(bytesPerSec) / Math.log(1024));
  const idx = Math.min(i, units.length - 1);
  return `${(bytesPerSec / Math.pow(1024, idx)).toFixed(idx > 0 ? 1 : 0)} ${units[idx]}`;
}

export default ResourceMonitor;
