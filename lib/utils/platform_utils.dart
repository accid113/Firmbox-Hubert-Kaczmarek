import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';

// Importy warunkowe
import 'dart:io' if (dart.library.html) 'dart:html' as universal;
import 'package:path_provider/path_provider.dart' 
    if (dart.library.html) 'package:path_provider/path_provider.dart' as path_provider;

class PlatformUtils {
  
  /// Zapisuje PDF w zależności od platformy
  static Future<String> savePdf({
    required Uint8List pdfBytes,
    required String fileName,
  }) async {
    if (kIsWeb) {
      // Na web używamy printing package do wyświetlania
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
      );
      return 'PDF został wyświetlony w przeglądarce';
    } else {
      // Na mobile/desktop zapisujemy do plików
      final directory = await path_provider.getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = universal.File(filePath);
      await file.writeAsBytes(pdfBytes);
      return filePath;
    }
  }
} 