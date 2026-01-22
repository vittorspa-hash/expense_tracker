// lib/utils/clipboard_utils.dart
import 'package:flutter/services.dart';

/// Utilities per operazioni sulla clipboard
class ClipboardUtils {
  ClipboardUtils._(); // Previene istanziazione
  
  /// Copia il testo nella clipboard
  /// Ritorna silenziosamente se il testo è null
  static Future<void> copy(String? text) async {
    if (text == null || text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
  }
}