/**
 * User Tier Provider — Firestore-based tier management
 * 
 * Mirrors the Flutter UserTierProvider exactly:
 * - Fetches tier from Firestore `users` collection by email
 * - Checks VIP expiry date
 * - Defaults to 'free' on any error (safe fallback)
 * 
 * Firestore document structure:
 *   Collection: users
 *   Document fields:
 *     - email: string
 *     - tier: 'free' | 'vip'  
 *     - vipExpiry: Timestamp (optional)
 */

import {
  collection,
  query,
  where,
  limit,
  getDocs,
  type Timestamp,
} from 'firebase/firestore';
import { db } from './firebase';

export type UserTier = 'free' | 'vip';

export interface TierInfo {
  tier: UserTier;
  email: string;
  loaded: boolean;
  vipExpiry?: Date;
}

/**
 * Fetch the user tier from Firestore for the given email.
 * Exactly mirrors the Flutter logic:
 *   1. Query `users` collection where email == email
 *   2. If found and tier == 'vip', check vipExpiry
 *   3. Default to 'free' on any error
 */
export async function fetchUserTier(email: string): Promise<TierInfo> {
  const normalizedEmail = email.toLowerCase().trim();

  if (!normalizedEmail) {
    return { tier: 'free', email: normalizedEmail, loaded: true };
  }

  try {
    const usersRef = collection(db, 'users');
    const q = query(usersRef, where('email', '==', normalizedEmail), limit(1));
    const snapshot = await getDocs(q);

    if (!snapshot.empty) {
      const data = snapshot.docs[0].data();
      const tierStr = (data.tier as string) || 'free';

      if (tierStr === 'vip') {
        // Check expiry if set
        const expiry = data.vipExpiry as Timestamp | null;
        if (!expiry || expiry.toDate() > new Date()) {
          return {
            tier: 'vip',
            email: normalizedEmail,
            loaded: true,
            vipExpiry: expiry?.toDate(),
          };
        }
        // VIP expired → fall through to free
      }
    }
  } catch (e) {
    console.error('UserTierProvider: Failed to fetch tier:', e);
    // On error, default to free — safe fallback
  }

  return { tier: 'free', email: normalizedEmail, loaded: true };
}
