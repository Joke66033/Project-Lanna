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
    var list = (data as List).map((x) => LannaCharModel.fromJson(x)).toList();

    // กรองเครื่องหมายควบคุมที่ไม่มีรูปอักขระแสดงผล (เช่น พินทุ / ไม้สะกด ที่เป็นรหัสคำสั่ง) ออก
    list = list.where((c) =>
      c.lannaChar.trim().isNotEmpty &&
      !c.thaiEquivalent.contains('พินทุ') &&
      !c.thaiEquivalent.contains('ไม้สะกด') &&
      !c.thaiEquivalent.contains('เครื่องหมายทำตัวห้อย') &&
      c.lannaChar != '\u1A60' &&
      c.lannaChar != '\u0E3A'
    ).toList();

    int extractIdNum(String id) {
      final match = RegExp(r'\d+').firstMatch(id);
      return match != null ? int.tryParse(match.group(0)!) ?? 0 : 0;
    }
    list.sort((a, b) => extractIdNum(a.charId).compareTo(extractIdNum(b.charId)));

    if (categoryCharId != null && categoryCharId.trim().isNotEmpty) {
      final targetIds = categoryCharId.split(',').map((s) => s.trim().toUpperCase()).toSet();
      return list.where((c) => targetIds.contains(c.categoryCharId.trim().toUpperCase())).toList();
    }
    return list;
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
    final allCats = (data as List).map((x) => CategoryCharModel.fromJson(x)).toList();

    return allCats.where((cat) {
      if (cat.learningCategoryCode != null && cat.learningCategoryCode!.trim().isNotEmpty) {
        return cat.learningCategoryCode!.trim().toUpperCase() == learningCategoryCode.trim().toUpperCase();
      }
      final mappedCode = _mapCategoryCharIdToLearningCode(cat.categoryCharId, cat.name);
      if (mappedCode != null) {
        return mappedCode == learningCategoryCode.trim().toUpperCase();
      }
      return false;
    }).toList();
  }

  static String? _mapCategoryCharIdToLearningCode(String categoryCharId, String name) {
    final id = categoryCharId.trim().toUpperCase();
    if (id == 'CL0001' || id == 'CL0002' || id == 'CL0003' || name.contains('พยัญชนะ')) {
      return 'LC001';
    }
    if (id == 'CL0004' || id == 'CL0005' || name.contains('สระ')) {
      return 'LC002';
    }
    if (id == 'CL0006' || name.contains('วรรณยุกต์')) {
      return 'LC003';
    }
    if (id == 'CL0007' || name.contains('เลข')) {
      return 'LC004';
    }
    if (id == 'CL0008' || id == 'CL0009' || id == 'CL0010' || name.contains('ตัวสะกด') || name.contains('ห นำ') || name.contains('ระวง')) {
      return 'LC005';
    }
    return null;
  }

  /// Get character category by ID
  Future<CategoryCharModel?> getCategoryById(String id) async {
    final data = await ApiService.get('${ApiConfig.categoryLannaChar}?action=getById&id=$id');
    if (data == null) return null;
    return CategoryCharModel.fromJson(data);
  }
}
