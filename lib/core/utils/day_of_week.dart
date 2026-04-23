/// Jour de la semaine assignable à une séance élève (colonne `day_of_week`
/// de `student_sessions`, stockée en texte).
///
/// Le calcul de la date assignée renvoie la prochaine occurrence du jour
/// choisi — si le jour choisi est *aujourd'hui*, la date retournée est celle
/// du jour (décision produit tranchée en cadrage).
library;

enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  /// Valeur stockée en base (`monday`..`sunday`).
  String get storageValue => name;

  /// Libellé français capitalisé (`Lundi`..`Dimanche`).
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

  /// Numéro ISO (1 = lundi, 7 = dimanche), aligné sur `DateTime.weekday`.
  int get isoWeekday => index + 1;

  static DayOfWeek? fromStorage(String? value) {
    if (value == null) return null;
    for (final d in DayOfWeek.values) {
      if (d.storageValue == value) return d;
    }
    return null;
  }
}

/// Prochaine date correspondant à `day`.
///
/// Retourne *aujourd'hui* si `day` tombe le même jour de semaine que `now`
/// (décision produit), sinon la prochaine occurrence future du jour.
///
/// `now` n'est exposé que pour faciliter les tests ; en production, on passe
/// `DateTime.now()`.
DateTime nextDateForDayOfWeek(DayOfWeek day, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  final diff = (day.isoWeekday - today.weekday) % 7;
  return today.add(Duration(days: diff));
}

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
