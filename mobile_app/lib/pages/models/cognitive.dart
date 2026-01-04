class LdAttempt {
  final String predLabel;
  final int shapeGameScore;
  final int colorGameScore;
  final int bubbleGameScore;
  final int totalGameScore;
  final DateTime createdAt;

  LdAttempt({
    required this.predLabel,
    required this.shapeGameScore,
    required this.colorGameScore,
    required this.bubbleGameScore,
    required this.totalGameScore,
    required this.createdAt,
  });

  factory LdAttempt.fromJson(Map<String, dynamic> json) {
    return LdAttempt(
      predLabel: (json['predLabel'] ?? '').toString(),
      shapeGameScore: (json['shapeGameScore'] ?? 0) as int,
      colorGameScore: (json['colorGameScore'] ?? 0) as int,
      bubbleGameScore: (json['bubbleGameScore'] ?? 0) as int,
      totalGameScore: (json['totalGameScore'] ?? 0) as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
