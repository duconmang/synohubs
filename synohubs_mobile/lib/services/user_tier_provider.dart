import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// User tier: free (default) or vip (premium features).
enum UserTier { free, vip }

/// Singleton that manages the current user's tier (Free / VIP).
/// Fetches tier from Firestore `users` collection by email.
/// Caches locally and notifies listeners on change.
class UserTierProvider extends ChangeNotifier {
  UserTierProvider._();
  static final UserTierProvider instance = UserTierProvider._();

  UserTier _tier = UserTier.free;
  String _email = '';
  bool _loaded = false;

  UserTier get tier => _tier;
  bool get isVip => _tier == UserTier.vip;
  bool get isFree => _tier == UserTier.free;
  String get email => _email;
  bool get loaded => _loaded;

  /// Fetch the user tier from Firestore for the given email.
  /// Call this after Google Sign-In succeeds.
  Future<void> fetchTier(String email) async {
    _email = email.toLowerCase().trim();
    _tier = UserTier.free; // default
    _loaded = false;

    if (_email.isEmpty) {
      _loaded = true;
      notifyListeners();
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final tierStr = data['tier'] as String? ?? 'free';

        if (tierStr == 'vip') {
          // Check expiry if set
          final expiry = data['vipExpiry'] as Timestamp?;
          if (expiry == null || expiry.toDate().isAfter(DateTime.now())) {
            _tier = UserTier.vip;
          }
        }
      }
    } catch (e) {
      debugPrint('UserTierProvider: Failed to fetch tier: $e');
      // On error, default to free — safe fallback
    }

    _loaded = true;
    notifyListeners();
  }

  /// Reset when user signs out.
  void reset() {
    _tier = UserTier.free;
    _email = '';
    _loaded = false;
    notifyListeners();
  }
}
