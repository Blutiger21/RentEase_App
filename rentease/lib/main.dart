import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentease/models/user_model.dart';
import 'package:rentease/screens/auth/login_screen.dart';
import 'package:rentease/screens/shared/role_selector.dart';
import 'package:rentease/services/auth_service.dart';
import 'package:rentease/services/database_service.dart';
import 'package:rentease/services/maintenance_service.dart';
import 'package:rentease/services/property_service.dart';
import 'package:rentease/services/storage_service.dart';
import 'package:rentease/utils/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rentease/services/payment_service.dart'; // <-- THIS IS THE FIX
import 'package:rentease/services/chat_service.dart';
import 'package:rentease/services/stats_service.dart';
import 'package:rentease/services/room_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
     url: '',
    anonKey: '',

  );
  runApp(const RentEaseApp());
}

final supabase = Supabase.instance.client;

class RentEaseApp extends StatelessWidget {
  const RentEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SupabaseClient>(create: (_) => supabase),
        Provider<AuthService>(create: (_) => AuthService(supabase.auth)),
        Provider<DatabaseService>(create: (_) => DatabaseService(supabase)),
        Provider<StorageService>(create: (_) => StorageService(supabase.storage)),
        Provider<PropertyService>(create: (_) => PropertyService(supabase)),
        Provider<MaintenanceService>(create: (_) => MaintenanceService(supabase)),
        Provider<PaymentService>(create: (_) => PaymentService(supabase)),
        Provider<ChatService>(create: (_) => ChatService(supabase)),
        Provider<StatsService>(create: (_) => StatsService(supabase)),
        Provider<RoomService>(create: (_) => RoomService(supabase)),
        StreamProvider<UserModel?>(
          create: (context) {
            final authService = context.read<AuthService>();
            final dbService = context.read<DatabaseService>();
            return authService.authStateChanges.asyncMap((user) {
              if (user == null) {
                return null;
              }
              return dbService.getUserData(user.id);
            });
          },
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: 'RentEase',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: kPrimaryColor,
            primary: kPrimaryColor,
            secondary: kSecondaryColor,
            // --- THIS IS THE FIX ---
            surface: kBackgroundColor, // Was 'background'
            // ---------------------
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: kBackgroundColor,
          appBarTheme: const AppBarTheme(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            elevation: 2,
            centerTitle: true,
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final userModel = context.watch<UserModel?>();
    final authState = supabase.auth.currentSession;
    
    if (authState != null && userModel == null) {
      return const RoleSelector(isloading: true);
    }
    
    if (userModel != null) {
      return const RoleSelector();
    }
    
    return const LoginScreen();
  }
}
