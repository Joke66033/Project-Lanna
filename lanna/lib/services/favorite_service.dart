import '../core/api_config.dart';
import '../models/favorite_model.dart';
import 'api_service.dart';

class FavoriteService {
  /// Get all favorites
  Future<List<FavoriteModel>> getAllFavorites() async {
    final data = await ApiService.get('${ApiConfig.favorites}?action=getAll');
    if (data == null) return [];
    return (data as List).map((x) => FavoriteModel.fromJson(x)).toList();
  }

  /// Get favorite by ID
  Future<FavoriteModel?> getFavoriteById(String id) async {
    final data = await ApiService.get('${ApiConfig.favorites}?action=getById&id=$id');
    if (data == null) return null;
    return FavoriteModel.fromJson(data);
  }

  /// Get favorites by User ID
  Future<List<FavoriteModel>> getFavoritesByUserId(String userId) async {
    final data = await ApiService.get('${ApiConfig.favorites}?action=getByUserId&userId=$userId');
    if (data == null) return [];
    return (data as List).map((x) => FavoriteModel.fromJson(x)).toList();
  }

  /// Create new favorite (user_id and vocab_id)
  Future<FavoriteModel> createFavorite(String userId, String vocabId) async {
    final body = {
      'user_id': userId,
      'vocab_id': vocabId,
    };
    final data = await ApiService.post('${ApiConfig.favorites}?action=create', body);
    return FavoriteModel.fromJson(data);
  }

  /// Delete favorite by ID
  Future<FavoriteModel> deleteFavorite(String id) async {
    final data = await ApiService.post('${ApiConfig.favorites}?action=delete&id=$id', {});
    return FavoriteModel.fromJson(data);
  }
}
