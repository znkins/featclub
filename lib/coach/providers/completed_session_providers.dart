// `completedSessionServiceProvider` + family providers d'historique/compteur
// sont déclarés dans `shared/providers` et re-exportés ici pour préserver
// les imports existants côté coach.
export '../../shared/providers/data_providers.dart'
    show completedSessionServiceProvider;
export '../../shared/providers/student_data_providers.dart'
    show
        studentRecentHistoryProvider,
        studentHistoryProvider,
        studentCompletedSessionCountProvider;
