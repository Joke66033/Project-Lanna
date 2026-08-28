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
      totalItems: 45,
    ),
    CategoryModel(
      categoryCode: 'LC002',
      title: 'สระล้านนา',
      description: 'เรียนรู้สระจมและสระลอย',
      isActive: true,
      totalItems: 25,
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
      description: 'เรียนรู้ตัวสะกด ห นำ ระวง อักขรวิธี และอักษรพิเศษ',
      isActive: true,
      totalItems: 36,
    ),
  ];

  /// Fetch all active learning categories with robust fallback
  Future<List<CategoryModel>> getActiveCategories() async {
    try {
      final String url = '${ApiConfig.learningCategory}?action=getAll&only_active=true';
      final data = await ApiService.get(url);
      if (data != null && data is List && data.isNotEmpty) {
        final categories = data.map((x) {
          var model = CategoryModel.fromJson(x);
          if (model.totalItems <= 0) {
            final fallback = defaultCategories.firstWhere(
              (d) => d.categoryCode == model.categoryCode,
              orElse: () => model,
            );
            if (fallback.totalItems > 0) {
              model = CategoryModel(
                categoryCode: model.categoryCode,
                title: model.title,
                description: model.description,
                isActive: model.isActive,
                totalItems: fallback.totalItems,
              );
            }
          }
          return model;
        }).where((c) => c.isActive).toList();
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
