import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc_advance/presentation/common_widgets/font_test_widget.dart';

void main() {
  group('FontTestWidget Tests', () {
    testWidgets('should render FontTestWidget correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: FontTestWidget()));

      // AppBar kontrolü
      expect(find.text('Font Test - Poppins'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);

      // Ana başlık kontrolü
      expect(find.text('Poppins Font Test'), findsOneWidget);

      // Font test metinleri kontrolü
      expect(find.text('Bu yazı Poppins fontu ile yazılmıştır.'), findsOneWidget);
      expect(find.text('abcdefghijklmnopqrstuvwxyz'), findsOneWidget);
      expect(find.text('ABCDEFGHIJKLMNOPQRSTUVWXYZ'), findsOneWidget);
      expect(find.text('0123456789'), findsOneWidget);

      // Font bilgileri bölümü kontrolü
      expect(find.text('Font Bilgileri:'), findsOneWidget);
      expect(find.text('Font Family:'), findsOneWidget);
      expect(find.text('Font Weight:'), findsOneWidget);
      expect(find.text('Font Size:'), findsOneWidget);

      // Poppins font özellikleri kontrolü
      expect(find.text('Poppins fontu karakteristik özellikleri:'), findsOneWidget);
      expect(find.text('• "a" harfi yuvarlak ve kapalı'), findsOneWidget);
      expect(find.text('• "g" harfi çift katmanlı'), findsOneWidget);
      expect(find.text('• "e" harfi yatay çizgisi kısa'), findsOneWidget);
      expect(find.text('• Genel olarak yumuşak ve modern'), findsOneWidget);
    });

    testWidgets('should display font information correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: FontTestWidget()));

      // Font bilgileri container'ının varlığını kontrol et
      expect(find.byType(Container), findsWidgets);

      // Font bilgileri metinlerinin doğru sırada olduğunu kontrol et
      final fontInfoFinder = find.text('Font Bilgileri:');
      expect(fontInfoFinder, findsOneWidget);

      // Font family, weight ve size bilgilerinin varlığını kontrol et
      expect(find.textContaining('Font Family:'), findsOneWidget);
      expect(find.textContaining('Font Weight:'), findsOneWidget);
      expect(find.textContaining('Font Size:'), findsOneWidget);
    });

    testWidgets('should display all font test characters', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: FontTestWidget()));

      // Küçük harfler
      expect(find.text('abcdefghijklmnopqrstuvwxyz'), findsOneWidget);

      // Büyük harfler
      expect(find.text('ABCDEFGHIJKLMNOPQRSTUVWXYZ'), findsOneWidget);

      // Rakamlar
      expect(find.text('0123456789'), findsOneWidget);
    });

    testWidgets('should display Poppins font characteristics', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: FontTestWidget()));

      // Poppins font özelliklerinin tamamının varlığını kontrol et
      final characteristics = [
        'Poppins fontu karakteristik özellikleri:',
        '• "a" harfi yuvarlak ve kapalı',
        '• "g" harfi çift katmanlı',
        '• "e" harfi yatay çizgisi kısa',
        '• Genel olarak yumuşak ve modern',
      ];

      for (final characteristic in characteristics) {
        expect(find.text(characteristic), findsOneWidget);
      }
    });

    testWidgets('should have proper layout structure', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: FontTestWidget()));

      // Scaffold yapısı kontrolü
      expect(find.byType(Scaffold), findsOneWidget);

      // Padding kontrolü
      expect(find.byType(Padding), findsWidgets);

      // Column yapısı kontrolü
      expect(find.byType(Column), findsWidgets);

      // SizedBox'ların varlığı kontrolü
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('should display Turkish text correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: FontTestWidget()));

      // Türkçe metinlerin doğru görüntülendiğini kontrol et
      expect(find.text('Bu yazı Poppins fontu ile yazılmıştır.'), findsOneWidget);
      expect(find.text('Poppins fontu karakteristik özellikleri:'), findsOneWidget);
    });
  });
}
