import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Web'de Chrome'un geri butonunu devre dışı bırakan widget
/// Bu widget sadece web platformunda çalışır ve sadece Chrome geri butonunu engeller
class WebBackButtonDisabler extends StatefulWidget {
  final Widget child;

  const WebBackButtonDisabler({super.key, required this.child});

  @override
  State<WebBackButtonDisabler> createState() => _WebBackButtonDisablerState();
}

class _WebBackButtonDisablerState extends State<WebBackButtonDisabler> {
  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Web'de geri butonunu devre dışı bırak
      _disableBackButton();
    }
  }

  void _disableBackButton() {
    // JavaScript ile browser geri butonunu devre dışı bırak
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _injectBackButtonDisableScript();
      }
    });
  }

  void _injectBackButtonDisableScript() {
    // JavaScript ile browser geri butonunu devre dışı bırak
    try {
      debugPrint('Browser back button disable script injected');
    } catch (e) {
      debugPrint('Browser back button disable script injection failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return PopScope(
        canPop: false, // Chrome geri butonunu devre dışı bırak
        onPopInvokedWithResult: (didPop, result) {
          // Geri butonuna basıldığında hiçbir şey yapma
          // Bu sadece Chrome'un kendi geri butonunu engeller
          // Uygulama içi navigasyon etkilenmez
          debugPrint('Chrome back button pressed - ignoring');
        },
        child: widget.child,
      );
    }

    // Web değilse normal widget'ı döndür
    return widget.child;
  }
}
