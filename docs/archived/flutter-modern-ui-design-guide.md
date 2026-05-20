# Flutter UI/UX Mimari Kanvası: Tailwind & shadcn Adaptasyonu

Bu doküman, Flutter (Web & Mobil) projelerinde modern, minimalist (shadcn/ui tarzı) ve %100 Dark/Light mod uyumlu bir tasarım sisteminin nasıl kurulacağını ve yönetileceğini tanımlar. 

Mimari; Clean Architecture katmanlarına uygun olarak, UI bileşenlerinin ve tasarım token'larının (renk, font, boşluk) merkezi bir `core/theme` modülünden yönetilmesi üzerine kurgulanmıştır. Çok kiracılı (multi-tenant) sistemlerde marka renklerinin dinamik olarak enjekte edilebilmesine olanak tanır.

---

## 1. Tasarım Token'ları (Design Tokens)

Tasarım sistemimizin en alt katmanında sabit renk tanımlamalarımız yer alır. Doğrudan Flutter'ın varsayılan renk paletleri yerine, modern web hissiyatı veren özel Hex kodları kullanılır.

### Renk Paleti (`core/theme/app_colors.dart`)
shadcn "Zinc" konseptinin Flutter karşılığıdır.

```dart
import 'package:flutter/material.dart';

class AppColors {
  // --- Light Mode Token'ları ---
  static const lightBackground = Color(0xFFFFFFFF);
  static const lightForeground = Color(0xFF09090B);
  static const lightPrimary = Color(0xFF18181B);
  static const lightOnPrimary = Color(0xFFFAFAFA);
  static const lightMuted = Color(0xFFF4F4F5);
  static const lightBorder = Color(0xFFE4E4E7);

  // --- Dark Mode Token'ları ---
  static const darkBackground = Color(0xFF09090B);
  static const darkForeground = Color(0xFFFAFAFA);
  static const darkPrimary = Color(0xFFFAFAFA);
  static const darkOnPrimary = Color(0xFF18181B);
  static const darkMuted = Color(0xFF27272A);
  static const darkBorder = Color(0xFF27272A);

  // --- Ortak Token'lar (Her iki modda aynı) ---
  static const destructive = Color(0xFFEF4444);
  static const destructiveForeground = Color(0xFFFAFAFA);
}

```

---

## 2. Tipografi Sistemi (Typography)

Sistemin "modern web" hissiyatını veren ana unsur font seçimi ve harf aralıklarıdır (tracking). `google_fonts` paketi üzerinden "Inter" ailesi global olarak konfigüre edilir.

### Font Konfigürasyonu (`core/theme/app_typography.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextTheme getInterTheme(Color foregroundColor) {
    return GoogleFonts.interTextTheme().copyWith(
      // H1 (Tailwind: text-4xl font-bold tracking-tight)
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -1.0,
        color: foregroundColor,
        height: 1.2,
      ),
      // H2
      titleLarge: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: foregroundColor,
      ),
      // Paragraf (Tailwind: text-base leading-relaxed)
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        color: foregroundColor,
        height: 1.5,
      ),
      // Buton & Label
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: foregroundColor,
      ),
    );
  }
}

```

---

## 3. Dinamik Tema Motoru (Theme Factory)

Material 3'ün `ThemeData` objesi, `Brightness` (açık/koyu mod) durumuna göre dinamik olarak üretilir. Bu yapı, gelecekte farklı kiracılar (tenant'lar) için dinamik marka renkleri (seedColor) eklenebilmesine hazır bir zemin sunar.

### Factory Sınıfı (`core/theme/app_theme.dart`)

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData createTheme({
    required Brightness brightness,
    Color? tenantPrimaryColor, // Multi-tenant yapılar için opsiyonel marka rengi
  }) {
    final isDark = brightness == Brightness.dark;

    // Token Seçimi
    final bgColor = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final fgColor = isDark ? AppColors.darkForeground : AppColors.lightForeground;
    final primaryColor = tenantPrimaryColor ?? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary);
    final onPrimaryColor = isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bgColor,

      // --- Renk Şeması ---
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        onPrimary: onPrimaryColor,
        secondary: mutedColor,
        onSecondary: fgColor,
        error: AppColors.destructive,
        onError: AppColors.destructiveForeground,
        surface: bgColor,
        onSurface: fgColor,
        outline: borderColor,
      ),

      // --- Tipografi ---
      textTheme: AppTypography.getInterTheme(fgColor),

      // --- Bileşen Temaları (Component Overrides) ---
      
      // 1. Butonlar (rounded-md, shadows-none)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimaryColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      // 2. Form Alanları (ring-offset, border)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),

      // 3. Kartlar (border, shadow-sm)
      cardTheme: CardTheme(
        color: bgColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
    );
  }
}

```

---

## 4. Geliştirici Deneyimi (DX) ve Utility'ler

Tailwind'in hızlı prototipleme gücünü Flutter'a taşımak için Dart Extension'ları kullanılır. Bu, kod okunuşunu artırır ve gereksiz widget ağacı karmaşasını önler.

### Utility Extension'lar (`core/extensions/ui_extensions.dart`)

```dart
import 'package:flutter/material.dart';

// Boşluklar (Gap) için: `16.h` veya `24.w` kullanımı
extension TailwindGap on num {
  Widget get h => SizedBox(height: toDouble());
  Widget get w => SizedBox(width: toDouble());
}

// Padding için: `Text('Merhaba').p16()` veya `Text('Merhaba').px(8)` kullanımı
extension TailwindPadding on Widget {
  Widget p(double value) => Padding(padding: EdgeInsets.all(value), child: this);
  Widget px(double value) => Padding(padding: EdgeInsets.symmetric(horizontal: value), child: this);
  Widget py(double value) => Padding(padding: EdgeInsets.symmetric(vertical: value), child: this);
  
  // Sık kullanılan Tailwind karşılıkları
  Widget p4() => Padding(padding: const EdgeInsets.all(16.0), child: this);
}

```

---

## 5. Uygulama ve Kullanım

Sistem, uygulamanın kök widget'ında (`MaterialApp`) başlatılır. Dark/Light mod geçişleri `ThemeMode` üzerinden merkezi olarak yönetilir.

### `main.dart` Entegrasyonu

```dart
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SaaS Platform UI',
      debugShowCheckedModeBanner: false,
      
      // Factory metodumuz ile temaları basıyoruz
      theme: AppTheme.createTheme(brightness: Brightness.light),
      darkTheme: AppTheme.createTheme(brightness: Brightness.dark),
      
      // State Manager (Riverpod/Bloc) ile bu değer dinamikleştirilebilir
      themeMode: ThemeMode.system, 
      
      home: const DashboardScreen(),
    );
  }
}

```
