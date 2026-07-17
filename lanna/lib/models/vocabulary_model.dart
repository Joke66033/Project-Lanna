class VocabularyModel {
  final String vocabId;
  final String lannaWord;
  final String thaiWord;
  final String reading;
  final String meaning;
  final String categoryVocabId;
  final String? category; // Joined category name

  VocabularyModel({
    required this.vocabId,
    required this.lannaWord,
    required this.thaiWord,
    required this.reading,
    required this.meaning,
    required this.categoryVocabId,
    this.category,
  });

  factory VocabularyModel.fromJson(Map<String, dynamic> json) {
    return VocabularyModel(
      vocabId: json['vocab_id']?.toString() ?? '',
      lannaWord: json['lanna_word']?.toString() ?? '',
      thaiWord: json['thai_word']?.toString() ?? '',
      reading: json['reading']?.toString() ?? '',
      meaning: json['meaning']?.toString() ?? '',
      categoryVocabId: json['category_vocab_id']?.toString() ?? '',
      category: json['category']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vocab_id': vocabId,
      'lanna_word': lannaWord,
      'thai_word': thaiWord,
      'reading': reading,
      'meaning': meaning,
      'category_vocab_id': categoryVocabId,
      if (category != null) 'category': category,
    };
  }
}
