import '../core/api_config.dart';
import '../models/translate_log_model.dart';
import 'api_service.dart';

class TranslateLogService {
  /// Get all translate logs
  Future<List<TranslateLogModel>> getAllLogs() async {
    final data = await ApiService.get('${ApiConfig.translateLogs}?action=getAll');
    if (data == null) return [];
    return (data as List).map((x) => TranslateLogModel.fromJson(x)).toList();
  }

  /// Get log by ID
  Future<TranslateLogModel?> getLogById(String id) async {
    final data = await ApiService.get('${ApiConfig.translateLogs}?action=getById&id=$id');
    if (data == null) return null;
    return TranslateLogModel.fromJson(data);
  }

  /// Create new log entry
  Future<TranslateLogModel> createLog(String userId, String inputText, String outputText) async {
    final body = {
      'user_id': userId,
      'input_text': inputText,
      'output_text': outputText,
    };
    final data = await ApiService.post('${ApiConfig.translateLogs}?action=create', body);
    return TranslateLogModel.fromJson(data);
  }

  /// Delete log entry
  Future<TranslateLogModel> deleteLog(String id) async {
    final data = await ApiService.post('${ApiConfig.translateLogs}?action=delete&id=$id', {});
    return TranslateLogModel.fromJson(data);
  }
}
