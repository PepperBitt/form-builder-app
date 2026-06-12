import 'package:flutter/material.dart';
import '../core/models.dart';
import '../services/form_service.dart';

class FormProvider extends ChangeNotifier {
  final _formService = FormService();

  List<FormModel> _forms = [];
  FormModel? _activeForm;
  FieldModel? _selectedField;
  bool _isLoading = false;
  String? _error;

  List<FormModel> get forms => _forms;
  FormModel? get activeForm => _activeForm;
  FieldModel? get selectedField => _selectedField;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalResponses => _forms.fold(0, (sum, f) => sum + f.responseCount);
  int get activeForms => _forms.where((f) => f.isLive).length;

  // ── Backend fetch ───────────────────────────────────────────────
  Future<void> fetchForms() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _forms = await _formService.listForms();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadFormById(String formId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final form = await _formService.getForm(formId);
      _activeForm = form;
      _selectedField = null;
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  // ── Builder (local UI state — synced to backend on saveForm) ────
  void openFormBuilder(FormModel form) {
    _activeForm = FormModel(
      id: form.id,
      title: form.title,
      description: form.description,
      fields: form.fields.map((f) => f.copyWith()).toList(),
      isLive: form.isLive,
      responseCount: form.responseCount,
      workspaceName: form.workspaceName,
      createdAt: form.createdAt,
    );
    _selectedField = null;
    notifyListeners();
  }

  void createNewForm() {
    final newForm = FormModel(
      id: 'draft_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Untitled Form',
      description: 'Add a description...',
      fields: [],
      isLive: false,
      createdAt: DateTime.now(),
    );
    _activeForm = newForm;
    _selectedField = null;
    notifyListeners();
  }

  void addField(FieldType type) {
    if (_activeForm == null) return;
    final field = FieldModel(
      id: 'field_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      label: '${type.label} Question',
      options: type == FieldType.multipleChoice || type == FieldType.checkbox
          ? ['Option 1', 'Option 2']
          : [],
    );
    _activeForm!.fields.add(field);
    _selectedField = field;
    notifyListeners();
  }

  void removeField(String fieldId) {
    if (_activeForm == null) return;
    _activeForm!.fields.removeWhere((f) => f.id == fieldId);
    if (_selectedField?.id == fieldId) _selectedField = null;
    notifyListeners();
  }

  void selectField(FieldModel field) {
    _selectedField = field;
    notifyListeners();
  }

  void deselectField() {
    _selectedField = null;
    notifyListeners();
  }

  void updateFieldLabel(String fieldId, String label) {
    final field = _activeForm?.fields.firstWhere((f) => f.id == fieldId);
    if (field != null) {
      field.label = label;
      notifyListeners();
    }
  }

  void updateFieldHelperText(String fieldId, String helperText) {
    final field = _activeForm?.fields.firstWhere((f) => f.id == fieldId);
    if (field != null) {
      field.helperText = helperText;
      notifyListeners();
    }
  }

  void toggleRequired(String fieldId) {
    final field = _activeForm?.fields.firstWhere((f) => f.id == fieldId);
    if (field != null) {
      field.isRequired = !field.isRequired;
      if (_selectedField?.id == fieldId) _selectedField = field;
      notifyListeners();
    }
  }

  void toggleRandomize(String fieldId) {
    final field = _activeForm?.fields.firstWhere((f) => f.id == fieldId);
    if (field != null) {
      field.randomize = !field.randomize;
      if (_selectedField?.id == fieldId) _selectedField = field;
      notifyListeners();
    }
  }

  void updateMaxRating(String fieldId, int maxRating) {
    final field = _activeForm?.fields.firstWhere((f) => f.id == fieldId);
    if (field != null) {
      field.maxRating = maxRating;
      if (_selectedField?.id == fieldId) _selectedField = field;
      notifyListeners();
    }
  }

  void addOption(String fieldId) {
    final field = _activeForm?.fields.firstWhere((f) => f.id == fieldId);
    if (field != null) {
      final newOptions = List<String>.from(field.options);
      newOptions.add('Option ${newOptions.length + 1}');
      field.options = newOptions;
      if (_selectedField?.id == fieldId) _selectedField = field;
      notifyListeners();
    }
  }

  void removeOption(String fieldId, int index) {
    final field = _activeForm?.fields.firstWhere((f) => f.id == fieldId);
    if (field != null && field.options.length > 1) {
      final newOptions = List<String>.from(field.options);
      newOptions.removeAt(index);
      field.options = newOptions;
      if (_selectedField?.id == fieldId) _selectedField = field;
      notifyListeners();
    }
  }

  void updateOption(String fieldId, int index, String text) {
    final field = _activeForm?.fields.firstWhere((f) => f.id == fieldId);
    if (field != null && index < field.options.length) {
      final newOptions = List<String>.from(field.options);
      newOptions[index] = text;
      field.options = newOptions;
    }
  }

  void updateFormTitle(String title) {
    if (_activeForm != null) {
      _activeForm!.title = title;
      notifyListeners();
    }
  }

  void updateFormDescription(String description) {
    if (_activeForm != null) {
      _activeForm!.description = description;
      notifyListeners();
    }
  }

  void reorderFields(int oldIndex, int newIndex) {
    if (_activeForm == null) return;
    if (newIndex > oldIndex) newIndex--;
    final item = _activeForm!.fields.removeAt(oldIndex);
    _activeForm!.fields.insert(newIndex, item);
    notifyListeners();
  }

  /// Persists the active form to the backend.
  /// (Backend currently only supports create; update would be a future phase.)
  Future<bool> saveForm() async {
    if (_activeForm == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newId = await _formService.createForm(_activeForm!);
      _activeForm = FormModel(
        id: newId,
        title: _activeForm!.title,
        description: _activeForm!.description,
        fields: _activeForm!.fields,
        isLive: _activeForm!.isLive,
        responseCount: _activeForm!.responseCount,
        workspaceName: _activeForm!.workspaceName,
        createdAt: _activeForm!.createdAt,
      );
      await fetchForms();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleFormLive(String formId) async {
    // Local-only flag — backend does not yet track live/draft state.
    final form = _forms.firstWhere((f) => f.id == formId);
    form.isLive = !form.isLive;
    notifyListeners();
  }

  Future<void> deleteForm(String formId) async {
    // Backend has no delete endpoint yet; remove locally.
    _forms.removeWhere((f) => f.id == formId);
    notifyListeners();
  }
}
