import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mode de thème courant de l'application.
///
/// Défaut : [ThemeMode.system] (suit le réglage de l'OS). Une fois que
/// l'utilisateur bascule manuellement, on conserve son choix le temps de la
/// session (pas de persistance disque en V1).
final themeModeProvider = StateProvider<ThemeMode>((_) => ThemeMode.system);
