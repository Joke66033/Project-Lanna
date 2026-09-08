import 'package:flutter/material.dart';
import '../core/api_config.dart';
import '../models/character_stroke_model.dart';
import 'api_service.dart';
import '../page/lean/train/stroke_data.dart' as sd;

class CharacterStrokeService {
  /// Cache of character strokes loaded from API to optimize performance
  static final Map<String, CharacterStrokeModel> _cache = {};

  static CharacterStrokeModel? getCachedStroke(String charSymbol) {
    final cleanChar = charSymbol.trim().replaceAll(RegExp(r'[\u200B-\u200F\uFEFF]'), '');
    return _cache[cleanChar];
  }

  /// Get all character strokes from database
  Future<List<CharacterStrokeModel>> getAllStrokes({String? category}) async {
    try {
      String url = '${ApiConfig.characterStrokes}?action=getAll';
      if (category != null && category.isNotEmpty) {
        url += '&category=$category';
      }
      final data = await ApiService.get(url);
      if (data == null || data is! List) return [];
      final list = data.map((x) => CharacterStrokeModel.fromJson(x as Map<String, dynamic>)).toList();
      for (var item in list) {
        _cache[item.charSymbol] = item;
      }
      return list;
    } catch (e) {
      debugPrint('CharacterStrokeService: getAllStrokes error: $e');
      return [];
    }
  }

  /// Get stroke data by specific character symbol (e.g. 'ᨠ', 'ᨡ')
  Future<CharacterStrokeModel?> getStrokeByChar(String charSymbol, {bool forceRefresh = false}) async {
    final cleanChar = charSymbol.trim().replaceAll(RegExp(r'[\u200B-\u200F\uFEFF]'), '');
    if (!forceRefresh && _cache.containsKey(cleanChar)) {
      return _cache[cleanChar];
    }
    try {
      final encodedChar = Uri.encodeComponent(cleanChar);
      final data = await ApiService.get('${ApiConfig.characterStrokes}?action=getByChar&char=$encodedChar');
      if (data != null && data is Map<String, dynamic>) {
        final model = CharacterStrokeModel.fromJson(data);
        _cache[cleanChar] = model;
        return model;
      }
    } catch (e) {
      debugPrint('CharacterStrokeService: getByChar unavailable, fallback to local: $e');
    }
    return _cache[cleanChar];
  }

  /// Create new character stroke data
  Future<CharacterStrokeModel> createStroke(CharacterStrokeModel model) async {
    final data = await ApiService.post('${ApiConfig.characterStrokes}?action=create', model.toJson());
    final result = CharacterStrokeModel.fromJson(data);
    _cache[result.charSymbol] = result;
    return result;
  }

  /// Update existing character stroke data
  Future<CharacterStrokeModel> updateStroke(int strokeId, Map<String, dynamic> fields) async {
    final data = await ApiService.post('${ApiConfig.characterStrokes}?action=update&id=$strokeId', fields);
    final result = CharacterStrokeModel.fromJson(data);
    _cache[result.charSymbol] = result;
    return result;
  }

  /// Delete stroke data
  Future<dynamic> deleteStroke(int strokeId) async {
    return await ApiService.post('${ApiConfig.characterStrokes}?action=delete&id=$strokeId', {});
  }
}

/// Global helper function to get stroke paths for drawing from database cache first, with local stroke_data as fallback
List<List<Offset>> getStrokeData(String charSymbol) {
  final cleanChar = charSymbol.trim().replaceAll(RegExp(r'[\u200B-\u200F\uFEFF]'), '');
  final cached = CharacterStrokeService.getCachedStroke(cleanChar);
  if (cached != null && cached.strokePaths.isNotEmpty && cached.strokePaths.first.isNotEmpty) {
    return cached.strokePaths;
  }
  final local = sd.getStrokeData(cleanChar);
  return local;
}
