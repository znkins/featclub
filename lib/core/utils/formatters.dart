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

/// Affichage humain d'une date assignée :
/// "Aujourd'hui" / "Demain" / nom du jour (si dans 7j) / sinon `JJ/MM/AAAA`.
///
/// Utilisé par l'accueil élève et la liste des séances du programme.
String? formatAssignedDateLabel(DateTime? date) {
  if (date == null) return null;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(date.year, date.month, date.day);
  final diff = d.difference(today).inDays;
  if (diff == 0) return 'Aujourd\'hui';
  if (diff == 1) return 'Demain';
  if (diff > 1 && diff < 7) return _frenchWeekdayName(d.weekday);
  return formatDate(date);
}

String _frenchWeekdayName(int isoWeekday) {
  switch (isoWeekday) {
    case DateTime.monday:
      return 'Lundi';
    case DateTime.tuesday:
      return 'Mardi';
    case DateTime.wednesday:
      return 'Mercredi';
    case DateTime.thursday:
      return 'Jeudi';
    case DateTime.friday:
      return 'Vendredi';
    case DateTime.saturday:
      return 'Samedi';
    default:
      return 'Dimanche';
  }
}
