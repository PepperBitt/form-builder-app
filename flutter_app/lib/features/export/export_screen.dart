import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  String _selectedDateRange = 'all';
  bool _isExporting = false;
  Map<String, bool> _selectedFields = {};
  FormModel? _form;

  // format metadata
  static const _formats = [
    _FormatMeta(
      id: 'pdf',
      label: 'PDF',
      description: 'Formatted report',
      icon: Icons.picture_as_pdf_rounded,
      color: Color(0xFFDC2626),
      bgColor: Color(0xFFFEE2E2),
    ),
    _FormatMeta(
      id: 'xlsx',
      label: 'Excel',
      description: 'Spreadsheet',
      icon: Icons.table_chart_rounded,
      color: Color(0xFF059669),
      bgColor: Color(0xFFD1FAE5),
    ),
    _FormatMeta(
      id: 'csv',
      label: 'CSV',
      description: 'Database import',
      icon: Icons.grid_on_rounded,
      color: Color(0xFF7C3AED),
      bgColor: Color(0xFFEDE9FE),
    ),
    _FormatMeta(
      id: 'json',
      label: 'JSON',
      description: 'Raw data',
      icon: Icons.data_object_rounded,
      color: Color(0xFFD97706),
      bgColor: Color(0xFFFEF3C7),
    ),
  ];

  static const _dateRanges = [
    ('7', 'Last 7 days'),
    ('30', 'Last 30 days'),
    ('90', 'Last 90 days'),
    ('all', 'All time'),
  ];

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
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(
                  'Export ready · ${bytes.length ~/ 1024} KB · ${_selectedFormat.toUpperCase()}'),
            ],
          ),
          backgroundColor: AppColors.live,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );
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

  _FormatMeta get _currentFormat =>
      _formats.firstWhere((f) => f.id == _selectedFormat);

  int get _selectedFieldCount => _selectedFields.values.where((v) => v).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Data',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            if (_form != null)
              Text(
                _form!.title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          // ── Hero summary card ─────────────────────────────────────────────
          _HeroCard(
            form: _form,
            format: _currentFormat,
            fieldCount: _selectedFieldCount,
            dateRange: _selectedDateRange,
          ),
          const SizedBox(height: 24),

          // ── Format Selection ──────────────────────────────────────────────
          _sectionLabel('Export Format'),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.85,
            children: _formats.map((fmt) {
              final isSelected = _selectedFormat == fmt.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedFormat = fmt.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  decoration: BoxDecoration(
                    color: isSelected ? fmt.bgColor : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? fmt.color.withValues(alpha: 0.6)
                          : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: fmt.color.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? fmt.color.withValues(alpha: 0.15)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          fmt.icon,
                          size: 18,
                          color: isSelected ? fmt.color : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        fmt.label,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? fmt.color : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fmt.description,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: isSelected
                              ? fmt.color.withValues(alpha: 0.8)
                              : AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // ── Date Range ────────────────────────────────────────────────────
          _sectionLabel('Date Range'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                // Quick chips
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                  child: Row(
                    children: _dateRanges.map((dr) {
                      final (value, label) = dr;
                      final sel = _selectedDateRange == value;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedDateRange = value),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    sel ? AppColors.primary : AppColors.border,
                              ),
                            ),
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: sel ? Colors.white : AppColors.textMed,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Custom date row
                const Padding(
                  padding: EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Row(
                    children: [
                      Expanded(child: _DateInput(label: 'From')),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward_rounded,
                            size: 14, color: AppColors.textMuted),
                      ),
                      Expanded(child: _DateInput(label: 'To')),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Fields Selection ──────────────────────────────────────────────
          Row(
            children: [
              _sectionLabel('Include Fields'),
              const Spacer(),
              Text(
                '$_selectedFieldCount selected',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () =>
                    setState(() => _selectedFields.updateAll((_, __) => true)),
                child: Text(
                  'All',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text('·', style: GoogleFonts.inter(color: AppColors.textMuted)),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () =>
                    setState(() => _selectedFields.updateAll((_, __) => false)),
                child: Text(
                  'None',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _FieldCheckRow(
                  id: 'respondentId',
                  label: 'Respondent ID',
                  badge: 'Meta',
                  badgeColor: AppColors.accent,
                  value: _selectedFields['respondentId'] ?? true,
                  onChanged: (v) =>
                      setState(() => _selectedFields['respondentId'] = v!),
                ),
                _divider(),
                _FieldCheckRow(
                  id: 'submissionDate',
                  label: 'Submission Date',
                  badge: 'Meta',
                  badgeColor: AppColors.accent,
                  value: _selectedFields['submissionDate'] ?? true,
                  onChanged: (v) =>
                      setState(() => _selectedFields['submissionDate'] = v!),
                ),
                _divider(),
                _FieldCheckRow(
                  id: 'respondentEmail',
                  label: 'Respondent Email',
                  badge: 'Meta',
                  badgeColor: AppColors.accent,
                  value: _selectedFields['respondentEmail'] ?? true,
                  onChanged: (v) =>
                      setState(() => _selectedFields['respondentEmail'] = v!),
                ),
                if (_form != null && _form!.fields.isNotEmpty)
                  ...List.generate(_form!.fields.length, (i) {
                    final field = _form!.fields[i];
                    return Column(
                      children: [
                        _divider(),
                        _FieldCheckRow(
                          id: field.id,
                          label: field.label.isEmpty
                              ? field.type.label
                              : field.label,
                          badge: 'Q${i + 1}',
                          badgeColor: AppColors.primary,
                          value: _selectedFields[field.id] ?? false,
                          onChanged: (v) =>
                              setState(() => _selectedFields[field.id] = v!),
                        ),
                      ],
                    );
                  }),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Export CTA ────────────────────────────────────────────────────
          _ExportCta(
            format: _currentFormat,
            responseCount: _form?.responseCount ?? 0,
            fieldCount: _selectedFieldCount,
            isExporting: _isExporting,
            onExport: _handleExport,
          ),

          const SizedBox(height: 24),

          // ── Export History empty state ─────────────────────────────────────
          _sectionLabel('Export History'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.history_rounded,
                      size: 22, color: AppColors.textMuted),
                ),
                const SizedBox(height: 10),
                Text(
                  'No export history',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Exports aren\'t stored server-side.\nFiles are saved directly to your device.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textLight,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
          letterSpacing: -0.1,
        ),
      );

  Widget _divider() =>
      const Divider(height: 1, color: AppColors.border, indent: 16);
}

// ── Format Metadata ────────────────────────────────────────────────────────────

class _FormatMeta {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _FormatMeta({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}

// ── Hero Summary Card ──────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final FormModel? form;
  final _FormatMeta format;
  final int fieldCount;
  final String dateRange;

  const _HeroCard({
    required this.form,
    required this.format,
    required this.fieldCount,
    required this.dateRange,
  });

  String get _rangeLabel {
    switch (dateRange) {
      case '7':
        return 'Last 7 days';
      case '30':
        return 'Last 30 days';
      case '90':
        return 'Last 90 days';
      default:
        return 'All time';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            format.color.withValues(alpha: 0.08),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: format.color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: format.bgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(format.icon, color: format.color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${format.label} Export',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    _Pill(
                      icon: Icons.inbox_outlined,
                      label: '${form?.responseCount ?? 0} responses',
                    ),
                    _Pill(
                      icon: Icons.checklist_rounded,
                      label: '$fieldCount fields',
                    ),
                    _Pill(
                      icon: Icons.calendar_today_outlined,
                      label: _rangeLabel,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppColors.textMuted),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Export CTA Card ────────────────────────────────────────────────────────────

class _ExportCta extends StatelessWidget {
  final _FormatMeta format;
  final int responseCount;
  final int fieldCount;
  final bool isExporting;
  final VoidCallback onExport;

  const _ExportCta({
    required this.format,
    required this.responseCount,
    required this.fieldCount,
    required this.isExporting,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: format.bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(format.icon, color: format.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready to export',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '$responseCount records · $fieldCount fields · ${format.label}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isExporting ? null : onExport,
              style: ElevatedButton.styleFrom(
                backgroundColor: format.color,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(format.icon, size: 18, color: Colors.white),
              label: Text(
                isExporting
                    ? 'Generating ${format.label}…'
                    : 'Download ${format.label}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Large exports may take a few moments to generate.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Date Input ─────────────────────────────────────────────────────────────────

class _DateInput extends StatelessWidget {
  final String label;
  const _DateInput({required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Pick date',
        hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
        suffixIcon: const Icon(Icons.calendar_today_outlined,
            size: 14, color: AppColors.textMuted),
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
      style: GoogleFonts.inter(fontSize: 13),
      onTap: () async {
        await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
      },
    );
  }
}

// ── Field Check Row ────────────────────────────────────────────────────────────

class _FieldCheckRow extends StatelessWidget {
  final String id;
  final String label;
  final String badge;
  final Color badgeColor;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _FieldCheckRow({
    required this.id,
    required this.label,
    required this.badge,
    required this.badgeColor,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: value ? AppColors.textDark : AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: badgeColor,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
