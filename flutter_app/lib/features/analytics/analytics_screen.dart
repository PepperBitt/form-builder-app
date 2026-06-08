import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/form_provider.dart';
import '../../providers/response_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String? _selectedFormId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final forms = context.read<FormProvider>();
      if (forms.forms.isNotEmpty) {
        setState(() => _selectedFormId = forms.forms.first.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final forms = context.watch<FormProvider>();
    final responses = context.watch<ResponseProvider>();

    final selectedForm = _selectedFormId != null && forms.forms.isNotEmpty
        ? forms.forms.firstWhere((f) => f.id == _selectedFormId,
            orElse: () => forms.forms.first)
        : null;

    final formResponses =
        selectedForm != null ? responses.getResponses(selectedForm.id) : [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text('Analytics'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_outlined, size: 16),
              label: const Text('Export'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
        ],
      ),
      body: selectedForm == null
          ? const Center(child: Text('No forms available'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Form picker
                _FormDropdown(
                  forms: forms.forms
                      .map((f) => MapEntry(f.id, f.title))
                      .toList(),
                  selected: _selectedFormId,
                  onChanged: (v) => setState(() => _selectedFormId = v),
                ),
                const SizedBox(height: 20),

                // Key metrics
                _SectionTitle('Key Metrics'),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _MetricCard(
                      label: 'Total Responses',
                      value: formResponses.length.toString(),
                      icon: Icons.inbox_outlined,
                      color: AppColors.primary,
                    ),
                    _MetricCard(
                      label: 'Completion Rate',
                      value: '87%',
                      icon: Icons.check_circle_outline,
                      color: AppColors.live,
                    ),
                    _MetricCard(
                      label: 'Avg. Time',
                      value: '2m 34s',
                      icon: Icons.timer_outlined,
                      color: const Color(0xFF7C3AED),
                    ),
                    _MetricCard(
                      label: 'Drop-off Rate',
                      value: '13%',
                      icon: Icons.trending_down_rounded,
                      color: AppColors.draft,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Response trend
                _SectionTitle('Response Trend'),
                const SizedBox(height: 10),
                _ChartCard(
                  child: _BarChart(
                    data: [12, 19, 8, 25, 14, 32, 18, 22, 16, 28, 20, 35],
                    labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
                  ),
                ),
                const SizedBox(height: 24),

                // Field breakdown
                _SectionTitle('Field Breakdown'),
                const SizedBox(height: 10),
                ...selectedForm.fields
                    .take(3)
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _FieldAnalyticsCard(
                            label: f.label.isEmpty ? f.type.label : f.label,
                            responseRate: 72 + (f.label.length % 25),
                            fieldType: f.type.label,
                          ),
                        )),
              ],
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      );
}

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
          hint: const Text('Select a form'),
          onChanged: onChanged,
          items: forms
              .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value,
                        style: const TextStyle(fontSize: 14)),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration:
                BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Text(label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final Widget child;
  const _ChartCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<int> data;
  final List<String> labels;

  const _BarChart({required this.data, required this.labels});

  @override
  Widget build(BuildContext context) {
    final max = data.reduce((a, b) => a > b ? a : b);
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              data.length,
              (i) => Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FractionallySizedBox(
                        heightFactor: data[i] / max,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300 + i * 50),
                          width: 18,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.6),
                                AppColors.primary,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: labels
              .map((l) => Flexible(
                    child: Text(
                      l,
                      style: const TextStyle(
                          fontSize: 9, color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _FieldAnalyticsCard extends StatelessWidget {
  final String label;
  final int responseRate;
  final String fieldType;

  const _FieldAnalyticsCard({
    required this.label,
    required this.responseRate,
    required this.fieldType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  fieldType,
                  style: const TextStyle(fontSize: 10, color: AppColors.textLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: responseRate / 100,
                    backgroundColor: AppColors.background,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$responseRate%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
