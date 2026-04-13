import React, { useState, useRef } from 'react';
import {
  Plus, ChevronLeft, ChevronRight, Server, Pencil,
  Trash2, X, Globe, User, Lock, Eye, EyeOff, Wifi,
  KeyRound, FlaskConical, LogOut, Crown, Mail, Calendar, Shield
} from 'lucide-react';
import { invoke } from '@tauri-apps/api/core';
import { openUrl } from '@tauri-apps/plugin-opener';
import { useAuthStore, useNasStore, useUserPrefsStore, type NasConnection } from '../../stores';
import { getNasModelImage, getNasSeriesColor } from '../../utils/nasModels';
import { SynoHubsLogo } from '../Logo';
import { useConfirmDialog } from '../ConfirmDialog/ConfirmDialog';
import './NasSidebar.css';

/**
 * NasSidebar — Left panel showing NAS device cards.
 * Collapsible. Contains Add NAS modal trigger.
 */
const NasSidebar: React.FC = () => {
  const { user, signOut } = useAuthStore();
  const { connections, activeNas, addConnection, setActiveNas, removeConnection, connectToNas, isConnecting } = useNasStore();
  const { avatar, setAvatar } = useUserPrefsStore();
  const [collapsed, setCollapsed] = useState(false);
  const [showForm, setShowForm] = useState(false);
  const [showProfile, setShowProfile] = useState(false);
  const avatarInputRef = useRef<HTMLInputElement>(null);
  const { showDialog, DialogComponent } = useConfirmDialog();

  // Form state
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
      setStatusMessage('Fill all fields');
      return;
    }
    setStatus(mode === 'test' ? 'testing' : 'connecting');
    setStatusMessage(mode === 'test' ? 'Testing...' : 'Connecting...');

    try {
      const result: any = await invoke('nas_login', {
        request: { address: address.trim(), username: username.trim(), password, otp_code: otpCode || null, device_id: null },
      });

      if (result.success) {
        const newNas: NasConnection = {
          id: `nas-${Date.now()}`,
          name: result.hostname || result.model || address.split('.')[0] || address,
          host: result.host,
          port: result.port,
          protocol: result.use_https ? 'https' : 'http',
          username,
          password,  // Save password encrypted for auto-reconnect
          device_id: result.did || undefined,
          model: result.model,
          dsm_version: result.dsm_version,
          serial: result.serial,
          status: 'online',
          is_admin: result.is_admin,
        };
        addConnection(newNas);

        if (mode === 'connect') {
          setActiveNas(newNas);
          setStatus('success');
          setStatusMessage('Connected!');
          setTimeout(() => { setShowForm(false); setStatus('idle'); }, 500);
        } else {
          setStatus('success');
          setStatusMessage(`✓ ${result.model || 'NAS'} verified`);
          invoke('nas_logout').catch(() => {});
          setTimeout(() => { setShowForm(false); setStatus('idle'); }, 1200);
        }
      } else if (result.error === '2FA_REQUIRED') {
        setShow2FA(true);
        setStatus('idle');
        setStatusMessage('');
      } else {
        setStatus('error');
        setStatusMessage(result.error || 'Failed');
      }
    } catch (err: any) {
      setStatus('error');
      setStatusMessage(err?.toString() || 'Failed');
    }
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

  const startRename = (e: React.MouseEvent, nas: NasConnection) => {
    e.stopPropagation();
    setEditingId(nas.id);
    setEditName(nas.name);
  };

  const confirmRename = (nasId: string) => {
    if (editName.trim()) {
      const conn = connections.find(c => c.id === nasId);
      if (conn) {
        removeConnection(nasId);
        const updated = { ...conn, name: editName.trim() };
        addConnection(updated);
        if (activeNas?.id === nasId) setActiveNas(updated);
      }
    }
    setEditingId(null);
  };

  const handleSelectNas = async (nas: NasConnection) => {
    if (isConnecting) return; // Prevent double-click
    // Auto-login with stored password
    await connectToNas(nas.id);
  };

  const handleDeleteNas = (e: React.MouseEvent, nasId: string) => {
    e.stopPropagation();
    removeConnection(nasId);
  };

  const handleAvatarChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (ev) => {
      const img = new Image();
      img.onload = () => {
        // Resize to 128x128
        const canvas = document.createElement('canvas');
        canvas.width = 128;
        canvas.height = 128;
        const ctx = canvas.getContext('2d')!;
        ctx.drawImage(img, 0, 0, 128, 128);
        setAvatar(canvas.toDataURL('image/jpeg', 0.85));
      };
      img.src = ev.target?.result as string;
    };
    reader.readAsDataURL(file);
    e.target.value = '';
  };

  const handleSignOut = async () => {
    setActiveNas(null);
    await signOut();
  };

  return (
    <>
      <aside className={`nas-sidebar ${collapsed ? 'nas-sidebar--collapsed' : ''}`}>
        {/* Header */}
        <div className="nas-sidebar__header">
          {!collapsed && (
            <>
              <SynoHubsLogo size={18} />
              <span className="nas-sidebar__title">SynoHubs</span>
            </>
          )}
          <button
            className="nas-sidebar__toggle"
            onClick={() => setCollapsed(!collapsed)}
            title={collapsed ? 'Expand' : 'Collapse'}
          >
            {collapsed ? <ChevronRight size={16} /> : <ChevronLeft size={16} />}
          </button>
        </div>

        {/* Add NAS Button */}
        <button
          className="nas-sidebar__add-btn"
          onClick={openAddForm}
          title="Add NAS Device"
        >
          <Plus size={16} />
          {!collapsed && <span>Add NAS</span>}
        </button>

        {/* NAS Device Cards */}
        <div className="nas-sidebar__devices">
          {connections.map((nas) => {
            const modelImage = getNasModelImage(nas.model);
            const isActive = activeNas?.id === nas.id;

            return (
              <div
                key={nas.id}
                className={`nas-sidebar__card ${isActive ? 'nas-sidebar__card--active' : ''}`}
                onClick={() => handleSelectNas(nas)}
                title={collapsed ? `${nas.name} (${nas.model || 'NAS'})` : ''}
              >
                {/* Status dot */}
                <div className={`nas-sidebar__card-status nas-sidebar__card-status--${nas.status}`} />

                {/* Image */}
                <div className="nas-sidebar__card-img">
                  {modelImage ? (
                    <img src={modelImage} alt={nas.model || 'NAS'} />
                  ) : (
                    <Server size={collapsed ? 28 : 40} style={{ color: getNasSeriesColor(nas.model) }} />
                  )}
                </div>

                {/* Info (hidden when collapsed) */}
                {!collapsed && (
                  <div className="nas-sidebar__card-info">
                    {editingId === nas.id ? (
                      <div className="nas-sidebar__rename">
                        <input
                          value={editName}
                          onChange={(e) => setEditName(e.target.value)}
                          onKeyDown={(e) => {
                            if (e.key === 'Enter') confirmRename(nas.id);
                            if (e.key === 'Escape') setEditingId(null);
                          }}
                          onBlur={() => confirmRename(nas.id)}
                          autoFocus
                          onClick={(e) => e.stopPropagation()}
                        />
                      </div>
                    ) : (
                      <div className="nas-sidebar__card-name">{nas.name}</div>
                    )}
                    <div className="nas-sidebar__card-model">{nas.model || 'Unknown'}</div>
                  </div>
                )}

                {/* Actions (hover, hidden when collapsed or editing) */}
                {!collapsed && editingId !== nas.id && (
                  <div className="nas-sidebar__card-actions">
                    <button onClick={(e) => startRename(e, nas)} title="Rename">
                      <Pencil size={11} />
                    </button>
                    <button
                      className="danger"
                      onClick={(e) => handleDeleteNas(e, nas.id)}
                      title="Remove"
                    >
                      <Trash2 size={11} />
                    </button>
                  </div>
                )}
              </div>
            );
          })}
        </div>

        {/* Bottom: User info */}
        <div className="nas-sidebar__bottom">
          {user && (
            <div className="nas-sidebar__user-section">
              <div className="nas-sidebar__user-row" onClick={() => setShowProfile(true)} style={{ cursor: 'pointer' }}>
                {/* Avatar */}
                <div
                  className="nas-sidebar__user-avatar"
                  onClick={(e) => { e.stopPropagation(); avatarInputRef.current?.click(); }}
                  title="Change avatar"
                >
                  {avatar ? (
                    <img src={avatar} alt="avatar" className="nas-sidebar__user-avatar-img" />
                  ) : (
                    user.name?.charAt(0).toUpperCase() || 'U'
                  )}
                  <div className="nas-sidebar__avatar-overlay">📷</div>
                </div>
                <input
                  ref={avatarInputRef}
                  type="file"
                  accept="image/*"
                  style={{ display: 'none' }}
                  onChange={handleAvatarChange}
                />

                {!collapsed && (
                  <div className="nas-sidebar__user-info">
                    <div className="nas-sidebar__user-name">{user.name}</div>
                    {user.tier === 'vip' ? (
                      <div className="nas-sidebar__tier-vip">
                        <span className="crown">👑</span>
                        <span className="premium-text">Premium</span>
                      </div>
                    ) : (
                      <div className="nas-sidebar__user-tier">Free User</div>
                    )}
                  </div>
                )}
              </div>

              {/* Upgrade button for free Google accounts */}
              {!collapsed && user.tier !== 'vip' && (
                <button
                  className="nas-sidebar__upgrade"
                  onClick={() => openUrl('https://synohubs.com/#premium')}
                  title="Upgrade to Premium"
                >
                  <Crown size={12} />
                  <span>Upgrade to Premium</span>
                </button>
              )}

              {!collapsed && (
                <button className="nas-sidebar__signout" onClick={handleSignOut} title="Sign out">
                  <LogOut size={13} />
                  <span>Sign out</span>
                </button>
              )}
            </div>
          )}
        </div>
      </aside>

      {/* Profile Card Modal */}
      {showProfile && user && (
        <div className="profile-modal-overlay" onClick={() => setShowProfile(false)}>
          <div className="profile-modal" onClick={e => e.stopPropagation()}>
            {/* Tier badge */}
            <div className={`profile-modal__tier-badge ${user.tier === 'vip' ? 'vip' : 'free'}`}>
              {user.tier === 'vip' ? '⭐ PREMIUM' : 'FREE'}
            </div>
            <button className="profile-modal__close" onClick={() => setShowProfile(false)}>
              <X size={16} />
            </button>

            {/* Avatar */}
            <div className="profile-modal__avatar-wrap">
              <div className="profile-modal__avatar">
                {avatar ? (
                  <img src={avatar} alt="avatar" />
                ) : (
                  <span>{user.name?.charAt(0).toUpperCase() || 'U'}</span>
                )}
              </div>
              {user.tier === 'vip' && <div className="profile-modal__avatar-ring" />}
            </div>

            {/* Name & Tier */}
            <h2 className="profile-modal__name">{user.name}</h2>
            <div className={`profile-modal__tier-label ${user.tier}`}>
              {user.tier === 'vip' ? (
                <><Crown size={12} /> Premium Member</>
              ) : (
                <><Shield size={12} /> Free Plan</>
              )}
            </div>

            {/* Info rows */}
            <div className="profile-modal__info">
              <div className="profile-modal__info-header">
                <Shield size={13} />
                <span>ACCOUNT INFO</span>
              </div>

              <div className="profile-modal__row">
                <div className="profile-modal__row-icon"><Mail size={14} /></div>
                <div className="profile-modal__row-label">Email</div>
                <div className="profile-modal__row-value">{user.email}</div>
              </div>

              <div className="profile-modal__row">
                <div className="profile-modal__row-icon"><Crown size={14} /></div>
                <div className="profile-modal__row-label">Tier</div>
                <div className="profile-modal__row-value">
                  <span className={`profile-modal__tier-pill ${user.tier}`}>
                    {user.tier === 'vip' ? 'Premium' : 'Free'}
                  </span>
                </div>
              </div>

              {user.tier === 'vip' && (
                <>
                  <div className="profile-modal__row">
                    <div className="profile-modal__row-icon"><Calendar size={14} /></div>
                    <div className="profile-modal__row-label">VIP Since</div>
                    <div className="profile-modal__row-value">
                      {user.vipSince ? user.vipSince.toLocaleDateString() : '—'}
                    </div>
                  </div>

                  <div className="profile-modal__row">
                    <div className="profile-modal__row-icon"><Calendar size={14} /></div>
                    <div className="profile-modal__row-label">VIP Expiry</div>
                    <div className="profile-modal__row-value">
                      {user.vipExpiry ? user.vipExpiry.toLocaleDateString() : 'Lifetime ♾️'}
                    </div>
                  </div>
                </>
              )}
            </div>

            <button className="profile-modal__signout" onClick={() => { setShowProfile(false); handleSignOut(); }}>
              <LogOut size={14} /> Sign Out
            </button>
          </div>
        </div>
      )}

      {/* Add NAS Form Modal */}
      {showForm && (
        <div className="nas-modal-overlay" onClick={() => setShowForm(false)}>
          <div className="nas-modal" onClick={(e) => e.stopPropagation()}>
            <div className="nas-modal__header">
              <span>Add NAS Device</span>
              <button className="btn btn-ghost btn-icon" onClick={() => setShowForm(false)}>
                <X size={16} />
              </button>
            </div>
            <form className="nas-modal__form" onSubmit={(e) => { e.preventDefault(); doLogin('connect'); }}>
              <div className="input-group">
                <label htmlFor="m-addr">Server Address</label>
                <div className="input-wrapper">
                  <Globe className="input-icon" />
                  <input id="m-addr" className="input" placeholder="IP, domain, or QuickConnect ID"
                    value={address} onChange={(e) => setAddress(e.target.value)} autoFocus />
                </div>
                <span className="input-hint">e.g. 192.168.1.100:5001 • myQCID</span>
              </div>
              <div className="input-group">
                <label htmlFor="m-user">Username</label>
                <div className="input-wrapper">
                  <User className="input-icon" />
                  <input id="m-user" className="input" placeholder="admin"
                    value={username} onChange={(e) => setUsername(e.target.value)} />
                </div>
              </div>
              <div className="input-group">
                <label htmlFor="m-pass">Password</label>
                <div className="input-wrapper">
                  <Lock className="input-icon" />
                  <input id="m-pass" className="input" type={showPassword ? 'text' : 'password'}
                    placeholder="••••••••" value={password} onChange={(e) => setPassword(e.target.value)} />
                  <button type="button" className="input-action" onClick={() => setShowPassword(!showPassword)}>
                    {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                  </button>
                </div>
              </div>
              {show2FA && (
                <div className="input-group">
                  <label htmlFor="m-otp">2FA Code</label>
                  <div className="input-wrapper">
                    <KeyRound className="input-icon" />
                    <input id="m-otp" className="input" placeholder="6-digit code"
                      value={otpCode} onChange={(e) => setOtpCode(e.target.value)} maxLength={6} autoFocus />
                  </div>
                </div>
              )}
              {status !== 'idle' && (
                <div className={`nas-login__status nas-login__status--${status}`}>
                  {(status === 'connecting' || status === 'testing') && <div className="spinner-sm" />}
                  {statusMessage}
                </div>
              )}
              <div className="nas-modal__actions">
                <button type="button" className="btn btn-outline" onClick={() => setShowForm(false)}>Cancel</button>
                <button type="button" className="btn btn-secondary" onClick={() => doLogin('test')}
                  disabled={status === 'connecting' || status === 'testing'}>
                  <FlaskConical size={14} /> {status === 'testing' ? 'Testing...' : 'Test'}
                </button>
                <button type="submit" className="btn btn-primary"
                  disabled={status === 'connecting' || status === 'testing'}>
                  <Wifi size={14} /> {status === 'connecting' ? 'Connecting...' : 'Connect'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
      {DialogComponent}
    </>
  );
};

export default NasSidebar;
