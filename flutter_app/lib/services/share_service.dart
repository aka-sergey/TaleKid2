import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Sharing service — uses share_plus on mobile, clipboard on web.
class ShareService {
  /// Share a story link.
  ///
  /// On mobile: opens the native share sheet.
  /// On web: copies the link to clipboard and returns true.
  Future<bool> shareStoryLink({
    required String storyId,
    required String storyTitle,
    String baseUrl = 'https://www.talekid.ai',
  }) async {
    final url = '$baseUrl/stories/$storyId';
    final text = '$storyTitle\n\nЧитайте на TaleKID: $url';

    if (kIsWeb) {
      await Clipboard.setData(ClipboardData(text: url));
      return true; // Indicates link was copied
    }

    final result = await Share.share(text, subject: storyTitle);
    return result.status == ShareResultStatus.success;
  }

  /// Share PDF bytes as a file.
  Future<bool> sharePdf({
    required Uint8List pdfBytes,
    required String fileName,
    required String storyTitle,
  }) async {
    if (kIsWeb) {
      // On web, we trigger download via printing package instead
      return false;
    }

    final xFile = XFile.fromData(
      pdfBytes,
      mimeType: 'application/pdf',
      name: fileName,
    );

    final result = await Share.shareXFiles(
      [xFile],
      subject: storyTitle,
      text: 'Сказка "$storyTitle" — создана в TaleKID',
    );
    return result.status == ShareResultStatus.success;
  }
}
