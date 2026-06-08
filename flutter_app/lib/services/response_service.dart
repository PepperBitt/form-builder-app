import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../core/models.dart';

class ResponseService {
  final _api = ApiClient.instance;

  /// POST /api/responses/submit
  ///
  /// Backend's schema_engine validates response_data keys against field LABELS
  /// (not field ids), so we translate the Flutter `{fieldId: value}` map into
  /// `{fieldLabel: value}` before sending.
  Future<String> submitResponse(
    String formId,
    Map<String, dynamic> answersByFieldId,
    List<FieldModel> formFields,
  ) async {
    final answersByLabel = <String, dynamic>{};
    for (final field in formFields) {
      if (answersByFieldId.containsKey(field.id)) {
        answersByLabel[field.label] = answersByFieldId[field.id];
      }
    }

    final res = await _api.post(ApiConstants.submitResponse, body: {
      'form_id': formId,
      'response_data': answersByLabel,
    }) as Map<String, dynamic>;

    return res['response_id'] as String;
  }

  /// GET /api/responses/{formId}?skip=&limit=
  Future<List<ResponseModel>> getResponses(String formId,
      {int skip = 0, int limit = 100}) async {
    final path = '${ApiConstants.getResponses(formId)}?skip=$skip&limit=$limit';
    final res = await _api.get(path) as Map<String, dynamic>;
    final data = (res['data'] ?? []) as List<dynamic>;

    return data.map((item) {
      final m = item as Map<String, dynamic>;
      return ResponseModel(
        id: m['response_id'] as String,
        formId: formId,
        data: (m['answers'] ?? {}) as Map<String, dynamic>,
        submittedAt: DateTime.tryParse(m['submitted_at']?.toString() ?? '') ?? DateTime.now(),
      );
    }).toList();
  }

  /// GET /api/responses/{formId}/analytics
  Future<Map<String, dynamic>> getAnalytics(String formId) async {
    final res = await _api.get(ApiConstants.getAnalytics(formId));
    return res as Map<String, dynamic>;
  }
}
