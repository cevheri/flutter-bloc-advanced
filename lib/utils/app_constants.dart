import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

class AppConstants{
  static const String APP_KEY = "SekoyaApi";
  static const String APP_NAME = "User-Offering-Management";
  static const String APP_VERSION = "1.0.0";
  static const String APP_DESCRIPTION = "User Roles and Offering Management mobile and web application";
  static const String APP_AUTHOR = "---";
  static const String APP_AUTHOR_EMAIL = "test@gmail.com";
  static String jwtToken = "";
  static String role = "";
  Future<pw.MemoryImage> getBackground() async {
    final backgroundImage = pw.MemoryImage((await rootBundle.load('assets/images/backgroundDocument2.png')).buffer.asUint8List());
    return backgroundImage;
  }

  Future<pw.MemoryImage> getKase() async {
    final kase = pw.MemoryImage((await rootBundle.load('assets/images/kase.png')).buffer.asUint8List());
    return kase;
  }

  Future<pw.Font> getFont() async {
    final font = await PdfGoogleFonts.nunitoExtraLight();
    return font;
  }
  Future<pw.Font> getFontRegular() async {
    final font = await PdfGoogleFonts.nunitoSansRegular();
    return font;
  }

  Future<pw.MemoryImage> getLogo() async {
    final logo = pw.MemoryImage((await rootBundle.load('assets/images/logo.png')).buffer.asUint8List());
    return logo;
  }
}


class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}

class CommaFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String text = newValue.text;
    return newValue.copyWith(
      text: text.replaceAll(',', '.'),
    );
  }
}

class DotFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String text = newValue.text;
    return newValue.copyWith(
      text: text.replaceAll('.', ','),
    );
  }
}

class NumberTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.replaceAll(RegExp(r'[^0-9]'), ''),
      selection: newValue.selection,
    );
  }
}