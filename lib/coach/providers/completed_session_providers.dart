// Re-exports vers `shared/providers` pour préserver les imports côté coach.
export '../../shared/providers/data_providers.dart'
    show completedSessionServiceProvider;
export '../../shared/providers/student_data_providers.dart'
    show
        studentRecentHistoryProvider,
        studentHistoryProvider,
        studentCompletedSessionCountProvider;
