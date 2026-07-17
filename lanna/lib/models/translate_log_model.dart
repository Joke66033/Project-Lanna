class TranslateLogModel {
  final String? logId;
  final String userId;
  final String inputText;
  final String outputText;
  final String? createdAt;

  TranslateLogModel({
    this.logId,
    required this.userId,
    required this.inputText,
    required this.outputText,
    this.createdAt,
  });

  factory TranslateLogModel.fromJson(Map<String, dynamic> json) {
    return TranslateLogModel(
      logId: json['log_id']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      inputText: json['input_text']?.toString() ?? '',
      outputText: json['output_text']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (logId != null) 'log_id': logId,
      'user_id': userId,
      'input_text': inputText,
      'output_text': outputText,
      if (createdAt != null) 'created_at': createdAt,
    };
  }
}
