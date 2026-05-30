import 'package:flutter/widgets.dart';

import 'screen_capture_protection.dart';

/// Mixin for a [State] whose [StatefulWidget] should disable screen capture
/// while mounted. Acquires a protection lease in [initState] and releases it in
/// [dispose]. Because [ScreenCaptureProtection] is reference-counted, nesting
/// protected screens is safe: protection stays on until the last protected
/// screen is disposed. See [ScreenCaptureProtection] for platform behaviour.
mixin ScreenCaptureProtected<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    ScreenCaptureProtection.enable();
  }

  @override
  void dispose() {
    ScreenCaptureProtection.disable();
    super.dispose();
  }
}
