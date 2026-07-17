class ArticleModel {
  final String articleId;
  final String title;
  final String content;
  final String? coverImage;
  final String? imagePath;
  final String? categoryCharId;
  final String? authorId;
  final String? createdAt;

  ArticleModel({
    required this.articleId,
    required this.title,
    required this.content,
    this.coverImage,
    this.imagePath,
    this.categoryCharId,
    this.authorId,
    this.createdAt,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      articleId: (json['article_id'] ?? json['id'])?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      coverImage: json['cover_image']?.toString(),
      imagePath: json['image_path']?.toString(),
      categoryCharId: json['category_char_id']?.toString(),
      authorId: json['author_id']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'article_id': articleId,
      'title': title,
      'content': content,
      if (coverImage != null) 'cover_image': coverImage,
      if (imagePath != null) 'image_path': imagePath,
      if (categoryCharId != null) 'category_char_id': categoryCharId,
      if (authorId != null) 'author_id': authorId,
      if (createdAt != null) 'created_at': createdAt,
    };
  }
}
