import React, { useEffect, useState, useCallback } from 'react';
import { invoke } from '@tauri-apps/api/core';
import {
  Container, RefreshCw, Search, Play, Square, AlertCircle,
  RotateCw, Cpu, MemoryStick
} from 'lucide-react';
import './Docker.css';

interface DockerContainer {
  name: string;
  image: string;
  status: string;       // "running", "stopped", "created", etc.
  state: string;        // same or more granular
  up_time?: number;     // seconds
  cpu?: number;         // CPU usage %
  memory?: number;      // Memory usage bytes
  memoryLimit?: number; // Memory limit bytes
}

const Docker: React.FC = () => {
  const [containers, setContainers] = useState<DockerContainer[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState('');
  const [actionPending, setActionPending] = useState<string | null>(null);
  const [dockerAvailable, setDockerAvailable] = useState(true);

  const fetchContainers = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const result: any = await invoke('docker_list');

      if (result?.success === true) {
        const rawContainers = result?.data?.containers || [];

        // Parse container list
        const parsed: DockerContainer[] = rawContainers.map((c: any) => ({
          name: c.name || c.Names?.[0]?.replace(/^\//, '') || 'unknown',
          image: c.image || c.Image || '',
          status: (c.status || c.state || c.State || 'unknown').toLowerCase(),
          state: (c.state || c.status || c.State || 'unknown').toLowerCase(),
          up_time: c.up_time || 0,
        }));

        setContainers(parsed);
        setDockerAvailable(true);

        // Try fetching resource usage
        try {
          const resResult: any = await invoke('docker_get_resource');
          if (resResult?.success && resResult?.data?.resources) {
            const resources = resResult.data.resources;
            setContainers(prev => prev.map(c => {
              const res = resources.find((r: any) => r.name === c.name);
              if (res) {
                return {
                  ...c,
                  cpu: res.cpu || res.CPUPerc || 0,
                  memory: res.memory || res.MemUsage || 0,
                  memoryLimit: res.memoryLimit || res.MemLimit || 0,
                };
              }
              return c;
            }));
          }
        } catch {
          // Resource API might not be available — ignore
        }
      } else {
        const code = result?.error?.code;
        if (code === 109 || code === 119) {
          // Docker not installed / API not available
          setDockerAvailable(false);
        } else {
          setError(`Docker API error: ${JSON.stringify(result?.error || 'Unknown')}`);
        }
      }
    } catch (err: any) {
      const msg = err?.toString() || '';
      if (msg.includes('119') || msg.includes('not found') || msg.includes('does not exist')) {
        setDockerAvailable(false);
      } else {
        setError(msg || 'Failed to load containers');
      }
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchContainers(); }, [fetchContainers]);

  // Auto-refresh every 10 seconds
  useEffect(() => {
    const interval = setInterval(fetchContainers, 10000);
    return () => clearInterval(interval);
  }, [fetchContainers]);

  const handleAction = async (name: string, action: 'start' | 'stop' | 'restart') => {
    setActionPending(name);
    try {
      const cmdName = `docker_${action}`;
      const result: any = await invoke(cmdName, { name });

      if (result?.success) {
        // Wait a moment for the container state to change
        setTimeout(fetchContainers, 1500);
      } else {
        setError(`Failed to ${action} "${name}": ${JSON.stringify(result?.error || 'Unknown error')}`);
      }
    } catch (err: any) {
      setError(`Failed to ${action} "${name}": ${err}`);
    } finally {
      setTimeout(() => setActionPending(null), 1500);
    }
  };

  const isRunning = (c: DockerContainer) => c.status === 'running';

  const filtered = containers.filter(c =>
    c.name.toLowerCase().includes(search.toLowerCase()) ||
    c.image.toLowerCase().includes(search.toLowerCase())
  );

  const running = filtered.filter(isRunning);
  const stopped = filtered.filter(c => !isRunning(c));

  // Docker not installed
  if (!dockerAvailable && !loading) {
    return (
      <div className="docker">
        <div className="docker__header">
          <h1><Container size={18} /> Docker</h1>
        </div>
        <div className="docker__not-installed">
          <Container size={48} />
          <div className="docker__not-installed-title">Docker Not Available</div>
          <div className="docker__not-installed-desc">
            Container Manager (Docker) is not installed or not running on this NAS.
            Install it from Package Center to manage containers.
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="docker">
      {/* Header */}
      <div className="docker__header">
        <h1>
          <Container size={18} />
          Docker
        </h1>
        <div className="docker__header-actions">
          <div className="docker__search">
            <Search size={13} />
            <input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search containers..."
            />
          </div>
          <button className="btn btn-ghost btn-icon" onClick={fetchContainers} title="Refresh">
            <RefreshCw size={14} className={loading ? 'animate-spin' : ''} />
          </button>
        </div>
      </div>

      {error && (
        <div className="docker__error">
          <AlertCircle size={14} /> {error}
        </div>
      )}

      {/* Stats */}
      <div className="docker__stats">
        <div className="docker__stat">
          <span className="docker__stat-value">{containers.length}</span>
          <span className="docker__stat-label">Total</span>
        </div>
        <div className="docker__stat docker__stat--running">
          <span className="docker__stat-value">{containers.filter(isRunning).length}</span>
          <span className="docker__stat-label">Running</span>
        </div>
        <div className="docker__stat docker__stat--stopped">
          <span className="docker__stat-value">{containers.filter(c => !isRunning(c)).length}</span>
          <span className="docker__stat-label">Stopped</span>
        </div>
      </div>

      {/* Container list */}
      <div className="docker__list">
        {running.length > 0 && (
          <>
            <div className="docker__section-label">Running ({running.length})</div>
            {running.map(c => (
              <DockerCard
                key={c.name}
                container={c}
                onAction={handleAction}
                pending={actionPending === c.name}
              />
            ))}
          </>
        )}

        {stopped.length > 0 && (
          <>
            <div className="docker__section-label">Stopped ({stopped.length})</div>
            {stopped.map(c => (
              <DockerCard
                key={c.name}
                container={c}
                onAction={handleAction}
                pending={actionPending === c.name}
              />
            ))}
          </>
        )}

        {!loading && filtered.length === 0 && (
          <div className="docker__empty">
            <Container size={32} />
            {search ? 'No containers match your search' : 'No Docker containers found'}
          </div>
        )}
      </div>
    </div>
  );
};

// ── Container Card ──

interface DockerCardProps {
  container: DockerContainer;
  onAction: (name: string, action: 'start' | 'stop' | 'restart') => void;
  pending: boolean;
}

const DockerCard: React.FC<DockerCardProps> = ({ container, onAction, pending }) => {
  const running = container.status === 'running';

  const formatUptime = (seconds: number): string => {
    if (!seconds || seconds <= 0) return '';
    const d = Math.floor(seconds / 86400);
    const h = Math.floor((seconds % 86400) / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    if (d > 0) return `${d}d ${h}h`;
    if (h > 0) return `${h}h ${m}m`;
    return `${m}m`;
  };

  const formatMemory = (bytes: number): string => {
    if (!bytes) return '—';
    if (bytes > 1024 * 1024 * 1024) return `${(bytes / (1024 * 1024 * 1024)).toFixed(1)} GB`;
    if (bytes > 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(0)} MB`;
    return `${(bytes / 1024).toFixed(0)} KB`;
  };

  const formatCpu = (cpu: number | undefined): string => {
    if (cpu === undefined || cpu === null) return '—';
    return `${cpu.toFixed(1)}%`;
  };

  return (
    <div className={`docker-card ${running ? 'docker-card--running' : ''}`}>
      {/* Icon */}
      <div className="docker-card__icon">
        <Container size={18} />
      </div>

      {/* Info */}
      <div className="docker-card__info">
        <div className="docker-card__name">{container.name}</div>
        <div className="docker-card__image">{container.image}</div>
        {running && container.up_time ? (
          <div className="docker-card__uptime">Up {formatUptime(container.up_time)}</div>
        ) : null}
      </div>

      {/* Resources (only for running) */}
      {running && (container.cpu !== undefined || container.memory !== undefined) && (
        <div className="docker-card__resources">
          <div className="docker-card__resource">
            <span className="docker-card__resource-value">
              <Cpu size={10} style={{ marginRight: 2 }} />
              {formatCpu(container.cpu)}
            </span>
            <span className="docker-card__resource-label">CPU</span>
          </div>
          <div className="docker-card__resource">
            <span className="docker-card__resource-value">
              <MemoryStick size={10} style={{ marginRight: 2 }} />
              {formatMemory(container.memory || 0)}
            </span>
            <span className="docker-card__resource-label">MEM</span>
          </div>
        </div>
      )}

      {/* Status badge */}
      <div className="docker-card__status">
        {running ? (
          <span className="docker-card__badge docker-card__badge--running">
            <Play size={9} /> Running
          </span>
        ) : (
          <span className="docker-card__badge docker-card__badge--stopped">
            <Square size={9} /> Stopped
          </span>
        )}
      </div>

      {/* Actions */}
      <div className="docker-card__actions">
        {running ? (
          <>
            <button
              className="docker-card__action docker-card__action--restart"
              onClick={() => onAction(container.name, 'restart')}
              disabled={pending}
              title="Restart"
            >
              <RotateCw size={13} className={pending ? 'animate-spin' : ''} />
            </button>
            <button
              className="docker-card__action docker-card__action--stop"
              onClick={() => onAction(container.name, 'stop')}
              disabled={pending}
              title="Stop"
            >
              <Square size={13} />
            </button>
          </>
        ) : (
          <button
            className="docker-card__action docker-card__action--start"
            onClick={() => onAction(container.name, 'start')}
            disabled={pending}
            title="Start"
          >
            <Play size={13} />
          </button>
        )}
      </div>
    </div>
  );
};

export default Docker;
