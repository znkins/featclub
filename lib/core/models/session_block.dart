/// Pivot séance ↔ bloc (table `public.session_blocks`).
class SessionBlock {
  SessionBlock({
    required this.id,
    required this.sessionId,
    required this.blockId,
    required this.position,
  });

  final String id;
  final String sessionId;
  final String blockId;
  final int position;

  factory SessionBlock.fromJson(Map<String, dynamic> json) {
    return SessionBlock(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      blockId: json['block_id'] as String,
      position: json['position'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'session_id': sessionId,
        'block_id': blockId,
        'position': position,
      };
}
