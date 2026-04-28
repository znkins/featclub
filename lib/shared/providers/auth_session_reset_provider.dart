import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coach/providers/coach_shell_providers.dart';
import '../../student/providers/student_shell_providers.dart';
import 'auth_provider.dart';

/// Réinitialise l'état UI lié à un compte (onglet actif des shells coach et
/// élève) quand l'utilisateur authentifié change.
///
/// Sans ça, les `StateProvider` qui retiennent l'onglet sélectionné
/// survivent à un signOut → signIn dans la même session de l'app, et le
/// nouveau compte arrive sur le dernier onglet utilisé par le précédent.
///
/// Doit être observé au montage de l'app (cf. `app.dart`) pour rester actif
/// pendant toute la durée de vie du process.
final authSessionResetProvider = Provider<void>((ref) {
  String? previousUserId;
  ref.listen(authStateChangesProvider, (_, next) {
    final nextUserId = next.value?.session?.user.id;
    if (nextUserId != previousUserId) {
      ref.read(coachActiveTabProvider.notifier).state = 0;
      ref.read(studentActiveTabProvider.notifier).state = 0;
      previousUserId = nextUserId;
    }
  });
});
