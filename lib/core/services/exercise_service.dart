import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/exercise.dart';

/// Bibliothèque d'exercices coach (`public.exercises`).
class ExerciseService {
  ExerciseService(this._client);

  final SupabaseClient _client;

  static const String _columns =
      'id, coach_id, title, description, category, video_url, created_at';

  Future<List<Exercise>> listByCoach(String coachId) async {
    final rows = await _client
        .from('exercises')
        .select(_columns)
        .eq('coach_id', coachId)
        .order('title', ascending: true);
    return (rows as List)
        .map((r) => Exercise.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<Exercise> fetchById(String id) async {
    final row = await _client
        .from('exercises')
        .select(_columns)
        .eq('id', id)
        .single();
    return Exercise.fromJson(row);
  }

  Future<Exercise> create({
    required String coachId,
    required String title,
    String? description,
    String? category,
    String? videoUrl,
  }) async {
    final row = await _client
        .from('exercises')
        .insert({
          'coach_id': coachId,
          'title': title,
          'description': _nullIfBlank(description),
          'category': _nullIfBlank(category),
          'video_url': _nullIfBlank(videoUrl),
        })
        .select(_columns)
        .single();
    return Exercise.fromJson(row);
  }

  Future<Exercise> update({
    required String id,
    required String title,
    String? description,
    String? category,
    String? videoUrl,
  }) async {
    final row = await _client
        .from('exercises')
        .update({
          'title': title,
          'description': _nullIfBlank(description),
          'category': _nullIfBlank(category),
          'video_url': _nullIfBlank(videoUrl),
        })
        .eq('id', id)
        .select(_columns)
        .single();
    return Exercise.fromJson(row);
  }

  Future<void> delete(String id) async {
    await _client.from('exercises').delete().eq('id', id);
  }
}

String? _nullIfBlank(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
