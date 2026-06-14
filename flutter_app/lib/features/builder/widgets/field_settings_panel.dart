import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/form_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models.dart';

class FieldSettingsPanel extends StatefulWidget {
  final FieldModel field;
  const FieldSettingsPanel({super.key, required this.field});

  @override
  State<FieldSettingsPanel> createState() => _FieldSettingsPanelState();
}

class _FieldSettingsPanelState extends State<FieldSettingsPanel> {
  late TextEditingController _labelCtrl;
  late TextEditingController _helperCtrl;
  // One controller per option — rebuilt when field changes
  List<TextEditingController> _optionCtrls = [];

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.field.label);
    _helperCtrl = TextEditingController(text: widget.field.helperText);
    _buildOptionControllers();
  }

  void _buildOptionControllers() {
    for (final c in _optionCtrls) {
      c.dispose();
    }
    _optionCtrls = widget.field.options
        .map((opt) => TextEditingController(text: opt))
        .toList();
  }

  @override
  void didUpdateWidget(FieldSettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.field.id != widget.field.id) {
      // switched to a different field — rebuild everything
      _labelCtrl.text = widget.field.label;
      _helperCtrl.text = widget.field.helperText;
      _buildOptionControllers();
      setState(() {});
    } else if (oldWidget.field.options.length != widget.field.options.length) {
      // option was added/removed — rebuild option controllers
      _buildOptionControllers();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _helperCtrl.dispose();
    for (final c in _optionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final forms = context.watch<FormProvider>();
    final field = widget.field;

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(_fieldIcon(field.type),
                      size: 15, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    field.type.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 18, color: AppColors.textLight),
                  onPressed: forms.deselectField,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Scrollable body ──────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FIELD LABEL
                  const _Label('FIELD LABEL'),
                  const SizedBox(height: 5),
                  _Input(
                    controller: _labelCtrl,
                    hint: 'Enter your question...',
                    onChanged: (v) => forms.updateFieldLabel(field.id, v),
                  ),
                  const SizedBox(height: 14),

                  // HELPER TEXT
                  const _Label('HELPER TEXT'),
                  const SizedBox(height: 5),
                  _Input(
                    controller: _helperCtrl,
                    hint: 'Optional description...',
                    maxLines: 2,
                    onChanged: (v) => forms.updateFieldHelperText(field.id, v),
                  ),
                  const SizedBox(height: 18),

                  // ── Options editor (Multiple Choice / Checkbox) ──
                  if (field.type == FieldType.multipleChoice ||
                      field.type == FieldType.checkbox) ...[
                    Row(
                      children: [
                        const _Label('OPTIONS'),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            forms.addOption(field.id);
                            // controller will be rebuilt in didUpdateWidget
                          },
                          child: const Row(
                            children: [
                              Icon(Icons.add,
                                  size: 14, color: AppColors.primary),
                              SizedBox(width: 3),
                              Text(
                                'Add',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._buildOptionRows(field, forms),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => forms.addOption(field.id),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.border,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add,
                                size: 16, color: AppColors.textLight),
                            SizedBox(width: 6),
                            Text(
                              'Add Option',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ToggleRow(
                      title: 'Randomize',
                      subtitle: 'Shuffle option order',
                      value: field.randomize,
                      onChanged: (_) => forms.toggleRandomize(field.id),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // ── Rating scale ─────────────────────────────────
                  if (field.type == FieldType.rating) ...[
                    Row(
                      children: [
                        const _Label('RATING SCALE'),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '1 – ${field.maxRating}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Row of numbered boxes 1-10
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(10, (i) {
                        final val = i + 1;
                        final active = val <= field.maxRating;
                        return GestureDetector(
                          onTap: () => forms.updateMaxRating(field.id, val),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.primary
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: active
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$val',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: active
                                      ? Colors.white
                                      : AppColors.textLight,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap a number to set the maximum rating.',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // ── Date field info ──────────────────────────────
                  if (field.type == FieldType.date) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: AppColors.primary),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Respondents will see a date picker popup when they tap this field.',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // ── File Upload info ─────────────────────────────
                  if (field.type == FieldType.fileUpload) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.draftBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: AppColors.draft),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Respondents can upload files. Max 10 MB per file.',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.draft),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // ── Required toggle (all fields) ─────────────────
                  _ToggleRow(
                    title: 'Required',
                    subtitle: 'Respondent must answer',
                    value: field.isRequired,
                    onChanged: (_) => forms.toggleRequired(field.id),
                  ),
                  const SizedBox(height: 20),

                  const Divider(),
                  const SizedBox(height: 10),

                  // ── Preview chip ─────────────────────────────────
                  const _Label('QUICK PREVIEW'),
                  const SizedBox(height: 8),
                  _FieldPreview(field: field),
                  const SizedBox(height: 20),

                  const Divider(),
                  const SizedBox(height: 10),

                  // ── Delete ───────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => forms.removeField(field.id),
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 16, color: AppColors.danger),
                      label: const Text(
                        'Delete Field',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.danger),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build option input rows ────────────────────────────────────────────
  List<Widget> _buildOptionRows(FieldModel field, FormProvider forms) {
    return List.generate(_optionCtrls.length, (i) {
      final ctrl = _optionCtrls[i];
      final isChoice = field.type == FieldType.multipleChoice;
      return Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(
          children: [
            // Radio / Checkbox indicator
            Icon(
              isChoice
                  ? Icons.radio_button_unchecked_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: ctrl,
                style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                decoration: InputDecoration(
                  hintText: 'Option ${i + 1}',
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                ),
                onChanged: (v) => forms.updateOption(field.id, i, v),
              ),
            ),
            const SizedBox(width: 6),
            // Delete option — always keep at least 1
            GestureDetector(
              onTap: field.options.length > 1
                  ? () => forms.removeOption(field.id, i)
                  : null,
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: field.options.length > 1
                    ? AppColors.textLight
                    : AppColors.border,
              ),
            ),
          ],
        ),
      );
    });
  }

  IconData _fieldIcon(FieldType type) {
    switch (type) {
      case FieldType.shortText:
        return Icons.notes_rounded;
      case FieldType.longText:
        return Icons.subject_rounded;
      case FieldType.email:
        return Icons.alternate_email_rounded;
      case FieldType.number:
        return Icons.pin_rounded;
      case FieldType.multipleChoice:
        return Icons.radio_button_checked_rounded;
      case FieldType.checkbox:
        return Icons.check_box_rounded;
      case FieldType.rating:
        return Icons.star_half_rounded;
      case FieldType.date:
        return Icons.calendar_today_rounded;
      case FieldType.fileUpload:
        return Icons.upload_file_rounded;
    }
  }
}

// ── Quick Field Preview ───────────────────────────────────────────────────
class _FieldPreview extends StatelessWidget {
  final FieldModel field;
  const _FieldPreview({required this.field});

  @override
  Widget build(BuildContext context) {
    switch (field.type) {
      case FieldType.shortText:
      case FieldType.email:
      case FieldType.number:
        return _previewContainer(
          child: Text(
            field.type == FieldType.email ? 'name@example.com' : 'User input…',
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        );

      case FieldType.longText:
        return _previewContainer(
          height: 60,
          child: const Align(
            alignment: Alignment.topLeft,
            child: Text(
              'Longer answer…',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
        );

      case FieldType.multipleChoice:
        return Column(
          children: field.options
              .take(3)
              .map((opt) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.radio_button_unchecked_rounded,
                            size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 8),
                        Text(opt,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textMed)),
                      ],
                    ),
                  ))
              .toList(),
        );

      case FieldType.checkbox:
        return Column(
          children: field.options
              .take(3)
              .map((opt) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.check_box_outline_blank_rounded,
                            size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 8),
                        Text(opt,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textMed)),
                      ],
                    ),
                  ))
              .toList(),
        );

      case FieldType.rating:
        return Row(
          children: List.generate(
            field.maxRating > 5 ? 5 : field.maxRating,
            (i) => const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.star_outline_rounded,
                  size: 24, color: AppColors.draft),
            ),
          ),
        );

      case FieldType.date:
        return _previewContainer(
          child: const Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 16, color: AppColors.textMuted),
              SizedBox(width: 8),
              Text('mm/dd/yyyy',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            ],
          ),
        );

      case FieldType.fileUpload:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            children: [
              Icon(Icons.cloud_upload_outlined,
                  size: 22, color: AppColors.textMuted),
              SizedBox(height: 4),
              Text('Upload file',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        );
    }
  }

  Widget _previewContainer({required Widget child, double height = 38}) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
          color: AppColors.textLight,
        ),
      );
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final int maxLines;

  const _Input({
    required this.controller,
    required this.hint,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  )),
              Text(subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  )),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}
