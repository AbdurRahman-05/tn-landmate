import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Saves files to the phone's public Downloads folder (Android 10+, no permission needed)
/// and opens them. Implemented in android/.../MainActivity.kt.
class DeviceFiles {
  static const MethodChannel _channel = MethodChannel('tnlandmate/files');

  static bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Saves [bytes] as Downloads/TN LandMate/[name]. Returns a content URI, or null when
  /// direct saving is not available (iOS, Android 9 and older) — callers then share instead.
  static Future<String?> saveToDownloads(Uint8List bytes, String name,
      {String mime = 'application/pdf'}) async {
    if (!_isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('saveToDownloads', {
        'bytes': bytes,
        'name': name,
        'mime': mime,
      });
    } on MissingPluginException {
      return null;
    }
  }

  /// Opens a saved file in the user's PDF viewer. Returns false if no app can open it.
  static Future<bool> open(String uri, {String mime = 'application/pdf'}) async {
    if (!_isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('open', {'uri': uri, 'mime': mime}) ?? false;
    } on MissingPluginException {
      return false;
    }
  }
}
