## Flutter'da Modern UI Tasarım Sistemi (Tailwind & shadcn/ui Yaklaşımı)

Bu rehber, web ekosistemindeki (React, Next.js) Tailwind CSS ve shadcn/ui gibi token tabanlı, minimalist ve bileşen odaklı tasarım sistemlerini Flutter'a (Web ve Mobil) entegre etmek için oluşturulmuştur. Temel amaç; renk, tipografi ve bileşenlerin (components) merkezi bir "core" katmanından yönetilmesini sağlayarak Clean Architecture prensiplerine uygun, ölçeklenebilir bir UI mimarisi kurmaktır.

### 1. Klasör Yapısı (Architecture)

Tasarım sistemimizi uygulamanın diğer katmanlarından izole etmek için `lib/core/` altında şu yapıyı kuruyoruz:

```text
lib/
└── core/
    ├── theme/
    │   ├── app_colors.dart      # Tailwind benzeri renk tokenları
    │   ├── app_typography.dart  # Font ve metin stilleri
    │   ├── app_theme.dart       # Material 3 ThemeData yapılandırması
    │   └── theme_provider.dart  # (Opsiyonel) Tema değiştirme mantığı
    ├── extensions/
    │   └── ui_extensions.dart   # Tailwind stili utility metodları (.p4, .gap)
    └── components/
        ├── buttons/
        │   └── primary_button.dart
        ├── cards/
        │   └── custom_card.dart
        └── inputs/
            └── custom_text_field.dart

```

### 2. Renk Sistemi (Design Tokens)

shadcn/ui'ın temel gücü, anlamsal (semantic) renklendirmedir. Doğrudan `Colors.red` kullanmak yerine `destructive` (yıkıcı) gibi isimlendirmeler kullanmalıyız.

**`core/theme/app_colors.dart`**

```dart
import 'package:flutter/material.dart';

class AppColors {
  // Light Theme (shadcn zinc/slate esintili)
  static const Color background = Color(0xFFFFFFFF);
  static const Color foreground = Color(0xFF09090B);
  
  static const Color primary = Color(0xFF18181B);
  static const Color primaryForeground = Color(0xFFFAFAFA);
  
  static const Color secondary = Color(0xFFF4F4F5);
  static const Color secondaryForeground = Color(0xFF18181B);
  
  static const Color muted = Color(0xFFF4F4F5);
  static const Color mutedForeground = Color(0xFF71717A);
  
  static const Color destructive = Color(0xFFEF4444);
  static const Color destructiveForeground = Color(0xFFFAFAFA);
  
  static const Color border = Color(0xFFE4E4E7);
  static const Color input = Color(0xFFE4E4E7);
  
  // Dark Theme Karşılıkları
  static const Color darkBackground = Color(0xFF09090B);
  static const Color darkForeground = Color(0xFFFAFAFA);
  static const Color darkPrimary = Color(0xFFFAFAFA);
  static const Color darkPrimaryForeground = Color(0xFF18181B);
  static const Color darkSecondary = Color(0xFF27272A);
  static const Color darkSecondaryForeground = Color(0xFFFAFAFA);
  static const Color darkBorder = Color(0xFF27272A);
  static const Color darkInput = Color(0xFF27272A);
}

```

### 3. Tipografi (Typography)

Modern web hissiyatı için `google_fonts` paketini kullanıyoruz. Genellikle Inter, Roboto veya Geist tercih edilir.

**`core/theme/app_typography.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextTheme getTextTheme(Brightness brightness, Color textColor) {
    return GoogleFonts.interTextTheme(
      ThemeData(brightness: brightness).textTheme,
    ).copyWith(
      displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1, color: textColor),
      titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.5, color: textColor),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.normal, color: textColor),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.normal, color: textColor),
      labelSmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
    );
  }
}

```

### 4. Tema Motorunun Kurulumu (Material 3)

Oluşturduğumuz tokenları Flutter'ın native `ThemeData`'sına entegre ediyoruz. Bu sayede yazacağımız özel bileşenler bu global temayı miras alacak.

**`core/theme/app_theme.dart`**

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        surface: AppColors.background,
        onSurface: AppColors.foreground,
        primary: AppColors.primary,
        onPrimary: AppColors.primaryForeground,
        secondary: AppColors.secondary,
        onSecondary: AppColors.secondaryForeground,
        error: AppColors.destructive,
        onError: AppColors.destructiveForeground,
        outline: AppColors.border,
      ),
      textTheme: AppTypography.getTextTheme(Brightness.light, AppColors.foreground),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.darkBackground,
        onSurface: AppColors.darkForeground,
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkPrimaryForeground,
        secondary: AppColors.darkSecondary,
        onSecondary: AppColors.darkSecondaryForeground,
        error: AppColors.destructive,
        onError: AppColors.destructiveForeground,
        outline: AppColors.darkBorder,
      ),
      textTheme: AppTypography.getTextTheme(Brightness.dark, AppColors.darkForeground),
      dividerTheme: const DividerThemeData(color: AppColors.darkBorder, thickness: 1),
    );
  }
}

```

### 5. shadcn Tarzı Yeniden Kullanılabilir Bileşenler (Components)

Temayı kurduktan sonra **asla** UI sayfalarında doğrudan renk veya stil tanımlamıyoruz. Bunun yerine `core/components` altında kendi kütüphanemizi oluşturuyoruz.

**Örnek: `primary_button.dart**` (shadcn Button varyantı)

```dart
import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      height: 40, // shadcn standart yüksekliği
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 0, // Minimalist görünüm için gölgeyi kaldırıyoruz
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6), // Radius token
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading 
            ? SizedBox(
                width: 16, 
                height: 16, 
                child: CircularProgressIndicator(
                  strokeWidth: 2, 
                  color: theme.colorScheme.onPrimary
                ))
            : Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
      ),
    );
  }
}

```

### 6. Tailwind Hissiyatı İçin Dart Extension'ları

`Padding`, `SizedBox` gibi widget'lar kodu uzatabilir. Dart'ın gücünü kullanarak Tailwind sınıf mantığını metod zincirleme (method chaining) ile simüle edebiliriz.

**`core/extensions/ui_extensions.dart`**

```dart
import 'package:flutter/material.dart';

extension TailwindPadding on Widget {
  Widget p(double value) => Padding(padding: EdgeInsets.all(value), child: this);
  Widget px(double value) => Padding(padding: EdgeInsets.symmetric(horizontal: value), child: this);
  Widget py(double value) => Padding(padding: EdgeInsets.symmetric(vertical: value), child: this);
  
  // Örnek: Text("Merhaba").px(16).py(8)
}

extension TailwindGap on num {
  // SizedBox(height: 16) yerine 16.h kullanımı
  Widget get h => SizedBox(height: toDouble());
  Widget get w => SizedBox(width: toDouble());
}

```

### 7. Global Entegrasyon (`main.dart`)

Son olarak, bu sistemi uygulamamıza dahil ediyoruz.

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
      title: 'Modern UI App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Veya state üzerinden dinamik olarak ThemeMode.light/dark
      home: const Scaffold(
        body: Center(
          child: Text('Tasarım Sistemi Hazır!'),
        ),
      ),
    );
  }
}

```
