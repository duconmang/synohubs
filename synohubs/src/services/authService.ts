/**
 * Google Auth Service — Tauri Desktop OAuth
 *
 * Flow:
 * 1. Call Rust `google_auth_start` via Tauri IPC
 * 2. Rust opens Tauri webview window with Google OAuth
 * 3. User signs in → redirect intercepted → tokens captured
 * 4. Frontend receives id_token + access_token from Rust
 * 5. Use `signInWithCredential` to authenticate with Firebase
 * 6. access_token stored in memory for Google Drive API calls
 */

import {
  signInWithCredential,
  GoogleAuthProvider,
  signOut as firebaseSignOut,
  onAuthStateChanged,
  type User,
} from 'firebase/auth';
import { auth } from './firebase';
import { invoke } from '@tauri-apps/api/core';

export interface GoogleUser {
  uid: string;
  email: string;
  displayName: string;
  photoURL: string | null;
}

// Google access_token for Drive API — in-memory only, never persisted
let _accessToken: string | null = null;

export function getAccessToken(): string | null {
  return _accessToken;
}

function userToGoogleUser(user: User): GoogleUser {
  return {
    uid: user.uid,
    email: user.email || '',
    displayName: user.displayName || '',
    photoURL: user.photoURL,
  };
}

/**
 * Sign in with Google via Tauri webview window.
 * Returns both Firebase user and stores access_token for Drive API.
 */
export async function signInWithGoogle(): Promise<GoogleUser | null> {
  const raw: string = await invoke('google_auth_start');

  let idToken: string;
  try {
    const parsed = JSON.parse(raw);
    idToken = parsed.id_token;
    _accessToken = parsed.access_token || null;
  } catch {
    // Backward compat: raw string is just the id_token
    idToken = raw;
    _accessToken = null;
  }

  const credential = GoogleAuthProvider.credential(idToken);
  const result = await signInWithCredential(auth, credential);

  return userToGoogleUser(result.user);
}

/**
 * Sign out from Firebase + clear access token.
 */
export async function signOutGoogle(): Promise<void> {
  _accessToken = null;
  await firebaseSignOut(auth);
}

/**
 * Check if user is already signed in (persistent session).
 * Note: access_token is NOT available after silent re-auth — only after interactive sign-in.
 */
export function getCurrentUser(): Promise<GoogleUser | null> {
  return new Promise((resolve) => {
    const unsubscribe = onAuthStateChanged(auth, (user: User | null) => {
      unsubscribe();
      resolve(user ? userToGoogleUser(user) : null);
    });
  });
}

/**
 * Subscribe to auth state changes.
 */
export function onAuthChange(callback: (user: GoogleUser | null) => void): () => void {
  return onAuthStateChanged(auth, (user: User | null) => {
    callback(user ? userToGoogleUser(user) : null);
  });
}
