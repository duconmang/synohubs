import { create } from 'zustand';
import { invoke } from '@tauri-apps/api/core';
import {
  signInWithGoogle,
  signOutGoogle,
  getCurrentUser,
  type GoogleUser,
} from '../services/authService';
import { fetchUserTier, type UserTier } from '../services/tierService';

/* ==========================================
   Auth Store — Google OAuth + Tier
   ========================================== */

export interface AppUser {
  uid: string;
  email: string;
  name: string;
  avatar: string | null;
  tier: UserTier;
  vipExpiry?: Date;
  vipSince?: Date;
}

interface AuthState {
  user: AppUser | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;

  signIn: () => Promise<boolean>;
  checkAuth: () => Promise<boolean>;
  signOut: () => Promise<void>;
  setLoading: (loading: boolean) => void;
}

async function buildAppUser(googleUser: GoogleUser): Promise<AppUser> {
  const tierInfo = await fetchUserTier(googleUser.email);
  return {
    uid: googleUser.uid,
    email: googleUser.email,
    name: googleUser.displayName || googleUser.email.split('@')[0],
    avatar: googleUser.photoURL,
    tier: tierInfo.tier,
    vipExpiry: tierInfo.vipExpiry,
  };
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  isAuthenticated: false,
  isLoading: false,
  error: null,

  /**
   * Sign in with Google.
   * Opens system browser → OAuth → ID token → Firebase credential.
   */
  signIn: async () => {
    set({ isLoading: true, error: null });
    try {
      const googleUser = await signInWithGoogle();
      if (!googleUser) {
        set({ isLoading: false });
        return false;
      }
      const appUser = await buildAppUser(googleUser);
      set({ user: appUser, isAuthenticated: true, isLoading: false });
      return true;
    } catch (error: any) {
      set({ isLoading: false, error: error.message || String(error) });
      return false;
    }
  },

  /**
   * Check existing auth session on app mount.
   * Firebase persists sessions in IndexedDB.
   */
  checkAuth: async () => {
    set({ isLoading: true });
    try {
      const cachedUser = await getCurrentUser();
      if (cachedUser) {
        const appUser = await buildAppUser(cachedUser);
        set({ user: appUser, isAuthenticated: true, isLoading: false });
        return true;
      }
      set({ isLoading: false });
      return false;
    } catch {
      set({ isLoading: false });
      return false;
    }
  },

  signOut: async () => {
    await signOutGoogle();
    set({ user: null, isAuthenticated: false, error: null });
  },

  setLoading: (isLoading) => set({ isLoading }),
}));

/* ==========================================
   NAS Store — Synology NAS Connections
   ========================================== */

export interface NasConnection {
  id: string;
  name: string;
  host: string;
  port: number;
  protocol: 'http' | 'https';
  username: string;
  password?: string;       // stored encrypted locally, NEVER synced to cloud
  device_id?: string;      // 2FA trusted device — skip OTP on re-login
  model?: string;
  dsm_version?: string;
  serial?: string;
  status: 'online' | 'offline' | 'connecting';
  sid?: string;
  quickconnect_id?: string;
  uptime?: string;
  is_admin?: boolean;
}

export interface SystemInfo {
  cpu_usage: number;
  ram_total: number;
  ram_used: number;
  network_up: number;
  network_down: number;
  temperature: number;
  hostname: string;
  volumes: Volume[];
  disks: DiskInfo[];
  packages: PackageInfo[];
}

export interface Volume {
  id: string;
  name: string;
  total_size: number;
  used_size: number;
  status: string;
  raid_type: string;
}

export interface DiskInfo {
  id: string;
  name: string;
  model: string;
  status: string;
  temperature: number;
  size_gb: number;
}

export interface PackageInfo {
  id: string;
  name: string;
  version: string;
  is_running: boolean;
}

interface NasState {
  connections: NasConnection[];
  activeNas: NasConnection | null;
  systemInfo: SystemInfo | null;
  isConnecting: boolean;
  connectionError: string | null;
  isSyncing: boolean;

  loadConnections: (uid: string) => Promise<void>;
  checkAllConnections: () => Promise<void>;
  connectToNas: (nasId: string) => Promise<boolean>;
  addConnection: (nas: NasConnection) => void;
  removeConnection: (id: string) => void;
  setActiveNas: (nas: NasConnection | null) => void;
  updateNasStatus: (id: string, status: NasConnection['status']) => void;
  updateConnection: (nas: NasConnection) => void;
  setSystemInfo: (info: SystemInfo) => void;
  setConnecting: (connecting: boolean) => void;
  setConnectionError: (error: string | null) => void;
}

const NAS_STORE_KEY = 'nas_connections';

/** Persist connections via encrypted Rust backend (password IS saved encrypted) */
async function persistEncrypted(connections: NasConnection[]) {
  const uid = useAuthStore.getState().user?.uid;
  if (!uid) return;
  try {
    // Strip SID (session) only — password is kept encrypted on disk
    const safe = connections.map(({ sid, ...rest }) => ({ ...rest, sid: undefined }));
    await invoke('secure_save', {
      userUid: uid,
      key: NAS_STORE_KEY,
      data: JSON.stringify(safe),
    });
  } catch (e) {
    console.warn('Failed to save encrypted:', e);
  }
}

/** Cloud sync for VIP users — NEVER sync passwords */
async function cloudSync(connections: NasConnection[]) {
  const user = useAuthStore.getState().user;
  if (!user || user.tier !== 'vip') return;
  try {
    const { pushDevices } = await import('../services/syncService');
    // Strip password + sid + device tokens before cloud sync
    const safe = connections.map(({ password, sid, device_id, ...rest }) => ({ ...rest })) as NasConnection[];
    await pushDevices(user.uid, safe);
  } catch (e) {
    console.warn('Cloud sync failed:', e);
  }
}

export const useNasStore = create<NasState>((set) => ({
  connections: [],
  activeNas: null,
  systemInfo: null,
  isConnecting: false,
  connectionError: null,
  isSyncing: false,

  loadConnections: async (uid: string) => {
    try {
      // 1. Load from encrypted local store
      const raw: string | null = await invoke('secure_load', {
        userUid: uid,
        key: NAS_STORE_KEY,
      });

      let localDevices: NasConnection[] = [];
      if (raw) {
        const parsed = JSON.parse(raw) as NasConnection[];
        localDevices = parsed.map(c => ({ ...c, status: 'offline' as const, sid: undefined }));
      } else {
        // Migration: check old localStorage
        const legacyKey = `synohubs_nas_${uid}`;
        const legacy = localStorage.getItem(legacyKey);
        if (legacy) {
          const parsed = JSON.parse(legacy) as NasConnection[];
          localDevices = parsed.map(c => ({ ...c, status: 'offline' as const, sid: undefined }));
          await persistEncrypted(localDevices);
          localStorage.removeItem(legacyKey);
        }
      }

      set({ connections: localDevices });

      // 2. Cloud sync for VIP users
      const user = useAuthStore.getState().user;
      if (user?.tier === 'vip') {
        set({ isSyncing: true });
        try {
          const { syncDevices } = await import('../services/syncService');
          const merged = await syncDevices(uid, localDevices);
          const safe = merged.map(c => ({ ...c, status: 'offline' as const, sid: undefined }));
          set({ connections: safe, isSyncing: false });
          await persistEncrypted(safe);
        } catch {
          set({ isSyncing: false });
        }
      }

      // 3. Auto-check all connections in background
      setTimeout(() => {
        useNasStore.getState().checkAllConnections();
      }, 500);
    } catch (e) {
      console.warn('Failed to load connections:', e);
    }
  },

  /** Ping all NAS connections to check online status */
  checkAllConnections: async () => {
    const { connections } = useNasStore.getState();
    console.log(`[SynoHubs] Auto-checking ${connections.length} NAS connection(s)...`);

    for (const nas of connections) {
      if (!nas.host || !nas.password) {
        console.log(`[SynoHubs] Skipping ${nas.name}: no host or password stored`);
        continue;
      }

      // Set connecting
      set((s) => ({
        connections: s.connections.map(c =>
          c.id === nas.id ? { ...c, status: 'connecting' as const } : c
        ),
      }));

      try {
        const addr = `${nas.protocol}://${nas.host}:${nas.port}`;
        console.log(`[SynoHubs] Checking ${nas.name} (${addr})...`, nas.device_id ? 'with device token' : 'no device token');

        const result: any = await invoke('nas_login', {
          request: {
            address: addr,
            username: nas.username,
            password: nas.password,
            otp_code: null,
            device_id: nas.device_id || null,
          },
        });

        if (result.success) {
          console.log(`[SynoHubs] ✅ ${nas.name} is ONLINE (admin: ${result.is_admin})`);

          // Save device token if returned (for 2FA trust)
          const updatedNas = {
            ...nas,
            status: 'online' as const,
            is_admin: result.is_admin,
            model: result.model || nas.model,
            dsm_version: result.dsm_version || nas.dsm_version,
            device_id: result.did || nas.device_id,
          };
          set((s) => ({
            connections: s.connections.map(c =>
              c.id === nas.id ? updatedNas : c
            ),
          }));
          // Persist updated device tokens
          persistEncrypted(useNasStore.getState().connections);
          // Logout — AWAIT to prevent race with next NAS login
          try { await invoke('nas_logout'); } catch {}
        } else {
          console.warn(`[SynoHubs] ❌ ${nas.name} login failed:`, result.error, `(code: ${result.error_code})`);
          set((s) => ({
            connections: s.connections.map(c =>
              c.id === nas.id ? { ...c, status: 'offline' as const } : c
            ),
          }));
        }
      } catch (err) {
        console.warn(`[SynoHubs] ❌ ${nas.name} connection error:`, err);
        set((s) => ({
          connections: s.connections.map(c =>
            c.id === nas.id ? { ...c, status: 'offline' as const } : c
          ),
        }));
      }
    }
    console.log('[SynoHubs] Auto-check complete.');
  },

  /** Auto-login to a NAS and set it as active */
  connectToNas: async (nasId: string): Promise<boolean> => {
    const { connections } = useNasStore.getState();
    const nas = connections.find(c => c.id === nasId);
    if (!nas) return false;

    if (!nas.password) {
      console.warn(`[SynoHubs] Cannot connect to ${nas.name}: no password stored. Delete and re-add.`);
      return false;
    }

    console.log(`[SynoHubs] Connecting to ${nas.name}...`, nas.device_id ? 'with device token' : 'no device token');

    set({ isConnecting: true, connectionError: null });
    set((s) => ({
      connections: s.connections.map(c =>
        c.id === nasId ? { ...c, status: 'connecting' as const } : c
      ),
    }));

    try {
      const addr = `${nas.protocol}://${nas.host}:${nas.port}`;
      const result: any = await invoke('nas_login', {
        request: {
          address: addr,
          username: nas.username,
          password: nas.password,
          otp_code: null,
          device_id: nas.device_id || null,
        },
      });

      if (result.success) {
        console.log(`[SynoHubs] ✅ Connected to ${nas.name} (admin: ${result.is_admin})`, result.did ? `did: ${result.did}` : '');
        const updated: NasConnection = {
          ...nas,
          status: 'online',
          is_admin: result.is_admin,
          model: result.model || nas.model,
          dsm_version: result.dsm_version || nas.dsm_version,
          device_id: result.did || nas.device_id,
        };
        set((s) => ({
          connections: s.connections.map(c => c.id === nasId ? updated : c),
          activeNas: updated,
          isConnecting: false,
        }));
        persistEncrypted(useNasStore.getState().connections);
        return true;
      } else {
        console.warn(`[SynoHubs] ❌ Connect to ${nas.name} failed:`, result.error, `(code: ${result.error_code})`);
        set((s) => ({
          connections: s.connections.map(c =>
            c.id === nasId ? { ...c, status: 'offline' as const } : c
          ),
          isConnecting: false,
          connectionError: result.error || 'Login failed',
        }));
        return false;
      }
    } catch (err: any) {
      set((s) => ({
        connections: s.connections.map(c =>
          c.id === nasId ? { ...c, status: 'offline' as const } : c
        ),
        isConnecting: false,
        connectionError: err?.toString() || 'Connection failed',
      }));
      return false;
    }
  },

  addConnection: (nas) => {
    set((state) => {
      const connections = [...state.connections.filter((c) => c.id !== nas.id), nas];
      persistEncrypted(connections);
      cloudSync(connections);
      return { connections };
    });
  },

  removeConnection: (id) => {
    set((state) => {
      const connections = state.connections.filter((c) => c.id !== id);
      persistEncrypted(connections);
      cloudSync(connections);
      return {
        connections,
        activeNas: state.activeNas?.id === id ? null : state.activeNas,
      };
    });
  },

  setActiveNas: (nas) => set({ activeNas: nas }),

  updateNasStatus: (id, status) => {
    set((state) => {
      const connections = state.connections.map((c) =>
        c.id === id ? { ...c, status } : c
      );
      persistEncrypted(connections);
      return { connections };
    });
  },

  updateConnection: (nas) => {
    set((state) => {
      const connections = state.connections.map((c) =>
        c.id === nas.id ? { ...c, ...nas } : c
      );
      persistEncrypted(connections);
      cloudSync(connections);
      return { connections };
    });
  },

  setSystemInfo: (info) => set({ systemInfo: info }),
  setConnecting: (isConnecting) => set({ isConnecting }),
  setConnectionError: (connectionError) => set({ connectionError }),
}));

/* ==========================================
   User Preferences Store (avatar, etc.)
   ========================================== */

interface UserPrefsState {
  avatar: string | null;  // base64 data URL
  loadPrefs: (uid: string) => Promise<void>;
  setAvatar: (dataUrl: string | null) => void;
}

const PREFS_STORE_KEY = 'user_prefs';

export const useUserPrefsStore = create<UserPrefsState>((set) => ({
  avatar: null,

  loadPrefs: async (uid: string) => {
    try {
      const raw: string | null = await invoke('secure_load', {
        userUid: uid,
        key: PREFS_STORE_KEY,
      });
      if (raw) {
        const prefs = JSON.parse(raw);
        set({ avatar: prefs.avatar || null });
      } else {
        // Migration from old localStorage
        const legacyKey = `synohubs_prefs_${uid}`;
        const legacy = localStorage.getItem(legacyKey);
        if (legacy) {
          const prefs = JSON.parse(legacy);
          set({ avatar: prefs.avatar || null });
          // Save to encrypted store
          await invoke('secure_save', {
            userUid: uid,
            key: PREFS_STORE_KEY,
            data: legacy,
          });
          localStorage.removeItem(legacyKey);
        }
      }
    } catch (e) {
      console.warn('Failed to load prefs:', e);
    }
  },

  setAvatar: async (dataUrl) => {
    const uid = useAuthStore.getState().user?.uid;
    if (!uid) return;
    set({ avatar: dataUrl });
    try {
      const prefs = JSON.stringify({ avatar: dataUrl });
      await invoke('secure_save', {
        userUid: uid,
        key: PREFS_STORE_KEY,
        data: prefs,
      });
    } catch (e) {
      console.warn('Failed to save prefs:', e);
    }
  },
}));
