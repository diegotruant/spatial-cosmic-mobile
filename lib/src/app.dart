import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'services/settings_service.dart';
import 'ui/auth_gate.dart';
import 'ui/theme/app_theme.dart';

import 'package:app_links/app_links.dart';
import 'services/integration_service.dart';
import 'services/oura_service.dart';
import 'services/auth_service.dart';
import 'services/log_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SpatialCosmicApp extends StatefulWidget {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  const SpatialCosmicApp({super.key});

  @override
  State<SpatialCosmicApp> createState() => _SpatialCosmicAppState();
}

class _SpatialCosmicAppState extends State<SpatialCosmicApp> with WidgetsBindingObserver {
  late AppLinks _appLinks;
  bool _isProcessingDeepLink = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("!!! APP RESUMED !!!");
      // Automatically check for updated connections when app comes to foreground
      // This acts as a fallback if the deep link didn't trigger the callback directly
      final ctx = SpatialCosmicApp.navigatorKey.currentContext;
      if (ctx != null) {
        Provider.of<IntegrationService>(ctx, listen: false).syncFromSupabase();
      }
    }
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Check initial link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        debugPrint('Initial Link: $initialLink');
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      debugPrint('Initial Link Error: $e');
    }

    // Listen to changes
    _appLinks.uriLinkStream.listen((uri) {
        debugPrint('Stream Link: $uri');
        _handleDeepLink(uri);
    });
  }

  Future<void> _handleDeepLink(Uri uri) async {
    debugPrint('!!! DEEP LINK RECEIVED: $uri');
    LogService.i('App: Deep link received: $uri');
    
    if (_isProcessingDeepLink) {
      LogService.d('App: Deep link already processing, skipping.');
      return;
    }

    _isProcessingDeepLink = true;
    
    try {
      // Safety delay to ensure Navigator and context are ready, especially on cold starts
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      // Handle Supabase Auth (Password Recovery, etc)
      await _handlePasswordRecovery(uri);

      // Handle Integration Callbacks (Strava, etc)
      if (uri.path == '/auth' || uri.queryParameters.containsKey('provider')) {
         SpatialCosmicApp.scaffoldMessengerKey.currentState?.showSnackBar(
           const SnackBar(content: Text('Ricevuta conferma da Strava... Attendi...'), duration: Duration(seconds: 2)),
         );
         
         final ctx = SpatialCosmicApp.navigatorKey.currentContext;
         if (ctx != null) {
           Provider.of<IntegrationService>(ctx, listen: false).handleAuthCallback(uri);
         }
      }
      
      // Handle Oura
      if (uri.toString().contains('oura')) {
         final ctx = SpatialCosmicApp.navigatorKey.currentContext;
         if (ctx == null) {
           LogService.e('App: Navigator context is NULL, cannot handle Oura callback.');
           return;
         }

         // Use SnackBar instead of Dialog for loading to avoid Navigator issues
         SpatialCosmicApp.scaffoldMessengerKey.currentState?.showSnackBar(
           const SnackBar(
             content: Row(
               children: [
                 SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                 SizedBox(width: 16),
                 Text('Sincronizzazione Oura in corso...'),
               ],
             ),
             duration: Duration(seconds: 10),
           ),
         );
         
         final ouraService = Provider.of<OuraService>(ctx, listen: false);
         // Execute handle callback
         await ouraService.handleCallback(uri);
         
         // Remove loading snackbar
         SpatialCosmicApp.scaffoldMessengerKey.currentState?.hideCurrentSnackBar();

         if (mounted) {
            if (ouraService.hasToken) {
               showDialog(
                 context: ctx,
                 builder: (dialogCtx) => AlertDialog(
                   title: const Text('✅ Oura Connesso!'),
                   content: const Text('L\'integrazione è avvenuta con successo.'),
                   actions: [
                     TextButton(
                       onPressed: () => Navigator.of(dialogCtx).pop(),
                       child: const Text('OK'),
                     ),
                   ],
                 ),
               );
            } else {
               showDialog(
                 context: ctx,
                 builder: (dialogCtx) => AlertDialog(
                   title: const Text('❌ Errore Oura'),
                   content: SingleChildScrollView(
                     child: Column(
                       mainAxisSize: MainAxisSize.min,
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         const Text('L\'integrazione ha riscontrato un problema durante lo scambio dei token.'),
                         const SizedBox(height: 12),
                         const Text('Dettagli tecnici:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                         const SizedBox(height: 4),
                         Container(
                           padding: const EdgeInsets.all(8),
                           decoration: BoxDecoration(
                             color: Colors.black12,
                             borderRadius: BorderRadius.circular(4),
                           ),
                           child: Text(
                             ouraService.lastLog,
                             style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                           ),
                         ),
                       ],
                     ),
                   ),
                   actions: [
                     TextButton(
                       onPressed: () => Navigator.of(dialogCtx).pop(),
                       child: const Text('CHIUDI'),
                     ),
                   ],
                 ),
               );
            }
         }
      }
    } catch (e) {
      LogService.e('App: Exception in deep link handler: $e');
    } finally {
      _isProcessingDeepLink = false;
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
          navigatorKey: SpatialCosmicApp.navigatorKey,
          scaffoldMessengerKey: SpatialCosmicApp.scaffoldMessengerKey,
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
