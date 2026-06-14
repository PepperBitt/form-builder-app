import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/form_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models.dart';
import 'widgets/field_settings_panel.dart';
import '../../widgets/app_logo.dart';

class FormBuilderScreen extends StatefulWidget {
  final String formId;
  const FormBuilderScreen({super.key, required this.formId});

  @override
  State<FormBuilderScreen> createState() => _FormBuilderScreenState();
}

class _FormBuilderScreenState extends State<FormBuilderScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final forms = context.read<FormProvider>();
      final active = forms.activeForm;
      final shouldLoadSavedForm = !widget.formId.startsWith('draft_') &&
          (active == null || active.id != widget.formId || active.fields.isEmpty);

      if (shouldLoadSavedForm) {
        forms.loadFormById(widget.formId).then((_) {
          if (mounted && forms.activeForm != null) {
            _titleCtrl.text = forms.activeForm!.title;
            _descCtrl.text = forms.activeForm!.description;
          }
        });
      }
      if (mounted && forms.activeForm != null && _titleCtrl.text.isEmpty) {
        _titleCtrl.text = forms.activeForm!.title;
        _descCtrl.text = forms.activeForm!.description;
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _openFieldSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FieldSelectorSheet(
        onSelect: (type) {
          context.read<FormProvider>().addField(type);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final forms = context.watch<FormProvider>();
    final form = forms.activeForm;
    if (form == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final hasSettingsPanel = forms.selectedField != null;
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 640;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: _ArchitectLogo(),
        actions: [
          // Preview button
          IconButton(
            icon: const Icon(Icons.visibility_outlined, size: 20, color: AppColors.textMed),
            onPressed: () => context.push('/form/${form.id}'),
            tooltip: 'Preview Form',
          ),
          // Save button
          TextButton(
            onPressed: forms.isLoading
                ? null
                : () async {
                    final success = await forms.saveForm();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? 'Form saved successfully'
                            : 'Save failed: ${forms.error ?? "Unknown error"}'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  },
            child: forms.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save', style: TextStyle(color: AppColors.primary)),
          ),
          // Publish toggle
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => forms.toggleFormLive(form.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: form.isLive ? AppColors.live : AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  form.isLive ? '● LIVE' : 'Publish',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Form title editor
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: TextField(
                  controller: _titleCtrl,
                  onChanged: (v) {
                    form.title = v;
                  },
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Form title...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const Divider(height: 1),

              // Main builder area
              Expanded(
                child: Row(
                  children: [
                    // Fields canvas
                    Expanded(
                      child: form.fields.isEmpty
                          ? _EmptyCanvas(
                              onAddField: () => setState(() => _showFieldSelector = true),
                            )
                          : _FieldsCanvas(
                              form: form,
                              onAddField: () =>
                                  setState(() => _showFieldSelector = true),
                            ),
                    ),

                    // Right panel: field settings
                    if (forms.selectedField != null)
                      FieldSettingsPanel(
                        field: forms.selectedField!,
                      ),
                  ],
                ),
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Flexible(
                    child: FieldSettingsPanel(field: forms.selectedField!),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Field Library Sidebar (desktop left panel)
// ─────────────────────────────────────────────────────────────────────────────

class _FieldLibrarySidebar extends StatelessWidget {
  final ValueChanged<FieldType> onAdd;
  const _FieldLibrarySidebar({required this.onAdd});

  static const _categories = [
    ('Text', [FieldType.shortText, FieldType.longText, FieldType.email]),
    ('Numbers & Data', [FieldType.number, FieldType.date]),
    ('Choice', [FieldType.multipleChoice, FieldType.checkbox]),
    ('Media', [FieldType.rating, FieldType.fileUpload]),
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onAddField,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                width: 160,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.background,
                ),
                child: Column(
                  children: [
                    const Icon(Icons.add_box_outlined,
                        size: 32, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    const Text(
                      'Drop a field\nhere',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'or click to choose\nfrom the menu',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _fieldIcon(FieldType type) {
    switch (type) {
      case FieldType.shortText:
        return Icons.short_text_rounded;
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

// ─────────────────────────────────────────────────────────────────────────────
// Builder Canvas (center area)
// ─────────────────────────────────────────────────────────────────────────────

class _BuilderCanvas extends StatelessWidget {
  final FormModel form;
  final VoidCallback onAddField;

  const _BuilderCanvas({required this.form, required this.onAddField});

  @override
  Widget build(BuildContext context) {
    if (form.fields.isEmpty) {
      return _EmptyCanvas(onAddField: onAddField);
    }

    final formProvider = context.read<FormProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        // Field count badge
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(
                '${form.fields.length} field${form.fields.length == 1 ? '' : 's'}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textLight,
                ),
              ),
              const Spacer(),
              Text(
                'Drag to reorder',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.drag_handle_rounded,
                  size: 14, color: AppColors.textMuted),
            ],
          ),
        ),

        // Reorderable field list
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorder: (oldIndex, newIndex) {
            formProvider.reorderFields(oldIndex, newIndex);
          },
          itemCount: form.fields.length,
          itemBuilder: (context, index) {
            final field = form.fields[index];
            return _FieldTile(
              key: ValueKey(field.id),
              field: field,
              index: index,
            );
          },
        ),

        const SizedBox(height: 16),

        // Add field button (inline, at bottom of list)
        _AddFieldButton(onTap: onAddField),
      ],
    );
  }
}

class _AddFieldButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AddFieldButton({required this.onTap});

  @override
  State<_AddFieldButton> createState() => _AddFieldButtonState();
}

class _AddFieldButtonState extends State<_AddFieldButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.border,
              style: BorderStyle.solid,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_rounded,
                size: 16,
                color: _hovered ? AppColors.primary : AppColors.textLight,
              ),
              const SizedBox(width: 8),
              Text(
                'Add a Field',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _hovered ? AppColors.primary : AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty Canvas
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyCanvas extends StatelessWidget {
  final VoidCallback onAddField;
  const _EmptyCanvas({required this.onAddField});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.add_box_outlined,
                  size: 34, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'Your form is empty',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pick a field type from the sidebar\nor tap the button below to get started.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textLight,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onAddField,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'Add First Field',
                style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Field Tile (canvas item)
// ─────────────────────────────────────────────────────────────────────────────

class _FieldTile extends StatefulWidget {
  final FieldModel field;
  final int index;

  const _FieldTile({super.key, required this.field, required this.index});

  @override
  State<_FieldTile> createState() => _FieldTileState();
}

class _FieldTileState extends State<_FieldTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final formProvider = context.read<FormProvider>();
    final isSelected =
        context.watch<FormProvider>().selectedField?.id == widget.field.id;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => formProvider.selectField(widget.field),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryLight.withValues(alpha: 0.6)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : _hovered
                      ? AppColors.primary.withValues(alpha: 0.35)
                      : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : _hovered
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                // Field type icon
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _fieldIcon(widget.field.type),
                    size: 16,
                    color: isSelected ? AppColors.primary : AppColors.textLight,
                  ),
                ),
                const SizedBox(width: 12),

                // Label + type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.field.label.isEmpty
                            ? '${widget.field.type.label} Question'
                            : widget.field.label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            widget.field.type.label,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textLight,
                            ),
                          ),
                          if (widget.field.isRequired) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.dangerLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Required',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions (visible on hover/selected)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: _hovered || isSelected ? 1.0 : 0.0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Delete
                      _TileAction(
                        icon: Icons.delete_outline_rounded,
                        color: AppColors.danger,
                        tooltip: 'Remove field',
                        onTap: () =>
                            formProvider.removeField(widget.field.id),
                      ),
                      const SizedBox(width: 4),
                      // Drag handle
                      ReorderableDragStartListener(
                        index: widget.index,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: AppColors.background,
                          ),
                          child: const Icon(Icons.drag_handle_rounded,
                              size: 15, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _fieldIcon(FieldType type) {
    switch (type) {
      case FieldType.shortText:
        return Icons.short_text_rounded;
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

class _TileAction extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _TileAction(
      {required this.icon,
      required this.color,
      required this.tooltip,
      required this.onTap});

  @override
  State<_TileAction> createState() => _TileActionState();
}

class _TileActionState extends State<_TileAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(widget.icon, size: 15, color: widget.color),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Field Selector Bottom Sheet (replaces the overlay — fixes overflow)
// ─────────────────────────────────────────────────────────────────────────────

class _FieldSelectorSheet extends StatelessWidget {
  final ValueChanged<FieldType> onSelect;

  const _FieldSelectorSheet({required this.onSelect});

  static const _fieldTypes = [
    (FieldType.shortText, Icons.short_text_rounded, 'Short Text', 'Single line answer'),
    (FieldType.longText, Icons.subject_rounded, 'Long Text', 'Multi-line answer'),
    (FieldType.email, Icons.alternate_email_rounded, 'Email', 'Email address input'),
    (FieldType.number, Icons.pin_rounded, 'Number', 'Numeric input'),
    (FieldType.multipleChoice, Icons.radio_button_checked_rounded, 'Multiple Choice', 'One answer from list'),
    (FieldType.checkbox, Icons.check_box_rounded, 'Checkboxes', 'Multiple selections'),
    (FieldType.rating, Icons.star_half_rounded, 'Rating', 'Star rating scale'),
    (FieldType.date, Icons.calendar_today_rounded, 'Date', 'Date picker'),
    (FieldType.fileUpload, Icons.upload_file_rounded, 'File Upload', 'Attach a file'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // Use DraggableScrollableSheet-style container with max height
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Text(
                  'Add a Field',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close_rounded,
                        size: 15, color: AppColors.textLight),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable grid of field types
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _fieldTypes.map((item) {
                  return _FieldTypeCard(
                    type: item.$1,
                    icon: item.$2,
                    label: item.$3,
                    description: item.$4,
                    onTap: () => onSelect(item.$1),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldTypeCard extends StatefulWidget {
  final FieldType type;
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _FieldTypeCard({
    required this.type,
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  State<_FieldTypeCard> createState() => _FieldTypeCardState();
}

class _FieldTypeCardState extends State<_FieldTypeCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_icon(type), size: 24, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(
              type.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textMed,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  IconData _icon(FieldType type) {
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

// ── Architect Logo ─────────────────────────────────────────────────────────
class _ArchitectLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GridIcon(),
        const SizedBox(width: 8),
        Flexible(
          child: Text(appName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        ),
      ],
    );
  }
}

class _GridIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _Square()),
                const SizedBox(width: 2),
                Expanded(child: _Square()),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _Square()),
                const SizedBox(width: 2),
                Expanded(child: _Square()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Square extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(2),
        ),
      );
}
