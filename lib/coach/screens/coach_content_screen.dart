import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import 'content/blocks/block_list_screen.dart';
import 'content/exercises/exercise_list_screen.dart';
import 'content/programs/program_list_screen.dart';
import 'content/sessions/session_list_screen.dart';

/// Onglet Contenu coach : bibliothèque templates (exercices, blocs, séances, programmes).
class CoachContentScreen extends StatelessWidget {
  const CoachContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: const [
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            labelPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            tabs: [
              Tab(text: 'Exercices'),
              Tab(text: 'Blocs'),
              Tab(text: 'Séances'),
              Tab(text: 'Programmes'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ExerciseListScreen(),
                BlockListScreen(),
                SessionListScreen(),
                ProgramListScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
