import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';

class ExportService {
  final _api = ApiClient.instance;

  /// Returns raw Excel file bytes. Caller decides whether to save/share.
  Future<List<int>> downloadExcel(String formId) {
    return _api.getBytes(ApiConstants.exportExcel(formId));
  }

  Future<List<int>> downloadPdf(String formId) {
    return _api.getBytes(ApiConstants.exportPdf(formId));
  }
}
