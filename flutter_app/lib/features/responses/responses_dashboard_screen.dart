import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../providers/response_provider.dart';
import '../../providers/form_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models.dart';

class ResponsesDashboardScreen extends StatefulWidget {
  const ResponsesDashboardScreen({super.key});

  @override
  State<ResponsesDashboardScreen> createState() =>
      _ResponsesDashboardScreenState();
}

class _ResponsesDashboardScreenState extends State<ResponsesDashboardScreen> {
  String? _selectedFormId;
  FormModel? _selectedForm;

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
        await _loadFormResponses(forms.forms.first.id);
      }
    });
  }

  Future<void> _loadFormResponses(String formId) async {
    setState(() {
      _selectedFormId = formId;
      _selectedForm = null;
    });

    final forms = context.read<FormProvider>();
    final responses = context.read<ResponseProvider>();
    final results = await Future.wait([
      forms.fetchFormDetails(formId),
      responses.loadResponses(formId),
    ]);

    if (!mounted || _selectedFormId != formId) return;
    setState(() => _selectedForm = results.first as FormModel?);
  }

  @override
  Widget build(BuildContext context) {
    final forms = context.watch<FormProvider>();
    final responses = context.watch<ResponseProvider>();
    final selectedForm = _selectedForm;

    final formResponses = selectedForm != null
        ? responses.getResponses(selectedForm.id)
        : <ResponseModel>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // AppBar
          SliverAppBar(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            title: Text(
              'Responses Hub',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                letterSpacing: -0.5,
              ),
            ),
            floating: true,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list_rounded, size: 22),
                color: AppColors.textMed,
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Form Selector
          if (forms.forms.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: forms.forms.map((form) {
                      final isSelected = form.id == _selectedFormId;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _FormSelectorChip(
                          title: form.title,
                          isSelected: isSelected,
                          onTap: () => _loadFormResponses(form.id),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

          // Stats Section
          if (selectedForm != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Total Responses',
                        value: formResponses.length.toString(),
                        icon: Icons.all_inbox_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'This Week',
                        value: formResponses
                            .where((r) => r.submittedAt.isAfter(
                                DateTime.now().subtract(const Duration(days: 7))))
                            .length
                            .toString(),
                        icon: Icons.trending_up_rounded,
                        color: AppColors.live,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Title & Live Badge
          if (selectedForm != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activity',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    _StatusBadge(isLive: selectedForm.isLive),
                  ],
                ),
              ),
            ),

          // Responses List
          if (selectedForm != null)
            if (formResponses.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final response = formResponses[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _ResponseCard(
                          response: response,
                          index: formResponses.length - index,
                          form: selectedForm,
                        ),
                      );
                    },
                    childCount: formResponses.length,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _FormSelectorChip extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormSelectorChip({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textMed,
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isLive;
  const _StatusBadge({required this.isLive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isLive ? AppColors.liveBackground : AppColors.draftBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isLive ? AppColors.live : AppColors.draft,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isLive ? 'LIVE' : 'DRAFT',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isLive ? AppColors.live : AppColors.draft,
            ),
          ),
        ],
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '#$index',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          title: Text(
            response.respondentEmail ?? 'Anonymous Participant',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              fmt.format(response.submittedAt),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textLight,
              ),
            ),
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: form.fields.map((field) {
                  final val = response.data[field.label] ?? response.data[field.id];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          field.label.isEmpty ? field.type.label : field.label,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (val != null)
                          Text(
                            val.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textDark,
                              height: 1.5,
                            ),
                          )
                        else
                          Text(
                            'No response provided',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 48,
              color: AppColors.primary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Responses Yet',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share your form link to start\ncollecting valuable responses.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textMed,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
