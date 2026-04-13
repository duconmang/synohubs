/**
 * Google Auth Service — Tauri Desktop OAuth
 * 
 * Flow:
 * 1. Call Rust `google_auth_start` via Tauri IPC
 * 2. Rust starts local HTTP server + opens Google OAuth in system browser
 * 3. User signs in on Google → redirect to local server → token captured
 * 4. Frontend receives Google ID token from Rust
 * 5. Use `signInWithCredential` to authenticate with Firebase
 * 6. Firebase session persists in WebView storage
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

function userToGoogleUser(user: User): GoogleUser {
  return {
    uid: user.uid,
    email: user.email || '',
    displayName: user.displayName || '',
    photoURL: user.photoURL,
  };
}

/**
 * Sign in with Google via system browser (Tauri desktop flow).
 * 
 * 1. Calls Rust backend which opens browser + captures ID token
 * 2. Uses the ID token to sign in with Firebase Auth
 */
export async function signInWithGoogle(): Promise<GoogleUser | null> {
  // Call Rust backend to handle OAuth flow
  const idToken: string = await invoke('google_auth_start');
  
  // Use the Google ID token to sign in with Firebase
  const credential = GoogleAuthProvider.credential(idToken);
  const result = await signInWithCredential(auth, credential);
  
  return userToGoogleUser(result.user);
}

/**
 * Sign out from Firebase.
 */
export async function signOutGoogle(): Promise<void> {
  await firebaseSignOut(auth);
}

/**
 * Check if user is already signed in (persistent session).
 * Firebase Auth persists sessions in IndexedDB.
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
