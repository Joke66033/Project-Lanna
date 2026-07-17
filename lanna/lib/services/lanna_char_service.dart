import '../core/api_config.dart';
import '../models/lanna_char_model.dart';
import '../models/category_model.dart';
import 'api_service.dart';

class LannaCharService {
  /// Get all Lanna characters
  Future<List<LannaCharModel>> getAllCharacters({String? categoryCharId}) async {
    String url = '${ApiConfig.lannaChar}?action=getAll';
    if (categoryCharId != null && categoryCharId.isNotEmpty) {
      url += '&category_char_id=$categoryCharId';
    }
    final data = await ApiService.get(url);
    if (data == null) return [];
    return (data as List).map((x) => LannaCharModel.fromJson(x)).toList();
  }

  /// Get character by ID
  Future<LannaCharModel?> getCharacterById(String id) async {
    final data = await ApiService.get('${ApiConfig.lannaChar}?action=getById&id=$id');
    if (data == null) return null;
    return LannaCharModel.fromJson(data);
  }

  /// Create new character
  Future<LannaCharModel> createCharacter(LannaCharModel character) async {
    final data = await ApiService.post('${ApiConfig.lannaChar}?action=create', character.toJson());
    return LannaCharModel.fromJson(data);
  }

  /// Update character
  Future<LannaCharModel> updateCharacter(String id, Map<String, dynamic> fields) async {
    final data = await ApiService.post('${ApiConfig.lannaChar}?action=update&id=$id', fields);
    return LannaCharModel.fromJson(data);
  }

  /// Delete character
  Future<LannaCharModel> deleteCharacter(String id) async {
    final data = await ApiService.post('${ApiConfig.lannaChar}?action=delete&id=$id', {});
    return LannaCharModel.fromJson(data);
  }

  // ================= CATEGORIES FOR LANNA CHARACTERS =================

  /// Get all character categories
  Future<List<CategoryCharModel>> getAllCategories() async {
    final data = await ApiService.get('${ApiConfig.categoryLannaChar}?action=getAll');
    if (data == null) return [];
    return (data as List).map((x) => CategoryCharModel.fromJson(x)).toList();
  }

  /// Get all character sub-categories filtered by main category code
  Future<List<CategoryCharModel>> getCategoriesByLearningCode(String learningCategoryCode) async {
    final String url = '${ApiConfig.categoryLannaChar}?action=getAll&learning_category_code=$learningCategoryCode';
    final data = await ApiService.get(url);
    if (data == null) return [];
    return (data as List).map((x) => CategoryCharModel.fromJson(x)).toList();
  }

  /// Get character category by ID
  Future<CategoryCharModel?> getCategoryById(String id) async {
    final data = await ApiService.get('${ApiConfig.categoryLannaChar}?action=getById&id=$id');
    if (data == null) return null;
    return CategoryCharModel.fromJson(data);
  }
}
