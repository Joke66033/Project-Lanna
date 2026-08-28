class CategoryCharModel {
  final String categoryCharId;
  final String name;
  final String? learningCategoryCode;

  const CategoryCharModel({
    required this.categoryCharId,
    required this.name,
    this.learningCategoryCode,
  });

  factory CategoryCharModel.fromJson(Map<String, dynamic> json) {
    return CategoryCharModel(
      categoryCharId: json['category_char_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      learningCategoryCode: json['learning_category_code']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_char_id': categoryCharId,
      'name': name,
      if (learningCategoryCode != null) 'learning_category_code': learningCategoryCode,
    };
  }
}

class CategoryVocabModel {
  final String categoryVocabId;
  final String name;

  const CategoryVocabModel({
    required this.categoryVocabId,
    required this.name,
  });

  factory CategoryVocabModel.fromJson(Map<String, dynamic> json) {
    return CategoryVocabModel(
      categoryVocabId: json['category_vocab_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_vocab_id': categoryVocabId,
      'name': name,
    };
  }
}

class CategoryModel {
  final String categoryCode;
  final String title;
  final String description;
  final bool isActive;
  final int totalItems;

  const CategoryModel({
    required this.categoryCode,
    required this.title,
    required this.description,
    required this.isActive,
    required this.totalItems,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryCode: json['category_code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      isActive: json['is_active'] == true || json['is_active'] == 1 || json['is_active'] == 'true' || json['is_active'] == '1',
      totalItems: int.tryParse(json['total_items']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_code': categoryCode,
      'title': title,
      'description': description,
      'is_active': isActive,
      'total_items': totalItems,
    };
  }
}
