import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/app.dart';
import 'src/services/auth_service.dart';
import 'src/services/bluetooth_service.dart';
import 'src/services/physiological_service.dart';
import 'src/services/workout_service.dart';
import 'src/services/sync_service.dart';
import 'src/services/athlete_profile_service.dart';
import 'src/services/settings_service.dart';
import 'src/services/integration_service.dart';
import 'src/viewmodels/payment_viewmodel.dart';
import 'src/viewmodels/payment_manager_viewmodel.dart';
import 'src/services/oura_service.dart';
import 'src/services/intervals_service.dart';
import 'src/services/events_service.dart';
import 'src/services/w_prime_service.dart';
import 'package:spatial_cosmic_mobile/src/config/app_config.dart';
import 'src/services/log_service.dart';
import 'package:spatial_cosmic_mobile/src/services/secure_storage_service.dart';

void main() {
  // Use synchronous main to ensure runApp is called as fast as possible
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint("!!! main() sync part starting !!!");
    
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      LogService.e("Flutter Error: ${details.exception}", details.exception, details.stack);
    };

    runApp(const Bootstrapper());
  }, (error, stack) {
    LogService.e("Zoned Error: $error", error, stack);
  });
}

class Bootstrapper extends StatefulWidget {
  const Bootstrapper({super.key});

  @override
  State<Bootstrapper> createState() => _BootstrapperState();
}

class _BootstrapperState extends State<Bootstrapper> {
  bool _isInitialized = false;
  String _status = "Avvio sistema...";
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      LogService.i("Boot: Starting sequence...");
      
      setState(() => _status = "Caricamento configurazione...");
      await AppConfig.load();
      await Future.delayed(const Duration(milliseconds: 200));
      
      setState(() => _status = "Inizializzazione log...");
      await LogService().ensureFileInitialized();
      await Future.delayed(const Duration(milliseconds: 200));

      if (!AppConfig.isValid) {
        throw "Configurazione non valida: SUPABASE_URL o ANON_KEY mancanti.";
      }

      setState(() => _status = "Connessione al server...");
      LogService.i("Boot: Initializing Supabase...");
      // Short delay so Android KeyStore/secure storage can be ready (avoids NotInitializedError on first launch)
      await Future.delayed(const Duration(milliseconds: 400));

      Object? lastError;
      for (int attempt = 0; attempt < 2; attempt++) {
        try {
          await Supabase.initialize(
            url: AppConfig.supabaseUrl,
            anonKey: AppConfig.supabaseAnonKey,
            authOptions: const FlutterAuthClientOptions(
              localStorage: SecureLocalStorage(),
            ),
          );
          lastError = null;
          break;
        } catch (e) {
          lastError = e;
          final msg = e.toString();
          if (msg.contains('NotInitialized') && attempt == 0) {
            LogService.w("Boot: Secure storage not ready, retrying in 1s...");
            await Future.delayed(const Duration(seconds: 1));
            continue;
          }
          rethrow;
        }
      }
      if (lastError != null) throw lastError!;

      await Future.delayed(const Duration(milliseconds: 200));

      LogService.i("Boot: Success!");
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _status = "Pronto!";
        });
      }
    } catch (e, stack) {
      LogService.e("Boot: Error during initialization: $e", e, stack);
      if (mounted) {
        final msg = e.toString();
        final isNotInitialized = msg.contains('NotInitialized');
        setState(() {
          _status = "Errore Critico";
          _error = isNotInitialized
              ? "Memoria sicura non pronta. Chiudi l'app e riaprila, oppure riavvia il dispositivo."
              : msg;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()),
          ChangeNotifierProvider(create: (_) => BluetoothService()),
          ChangeNotifierProvider(create: (_) => SettingsService()),
          ChangeNotifierProxyProvider2<BluetoothService, SettingsService, WorkoutService>(
            create: (_) => WorkoutService(),
            update: (_, bluetooth, settings, workout) => workout!
              ..updateBluetoothService(bluetooth)
              ..updateSettingsService(settings),
          ),
          ChangeNotifierProvider(create: (_) => PaymentViewModel()),
          ChangeNotifierProvider(create: (_) => PaymentManagerViewModel()),
          ChangeNotifierProxyProvider<AuthService, PhysiologicalService>(
            create: (_) => PhysiologicalService(),
            update: (_, auth, physio) => physio!..updateAthleteId(auth.athleteId),
          ),
          ChangeNotifierProvider(create: (_) => SyncService()),
          ChangeNotifierProxyProvider<AuthService, AthleteProfileService>(
            create: (_) => AthleteProfileService(),
            update: (_, auth, profile) => profile!..updateAthleteId(auth.athleteId),
          ),
          ChangeNotifierProvider(create: (_) => IntegrationService()),
          ChangeNotifierProvider(create: (_) => OuraService()),
          ChangeNotifierProvider(create: (_) => IntervalsService()),
          ChangeNotifierProxyProvider<AuthService, EventsService>(
            create: (_) => EventsService(),
            update: (_, auth, events) => events!..updateAthleteId(auth.athleteId),
          ),
          ChangeNotifierProxyProvider2<BluetoothService, AthleteProfileService, WPrimeService>(
            create: (_) => WPrimeService(),
            update: (_, bluetooth, profile, wPrime) => wPrime!..update(bluetooth, profile),
          ),
        ],
        child: const SpatialCosmicApp(),
      );
    }

    // High Visibility Loading Screen (to rule out black screen confusion)
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0A0A14),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 60, height: 60,
                child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 3),
              ),
              const SizedBox(height: 40),
              Text(
                _status,
                style: const TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 1.2),
              ),
              if (_error != null) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
