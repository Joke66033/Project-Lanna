class LannaCharModel {
  final String? lannaCharId;
  final String lannaChar;
  final String thaiEquivalent;
  final String categoryCharId;
  final String? categoryName; // Optional joined category name from endpoints

  const LannaCharModel({
    this.lannaCharId,
    required this.lannaChar,
    required this.thaiEquivalent,
    required this.categoryCharId,
    this.categoryName,
  });

  factory LannaCharModel.fromJson(Map<String, dynamic> json) {
    String? catName;
    if (json['category_lanna_char'] is Map) {
      catName = json['category_lanna_char']['name']?.toString();
    }
    return LannaCharModel(
      lannaCharId: (json['char_id'] ?? json['lanna_char_id'])?.toString().trim(),
      lannaChar: json['lanna_char']?.toString() ?? '',
      thaiEquivalent: json['thai_equivalent']?.toString() ?? '',
      categoryCharId: json['category_char_id']?.toString() ?? '',
      categoryName: catName ?? json['category_name']?.toString() ?? json['category']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (lannaCharId != null) 'char_id': lannaCharId,
      if (lannaCharId != null) 'lanna_char_id': lannaCharId,
      'lanna_char': lannaChar,
      'thai_equivalent': thaiEquivalent,
      'category_char_id': categoryCharId,
      if (categoryName != null) 'category_name': categoryName,
    };
  }
}
