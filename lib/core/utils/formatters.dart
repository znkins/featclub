// Helpers d'affichage partagés (dates, poids).
library;

/// `JJ/MM/AAAA` — format standard de l'app.
String formatDate(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}

/// `JJ/MM/AA` — format compact (utilisé par le tooltip du graphique poids).
String formatDateShort(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final yy = (d.year % 100).toString().padLeft(2, '0');
  return '$dd/$mm/$yy';
}

/// Poids en kg, entier si valeur ronde, 1 décimale sinon.
String formatWeightKg(double kg) {
  final rounded = kg.toStringAsFixed(kg % 1 == 0 ? 0 : 1);
  return '$rounded kg';
}

/// Date assignée affichée naturellement :
/// "Aujourd'hui" / "Demain" / nom du jour si dans 7j / `JJ/MM/AAAA` sinon.
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
