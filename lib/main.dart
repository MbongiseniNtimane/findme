import 'package:findme/widgets/Pages/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Check if running on the web
  if (kIsWeb) {
    // Initialize Firebase for web
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyD14Cj4kuZslqfx890SgpQQpHOrvc_FcQI",
        authDomain: "findme-v2-a7b1f.firebaseapp.com",
        projectId: "findme-v2-a7b1f",
         storageBucket: "findme-v2-a7b1f.firebasestorage.app",
         messagingSenderId: "571774388765",
       appId: "1:571774388765:web:fda78d82d900ce1cf594f4"
      ),
    );
  } else {
    // Initialize Firebase for mobile platforms
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Find Me',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false, // Remove the debug banner
      home: const LoginScreen(), // Replace with SignupPage() if needed
    );
  }
}
