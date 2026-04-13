import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Globe, User, Lock, Eye, EyeOff, Server, Search,
  Plus, X, Wifi, Settings, KeyRound, FolderOpen,
  LayoutDashboard, Pencil, Check, Trash2, FlaskConical
} from 'lucide-react';
import { invoke } from '@tauri-apps/api/core';
import { SynoHubsLogo } from '../../components/Logo';
import { useAuthStore, useNasStore, type NasConnection } from '../../stores';
import { getNasModelImage, getNasSeriesColor } from '../../utils/nasModels';
import { useConfirmDialog } from '../../components/ConfirmDialog/ConfirmDialog';
import './NasLogin.css';

/**
 * NAS Management — View, add, test, rename, and connect to NAS devices
 * 
 * Features:
 * - Real NAS device images displayed for each model
 * - Test button: validates connection without entering the dashboard
 * - Double-click NAS card to connect
 * - Rename NAS devices for easy identification
 */
const NasLogin: React.FC = () => {
  const navigate = useNavigate();
  const { user } = useAuthStore();
  const { connections, activeNas, addConnection, setActiveNas, removeConnection } = useNasStore();
  const { showDialog, DialogComponent } = useConfirmDialog();
  const [showForm, setShowForm] = useState(false);
  const [address, setAddress] = useState('');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [otpCode, setOtpCode] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [show2FA, setShow2FA] = useState(false);
  const [status, setStatus] = useState<'idle' | 'connecting' | 'testing' | 'success' | 'error'>('idle');
  const [statusMessage, setStatusMessage] = useState('');

  // Rename state
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editName, setEditName] = useState('');

  const doLogin = async (mode: 'connect' | 'test') => {
    if (!address || !username || !password) {
      setStatus('error');
      setStatusMessage('Please fill in all fields');
      return;
    }

    setStatus(mode === 'test' ? 'testing' : 'connecting');
    setStatusMessage(mode === 'test' ? 'Testing connection...' : 'Connecting...');

    try {
      const result: any = await invoke('nas_login', {
        request: {
          address: address.trim(),
          username: username.trim(),
          password,
          otp_code: otpCode || null,
        },
      });

      if (result.success) {
        const newNas: NasConnection = {
          id: `nas-${Date.now()}`,
          name: result.hostname || result.model || address.split('.')[0] || address,
          host: result.host,
          port: result.port,
          protocol: result.use_https ? 'https' : 'http',
          username,
          model: result.model,
          dsm_version: result.dsm_version,
          serial: result.serial,
          status: 'online',
          is_admin: result.is_admin,
        };

        addConnection(newNas);

        if (mode === 'connect') {
          // Connect: go to dashboard
          setActiveNas(newNas);
          setStatus('success');
          setStatusMessage('Connected!');
          setTimeout(() => {
            setShowForm(false);
            navigate('/app/dashboard');
          }, 500);
        } else {
          // Test: stay on NAS manager, show success
          setStatus('success');
          setStatusMessage(`✓ ${result.model || 'NAS'} verified — ${result.hostname || result.host}`);
          // Logout after test (don't keep session)
          invoke('nas_logout').catch(() => {});
          setTimeout(() => {
            setShowForm(false);
            setStatus('idle');
          }, 1500);
        }
      } else if (result.error === '2FA_REQUIRED') {
        setShow2FA(true);
        setStatus('idle');
        setStatusMessage('');
      } else {
        setStatus('error');
        setStatusMessage(result.error || 'Connection failed');
      }
    } catch (err: any) {
      setStatus('error');
      setStatusMessage(err?.toString() || 'Connection failed');
    }
  };

  const handleConnect = (e: React.FormEvent) => {
    e.preventDefault();
    doLogin('connect');
  };

  const handleTest = () => {
    doLogin('test');
  };

  const handleDoubleClickNas = (nas: NasConnection) => {
    // Double-click to connect and go to dashboard
    setActiveNas(nas);
    navigate('/app/dashboard');
  };

  const handleDeleteNas = (e: React.MouseEvent, nasId: string) => {
    e.stopPropagation();
    removeConnection(nasId);
  };

  // Rename handlers
  const startRename = (e: React.MouseEvent, nas: NasConnection) => {
    e.stopPropagation();
    setEditingId(nas.id);
    setEditName(nas.name);
  };

  const confirmRename = (nasId: string) => {
    if (editName.trim()) {
      // Update the connection name in store
      const conn = connections.find(c => c.id === nasId);
      if (conn) {
        removeConnection(nasId);
        addConnection({ ...conn, name: editName.trim() });
      }
    }
    setEditingId(null);
  };

  const openAddForm = async () => {
    if (user?.tier === 'free' && connections.length >= 1) {
      await showDialog({
        title: 'Free Tier Limit',
        message: 'Free accounts can only manage 1 NAS device. Upgrade to Premium for unlimited NAS connections.',
        variant: 'warning',
        confirmText: 'Got it',
        showCancel: false,
      });
      return;
    }
    setShowForm(true);
    setStatus('idle');
    setShow2FA(false);
    setAddress('');
    setUsername('');
    setPassword('');
    setOtpCode('');
  };

  return (
    <div className="nas-login">
      {/* Top bar */}
      <div className="nas-login__topbar">
        <SynoHubsLogo size={22} />
        <div className="nas-login__search">
          <Search size={14} color="var(--color-text-dim)" />
          <input placeholder="Search NAS devices..." />
        </div>
        <div className="nas-login__topbar-right">
          {activeNas && (
            <button
              className="btn btn-outline btn-sm"
              onClick={() => navigate('/app/dashboard')}
              style={{ marginRight: '8px' }}
            >
              <LayoutDashboard size={14} /> Back to Dashboard
            </button>
          )}
          <span className="badge badge-info" style={{ fontSize: '11px' }}>
            {connections.length} of {user?.tier === 'vip' ? '∞' : '1'} NAS
          </span>
        </div>
      </div>

      <div className="nas-login__body">
        {/* Sidebar */}
        <div className="nas-login__sidebar">
          <button className="nas-login__sidebar-item active">
            <Server size={16} /> NAS Devices
          </button>
          <button className="nas-login__sidebar-item">
            <KeyRound size={16} /> Keychain
          </button>
          <button className="nas-login__sidebar-item">
            <FolderOpen size={16} /> Local Share
          </button>
          <button className="nas-login__sidebar-item">
            <Settings size={16} /> Settings
          </button>

          <div className="nas-login__sidebar-bottom">
            {user && (
              <>
                <div className="nas-login__user-info">
                  <div className="nas-login__user-avatar">
                    {user.name?.charAt(0).toUpperCase() || 'U'}
                  </div>
                  <span className="nas-login__user-name">{user.name}</span>
                </div>
                <div className="nas-login__user-version">v0.1.0</div>
              </>
            )}
          </div>
        </div>

        {/* Content */}
        <div className="nas-login__content">
          {/* Header with actions */}
          <div className="nas-login__content-header">
            <h2>NAS Devices</h2>
            <div className="nas-login__actions">
              <button className="btn btn-primary" onClick={openAddForm}>
                <Plus size={14} /> Add NAS
              </button>
            </div>
          </div>

          {/* NAS Cards Grid */}
          {connections.length > 0 ? (
            <div className="nas-cards-grid">
              {connections.map((nas) => {
                const modelImage = getNasModelImage(nas.model);
                const isActive = activeNas?.id === nas.id;

                return (
                  <div
                    key={nas.id}
                    className={`nas-card ${isActive ? 'nas-card--active' : ''}`}
                    onDoubleClick={() => handleDoubleClickNas(nas)}
                    title="Double-click to connect"
                  >
                    {/* Status indicator */}
                    <div className={`nas-card__status-dot nas-card__status-dot--${nas.status}`} />

                    {/* NAS Image */}
                    <div className="nas-card__image">
                      {modelImage ? (
                        <img src={modelImage} alt={nas.model || 'NAS'} />
                      ) : (
                        <div
                          className="nas-card__image-placeholder"
                          style={{ color: getNasSeriesColor(nas.model) }}
                        >
                          <Server size={48} />
                        </div>
                      )}
                    </div>

                    {/* NAS Info */}
                    <div className="nas-card__info">
                      {editingId === nas.id ? (
                        <div className="nas-card__rename">
                          <input
                            value={editName}
                            onChange={(e) => setEditName(e.target.value)}
                            onKeyDown={(e) => {
                              if (e.key === 'Enter') confirmRename(nas.id);
                              if (e.key === 'Escape') setEditingId(null);
                            }}
                            autoFocus
                            className="nas-card__rename-input"
                          />
                          <button
                            className="nas-card__rename-btn"
                            onClick={() => confirmRename(nas.id)}
                          >
                            <Check size={14} />
                          </button>
                        </div>
                      ) : (
                        <div className="nas-card__name">{nas.name}</div>
                      )}
                      <div className="nas-card__model">{nas.model || 'Unknown Model'}</div>
                      <div className="nas-card__detail">
                        {nas.dsm_version && <span>{nas.dsm_version}</span>}
                      </div>
                      <div className="nas-card__host">
                        {nas.username}@{nas.host}:{nas.port}
                      </div>
                    </div>

                    {/* Actions */}
                    <div className="nas-card__actions">
                      <button
                        className="nas-card__action-btn"
                        onClick={(e) => startRename(e, nas)}
                        title="Rename"
                      >
                        <Pencil size={13} />
                      </button>
                      <button
                        className="nas-card__action-btn nas-card__action-btn--danger"
                        onClick={(e) => handleDeleteNas(e, nas.id)}
                        title="Remove"
                      >
                        <Trash2 size={13} />
                      </button>
                    </div>

                    {isActive && (
                      <div className="nas-card__connected-badge">CONNECTED</div>
                    )}
                  </div>
                );
              })}
            </div>
          ) : (
            <div className="nas-login__empty">
              <Server size={48} strokeWidth={1} />
              <h3>No NAS devices yet</h3>
              <p>Click "Add NAS" to connect your first Synology device.</p>
              <button className="btn btn-primary" onClick={openAddForm}>
                <Plus size={14} /> Add NAS
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Connection Form Modal */}
      {showForm && (
        <div className="nas-login__form-overlay" onClick={() => setShowForm(false)}>
          <div className="nas-login__form-card" onClick={(e) => e.stopPropagation()}>
            <div className="nas-login__form-title">
              <span>Add NAS Device</span>
              <button className="btn btn-ghost btn-icon" onClick={() => setShowForm(false)}>
                <X size={16} />
              </button>
            </div>

            <form className="nas-login__form" onSubmit={handleConnect}>
              <div className="input-group">
                <label htmlFor="nas-addr">Server Address</label>
                <div className="input-wrapper">
                  <Globe className="input-icon" />
                  <input
                    id="nas-addr"
                    className="input"
                    placeholder="IP, domain, or QuickConnect ID"
                    value={address}
                    onChange={(e) => setAddress(e.target.value)}
                    autoFocus
                  />
                </div>
                <span className="input-hint">
                  Examples: 192.168.1.100:5001 • nas.example.com • myQCID
                </span>
              </div>

              <div className="input-group">
                <label htmlFor="nas-user">Username</label>
                <div className="input-wrapper">
                  <User className="input-icon" />
                  <input
                    id="nas-user"
                    className="input"
                    placeholder="admin"
                    value={username}
                    onChange={(e) => setUsername(e.target.value)}
                  />
                </div>
              </div>

              <div className="input-group">
                <label htmlFor="nas-pass">Password</label>
                <div className="input-wrapper">
                  <Lock className="input-icon" />
                  <input
                    id="nas-pass"
                    className="input"
                    type={showPassword ? 'text' : 'password'}
                    placeholder="••••••••"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                  />
                  <button
                    type="button"
                    className="input-action"
                    onClick={() => setShowPassword(!showPassword)}
                  >
                    {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                  </button>
                </div>
              </div>

              {show2FA && (
                <div className="input-group">
                  <label htmlFor="nas-otp">2FA Code (OTP)</label>
                  <div className="input-wrapper">
                    <KeyRound className="input-icon" />
                    <input
                      id="nas-otp"
                      className="input"
                      placeholder="6-digit code"
                      value={otpCode}
                      onChange={(e) => setOtpCode(e.target.value)}
                      maxLength={6}
                      autoFocus
                    />
                  </div>
                </div>
              )}

              {status !== 'idle' && (
                <div className={`nas-login__status nas-login__status--${status}`}>
                  {(status === 'connecting' || status === 'testing') && <div className="spinner-sm" />}
                  {statusMessage}
                </div>
              )}

              <div className="nas-login__form-actions">
                <button type="button" className="btn btn-outline" onClick={() => setShowForm(false)}>
                  Cancel
                </button>
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={handleTest}
                  disabled={status === 'connecting' || status === 'testing'}
                  title="Test connection without entering the NAS"
                >
                  <FlaskConical size={14} />
                  {status === 'testing' ? 'Testing...' : 'Test'}
                </button>
                <button
                  type="submit"
                  className="btn btn-primary"
                  disabled={status === 'connecting' || status === 'testing'}
                >
                  <Wifi size={14} />
                  {status === 'connecting' ? 'Connecting...' : 'Connect'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
      {DialogComponent}
    </div>
  );
};

export default NasLogin;
