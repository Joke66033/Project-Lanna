import 'vocabulary_model.dart';

class FavoriteModel {
  final String favoriteId;
  final String userId;
  final String vocabId;
  final String? createdAt;
  final VocabularyModel? vocabulary; // Optional joined vocabulary details

  FavoriteModel({
    required this.favoriteId,
    required this.userId,
    required this.vocabId,
    this.createdAt,
    this.vocabulary,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      favoriteId: json['favorite_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      vocabId: json['vocab_id']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
      vocabulary: json['vocabulary'] != null
          ? VocabularyModel.fromJson(json['vocabulary'])
          : (json['lanna_word'] != null
              ? VocabularyModel.fromJson(json) // If it was flattened
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'favorite_id': favoriteId,
      'user_id': userId,
      'vocab_id': vocabId,
      if (createdAt != null) 'created_at': createdAt,
      if (vocabulary != null) 'vocabulary': vocabulary!.toJson(),
    };
  }
}
