import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lanna/services/favorite_store.dart';
// auth pages
import 'package:lanna/page/auth/splash.dart';
import 'package:lanna/page/auth/login.dart';
import 'package:lanna/page/auth/register.dart';
import 'package:lanna/page/auth/forgot_password.dart';

// home shell
import 'package:lanna/page/home_shell.dart';

import 'package:lanna/page/translate.dart';
import 'package:lanna/page/camera.dart';
import 'package:lanna/page/favorite.dart';
import 'package:lanna/page/profile.dart';

import 'package:lanna/services/auth_provider.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FavoriteStore()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LANNA',

      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: GoogleFonts.sarabun().fontFamily,
        textTheme: GoogleFonts.sarabunTextTheme(
          const TextTheme(
            bodyLarge: TextStyle(fontSize: 8, color: Colors.black87),
            bodyMedium: TextStyle(fontSize: 8, color: Colors.black87),
            bodySmall: TextStyle(fontSize: 8, color: Colors.black87),
            titleLarge: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
            titleMedium: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black),
            titleSmall: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black),
            labelLarge: TextStyle(fontSize: 8, color: Colors.black87),
          ),
        ),
      ),

      // ✅ เริ่มที่ Splash
      home: const SplashPage(),

      // ✅ ROUTES ที่มีจริง
      routes: {
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/forgot-password': (_) => const ForgotPasswordPage(),

        '/home-guest': (_) => const HomeShell(isGuest: true),
        '/home-user': (_) => const HomeShell(isGuest: false),

        // ✅ bottom nav routes (ส่ง isGuest ให้ครบ)
        '/translate': (_) => const TranslatePage(isGuest: false),
        '/camera': (_) => const CameraPage(),
        '/favorite': (_) => const FavoritePage(),
        '/profile': (_) => const ProfileContent(isGuest: false),
      },
    );
  }
}
