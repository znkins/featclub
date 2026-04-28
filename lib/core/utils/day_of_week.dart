// Jours de la semaine et calcul de la prochaine occurrence d'une séance.
library;

/// Jour assignable à une séance élève (colonne `student_sessions.day_of_week`).
enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  /// Valeur stockée en base ('monday'..'sunday').
  String get storageValue => name;

  /// Libellé français capitalisé ('Lundi'..'Dimanche').
  String get frenchLabel {
    switch (this) {
      case DayOfWeek.monday:
        return 'Lundi';
      case DayOfWeek.tuesday:
        return 'Mardi';
      case DayOfWeek.wednesday:
        return 'Mercredi';
      case DayOfWeek.thursday:
        return 'Jeudi';
      case DayOfWeek.friday:
        return 'Vendredi';
      case DayOfWeek.saturday:
        return 'Samedi';
      case DayOfWeek.sunday:
        return 'Dimanche';
    }
  }

  /// Numéro ISO (1 = lundi … 7 = dimanche), aligné sur `DateTime.weekday`.
  int get isoWeekday => index + 1;

  static DayOfWeek? fromStorage(String? value) {
    if (value == null) return null;
    for (final d in DayOfWeek.values) {
      if (d.storageValue == value) return d;
    }
    return null;
  }
}

/// Date du `day` dans la semaine ISO en cours (lundi = début de semaine).
DateTime dateForDayInCurrentWeek(DayOfWeek day, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  final monday = today.subtract(Duration(days: today.weekday - 1));
  return monday.add(Duration(days: day.isoWeekday - 1));
}

/// Lundi 00h00 de la semaine ISO en cours.
DateTime currentWeekStart({DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  return today.subtract(Duration(days: today.weekday - 1));
}

/// Lundi 00h00 de la semaine suivante (borne supérieure exclusive).
DateTime currentWeekEnd({DateTime? now}) =>
    currentWeekStart(now: now).add(const Duration(days: 7));

/// Prochaine occurrence affichée à l'élève pour une séance hebdomadaire.
///
/// Modèle « la complétion valide la semaine » :
/// - séance déjà faite cette semaine → semaine prochaine ;
/// - sinon, date de cette semaine déjà passée → semaine prochaine ;
/// - sinon → date de cette semaine.
DateTime nextOccurrenceForStudent(
  DayOfWeek day, {
  required bool completedThisWeek,
  DateTime? now,
}) {
  final today = _dateOnly(now ?? DateTime.now());
  final base = dateForDayInCurrentWeek(day, now: today);
  final shouldRoll = completedThisWeek || base.isBefore(today);
  return shouldRoll ? base.add(const Duration(days: 7)) : base;
}

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
