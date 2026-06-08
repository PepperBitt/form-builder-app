import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/response_provider.dart';
import '../../providers/form_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models.dart';
import 'package:intl/intl.dart';

class ResponsesDashboardScreen extends StatefulWidget {
  const ResponsesDashboardScreen({super.key});

  @override
  State<ResponsesDashboardScreen> createState() => _ResponsesDashboardScreenState();
}

class _ResponsesDashboardScreenState extends State<ResponsesDashboardScreen> {
  String? _selectedFormId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final forms = context.read<FormProvider>();
      if (forms.forms.isEmpty) {
        await forms.fetchForms();
      }
      if (!mounted) return;
      if (forms.forms.isNotEmpty && _selectedFormId == null) {
        setState(() => _selectedFormId = forms.forms.first.id);
        context.read<ResponseProvider>().loadResponses(forms.forms.first.id);
      }
    });
  }

  void _selectForm(String formId) {
    setState(() => _selectedFormId = formId);
    context.read<ResponseProvider>().loadResponses(formId);
  }

  @override
  Widget build(BuildContext context) {
    final forms = context.watch<FormProvider>();
    final responses = context.watch<ResponseProvider>();

    final selectedForm = _selectedFormId != null
        ? forms.forms.firstWhere((f) => f.id == _selectedFormId,
            orElse: () => forms.forms.first)
        : (forms.forms.isNotEmpty ? forms.forms.first : null);

    final formResponses =
        selectedForm != null ? responses.getResponses(selectedForm.id) : <ResponseModel>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text('Responses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Form selector
          if (forms.forms.isNotEmpty)
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: forms.forms.map((form) {
                    final isSelected = form.id == _selectedFormId;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _selectForm(form.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryLight
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            form.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textMed,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          const Divider(height: 1),

          // Stats
          if (selectedForm != null)
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _MiniStat(label: 'Total', value: formResponses.length.toString()),
                  const SizedBox(width: 24),
                  _MiniStat(
                      label: 'This Week',
                      value: formResponses
                          .where((r) => r.submittedAt
                              .isAfter(DateTime.now().subtract(const Duration(days: 7))))
                          .length
                          .toString()),
                  const Spacer(),
                  _StatusBadge(isLive: selectedForm.isLive),
                ],
              ),
            ),
          const Divider(height: 1),

          // Response list
          Expanded(
            child: formResponses.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: formResponses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final response = formResponses[index];
                      return _ResponseCard(
                        response: response,
                        index: index + 1,
                        form: selectedForm!,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isLive;
  const _StatusBadge({required this.isLive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isLive ? AppColors.liveBackground : AppColors.draftBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isLive ? '● LIVE' : 'DRAFT',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isLive ? AppColors.live : AppColors.draft,
        ),
      ),
    );
  }
}

class _ResponseCard extends StatelessWidget {
  final ResponseModel response;
  final int index;
  final FormModel form;

  const _ResponseCard({
    required this.response,
    required this.index,
    required this.form,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy • h:mm a');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '#$index',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        title: Text(
          response.respondentEmail ?? 'Anonymous',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Text(
          fmt.format(response.submittedAt),
          style: const TextStyle(fontSize: 11, color: AppColors.textLight),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (response.location != null)
              Text(
                response.location!,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.expand_more_rounded,
                size: 20, color: AppColors.textMuted),
          ],
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: form.fields.map((field) {
                final val = response.data[field.id];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field.label.isEmpty ? field.type.label : field.label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (val != null)
                        Text(
                          val.toString(),
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.textDark),
                        )
                      else
                        const Text(
                          '—',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No responses yet',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textLight),
          ),
          const SizedBox(height: 8),
          const Text(
            'Share your form to start\ncollecting responses.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
