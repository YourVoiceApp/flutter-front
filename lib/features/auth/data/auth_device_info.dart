import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Value for Spring `deviceInfo` (no `dart:io`, safe for web builds).
String buildAuthDeviceInfo() {
  if (kIsWeb) return 'web';
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    TargetPlatform.linux => 'linux',
    TargetPlatform.macOS => 'macos',
    TargetPlatform.windows => 'windows',
    TargetPlatform.fuchsia => 'fuchsia',
  };
}
