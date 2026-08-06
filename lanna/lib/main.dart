import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

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
import 'package:lanna/page/dictionary.dart';

import 'package:lanna/services/auth_provider.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  if (!kIsWeb) {
    HttpOverrides.global = MyHttpOverrides();
  }
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
    // 🔤 ฟ้อนไทยหลักของแอป: Noto Sans Thai Looped (ฟ้อนมีหัว)
    // ใช้ GoogleFonts.xxxTextTheme() ครอบ TextTheme เดิม เพื่อคง fontSize/
    // fontWeight/color ของแต่ละสไตล์ไว้ทั้งหมด แล้วแค่เปลี่ยน fontFamily ให้เป็นฟ้อนมีหัว
    final baseTextTheme = const TextTheme(
      bodyLarge: TextStyle(fontSize: 15.5, color: Colors.black87),
      bodyMedium: TextStyle(fontSize: 13.5, color: Colors.black87),
      bodySmall: TextStyle(fontSize: 11.5, color: Colors.black87),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      titleSmall: TextStyle(
        fontSize: 15.5,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      labelLarge: TextStyle(fontSize: 13.5, color: Colors.black87),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LANNA',
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final currentScale = mediaQuery.textScaler.scale(1);
        final appScale = currentScale.clamp(1.22, 1.38).toDouble();

        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: TextScaler.linear(appScale)),
          child: child ?? const SizedBox.shrink(),
        );
      },

      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: GoogleFonts.notoSansThaiLooped().fontFamily,
        textTheme: GoogleFonts.notoSansThaiLoopedTextTheme(baseTextTheme),
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
        '/dictionary': (_) => const DictionaryPage(),
        '/profile': (_) => const ProfileContent(isGuest: false),
      },
    );
  }
}
