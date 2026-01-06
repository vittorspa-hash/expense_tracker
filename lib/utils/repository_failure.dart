/// FILE: core/failures/repository_failure.dart
/// DESCRIZIONE: Classe di eccezione personalizzata per il layer dei dati.
/// Viene utilizzata per incapsulare errori provenienti da fonti esterne (es. Firebase, API)
/// fornendo un'interfaccia standardizzata (messaggio + codice) gestibile dalla UI.
class RepositoryFailure implements Exception {
  final String message;
  final String? code;

  RepositoryFailure(this.message, {this.code});

  @override
  String toString() => 'RepositoryFailure: $message (Code: $code)';
}