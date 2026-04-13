/**
 * Firebase Configuration for SynoHubs Desktop App
 * Project: synohubs (Firebase Console)
 *
 * NOTE: You need to add a Web App in Firebase Console to get these values.
 *       Go to: Firebase Console → Project Settings → Add App → Web (</> icon)
 *       Then replace the values below.
 *
 * The apiKey and projectId below are from the existing Android config.
 * authDomain is derived from projectId.
 */

import { initializeApp } from 'firebase/app';
import { getAuth, GoogleAuthProvider } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

const firebaseConfig = {
  apiKey: 'AIzaSyBWj1ImLYVuKqWkwlksJqz61zZ_ZedphL4',
  authDomain: 'synohubs.firebaseapp.com',
  projectId: 'synohubs',
  storageBucket: 'synohubs.firebasestorage.app',
  messagingSenderId: '650864805831',
  appId: '1:650864805831:web:f4117fb91629414f3f3be2',
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Auth
export const auth = getAuth(app);
export const googleProvider = new GoogleAuthProvider();
googleProvider.addScope('email');

// Firestore
export const db = getFirestore(app);

export default app;
