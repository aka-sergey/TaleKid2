import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/story.dart';

/// Generates a landscape PDF from a completed story.
///
/// Layout per page:
///   - Full-bleed illustration (landscape)
///   - Text overlay at the bottom
///
/// First page is the cover with title.
class PdfService {
  /// Build a PDF document from the story detail.
  /// Returns raw PDF bytes ready for printing / saving.
  Future<Uint8List> generateStoryPdf(StoryDetail story) async {
    final pdf = pw.Document(
      title: story.displayTitle,
      author: 'TaleKID',
    );

    final pages = List<StoryPage>.from(story.pages)
      ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

    // Pre-download all images
    final imageCache = <String, pw.MemoryImage>{};
    for (final page in pages) {
      if (page.imageUrl != null && !imageCache.containsKey(page.imageUrl)) {
        try {
          final response = await http.get(Uri.parse(page.imageUrl!));
          if (response.statusCode == 200) {
            imageCache[page.imageUrl!] = pw.MemoryImage(response.bodyBytes);
          }
        } catch (_) {
          // Skip failed downloads
        }
      }
    }

    // Also download cover image if different
    if (story.coverImageUrl != null &&
        !imageCache.containsKey(story.coverImageUrl)) {
      try {
        final response = await http.get(Uri.parse(story.coverImageUrl!));
        if (response.statusCode == 200) {
          imageCache[story.coverImageUrl!] =
              pw.MemoryImage(response.bodyBytes);
        }
      } catch (_) {}
    }

    // ---- Cover Page ----
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Stack(
            children: [
              // Cover image
              if (story.coverImageUrl != null &&
                  imageCache.containsKey(story.coverImageUrl))
                pw.Positioned.fill(
                  child: pw.Image(
                    imageCache[story.coverImageUrl!]!,
                    fit: pw.BoxFit.cover,
                  ),
                ),

              // Dark overlay for text readability
              pw.Positioned.fill(
                child: pw.Container(
                  color: PdfColor.fromInt(0x80000000),
                ),
              ),

              // Title text
              pw.Center(
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      story.displayTitle,
                      style: pw.TextStyle(
                        fontSize: 36,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 16),
                    pw.Text(
                      'TaleKID',
                      style: const pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // ---- Story Pages ----
    for (final page in pages) {
      final hasImage =
          page.imageUrl != null && imageCache.containsKey(page.imageUrl);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: pw.EdgeInsets.zero,
          build: (context) {
            return pw.Stack(
              children: [
                // Full-bleed illustration
                if (hasImage)
                  pw.Positioned.fill(
                    child: pw.Image(
                      imageCache[page.imageUrl!]!,
                      fit: pw.BoxFit.cover,
                    ),
                  ),

                // Text at bottom
                if (page.textContent != null)
                  pw.Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 20,
                      ),
                      color: PdfColor.fromInt(0xB0000000),
                      child: pw.Text(
                        page.textContent!,
                        style: const pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.white,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ),

                // Page number
                pw.Positioned(
                  top: 12,
                  right: 16,
                  child: pw.Text(
                    '${page.pageNumber}',
                    style: pw.TextStyle(
                      fontSize: 11,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }
}
