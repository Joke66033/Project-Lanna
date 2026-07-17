import '../core/api_config.dart';
import '../models/article_model.dart';
import 'api_service.dart';

class ArticleService {
  /// Get all articles
  Future<List<ArticleModel>> getAllArticles({String? categoryCharId}) async {
    String url = '${ApiConfig.articles}?action=getAll';
    if (categoryCharId != null && categoryCharId.isNotEmpty) {
      url += '&category_char_id=$categoryCharId';
    }
    final data = await ApiService.get(url);
    if (data == null) return [];
    return (data as List).map((x) => ArticleModel.fromJson(x)).toList();
  }

  /// Get article by ID
  Future<ArticleModel?> getArticleById(String id) async {
    final data = await ApiService.get('${ApiConfig.articles}?action=getById&id=$id');
    if (data == null) return null;
    return ArticleModel.fromJson(data);
  }

  /// Create a new article
  Future<ArticleModel> createArticle(ArticleModel article) async {
    final data = await ApiService.post('${ApiConfig.articles}?action=create', article.toJson());
    return ArticleModel.fromJson(data);
  }

  /// Update an article
  Future<ArticleModel> updateArticle(String id, Map<String, dynamic> fields) async {
    final data = await ApiService.post('${ApiConfig.articles}?action=update&id=$id', fields);
    return ArticleModel.fromJson(data);
  }

  /// Delete an article
  Future<ArticleModel> deleteArticle(String id) async {
    final data = await ApiService.post('${ApiConfig.articles}?action=delete&id=$id', {});
    return ArticleModel.fromJson(data);
  }
}
