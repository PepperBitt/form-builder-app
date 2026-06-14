import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';

class ExportService {
  final _api = ApiClient.instance;

  /// Returns raw Excel file bytes.
  Future<List<int>> downloadExcel(String formId) {
    return _api.getBytes(ApiConstants.exportExcel(formId));
  }

  /// Returns raw PDF file bytes.
  Future<List<int>> downloadPdf(String formId) {
    return _api.getBytes(ApiConstants.exportPdf(formId));
  }

  /// Returns raw CSV file bytes.
  Future<List<int>> downloadCsv(String formId) {
    return _api.getBytes(ApiConstants.exportCsv(formId));
  }

  /// Returns raw JSON file bytes.
  Future<List<int>> downloadJson(String formId) {
    return _api.getBytes(ApiConstants.exportJson(formId));
  }
}
