/**
 * Sync Service — Firestore cloud sync for NAS devices
 * 
 * Syncs NAS connection metadata (NOT passwords) to Firestore,
 * enabling multi-device access for VIP users.
 * 
 * Firestore structure:
 *   users/{uid}/devices/{deviceId} → NasDeviceSync
 * 
 * Security:
 *   - Host/port are stored in Firestore (not sensitive — just IPs)
 *   - Passwords are NEVER synced
 *   - SIDs are NEVER synced
 *   - Only VIP users can sync
 */

import {
  collection,
  doc,
  getDocs,
  setDoc,
  deleteDoc,
  serverTimestamp,
  type Timestamp,
} from 'firebase/firestore';
import { db } from './firebase';
import type { NasConnection } from '../stores';

/** What we store in Firestore (no secrets) */
interface NasDeviceSync {
  name: string;
  host: string;
  port: number;
  protocol: 'http' | 'https';
  username: string;
  model?: string;
  dsm_version?: string;
  serial?: string;
  quickconnect_id?: string;
  updated_at: Timestamp | ReturnType<typeof serverTimestamp>;
}

/** Convert NasConnection to sync-safe format */
function toSyncDevice(nas: NasConnection): Omit<NasDeviceSync, 'updated_at'> {
  return {
    name: nas.name,
    host: nas.host,
    port: nas.port,
    protocol: nas.protocol,
    username: nas.username,
    model: nas.model,
    dsm_version: nas.dsm_version,
    serial: nas.serial,
    quickconnect_id: nas.quickconnect_id,
  };
}

/** Convert Firestore doc back to NasConnection */
function fromSyncDevice(id: string, data: NasDeviceSync): NasConnection {
  return {
    id,
    name: data.name,
    host: data.host,
    port: data.port,
    protocol: data.protocol,
    username: data.username,
    model: data.model,
    dsm_version: data.dsm_version,
    serial: data.serial,
    quickconnect_id: data.quickconnect_id,
    status: 'offline', // Always offline on load — need to re-authenticate
  };
}

/**
 * Push all NAS devices to Firestore.
 * Overwrites cloud with local data.
 */
export async function pushDevices(uid: string, devices: NasConnection[]): Promise<void> {
  const devicesRef = collection(db, 'users', uid, 'devices');

  // Delete existing cloud devices first
  const existing = await getDocs(devicesRef);
  const deletePromises = existing.docs.map((d) => deleteDoc(d.ref));
  await Promise.all(deletePromises);

  // Push current devices
  const pushPromises = devices.map((nas) =>
    setDoc(doc(devicesRef, nas.id), {
      ...toSyncDevice(nas),
      updated_at: serverTimestamp(),
    })
  );
  await Promise.all(pushPromises);
}

/**
 * Pull NAS devices from Firestore.
 * Returns cloud devices.
 */
export async function pullDevices(uid: string): Promise<NasConnection[]> {
  const devicesRef = collection(db, 'users', uid, 'devices');
  const snapshot = await getDocs(devicesRef);

  return snapshot.docs.map((d) =>
    fromSyncDevice(d.id, d.data() as NasDeviceSync)
  );
}

/**
 * Push a single device to Firestore.
 */
export async function pushDevice(uid: string, nas: NasConnection): Promise<void> {
  const devRef = doc(db, 'users', uid, 'devices', nas.id);
  await setDoc(devRef, {
    ...toSyncDevice(nas),
    updated_at: serverTimestamp(),
  });
}

/**
 * Delete a single device from Firestore.
 */
export async function removeDevice(uid: string, nasId: string): Promise<void> {
  const devRef = doc(db, 'users', uid, 'devices', nasId);
  await deleteDoc(devRef);
}

/**
 * Merge local and cloud devices.
 * Cloud devices NOT in local are added.
 * Local devices NOT in cloud are pushed.
 * Conflicts: local wins (user's current machine is authority).
 */
export async function syncDevices(
  uid: string,
  localDevices: NasConnection[]
): Promise<NasConnection[]> {
  try {
    const cloudDevices = await pullDevices(uid);

    // Build maps
    const localMap = new Map(localDevices.map((d) => [d.id, d]));
    const cloudMap = new Map(cloudDevices.map((d) => [d.id, d]));

    // Merged = all local + cloud-only devices
    const merged = [...localDevices];
    for (const [id, cloudDev] of cloudMap) {
      if (!localMap.has(id)) {
        merged.push(cloudDev);
      }
    }

    // Push merged state to cloud
    await pushDevices(uid, merged);

    return merged;
  } catch (e) {
    console.warn('Sync failed (offline?):', e);
    // Return local data as-is if sync fails
    return localDevices;
  }
}
