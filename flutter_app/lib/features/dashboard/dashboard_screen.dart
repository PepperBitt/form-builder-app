import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/form_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models.dart';
import '../../app.dart' show appName;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FormProvider>().fetchForms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final forms = context.watch<FormProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: ArchitectLogo(),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.textMed),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _UserAvatar(auth.currentUser?.name ?? 'U'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<FormProvider>().fetchForms(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Form Overview',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage your active forms, analyze response data, and create new architectural data structures.',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Create New Form button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          forms.createNewForm();
                          if (forms.activeForm != null) {
                            context.push('/builder/${forms.activeForm!.id}');
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Create New Form'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats row
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'TOTAL RESPONSES',
                            value: '12,482',
                            trend: '+18.4% from last month',
                            trendPositive: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'ACTIVE FORMS',
                            value: forms.activeForms.toString(),
                            trend: 'Across 4 workspaces',
                            trendPositive: null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Forms section header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Existing Forms',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.grid_view_rounded,
                                  size: 20, color: AppColors.textLight),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.list_rounded,
                                  size: 20, color: AppColors.primary),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Forms list
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final form = forms.forms[index];
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                        16, 0, 16, index == forms.forms.length - 1 ? 0 : 10),
                    child: _FormCard(form: form),
                  );
                },
                childCount: forms.forms.length,
              ),
            ),

            // Recent activity
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ActivityItem(
                      message: 'New response received for ',
                      formName: '"Customer Experience 2024"',
                      time: '2 minutes ago • United States',
                    ),
                    _ActivityItem(
                      message: 'Form ',
                      formName: '"Event Registration"',
                      time: '1 hour ago • Revision #12',
                      suffix: ' was updated by Sarah L.',
                    ),
                    _ActivityItem(
                      message: 'Analytics report exported for ',
                      formName: '"Product Feedback"',
                      time: '4 hours ago • PDF Format',
                    ),
                    const SizedBox(height: 20),

                    // Upgrade to Pro card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Upgrade to Pro',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Unlock conditional logic, white-labeling and unlimited responses.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1E3A8A),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              textStyle: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            child: const Text('Upgrade Workspace'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
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

// ── Stat Card ─────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final bool? trendPositive;

  const _StatCard({
    required this.label,
    required this.value,
    required this.trend,
    required this.trendPositive,
  });

  @override
  Widget build(BuildContext context) {
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
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          if (trendPositive != null)
            Row(
              children: [
                Icon(
                  trendPositive! ? Icons.trending_up : Icons.trending_down,
                  size: 14,
                  color: trendPositive! ? AppColors.live : AppColors.danger,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    trend,
                    style: TextStyle(
                      fontSize: 11,
                      color: trendPositive! ? AppColors.live : AppColors.danger,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          else
            Text(
              trend,
              style: const TextStyle(fontSize: 11, color: AppColors.textLight),
            ),
        ],
      ),
    );
  }
}

// ── Form Card ─────────────────────────────────────────────────────────────
class _FormCard extends StatelessWidget {
  final FormModel form;
  const _FormCard({required this.form});

  @override
  Widget build(BuildContext context) {
    final formProvider = context.read<FormProvider>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getFormIcon(form),
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              form.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(isLive: form.isLive),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        form.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.textLight, size: 20),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        formProvider.openFormBuilder(form);
                        context.push('/builder/${form.id}');
                        break;
                      case 'preview':
                        context.push('/form/${form.id}');
                        break;
                      case 'export':
                        context.push('/export/${form.id}');
                        break;
                      case 'delete':
                        formProvider.deleteForm(form.id);
                        break;
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit Builder')),
                    PopupMenuItem(value: 'preview', child: Text('Preview Form')),
                    PopupMenuItem(value: 'export', child: Text('Export Data')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: AppColors.danger)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: AppColors.border.withValues(alpha: 0.6)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.inbox_outlined, size: 14, color: AppColors.textLight),
                const SizedBox(width: 5),
                Text(
                  '${form.responseCount} responses',
                  style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    formProvider.openFormBuilder(form);
                    context.push('/builder/${form.id}');
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Edit →',
                      style: TextStyle(fontSize: 12, color: AppColors.primary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFormIcon(FormModel form) {
    if (form.fields.any((f) => f.type == FieldType.rating)) {
      return Icons.star_outline_rounded;
    } else if (form.fields.any((f) => f.type == FieldType.date)) {
      return Icons.calendar_today_outlined;
    }
    return Icons.article_outlined;
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final bool isLive;
  const _StatusBadge({required this.isLive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isLive ? AppColors.liveBackground : AppColors.draftBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isLive ? 'LIVE' : 'DRAFT',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: isLive ? AppColors.live : AppColors.draft,
        ),
      ),
    );
  }
}

// ── Activity Item ──────────────────────────────────────────────────────────
class _ActivityItem extends StatelessWidget {
  final String message;
  final String formName;
  final String time;
  final String? suffix;

  const _ActivityItem({
    required this.message,
    required this.formName,
    required this.time,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMed),
                    children: [
                      TextSpan(text: message),
                      TextSpan(
                        text: formName,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (suffix != null) TextSpan(text: suffix),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Architect Logo (reusable) ─────────────────────────────────────────────
class ArchitectLogo extends StatelessWidget {
  const ArchitectLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GridIcon(),
        const SizedBox(width: 8),
        Text(
          appName,
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
      ],
    );
  }
}

class _GridIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
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
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ── User Avatar ───────────────────────────────────────────────────────────
class _UserAvatar extends StatelessWidget {
  final String name;
  const _UserAvatar(this.name);

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return CircleAvatar(
      radius: 17,
      backgroundColor: AppColors.primary,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}
