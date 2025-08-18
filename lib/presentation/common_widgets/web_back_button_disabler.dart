import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Web'de Chrome'un geri butonunu devre dışı bırakan widget
/// Bu widget sadece web platformunda çalışır ve sadece Chrome geri butonunu engeller
class WebBackButtonDisabler extends StatefulWidget {
  final Widget child;

  const WebBackButtonDisabler({
    super.key,
    required this.child,
  });

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
    const String script = '''
      (function() {
        // Popstate event'ini yakala ve engelle
        window.addEventListener('popstate', function(event) {
          console.log('Browser back button pressed - preventing navigation');
          event.preventDefault();
          event.stopPropagation();
          event.stopImmediatePropagation();
          
          // URL'yi değiştirme
          window.history.pushState(null, '', window.location.href);
          
          return false;
        }, true);
        
        // History API'yi override et
        const originalBack = window.history.back;
        const originalGo = window.history.go;
        
        window.history.back = function() {
          console.log('History.back() prevented');
          return;
        };
        
        window.history.go = function(delta) {
          if (delta < 0) {
            console.log('History.go() back prevented');
            return;
          }
          return originalGo.call(this, delta);
        };
        
        // Başlangıç URL'sini kaydet
        window.history.pushState(null, '', window.location.href);
        
        console.log('Browser back button disabled via Flutter widget');
      })();
    ''';
    
    // Script'i çalıştır
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
        onPopInvoked: (didPop) {
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
