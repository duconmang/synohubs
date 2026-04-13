import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'package:media_kit/media_kit.dart';

import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'services/locale_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/google_sign_in_screen.dart';
import 'screens/nas_manager_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/file_manager_screen.dart';
import 'screens/media_hub_screen.dart';
import 'screens/photos_screen.dart';
import 'services/session_manager.dart';
import 'services/google_auth_service.dart';
import 'services/nas_profile_store.dart';
import 'services/user_tier_provider.dart';
import 'widgets/synohub_app_bar.dart';
import 'widgets/bottom_nav_bar.dart';

/// Accept self-signed certificates ONLY for known NAS hosts.
/// Google, TMDB, and all other HTTPS connections keep full cert validation.
class NasCertOverrides extends HttpOverrides {
  static final Set<String> _trustedNasHosts = {};

  /// Register a NAS host to allow self-signed certs.
  static void trustHost(String host) =>
      _trustedNasHosts.add(host.toLowerCase());

  /// Remove a NAS host from the trusted set.
  static void untrustHost(String host) =>
      _trustedNasHosts.remove(host.toLowerCase());

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) {
        return _trustedNasHosts.contains(host.toLowerCase());
      };
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  HttpOverrides.global = NasCertOverrides();
  await LocaleProvider.instance.load();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F1A2E),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const SynoHubApp());
}

class SynoHubApp extends StatelessWidget {
  const SynoHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleProvider.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'SynoHub',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          locale: LocaleProvider.instance.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AuthGate(),
        );
      },
    );
  }
}

/// App flow:
///   Splash (neon logo + silent Google sign-in)
///   → GoogleSignInScreen (if silent fails)
///   → NasManagerScreen (always — list of saved NAS)
///   → MainShell (after selecting/connecting a NAS)
enum _AppState { splash, googleSignIn, nasManager, nasConnected }

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  _AppState _state = _AppState.splash;

  @override
  void initState() {
    super.initState();
    SessionManager.instance.addListener(_onSessionChanged);
  }

  @override
  void dispose() {
    SessionManager.instance.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    // If NAS session is lost while in MainShell, go back to NAS manager
    if (_state == _AppState.nasConnected &&
        !SessionManager.instance.isLoggedIn) {
      setState(() => _state = _AppState.nasManager);
    }
  }

  /// Called during splash — tries silent Google sign-in + loads NAS profiles.
  Future<void> _initApp() async {
    final silentOk = await GoogleAuthService.instance.trySilentSignIn();

    if (silentOk) {
      final email = GoogleAuthService.instance.email;
      await NasProfileStore.instance.setUser(email);
      await NasProfileStore.instance.load();
      await UserTierProvider.instance.fetchTier(email);
    }

    if (!mounted) return;

    if (silentOk) {
      setState(() => _state = _AppState.nasManager);
    } else {
      setState(() => _state = _AppState.googleSignIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _AppState.splash:
        return SplashScreen(onInit: _initApp);

      case _AppState.googleSignIn:
        return GoogleSignInScreen(
          onSignedIn: () async {
            final email = GoogleAuthService.instance.email;
            await NasProfileStore.instance.setUser(email);
            await NasProfileStore.instance.load();
            UserTierProvider.instance.fetchTier(email);
            if (mounted) setState(() => _state = _AppState.nasManager);
          },
        );

      case _AppState.nasManager:
        return NasManagerScreen(
          onNasConnected: () => setState(() => _state = _AppState.nasConnected),
          onSignOut: () => setState(() => _state = _AppState.googleSignIn),
        );

      case _AppState.nasConnected:
        return MainShell(
          onDisconnect: () => setState(() => _state = _AppState.nasManager),
        );
    }
  }
}

class MainShell extends StatefulWidget {
  final VoidCallback onDisconnect;

  const MainShell({super.key, required this.onDisconnect});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = [
    const DashboardScreen(),
    const FileManagerScreen(),
    const MediaHubScreen(),
    const PhotosScreen(),
  ];

  @override
  void initState() {
    super.initState();
    UserTierProvider.instance.addListener(_onTierChanged);
  }

  @override
  void dispose() {
    UserTierProvider.instance.removeListener(_onTierChanged);
    super.dispose();
  }

  void _onTierChanged() => setState(() {});

  void _onTabTap(int i) {
    // Media (2) and Photos (3) require VIP
    if ((i == 2 || i == 3) && UserTierProvider.instance.isFree) {
      _showPremiumDialog();
      return;
    }
    setState(() => _currentIndex = i);
  }

  void _showPremiumDialog() {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Icons.workspace_premium,
              color: Color(0xFFFFD700),
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              l.premiumFeature,
              style: const TextStyle(color: AppColors.onSurface),
            ),
          ],
        ),
        content: Text(
          l.premiumFeatureDesc,
          style: const TextStyle(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.ok)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SynoHubAppBar(onDisconnect: widget.onDisconnect),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTap,
        premiumIndices: UserTierProvider.instance.isFree
            ? const {2, 3}
            : const {},
      ),
    );
  }
}
