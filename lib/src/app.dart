import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'services/settings_service.dart';
import 'ui/auth_gate.dart';
import 'ui/theme/app_theme.dart';

import 'package:app_links/app_links.dart';
import 'services/integration_service.dart';
import 'services/oura_service.dart';
import 'services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SpatialCosmicApp extends StatefulWidget {
  const SpatialCosmicApp({super.key});

  @override
  State<SpatialCosmicApp> createState() => _SpatialCosmicAppState();
}

class _SpatialCosmicAppState extends State<SpatialCosmicApp> {
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Check initial link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      // Ignore
    }

    // Listen to changes
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('!!! DEEP LINK RECEIVED: $uri');
    debugPrint('!!! SCHEME: ${uri.scheme}');
    debugPrint('!!! HOST: ${uri.host}');
    debugPrint('!!! PATH: ${uri.path}');

    if (mounted) {
       _handlePasswordRecovery(uri);
       Provider.of<IntegrationService>(context, listen: false).handleAuthCallback(uri);
       Provider.of<OuraService>(context, listen: false).handleCallback(uri);
    }
  }

  Future<void> _handlePasswordRecovery(Uri uri) async {
    try {
      final response = await Supabase.instance.client.auth.getSessionFromUrl(uri);
      if (response.redirectType == 'recovery' && mounted) {
        Provider.of<AuthService>(context, listen: false).startPasswordRecovery();
      }
    } catch (e) {
      debugPrint('Password recovery session error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'CyclingCoach',
          debugShowCheckedModeBanner: false,
          locale: _getLocaleFromLanguage(settings.language),
          supportedLocales: const [
            Locale('en'),
            Locale('de'),
            Locale('es'),
            Locale('fr'),
            Locale('it'),
            Locale('pl'),
            Locale('ru'),
            Locale('ja'),
            Locale('zh'),
            Locale('zh', 'TW'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.darkTheme,
          home: const AuthGate(),
        );
      },
    );
  }

  Locale _getLocaleFromLanguage(String language) {
    switch (language) {
      case 'English':
        return const Locale('en');
      case 'Deutsch':
        return const Locale('de');
      case 'Español':
        return const Locale('es');
      case 'Français':
        return const Locale('fr');
      case 'Italiano':
        return const Locale('it');
      case 'Polski':
        return const Locale('pl');
      case 'Русский':
        return const Locale('ru');
      case '日本語':
        return const Locale('ja');
      case '简体中文':
        return const Locale('zh');
      case '繁體中文':
        return const Locale('zh', 'TW');
      default:
        return const Locale('it');
    }
  }
}
