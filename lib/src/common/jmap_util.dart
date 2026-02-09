import 'package:jmap_dart_client/jmap/contact/contact_api_version.dart';

/// Utility class for handling JMAP-related helpers.
class JmapUtils {
  
  /// Converts a CLI string argument into a [ContactApiVersion].
  ///
  /// Supported values:
  /// - "ietf" (default)
  /// - "cyrus"
  /// - "jscontact"
  ///
  /// Any unknown or null input defaults to [ContactApiVersion.ietf].
  static ContactApiVersion parseApiVersion(String? version) {
    switch (version?.toLowerCase()) {
      case 'cyrus':
        return ContactApiVersion.cyrus;
      case 'jscontact':
        return ContactApiVersion.jscontact;
      case 'ietf':
      case null:
      default:
        return ContactApiVersion.ietf;
    }
  }

  String uniqueFileName(String base) {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final parts = base.split('.');
    if (parts.length == 1) {
      return '${base}_$ts';
    }
    final ext = parts.removeLast();
    return '${parts.join('.')}_$ts.$ext';
  }
}
