import 'dart:io';
import 'package:http/http.dart' as http;

/// PDF dosyalarının içindeki gerçek yazıyı çıkarmak için kullanılır.
/// Sunucuda kurulu `pdftotext` (poppler-utils paketi) komutunu kullanır.
class PdfTextService {
  /// Verilen URL'deki PDF'i indirir, içindeki yazıyı çıkarır.
  /// Herhangi bir hata durumunda boş string döner — çağıran taraf
  /// bu durumda metadata'ya (başlık/açıklama vb.) fallback yapmalı.
  static Future<String> extractTextFromUrl(String fileUrl) async {
    File? tempFile;

    try {
      final response = await http
          .get(Uri.parse(fileUrl))
          .timeout(const Duration(seconds: 25));

      if (response.statusCode != 200) {
        print('PDF_DOWNLOAD_FAILED: status=${response.statusCode} url=$fileUrl');
        return '';
      }

      final tempDir = Directory.systemTemp;
      final tempName = 'note_${DateTime.now().microsecondsSinceEpoch}.pdf';
      tempFile = File('${tempDir.path}/$tempName');
      await tempFile.writeAsBytes(response.bodyBytes);

      // '-layout' sayfa düzenini korur, '-' çıktıyı stdout'a yazdırır
      final result = await Process.run(
        'pdftotext',
        ['-layout', tempFile.path, '-'],
      ).timeout(const Duration(seconds: 25));

      if (result.exitCode != 0) {
        print('PDF_TEXT_EXTRACT_ERROR: exitCode=${result.exitCode} stderr=${result.stderr}');
        return '';
      }

      final text = (result.stdout as String).trim();

      if (text.isEmpty) {
        // Taranmış (image-only) PDF'lerde metin katmanı olmayabilir.
        print('PDF_TEXT_EMPTY: url=$fileUrl (taranmış/görsel PDF olabilir)');
        return '';
      }

      // Çok uzun metinleri kısalt — DB boyutu ve performans için.
      const maxLength = 20000;
      return text.length > maxLength ? text.substring(0, maxLength) : text;
    } catch (e) {
      print('PDF_TEXT_EXTRACT_EXCEPTION: $e');
      return '';
    } finally {
      try {
        if (tempFile != null && await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {
        // Temp dosya silinemese de işlemi bozma.
      }
    }
  }
}