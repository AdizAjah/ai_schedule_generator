import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart'; // untuk kReleaseMode
import 'package:flutter/material.dart';

import 'ui/home_screen.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: !kReleaseMode, // Aktif hanya saat development (non-release)
      builder: (context) => const MainApp(), // Root aplikasi
    ),
  );
}

// Root Widget aplikasi
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery:
          true, // Mengikuti ukuran device dari DevicePreview
      locale: DevicePreview.locale(context), // Menyesuaikan locale preview
      builder:
          DevicePreview.appBuilder, // Builder untuk integrasi DevicePreview

      debugShowCheckedModeBanner: false, // Menghilangkan banner debug
      title: 'AI Schedule Generator', // Judul aplikasi

      theme: ThemeData(
        // Konfigurasi tema global aplikasi
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo, // Warna utama aplikasi
          brightness: Brightness.light,
        ),
        useMaterial3: true, // Menggunakan Material Design 3
        scaffoldBackgroundColor: Colors.grey[50], // Warna background utama
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
      ),

      home: const HomeScreen(), // Halaman pertama saat aplikasi dibuka
    );
  }
}
