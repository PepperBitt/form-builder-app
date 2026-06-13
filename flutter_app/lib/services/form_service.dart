import '../core/network/api_client.dart';
import '../core/constants/api_constants.dart';
import '../core/models.dart';

/// Bridges between the Flutter FieldType enum and the simple string
/// `type` that the backend schema stores.
String fieldTypeToBackend(FieldType t) {
  switch (t) {
    case FieldType.shortText:      return 'text';
    case FieldType.longText:       return 'textarea';
    case FieldType.email:          return 'email';
    case FieldType.number:         return 'number';
    case FieldType.multipleChoice: return 'radio';
    case FieldType.checkbox:       return 'checkbox';
    case FieldType.rating:         return 'rating';
    case FieldType.date:           return 'date';
    case FieldType.fileUpload:     return 'file';
  }
}

FieldType fieldTypeFromBackend(String s) {
  switch (s) {
    case 'textarea': return FieldType.longText;
    case 'email':    return FieldType.email;
    case 'number':   return FieldType.number;
    case 'radio':    return FieldType.multipleChoice;
    case 'checkbox': return FieldType.checkbox;
    case 'rating':   return FieldType.rating;
    case 'date':     return FieldType.date;
    case 'file':     return FieldType.fileUpload;
    case 'text':
    default:         return FieldType.shortText;
  }
}

class FormService {
  final _api = ApiClient.instance;

  /// POST /api/forms/create — returns the new form's id.
  Future<String> createForm(FormModel form) async {
    final body = {
      'title': form.title,
      'fields': form.fields.map((f) => {
            'type': fieldTypeToBackend(f.type),
            'label': f.label,
            'required': f.isRequired,
          }).toList(),
    };
    final res = await _api.post(ApiConstants.createForm, body: body) as Map<String, dynamic>;
    return res['form_id'] as String;
  }

  /// GET /api/forms/drafts - list the current user's draft forms.
  Future<List<FormModel>> listForms() async {
    final res = await _api.get(ApiConstants.listForms);
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
        createdAt:
            DateTime.tryParse(m['created_at']?.toString() ?? '') ??
                DateTime.now(),
      );
    }).toList();
  }

  /// GET /api/forms/{id} — fetches full schema including fields.
  Future<FormModel> getForm(String formId) async {
    final res = await _api.get(ApiConstants.getForm(formId)) as Map<String, dynamic>;
    final schema = (res['schema'] ?? {}) as Map<String, dynamic>;
    final rawFields = (schema['fields'] ?? []) as List<dynamic>;

    final fields = rawFields.asMap().entries.map((e) {
      final idx = e.key;
      final f = e.value as Map<String, dynamic>;
      return FieldModel(
        id: 'field_${formId}_$idx',
        type: fieldTypeFromBackend((f['type'] ?? 'text') as String),
        label: (f['label'] ?? '') as String,
        isRequired: (f['required'] ?? false) as bool,
      );
    }).toList();

    return FormModel(
      id: res['form_id'] as String,
      title: (res['title'] ?? 'Untitled') as String,
      fields: fields,
      createdAt: DateTime.now(),
    );
  }
}
