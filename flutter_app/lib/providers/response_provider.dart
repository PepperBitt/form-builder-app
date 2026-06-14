import 'package:flutter/material.dart';
import '../core/models.dart';
import '../services/response_service.dart';

class ResponseProvider extends ChangeNotifier {
  final _responseService = ResponseService();

  final Map<String, List<ResponseModel>> _responsesByForm = {};
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ResponseModel> getResponses(String formId) =>
      _responsesByForm[formId] ?? const [];

  int getResponseCount(String formId) => _responsesByForm[formId]?.length ?? 0;

  /// Fetches all responses for a form from the backend and caches them.
  Future<void> loadResponses(String formId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final list = await _responseService.getResponses(formId);
      _responsesByForm[formId] = list;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Submits a response. `formFields` is needed because the backend validates
  /// by field label, so we have to translate {fieldId: value} -> {label: value}.
  Future<bool> submitResponse(
    String formId,
    Map<String, dynamic> data, {
    required List<FieldModel> formFields,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final id =
          await _responseService.submitResponse(formId, data, formFields);
      final response = ResponseModel(
        id: id,
        formId: formId,
        data: data,
        submittedAt: DateTime.now(),
      );
      _responsesByForm.putIfAbsent(formId, () => []);
      _responsesByForm[formId]!.insert(0, response);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
