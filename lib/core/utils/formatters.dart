/// Helpers d'affichage partagés.
///
/// Centralisés ici pour garantir un format uniforme dans toute l'app : une
/// seule source de vérité pour les dates et les poids.
library;

/// Formate une date au format `JJ/MM/AAAA` (standard de l'app).
String formatDate(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}

/// Formate une date au format court `JJ/MM/AA` (utilisé par le tooltip du
/// graphique de poids, où la place est contrainte).
String formatDateShort(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final yy = (d.year % 100).toString().padLeft(2, '0');
  return '$dd/$mm/$yy';
}

/// Formate un poids en kilogrammes : entier si valeur ronde, 1 décimale sinon.
String formatWeightKg(double kg) {
  final rounded = kg.toStringAsFixed(kg % 1 == 0 ? 0 : 1);
  return '$rounded kg';
}
