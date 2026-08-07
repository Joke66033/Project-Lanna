import '../core/api_config.dart';
import '../models/category_model.dart';
import 'api_service.dart';

class LearningCategoryService {
  static final List<CategoryModel> defaultCategories = [
    CategoryModel(
      categoryCode: 'LC001',
      title: 'พยัญชนะล้านนา',
      description: 'เรียนรู้พยัญชนะตั๋วเมืองและเสียงอ่าน',
      isActive: true,
      totalItems: 55,
    ),
    CategoryModel(
      categoryCode: 'LC002',
      title: 'สระล้านนา',
      description: 'เรียนรู้สระจมและสระลอย',
      isActive: true,
      totalItems: 19,
    ),
    CategoryModel(
      categoryCode: 'LC003',
      title: 'วรรณยุกต์ล้านนา',
      description: 'เรียนรู้วรรณยุกต์และเครื่องหมายพิเศษ',
      isActive: true,
      totalItems: 7,
    ),
    CategoryModel(
      categoryCode: 'LC004',
      title: 'ตัวเลขล้านนา',
      description: 'เรียนรู้ตัวเลขธัมม์และเลขโหรา',
      isActive: true,
      totalItems: 20,
    ),
    CategoryModel(
      categoryCode: 'LC005',
      title: 'ตัวสะกดล้านนา',
      description: 'เรียนรู้ตัวสะกดและ ห นำ',
      isActive: true,
      totalItems: 62,
    ),
  ];

  /// Fetch all active learning categories with robust fallback
  Future<List<CategoryModel>> getActiveCategories() async {
    try {
      final String url = '${ApiConfig.learningCategory}?action=getAll&only_active=true';
      final data = await ApiService.get(url);
      if (data != null && data is List && data.isNotEmpty) {
        final categories = data
            .map((x) => CategoryModel.fromJson(x))
            .where((c) => c.isActive)
            .toList();
        if (categories.isNotEmpty) {
          return categories;
        }
      }
    } catch (e) {
      // Fallback seamlessly on server connection error or CORS restriction
    }
    return defaultCategories.where((c) => c.isActive).toList();
  }
}
