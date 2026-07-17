import '../core/api_config.dart';
import '../models/category_model.dart';
import 'api_service.dart';

class LearningCategoryService {
  /// Fetch all active learning categories
  Future<List<CategoryModel>> getActiveCategories() async {
    final String url = '${ApiConfig.learningCategory}?action=getAll&only_active=true';
    final data = await ApiService.get(url);
    if (data == null) return [];
    return (data as List).map((x) => CategoryModel.fromJson(x)).toList();
  }
}
