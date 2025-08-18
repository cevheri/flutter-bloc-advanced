import 'package:flutter/material.dart';

class FontTestWidget extends StatelessWidget {
  const FontTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Font Test - Poppins')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Poppins Font Test', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            Text('Bu yazı Poppins fontu ile yazılmıştır.', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 10),
            Text('abcdefghijklmnopqrstuvwxyz', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            Text('ABCDEFGHIJKLMNOPQRSTUVWXYZ', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            Text('0123456789', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Font Bilgileri:', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Font Family: ${Theme.of(context).textTheme.bodyMedium?.fontFamily ?? "Varsayılan"}'),
                  Text('Font Weight: ${Theme.of(context).textTheme.bodyMedium?.fontWeight ?? "Normal"}'),
                  Text('Font Size: ${Theme.of(context).textTheme.bodyMedium?.fontSize ?? "14"}'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Poppins fontu karakteristik özellikleri:', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            const Text('• "a" harfi yuvarlak ve kapalı'),
            const Text('• "g" harfi çift katmanlı'),
            const Text('• "e" harfi yatay çizgisi kısa'),
            const Text('• Genel olarak yumuşak ve modern'),
          ],
        ),
      ),
    );
  }
}
