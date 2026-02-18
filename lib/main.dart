import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  LogService.i("App Starting...");
  
  await AppConfig.load();

  if (!AppConfig.isValid) {
    runApp(const MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              "Configuration Error:\nMissing Supabase URL or Key.\n\nPlease check your build configuration.",
              style: TextStyle(color: Colors.red, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ));
    return;
  }

  try {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  } catch (e) {
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              "Initialization Error:\n$e",
              style: const TextStyle(color: Colors.red, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ));
    return;
  }

  runApp(
    MultiProvider(
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
    ),
  );
}
