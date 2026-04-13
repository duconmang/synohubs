import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper around Google Sign-In.
/// Manages sign-in state and provides user info (name, email, avatar).
/// No backend server — Google identity is used only as an app lock +
/// user profile display + Google Drive scope for backup.
class GoogleAuthService {
  GoogleAuthService._();
  static final GoogleAuthService instance = GoogleAuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      // Google Drive appdata scope — can only access files created by this app
      'https://www.googleapis.com/auth/drive.appdata',
    ],
  );

  GoogleSignInAccount? _currentUser;

  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  String get displayName => _currentUser?.displayName ?? '';
  String get email => _currentUser?.email ?? '';
  String? get photoUrl => _currentUser?.photoUrl;

  /// Try to silently sign in (returning user).
  /// Returns true if successful, false if interactive sign-in is needed.
  Future<bool> trySilentSignIn() async {
    _currentUser = await _googleSignIn.signInSilently();
    return _currentUser != null;
  }

  /// Interactive Google sign-in (shows account picker).
  /// Returns true if successful.
  Future<bool> signIn() async {
    _currentUser = await _googleSignIn.signIn();
    return _currentUser != null;
  }

  /// Sign out.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  /// Get the underlying GoogleSignIn instance (needed for googleapis_auth).
  GoogleSignIn get googleSignIn => _googleSignIn;
}
