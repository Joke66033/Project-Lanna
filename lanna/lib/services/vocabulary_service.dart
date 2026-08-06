import '../core/api_config.dart';
import '../models/vocabulary_model.dart';
import '../models/category_model.dart';
import 'api_service.dart';

class VocabularyService {
  /// Translate free-form Thai text through the hybrid dictionary/rule engine.
  Future<Map<String, dynamic>> translate(String text) async {
    final keyword = Uri.encodeQueryComponent(text);
    final data = await ApiService.get(
      '${ApiConfig.vocabulary}?action=translate&keyword=$keyword',
    );
    return Map<String, dynamic>.from(data as Map);
  }

  /// Get all vocabulary items
  Future<List<VocabularyModel>> getAllVocabulary() async {
    final data = await ApiService.get('${ApiConfig.vocabulary}?action=getAll');
    if (data == null) return [];
    return (data as List).map((x) => VocabularyModel.fromJson(x)).toList();
  }

  /// Get vocabulary by ID
  Future<VocabularyModel?> getVocabularyById(String id) async {
    final data = await ApiService.get(
      '${ApiConfig.vocabulary}?action=getById&id=$id',
    );
    if (data == null) return null;
    return VocabularyModel.fromJson(data);
  }

  /// Search vocabulary items by keyword
  Future<List<VocabularyModel>> searchVocabulary(String keyword) async {
    final data = await ApiService.get(
      '${ApiConfig.vocabulary}?action=search&keyword=$keyword',
    );
    if (data == null) return [];
    return (data as List).map((x) => VocabularyModel.fromJson(x)).toList();
  }

  /// Create new vocabulary item
  Future<VocabularyModel> createVocabulary(VocabularyModel item) async {
    final data = await ApiService.post(
      '${ApiConfig.vocabulary}?action=create',
      item.toJson(),
    );
    return VocabularyModel.fromJson(data);
  }

  /// Update vocabulary item
  Future<VocabularyModel> updateVocabulary(
    String id,
    Map<String, dynamic> fields,
  ) async {
    final data = await ApiService.post(
      '${ApiConfig.vocabulary}?action=update&id=$id',
      fields,
    );
    return VocabularyModel.fromJson(data);
  }

  /// Delete vocabulary item
  Future<VocabularyModel> deleteVocabulary(String id) async {
    final data = await ApiService.post(
      '${ApiConfig.vocabulary}?action=delete&id=$id',
      {},
    );
    return VocabularyModel.fromJson(data);
  }

  // ================= CATEGORIES FOR VOCABULARY =================

  /// Get all vocabulary categories
  Future<List<CategoryVocabModel>> getAllCategories() async {
    final data = await ApiService.get(
      '${ApiConfig.categoryVocab}?action=getAll',
    );
    if (data == null) return [];
    return (data as List).map((x) => CategoryVocabModel.fromJson(x)).toList();
  }

  /// Get vocabulary category by ID
  Future<CategoryVocabModel?> getCategoryById(String id) async {
    final data = await ApiService.get(
      '${ApiConfig.categoryVocab}?action=getById&id=$id',
    );
    if (data == null) return null;
    return CategoryVocabModel.fromJson(data);
  }
}
