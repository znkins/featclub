import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../coach/providers/coach_shell_providers.dart';
import '../../student/providers/student_shell_providers.dart';
import 'auth_provider.dart';

/// Remet à 0 l'onglet actif des shells coach et élève quand l'utilisateur
/// authentifié change.
///
/// Sans ça, les `StateProvider` de tab survivraient à un signOut → signIn
/// dans la même session, et le nouveau compte arriverait sur le dernier
/// onglet utilisé par le précédent. Doit être watché au montage de l'app.
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
