import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/form_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models.dart';
import 'widgets/field_settings_panel.dart';
import '../../app.dart' show appName;

class FormBuilderScreen extends StatefulWidget {
  final String formId;
  const FormBuilderScreen({super.key, required this.formId});

  @override
  State<FormBuilderScreen> createState() => _FormBuilderScreenState();
}

class _FormBuilderScreenState extends State<FormBuilderScreen> {
  final _titleCtrl = TextEditingController();
  bool _showFieldSelector = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final forms = context.read<FormProvider>();
      // If there's no active form, or the id doesn't match the route, fetch it.
      // Drafts (id starts with 'draft_') only exist locally until saved.
      final active = forms.activeForm;
      if (active == null || active.id != widget.formId) {
        if (!widget.formId.startsWith('draft_')) {
          forms.loadFormById(widget.formId).then((_) {
            if (mounted && forms.activeForm != null) {
              _titleCtrl.text = forms.activeForm!.title;
            }
          });
        }
      }
      if (mounted && forms.activeForm != null && _titleCtrl.text.isEmpty) {
        _titleCtrl.text = forms.activeForm!.title;
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final forms = context.watch<FormProvider>();
    final form = forms.activeForm;
    if (form == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

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

              // Bottom toolbar
              _BottomToolbar(
                onInsert: () => setState(() => _showFieldSelector = true),
              ),
            ],
          ),

          // Field selector overlay
          if (_showFieldSelector)
            _FieldSelectorOverlay(
              onSelect: (type) {
                forms.addField(type);
                setState(() => _showFieldSelector = false);
              },
              onDismiss: () => setState(() => _showFieldSelector = false),
            ),
        ],
      ),
    );
  }
}

// ── Empty Canvas ──────────────────────────────────────────────────────────
class _EmptyCanvas extends StatelessWidget {
  final VoidCallback onAddField;
  const _EmptyCanvas({required this.onAddField});

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
}

// ── Fields Canvas ─────────────────────────────────────────────────────────
class _FieldsCanvas extends StatelessWidget {
  final FormModel form;
  final VoidCallback onAddField;

  const _FieldsCanvas({required this.form, required this.onAddField});

  @override
  Widget build(BuildContext context) {
    final formProvider = context.read<FormProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onAddField,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Field'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
}

// ── Field Tile ─────────────────────────────────────────────────────────────
class _FieldTile extends StatelessWidget {
  final FieldModel field;
  final int index;

  const _FieldTile({super.key, required this.field, required this.index});

  @override
  Widget build(BuildContext context) {
    final formProvider = context.read<FormProvider>();
    final isSelected = context.watch<FormProvider>().selectedField?.id == field.id;

    return GestureDetector(
      onTap: () => formProvider.selectField(field),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
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
              : null,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _fieldIcon(field.type),
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    field.label.isEmpty ? '${field.type.label} Question' : field.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    field.type.label,
                    style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              if (field.isRequired)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Required',
                    style: TextStyle(
                        fontSize: 10, color: AppColors.danger, fontWeight: FontWeight.w500),
                  ),
                ),
              const SizedBox(width: 12),
              ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle_rounded,
                    size: 20, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
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

// ── Bottom Toolbar ────────────────────────────────────────────────────────
class _BottomToolbar extends StatelessWidget {
  final VoidCallback onInsert;
  const _BottomToolbar({required this.onInsert});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ElevatedButton.icon(
              onPressed: onInsert,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('INSERT'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const VerticalDivider(width: 1, indent: 12, endIndent: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ToolbarIcon(icon: Icons.short_text_rounded, onTap: onInsert),
                _ToolbarIcon(icon: Icons.checklist_rounded, onTap: onInsert),
                _ToolbarIcon(icon: Icons.image_outlined, onTap: onInsert),
                _ToolbarIcon(icon: Icons.calendar_today_outlined, onTap: onInsert),
                _ToolbarIcon(icon: Icons.layers_outlined, onTap: onInsert),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ToolbarIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 22, color: AppColors.textMed),
      onPressed: onTap,
      splashRadius: 20,
    );
  }
}


// ── Field Selector Overlay ────────────────────────────────────────────────
class _FieldSelectorOverlay extends StatelessWidget {
  final ValueChanged<FieldType> onSelect;
  final VoidCallback onDismiss;

  const _FieldSelectorOverlay({
    required this.onSelect,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Add a Field',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.1,
                    children: FieldType.values
                        .map((type) => _FieldTypeItem(
                              type: type,
                              onTap: () => onSelect(type),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldTypeItem extends StatelessWidget {
  final FieldType type;
  final VoidCallback onTap;

  const _FieldTypeItem({required this.type, required this.onTap});

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
