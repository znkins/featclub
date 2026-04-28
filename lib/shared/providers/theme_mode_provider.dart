import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mode de thème courant. Défaut : suit le réglage OS. Pas de persistance
/// disque en V1 — le choix manuel ne survit pas au redémarrage de l'app.
final themeModeProvider = StateProvider<ThemeMode>((_) => ThemeMode.system);
