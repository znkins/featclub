/// Pivot programme <-> séance (table `public.program_sessions`).
class ProgramSession {
  ProgramSession({
    required this.id,
    required this.programId,
    required this.sessionId,
    required this.position,
  });

  final String id;
  final String programId;
  final String sessionId;
  final int position;

  factory ProgramSession.fromJson(Map<String, dynamic> json) {
    return ProgramSession(
      id: json['id'] as String,
      programId: json['program_id'] as String,
      sessionId: json['session_id'] as String,
      position: json['position'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'program_id': programId,
        'session_id': sessionId,
        'position': position,
      };
}
