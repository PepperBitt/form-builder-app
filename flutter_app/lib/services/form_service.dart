import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../core/models.dart';

/// Bridges between the Flutter FieldType enum and the simple string
/// `type` that the backend schema stores.
String fieldTypeToBackend(FieldType t) {
  switch (t) {
    case FieldType.shortText:
      return 'text';
    case FieldType.longText:
      return 'textarea';
    case FieldType.email:
      return 'email';
    case FieldType.number:
      return 'number';
    case FieldType.multipleChoice:
      return 'radio';
    case FieldType.checkbox:
      return 'checkbox';
    case FieldType.rating:
      return 'rating';
    case FieldType.date:
      return 'date';
    case FieldType.fileUpload:
      return 'file';
  }
}

FieldType fieldTypeFromBackend(String s) {
  switch (s) {
    case 'textarea':
      return FieldType.longText;
    case 'email':
      return FieldType.email;
    case 'number':
      return FieldType.number;
    case 'radio':
      return FieldType.multipleChoice;
    case 'checkbox':
      return FieldType.checkbox;
    case 'rating':
      return FieldType.rating;
    case 'date':
      return FieldType.date;
    case 'file':
      return FieldType.fileUpload;
    case 'text':
    default:
      return FieldType.shortText;
  }
}

class FormService {
  final _api = ApiClient.instance;

  /// POST /api/forms/create — returns the new form's id.
  Future<String> createForm(FormModel form) async {
    final body = {
      'title': form.title,
      'fields': form.fields
          .map((f) => {
                'type': fieldTypeToBackend(f.type),
                'label': f.label,
                'required': f.isRequired,
              })
          .toList(),
    };
    final res = await _api.post(ApiConstants.createForm, body: body)
        as Map<String, dynamic>;
    return res['form_id'] as String;
  }

  /// GET /api/users/me/forms — lists ALL forms (draft + published) for the user.
  Future<List<FormModel>> listForms() async {
    final res = await _api.get(ApiConstants.userForms);
    final items = res is Map<String, dynamic>
        ? (res['items'] as List<dynamic>? ?? const [])
        : res as List<dynamic>;

    return items.map((item) {
      final m = item as Map<String, dynamic>;
      final status = (m['status'] ?? 'draft') as String;

      return FormModel(
        id: m['form_id'] as String,
        title: (m['title'] ?? 'Untitled') as String,
        description: (m['description'] ?? '') as String,
        fields: const [], // list view doesn't include fields; fetch with getForm()
        isLive: status == 'published',
        responseCount: (m['response_count'] ?? 0) as int,
        createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }

  /// GET /api/forms/ — all publicly visible published forms (no auth needed).
  Future<List<FormModel>> fetchPublicForms() async {
    final res = await _api.get(ApiConstants.publicForms);
    final items = res is List<dynamic> ? res : <dynamic>[];
    return items.map((item) {
      final m = item as Map<String, dynamic>;
      return FormModel(
        id: m['form_id'] as String,
        title: (m['title'] ?? 'Untitled') as String,
        description: (m['description'] ?? '') as String,
        fields: const [],
        isLive: true,
        responseCount: (m['total_responses'] ?? m['response_count'] ?? 0) as int,
        createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }

  /// GET /api/forms/{id} — fetches full schema including fields.
  Future<FormModel> getForm(String formId) async {
    final res =
        await _api.get(ApiConstants.getForm(formId)) as Map<String, dynamic>;
    final schema = (res['schema'] ?? {}) as Map<String, dynamic>;
    final rawFields = (schema['fields'] ?? []) as List<dynamic>;

    final fields = rawFields.asMap().entries.map((e) {
      final idx = e.key;
      final f = e.value as Map<String, dynamic>;
      final opts =
          (f['options'] as List<dynamic>?)?.map((o) => o.toString()).toList() ??
              [];
      return FieldModel(
        id: 'field_${formId}_$idx',
        type: fieldTypeFromBackend((f['type'] ?? 'text') as String),
        label: (f['label'] ?? '') as String,
        isRequired: (f['required'] ?? false) as bool,
        options: opts,
        maxRating: (f['max_rating'] ?? 5) as int,
      );
    }).toList();

    final status = (res['status'] ?? 'draft') as String;
    return FormModel(
      id: res['form_id'] as String,
      title: (res['title'] ?? 'Untitled') as String,
      description: (res['description'] ?? '') as String,
      fields: fields,
      isLive: status == 'published',
      responseCount: (res['response_count'] ?? 0) as int,
      createdAt: DateTime.tryParse(res['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// PUT /api/forms/{id} — updates title, description, fields.
  Future<FormModel> updateForm(FormModel form) async {
    final body = {
      'title': form.title,
      'description': form.description,
      'fields': form.fields
          .map((f) => {
                'type': fieldTypeToBackend(f.type),
                'label': f.label,
                'required': f.isRequired,
                'options': f.options,
                'max_rating': f.maxRating,
              })
          .toList(),
    };
    final res = await _api.put(ApiConstants.updateForm(form.id), body: body)
        as Map<String, dynamic>;
    return _formDetailToModel(res);
  }

  /// DELETE /api/forms/{id}
  Future<void> deleteForm(String formId) async {
    await _api.delete(ApiConstants.deleteForm(formId));
  }

  /// POST /api/forms/{id}/publish — returns updated form detail.
  Future<FormModel> publishForm(String formId) async {
    final res = await _api.post(ApiConstants.publishForm(formId))
        as Map<String, dynamic>;
    return _formDetailToModel(res);
  }

  /// POST /api/forms/{id}/unpublish — returns updated form detail.
  Future<FormModel> unpublishForm(String formId) async {
    final res = await _api.post(ApiConstants.unpublishForm(formId))
        as Map<String, dynamic>;
    return _formDetailToModel(res);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  FormModel _formDetailToModel(Map<String, dynamic> res) {
    final schema = (res['schema'] ?? {}) as Map<String, dynamic>;
    final rawFields = (schema['fields'] ?? []) as List<dynamic>;
    final formId = res['form_id'] as String;

    final fields = rawFields.asMap().entries.map((e) {
      final idx = e.key;
      final f = e.value as Map<String, dynamic>;
      final opts =
          (f['options'] as List<dynamic>?)?.map((o) => o.toString()).toList() ??
              [];
      return FieldModel(
        id: 'field_${formId}_$idx',
        type: fieldTypeFromBackend((f['type'] ?? 'text') as String),
        label: (f['label'] ?? '') as String,
        isRequired: (f['required'] ?? false) as bool,
        options: opts,
        maxRating: (f['max_rating'] ?? 5) as int,
      );
    }).toList();

    final status = (res['status'] ?? 'draft') as String;
    return FormModel(
      id: formId,
      title: (res['title'] ?? 'Untitled') as String,
      description: (res['description'] ?? '') as String,
      fields: fields,
      isLive: status == 'published',
      responseCount: (res['response_count'] ?? 0) as int,
      createdAt: DateTime.tryParse(res['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
