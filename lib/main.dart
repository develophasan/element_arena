import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyA-fdR1ynkRIO98X1JoccyJ28sWcTJIoTI",
      authDomain: "elementarena-d8282.firebaseapp.com",
      databaseURL: "https://elementarena-d8282-default-rtdb.firebaseio.com",
      projectId: "elementarena-d8282",
      storageBucket: "elementarena-d8282.firebasestorage.app",
      messagingSenderId: "548117712352",
      appId: "1:548117712352:web:6bc7f13db709262c736f85",
      measurementId: "G-EV09XTG7CM",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Element Arena',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return const MainMenuScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
