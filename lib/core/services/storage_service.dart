import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Upload des avatars dans le bucket Supabase Storage.
class StorageService {
  StorageService(this._client);

  final SupabaseClient _client;

  String get avatarsBucket => SupabaseConfig.avatarsBucket;

  /// Upload un avatar pour [userId] et renvoie l'URL publique fraîche
  /// (avec un cache-buster pour forcer le rechargement).
  ///
  /// L'image est écrasée si elle existe déjà (`upsert: true`).
  /// Le bucket est supposé public côté Supabase, conformément à la config
  /// validée pour ce projet.
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
