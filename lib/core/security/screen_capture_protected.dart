import 'package:flutter/widgets.dart';

import 'screen_capture_protection.dart';

/// Mixin for a [State] whose [StatefulWidget] should disable screen capture
/// while mounted. Enables protection in [initState] and releases it in
/// [dispose]. See [ScreenCaptureProtection] for platform behaviour.
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
