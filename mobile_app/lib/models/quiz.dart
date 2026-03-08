class Quiz {
  final String id;
  final String question;
  final String answer;

  Quiz({required this.id, required this.question, required this.answer});

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['_id'],
      question: json['question'],
      answer: json['answer'],
    );
  }
}
