import 'package:flutter/services.dart';

/// FILE: clipboard_utils.dart
/// DESCRIZIONE: Utilities per operazioni sulla clipboard del sistema.
/// Fornisce metodi statici per copiare testo negli appunti in modo sicuro,
/// gestendo automaticamente i casi edge (testo null o vuoto).

class ClipboardUtils {
  // Costruttore privato per prevenire l'istanziazione della classe.
  // Questa classe fornisce solo metodi statici di utilità.
  ClipboardUtils._();

  // --- COPIA NELLA CLIPBOARD ---
  // Copia il testo fornito nella clipboard del sistema.
  // Gestisce automaticamente i casi edge: ritorna silenziosamente
  // se il testo è null o vuoto, evitando errori runtime.
  static Future<void> copy(String? text) async {
    if (text == null || text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
  }
}