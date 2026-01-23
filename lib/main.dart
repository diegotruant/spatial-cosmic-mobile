import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'src/app.dart';
import 'src/services/auth_service.dart';
import 'src/services/bluetooth_service.dart';
import 'src/services/payment_service.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xdqvjqqwywuguuhsehxm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhkcXZqcXF3eXd1Z3V1aHNlaHhtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUyNjk3NjIsImV4cCI6MjA4MDg0NTc2Mn0.B6abwwCelqWUFyszkqMyXvrsUz1TiOf3FFRsvpm6ezA',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => BluetoothService()),
        ChangeNotifierProvider(create: (_) => WorkoutService()),
        ChangeNotifierProvider(create: (_) => PaymentViewModel()),
        ChangeNotifierProvider(create: (_) => PaymentManagerViewModel()),
        ChangeNotifierProvider(create: (_) => PhysiologicalService()),
        ChangeNotifierProvider(create: (_) => SyncService()),
        ChangeNotifierProvider(create: (_) => AthleteProfileService()),
        ChangeNotifierProvider(create: (_) => SettingsService()),
        ChangeNotifierProvider(create: (_) => IntegrationService()),
        ChangeNotifierProvider(create: (_) => OuraService()),
        ChangeNotifierProvider(create: (_) => IntervalsService()),
      ],
      child: const SpatialCosmicApp(),
    ),
  );
}
