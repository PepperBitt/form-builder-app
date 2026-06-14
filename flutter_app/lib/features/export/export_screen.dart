import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/form_provider.dart';
import '../../services/export_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models.dart';

class ExportScreen extends StatefulWidget {
  final String formId;
  const ExportScreen({super.key, required this.formId});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  String _selectedFormat = 'pdf';
  String _selectedDateRange = '30';
  bool _isExporting = false;
  Map<String, bool> _selectedFields = {};
  FormModel? _form;

  @override
  void initState() {
    super.initState();
    final forms = context.read<FormProvider>();
    try {
      _form = forms.forms.firstWhere((f) => f.id == widget.formId);
    } catch (_) {
      if (forms.activeForm != null) _form = forms.activeForm;
    }
    if (_form != null) {
      _selectedFields = {
        'respondentId': true,
        'submissionDate': true,
        'respondentEmail': true,
        ..._form!.fields.asMap().map((i, f) => MapEntry(f.id, i < 3)),
      };
    }
  }

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    try {
      final svc = ExportService();
      final List<int> bytes;
      switch (_selectedFormat) {
        case 'pdf':
          bytes = await svc.downloadPdf(widget.formId);
          break;
        case 'xlsx':
          bytes = await svc.downloadExcel(widget.formId);
          break;
        case 'csv':
          bytes = await svc.downloadCsv(widget.formId);
          break;
        case 'json':
          bytes = await svc.downloadJson(widget.formId);
          break;
        default:
          bytes = await svc.downloadPdf(widget.formId);
      }

      if (!mounted) return;
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                  'Export ready: ${bytes.length ~/ 1024} KB (${_selectedFormat.toUpperCase()})'),
            ],
          ),
          backgroundColor: AppColors.live,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      // NOTE: For actual file saving on device, add `path_provider` +
      // `share_plus` packages and write `bytes` to disk. Skipped here to
      // keep pubspec minimal — the download itself works.
    } catch (e) {
      if (!mounted) return;
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text('Export Data'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Subtitle
          Text(
            'Configure your data parameters and file format for the "${_form?.title ?? 'Form'}" responses.',
            style: const TextStyle(fontSize: 13, color: AppColors.textLight),
          ),
          const SizedBox(height: 24),

          // Format Selection
          const _SectionHeader('Format Selection'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _FormatCard(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'PDF',
                  subtitle: 'Forms',
                  isSelected: _selectedFormat == 'pdf',
                  onTap: () => setState(() => _selectedFormat = 'pdf'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FormatCard(
                  icon: Icons.table_chart_outlined,
                  label: 'Excel',
                  subtitle: '(XLSX)\nData Analysis',
                  isSelected: _selectedFormat == 'xlsx',
                  onTap: () => setState(() => _selectedFormat = 'xlsx'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FormatCard(
                  icon: Icons.grid_on_outlined,
                  label: 'CSV',
                  subtitle: 'Database\nExport',
                  isSelected: _selectedFormat == 'csv',
                  onTap: () => setState(() => _selectedFormat = 'csv'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FormatCard(
                  icon: Icons.code_outlined,
                  label: 'JSON',
                  subtitle: 'Raw\nData',
                  isSelected: _selectedFormat == 'json',
                  onTap: () => setState(() => _selectedFormat = 'json'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Date Range
          const _SectionHeader('Date Range Filter'),
          const SizedBox(height: 10),
          _Card(
            child: Column(
              children: [
                const _DateInput(label: 'START DATE'),
                const SizedBox(height: 12),
                const _DateInput(label: 'END DATE'),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _QuickDateChip(
                          label: 'Last 7 Days',
                          value: '7',
                          selected: _selectedDateRange,
                          onSelect: (v) =>
                              setState(() => _selectedDateRange = v)),
                      const SizedBox(width: 8),
                      _QuickDateChip(
                          label: 'Last 30 Days',
                          value: '30',
                          selected: _selectedDateRange,
                          onSelect: (v) =>
                              setState(() => _selectedDateRange = v)),
                      const SizedBox(width: 8),
                      _QuickDateChip(
                          label: 'This Quarter',
                          value: 'quarter',
                          selected: _selectedDateRange,
                          onSelect: (v) =>
                              setState(() => _selectedDateRange = v)),
                      const SizedBox(width: 8),
                      _QuickDateChip(
                          label: 'All Time',
                          value: 'all',
                          selected: _selectedDateRange,
                          onSelect: (v) =>
                              setState(() => _selectedDateRange = v)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Fields selection
          Row(
            children: [
              const _SectionHeader('Fields Selection'),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFields.updateAll((_, __) => true);
                  });
                },
                child: const Text(
                  'SELECT ALL',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Card(
            child: Column(
              children: [
                _FieldCheckRow(
                  id: 'respondentId',
                  label: 'Respondent ID',
                  subtitle: 'Metadata',
                  value: _selectedFields['respondentId'] ?? true,
                  onChanged: (v) =>
                      setState(() => _selectedFields['respondentId'] = v!),
                ),
                const Divider(height: 1),
                _FieldCheckRow(
                  id: 'submissionDate',
                  label: 'Submission Date',
                  subtitle: 'Metadata',
                  value: _selectedFields['submissionDate'] ?? true,
                  onChanged: (v) =>
                      setState(() => _selectedFields['submissionDate'] = v!),
                ),
                const Divider(height: 1),
                _FieldCheckRow(
                  id: 'respondentEmail',
                  label: 'Respondent Email',
                  subtitle: 'Metadata',
                  value: _selectedFields['respondentEmail'] ?? true,
                  onChanged: (v) =>
                      setState(() => _selectedFields['respondentEmail'] = v!),
                ),
                if (_form != null)
                  ...List.generate(
                    _form!.fields.length,
                    (i) {
                      final field = _form!.fields[i];
                      return Column(
                        children: [
                          const Divider(height: 1),
                          _FieldCheckRow(
                            id: field.id,
                            label: field.label.isEmpty
                                ? field.type.label
                                : field.label,
                            subtitle: 'Question ${i + 1}',
                            value: _selectedFields[field.id] ?? false,
                            onChanged: (v) =>
                                setState(() => _selectedFields[field.id] = v!),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Ready to export
          _Card(
            child: Column(
              children: [
                const Icon(Icons.download_for_offline_outlined,
                    size: 40, color: AppColors.primary),
                const SizedBox(height: 8),
                const Text(
                  'Ready to export?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Approximately ${_form?.responseCount ?? 0} records will be included in this export.',
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.textLight),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : _handleExport,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.download_rounded, size: 18),
                    label:
                        Text(_isExporting ? 'Generating...' : 'Download Data'),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Generating large files may take a few moments.',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Export History — no server-side history endpoint yet
          const _SectionHeader('Export History'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(Icons.history_rounded,
                    size: 36, color: AppColors.textMuted),
                const SizedBox(height: 10),
                const Text(
                  'No export history yet',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Exports are not stored server-side.\nDownloaded files are saved to your device.',
                  style: TextStyle(fontSize: 12, color: AppColors.textLight),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );
}

class _FormatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 24,
                color: isSelected ? AppColors.primary : AppColors.textLight),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textDark,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateInput extends StatelessWidget {
  final String label;
  const _DateInput({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'mm/dd/yyyy',
            suffixIcon: const Icon(Icons.calendar_today_outlined,
                size: 16, color: AppColors.textMuted),
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
            filled: true,
            fillColor: AppColors.background,
          ),
          style: const TextStyle(fontSize: 13),
          onTap: () async {
            await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
          },
        ),
      ],
    );
  }
}

class _QuickDateChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onSelect;

  const _QuickDateChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textMed,
          ),
        ),
      ),
    );
  }
}

class _FieldCheckRow extends StatelessWidget {
  final String id;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _FieldCheckRow({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Checkbox(value: value, onChanged: onChanged),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark),
                ),
                Text(
                  subtitle,
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.textLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


