// Upload des avatars dans Supabase Storage.

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class StorageService {
  StorageService(this._client);

  final SupabaseClient _client;

  String get avatarsBucket => SupabaseConfig.avatarsBucket;

  /// Upload un avatar pour [userId] et renvoie son URL publique.
  /// L'image existante est écrasée (`upsert: true`). Un cache-buster est
  /// ajouté à l'URL pour forcer le rechargement côté client.
  Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final path = '$userId/avatar.jpg';

    await _client.storage.from(avatarsBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType,
          ),
        );

    final publicUrl = _client.storage.from(avatarsBucket).getPublicUrl(path);
    return '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
  }
}
