class Quiz {
  final String id;
  final String question;

  Quiz({required this.id, required this.question});

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(id: json['_id'], question: json['question']);
  }
}
