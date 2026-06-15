import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/form_provider.dart';
import '../../providers/response_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/response_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String? _selectedFormId;
  bool _analyticsLoading = false;
  Map<String, dynamic>? _analyticsData;
  String? _analyticsError;
  final _responseService = ResponseService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final forms = context.read<FormProvider>();
      if (forms.forms.isNotEmpty && _selectedFormId == null) {
        _selectForm(forms.forms.first.id);
      }
    });
  }

  Future<void> _selectForm(String formId) async {
    setState(() {
      _selectedFormId = formId;
      _analyticsLoading = true;
      _analyticsData = null;
      _analyticsError = null;
    });
    // Load responses in parallel
    context.read<ResponseProvider>().loadResponses(formId);
    try {
      final data = await _responseService.getAnalytics(formId);
      if (mounted) {
        setState(() {
          _analyticsData = data;
          _analyticsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _analyticsError = e.toString();
          _analyticsLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final forms = context.watch<FormProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Analytics',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: forms.forms.isEmpty
          ? _buildNoForms(forms.isLoading)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Form picker
                _FormDropdown(
                  forms:
                      forms.forms.map((f) => MapEntry(f.id, f.title)).toList(),
                  selected: _selectedFormId,
                  onChanged: (v) {
                    if (v != null) _selectForm(v);
                  },
                ),
                const SizedBox(height: 20),

                if (_analyticsLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                else if (_analyticsError != null)
                  _buildError(_analyticsError!)
                else if (_analyticsData != null)
                  ..._buildAnalyticsContent(_analyticsData!),
              ],
            ),
    );
  }

  List<Widget> _buildAnalyticsContent(Map<String, dynamic> data) {
    final totalResponses = (data['total_responses'] ?? 0) as int;
    final analytics = (data['analytics'] ?? {}) as Map<String, dynamic>;

    return [
      // ── Total Responses metric ──────────────────────────────────────────
      const _SectionTitle('Key Metrics'),
      const SizedBox(height: 10),
      _MetricCard(
        label: 'Total Responses',
        value: totalResponses.toString(),
        icon: Icons.inbox_outlined,
        color: AppColors.primary,
      ),
      const SizedBox(height: 24),

      // ── Field Breakdown ─────────────────────────────────────────────────
      const _SectionTitle('Field Breakdown'),
      const SizedBox(height: 10),

      if (analytics.isEmpty)
        _buildEmptyAnalytics()
      else ...[
        ...analytics.entries.map((entry) {
          final label = entry.key;
          final counts = entry.value as Map<String, dynamic>;
          final total = counts.values.fold<int>(0, (s, v) => s + (v as int));
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FieldBreakdownCard(
              label: label,
              counts: counts,
              totalResponses: total,
            ),
          );
        }),
      ],
    ];
  }

  Widget _buildNoForms(bool isLoading) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
            strokeWidth: 2.5, color: AppColors.primary),
      );
    }
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
              child: const Icon(Icons.bar_chart_rounded,
                  color: AppColors.primary, size: 34),
            ),
            const SizedBox(height: 20),
            Text(
              'No forms yet',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a form on the Forms tab to start\ncollecting and analyzing responses.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textLight,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAnalytics() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined,
              size: 40, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            'No responses yet',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Share your form to start collecting responses.\nAnalytics will appear here automatically.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textLight,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Failed to load analytics: $error',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Title ──────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      );
}

// ── Form Dropdown ──────────────────────────────────────────────────────────────

class _FormDropdown extends StatelessWidget {
  final List<MapEntry<String, String>> forms;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _FormDropdown({
    required this.forms,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          hint: Text(
            'Select a form',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
          ),
          onChanged: onChanged,
          items: forms
              .map((e) => DropdownMenuItem(
                    value: e.key,
                    child:
                        Text(e.value, style: GoogleFonts.inter(fontSize: 14)),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ── Metric Card ────────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Field Breakdown Card ────────────────────────────────────────────────────────

class _FieldBreakdownCard extends StatelessWidget {
  final String label;
  final Map<String, dynamic> counts;
  final int totalResponses;

  const _FieldBreakdownCard({
    required this.label,
    required this.counts,
    required this.totalResponses,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = counts.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          ...sorted.take(6).map((entry) {
            final count = entry.value as int;
            final pct = totalResponses > 0 ? count / totalResponses : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textMed,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$count',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: AppColors.background,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (sorted.length > 6)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${sorted.length - 6} more answers',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
