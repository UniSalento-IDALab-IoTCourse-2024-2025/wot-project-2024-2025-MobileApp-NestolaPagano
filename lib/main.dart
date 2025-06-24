import 'package:app/services/driving_session_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/services/auth_service.dart';
import 'package:app/ble/bluetooth_manager.dart';
import 'package:app/ui/auth/auth_check_screen.dart';
import 'package:app/ui/auth/registration_screen.dart';
import 'package:app/ui/auth/login_screen.dart';
import 'package:app/ui/home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthService()),
        Provider(create: (context) => BluetoothManager()),
        ChangeNotifierProvider(create: (context) => DrivingSessionManager())
      ],
      child: const ThingyApp(),
    ),
  );
}

class ThingyApp extends StatelessWidget {
  const ThingyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthCheckScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}