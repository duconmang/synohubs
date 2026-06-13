/**
 * Google Drive Backup/Sync Service
 *
 * Reads/writes encrypted NAS profiles to Google Drive appDataFolder.
 * Uses AES-256-CBC encryption compatible with the mobile Flutter app.
 * All data stays on the user's own Google Drive — zero server involvement.
 *
 * Drive files (appDataFolder — hidden, app-only):
 *   synohub_nas_profiles.enc  — encrypted NAS profiles JSON
 *   synohub_backup_key.dat    — AES key for cross-device recovery
 */

import { getAccessToken } from './authService';
import { invoke } from '@tauri-apps/api/core';

const BACKUP_FILE = 'synohub_nas_profiles.enc';
const KEY_FILE = 'synohub_backup_key.dat';
const ENC_KEY_STORE = 'drive_backup_key';

const DRIVE_API = 'https://www.googleapis.com/drive/v3';
const DRIVE_UPLOAD = 'https://www.googleapis.com/upload/drive/v3';

// ── Drive API helpers ───────────────────────────────────────

function authHeaders(): HeadersInit {
  const token = getAccessToken();
  if (!token) throw new Error('No Google access token — sign in first');
  return { Authorization: `Bearer ${token}` };
}

async function findFile(name: string): Promise<string | null> {
  const q = encodeURIComponent(`name = '${name}'`);
  const resp = await fetch(
    `${DRIVE_API}/files?spaces=appDataFolder&q=${q}&fields=files(id)`,
    { headers: authHeaders() },
  );
  if (!resp.ok) return null;
  const data = await resp.json();
  return data.files?.[0]?.id ?? null;
}

async function readFile(fileId: string): Promise<string> {
  const resp = await fetch(`${DRIVE_API}/files/${fileId}?alt=media`, {
    headers: authHeaders(),
  });
  if (!resp.ok) throw new Error(`Drive read failed: ${resp.status}`);
  return resp.text();
}

async function writeFile(name: string, content: string): Promise<void> {
  const existingId = await findFile(name);
  const body = new TextEncoder().encode(content);

  if (existingId) {
    const resp = await fetch(
      `${DRIVE_UPLOAD}/files/${existingId}?uploadType=media`,
      { method: 'PATCH', headers: { ...authHeaders(), 'Content-Type': 'application/octet-stream' }, body },
    );
    if (!resp.ok) throw new Error(`Drive update failed: ${resp.status}`);
  } else {
    const metadata = JSON.stringify({ name, parents: ['appDataFolder'] });
    const boundary = '-----synohubs' + Date.now();
    const multipart =
      `--${boundary}\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n${metadata}\r\n` +
      `--${boundary}\r\nContent-Type: application/octet-stream\r\n\r\n${content}\r\n` +
      `--${boundary}--`;
    const resp = await fetch(`${DRIVE_UPLOAD}/files?uploadType=multipart`, {
      method: 'POST',
      headers: { ...authHeaders(), 'Content-Type': `multipart/related; boundary=${boundary}` },
      body: multipart,
    });
    if (!resp.ok) throw new Error(`Drive create failed: ${resp.status}`);
  }
}

// ── AES-256-CBC (compatible with mobile Flutter encrypt package) ──

function base64ToBytes(b64: string): Uint8Array {
  const bin = atob(b64.trim());
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes;
}

function bytesToBase64(bytes: Uint8Array): string {
  let bin = '';
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin);
}

async function importAesKey(keyBytes: Uint8Array): Promise<CryptoKey> {
  return crypto.subtle.importKey('raw', keyBytes, { name: 'AES-CBC' }, false, [
    'encrypt',
    'decrypt',
  ]);
}

async function encryptAesCbc(plaintext: string, keyBytes: Uint8Array): Promise<string> {
  const iv = crypto.getRandomValues(new Uint8Array(16));
  const key = await importAesKey(keyBytes);
  const encoded = new TextEncoder().encode(plaintext);
  const cipherBuf = await crypto.subtle.encrypt({ name: 'AES-CBC', iv }, key, encoded);
  const combined = new Uint8Array(iv.length + cipherBuf.byteLength);
  combined.set(iv, 0);
  combined.set(new Uint8Array(cipherBuf), iv.length);
  return bytesToBase64(combined);
}

async function decryptAesCbc(cipherBase64: string, keyBytes: Uint8Array): Promise<string> {
  const combined = base64ToBytes(cipherBase64);
  const iv = combined.slice(0, 16);
  const ciphertext = combined.slice(16);
  const key = await importAesKey(keyBytes);
  const plainBuf = await crypto.subtle.decrypt({ name: 'AES-CBC', iv }, key, ciphertext);
  return new TextDecoder().decode(plainBuf);
}

// ── Encryption key management ───────────────────────────────

async function getOrCreateKey(userUid: string): Promise<Uint8Array> {
  // 1. Try local encrypted store
  try {
    const stored: string | null = await invoke('secure_load', { userUid, key: ENC_KEY_STORE });
    if (stored) return base64ToBytes(stored);
  } catch { /* not found */ }

  // 2. Try Drive recovery
  try {
    const fileId = await findFile(KEY_FILE);
    if (fileId) {
      const keyB64 = (await readFile(fileId)).trim();
      if (keyB64) {
        const keyBytes = base64ToBytes(keyB64);
        await invoke('secure_save', { userUid, key: ENC_KEY_STORE, data: keyB64 });
        return keyBytes;
      }
    }
  } catch { /* Drive not available */ }

  // 3. Generate new key
  const keyBytes = crypto.getRandomValues(new Uint8Array(32));
  const keyB64 = bytesToBase64(keyBytes);
  await invoke('secure_save', { userUid, key: ENC_KEY_STORE, data: keyB64 });
  return keyBytes;
}

// ── Drive profile format (compatible with mobile NasProfile) ──

interface DriveProfile {
  id: string;
  nickname: string;
  host: string;
  port: number;
  protocol: string;
  username: string;
  password: string;
  model?: string;
  dsmVersion?: string;
  lastConnected?: string;
  updatedAt: string;
  serial?: string;
  quickconnectId?: string;
}

import type { NasConnection } from '../stores';

function connectionToDriveProfile(c: NasConnection): DriveProfile {
  return {
    id: c.id,
    nickname: c.name,
    host: c.host,
    port: c.port,
    protocol: c.protocol,
    username: c.username,
    password: c.password || '',
    model: c.model,
    dsmVersion: c.dsm_version,
    updatedAt: (c as any).updatedAt || new Date().toISOString(),
    serial: c.serial,
    quickconnectId: c.quickconnect_id,
  };
}

function driveProfileToConnection(p: DriveProfile): NasConnection {
  return {
    id: p.id,
    name: p.nickname,
    host: p.host,
    port: p.port,
    protocol: p.protocol as 'http' | 'https',
    username: p.username,
    password: p.password,
    model: p.model,
    dsm_version: p.dsmVersion,
    serial: p.serial,
    quickconnect_id: p.quickconnectId,
    status: 'offline',
    updatedAt: p.updatedAt,
  } as NasConnection & { updatedAt: string };
}

// ── Public API ──────────────────────────────────────────────

export async function backupToDrive(
  userUid: string,
  connections: NasConnection[],
): Promise<void> {
  const keyBytes = await getOrCreateKey(userUid);
  const profiles = connections.map(connectionToDriveProfile);
  const json = JSON.stringify(profiles);
  const encrypted = await encryptAesCbc(json, keyBytes);
  await writeFile(BACKUP_FILE, encrypted);
  // Persist key to Drive for recovery on other devices
  await writeFile(KEY_FILE, bytesToBase64(keyBytes));
}

export async function restoreFromDrive(
  userUid: string,
): Promise<NasConnection[] | null> {
  const fileId = await findFile(BACKUP_FILE);
  if (!fileId) return null;

  const raw = await readFile(fileId);
  const keyBytes = await getOrCreateKey(userUid);

  let json: string;
  try {
    json = await decryptAesCbc(raw, keyBytes);
  } catch {
    // Key mismatch — try recovering from Drive
    const keyFileId = await findFile(KEY_FILE);
    if (!keyFileId) throw new Error('Cannot decrypt backup — key not found');
    const recoveredB64 = (await readFile(keyFileId)).trim();
    const recoveredKey = base64ToBytes(recoveredB64);
    json = await decryptAesCbc(raw, recoveredKey);
    // Save recovered key locally
    await invoke('secure_save', { userUid, key: ENC_KEY_STORE, data: recoveredB64 });
  }

  const profiles: DriveProfile[] = JSON.parse(json);
  return profiles.map(driveProfileToConnection);
}

/**
 * Auto-sync: pull from Drive → merge with local → push back.
 * Called once after Google sign-in. Silent on failure.
 */
export async function syncOnSignIn(
  userUid: string,
  localConnections: NasConnection[],
): Promise<NasConnection[]> {
  try {
    if (!getAccessToken()) return localConnections;

    // Pull from Drive
    const remote = await restoreFromDrive(userUid);

    // Merge
    const localMap = new Map(localConnections.map((c) => [c.id, c]));
    const merged = [...localConnections];
    let changed = false;

    if (remote) {
      for (const r of remote) {
        const rUpdated = (r as any).updatedAt || '';
        const local = localMap.get(r.id);
        if (!local) {
          merged.push(r);
          changed = true;
        } else {
          const lUpdated = (local as any).updatedAt || '';
          if (rUpdated > lUpdated) {
            // Remote is newer — update, but keep local password if remote is empty
            const idx = merged.findIndex((c) => c.id === r.id);
            if (idx >= 0) {
              if (!r.password && local.password) r.password = local.password;
              merged[idx] = r;
              changed = true;
            }
          }
        }
      }
    }

    // Push merged state back
    if (changed || !remote) {
      await backupToDrive(userUid, merged);
    }

    console.log('[DriveSync] Auto-sync completed');
    return merged;
  } catch (e) {
    console.warn('[DriveSync] Auto-sync failed (non-fatal):', e);
    return localConnections;
  }
}
