import 'package:flutter/material.dart';
import '../../../core/models.dart';
import '../../../core/theme/app_theme.dart';

/// Dynamically renders a single form field based on its FieldType.
class DynamicField extends StatefulWidget {
  final FieldModel field;
  final int questionNumber;
  final FormFieldSetter<dynamic>? onSaved;

  const DynamicField({
    super.key,
    required this.field,
    required this.questionNumber,
    this.onSaved,
  });

  @override
  State<DynamicField> createState() => _DynamicFieldState();
}

class _DynamicFieldState extends State<DynamicField> {
  String? _selectedOption;
  int _selectedRating = 0;
  final Set<String> _selectedCheckboxes = {};
  DateTime? _selectedDate;
  final TextEditingController _textCtrl = TextEditingController();

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;

    return FormField<dynamic>(
      validator: (v) {
        if (field.isRequired) {
          switch (field.type) {
            case FieldType.shortText:
            case FieldType.longText:
            case FieldType.email:
            case FieldType.number:
              if (_textCtrl.text.trim().isEmpty) {
                return 'This field is required';
              }
              if (field.type == FieldType.email &&
                  !_textCtrl.text.contains('@')) {
                return 'Enter a valid email';
              }
              break;
            case FieldType.multipleChoice:
              if (_selectedOption == null) return 'Please select an option';
              break;
            case FieldType.rating:
              if (_selectedRating == 0) return 'Please select a rating';
              break;
            case FieldType.date:
              if (_selectedDate == null) return 'Please select a date';
              break;
            default:
              break;
          }
        }
        return null;
      },
      onSaved: (v) {
        switch (field.type) {
          case FieldType.shortText:
          case FieldType.longText:
          case FieldType.email:
          case FieldType.number:
            widget.onSaved?.call(_textCtrl.text);
            break;
          case FieldType.multipleChoice:
            widget.onSaved?.call(_selectedOption);
            break;
          case FieldType.checkbox:
            widget.onSaved?.call(_selectedCheckboxes.toList());
            break;
          case FieldType.rating:
            widget.onSaved?.call(_selectedRating);
            break;
          case FieldType.date:
            widget.onSaved?.call(_selectedDate?.toIso8601String());
            break;
          default:
            widget.onSaved?.call(null);
        }
      },
      builder: (state) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: state.hasError ? AppColors.danger : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question label
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${widget.questionNumber}. ',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    TextSpan(
                      text: field.label.isEmpty
                          ? '${field.type.label} Question'
                          : field.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (field.isRequired)
                      const TextSpan(
                        text: ' *',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              if (field.helperText.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  field.helperText,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
              ],
              const SizedBox(height: 12),

              // Field input
              _buildInput(field, state),

              if (state.hasError) ...[
                const SizedBox(height: 6),
                Text(
                  state.errorText!,
                  style: const TextStyle(fontSize: 12, color: AppColors.danger),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInput(FieldModel field, FormFieldState state) {
    switch (field.type) {
      case FieldType.shortText:
        return _TextInput(
            controller: _textCtrl, onChanged: (v) => state.didChange(v));

      case FieldType.longText:
        return _TextInput(
          controller: _textCtrl,
          maxLines: 4,
          hint: 'Your answer...',
          onChanged: (v) => state.didChange(v),
        );

      case FieldType.email:
        return _TextInput(
          controller: _textCtrl,
          hint: 'name@example.com',
          keyboardType: TextInputType.emailAddress,
          onChanged: (v) => state.didChange(v),
        );

      case FieldType.number:
        return _TextInput(
          controller: _textCtrl,
          hint: '0',
          keyboardType: TextInputType.number,
          onChanged: (v) => state.didChange(v),
        );

      case FieldType.multipleChoice:
        return Column(
          children: field.options.isEmpty
              ? [
                  _OptionTile(
                    label: 'Option 1',
                    selected: _selectedOption == 'Option 1',
                    onTap: () => setState(() => _selectedOption = 'Option 1'),
                  ),
                ]
              : field.options.map((opt) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _OptionTile(
                      label: opt,
                      selected: _selectedOption == opt,
                      onTap: () {
                        setState(() => _selectedOption = opt);
                        state.didChange(opt);
                      },
                    ),
                  );
                }).toList(),
        );

      case FieldType.checkbox:
        return Column(
          children: field.options.isEmpty
              ? [
                  _CheckboxTile(
                    label: 'Option 1',
                    selected: _selectedCheckboxes.contains('Option 1'),
                    onChanged: (v) {
                      setState(() {
                        if (v!) {
                          _selectedCheckboxes.add('Option 1');
                        } else {
                          _selectedCheckboxes.remove('Option 1');
                        }
                      });
                      state.didChange(_selectedCheckboxes.toList());
                    },
                  ),
                ]
              : field.options.map((opt) {
                  return _CheckboxTile(
                    label: opt,
                    selected: _selectedCheckboxes.contains(opt),
                    onChanged: (v) {
                      setState(() {
                        if (v!) {
                          _selectedCheckboxes.add(opt);
                        } else {
                          _selectedCheckboxes.remove(opt);
                        }
                      });
                      state.didChange(_selectedCheckboxes.toList());
                    },
                  );
                }).toList(),
        );

      case FieldType.rating:
        return Row(
          children: List.generate(
            field.maxRating,
            (i) {
              final starIndex = i + 1;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedRating = starIndex);
                  state.didChange(starIndex);
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    starIndex <= _selectedRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 32,
                    color: starIndex <= _selectedRating
                        ? const Color(0xFFF59E0B)
                        : AppColors.textMuted,
                  ),
                ),
              );
            },
          ),
        );

      case FieldType.date:
        return GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
              state.didChange(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 18, color: AppColors.textMuted),
                const SizedBox(width: 10),
                Text(
                  _selectedDate == null
                      ? 'Select a date'
                      : '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}',
                  style: TextStyle(
                    fontSize: 14,
                    color: _selectedDate == null
                        ? AppColors.textMuted
                        : AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        );

      case FieldType.fileUpload:
        return GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: AppColors.border, style: BorderStyle.solid),
            ),
            child: const Column(
              children: [
                Icon(Icons.cloud_upload_outlined,
                    size: 32, color: AppColors.textMuted),
                SizedBox(height: 8),
                Text(
                  'Click to upload',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary),
                ),
                Text(
                  'or drag and drop',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        );
    }
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  const _TextInput({
    required this.controller,
    this.hint = 'Your answer...',
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.background,
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.textMuted,
                  width: selected ? 5 : 1.5,
                ),
                color: selected ? AppColors.primary : Colors.transparent,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: selected ? AppColors.primary : AppColors.textMed,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckboxTile extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool?> onChanged;

  const _CheckboxTile({
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(value: selected, onChanged: onChanged),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(fontSize: 14, color: AppColors.textMed)),
      ],
    );
  }
}
