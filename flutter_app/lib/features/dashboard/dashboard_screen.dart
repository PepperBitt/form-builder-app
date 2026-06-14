import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/form_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models.dart';
import '../../widgets/app_logo.dart';

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
    final userName = auth.currentUser?.name ?? '';
    final firstName = userName.split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: const AppLogo(size: 26),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: AppColors.textLight,
            onPressed: () {},
            tooltip: 'Notifications',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _UserAvatar(name: userName),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => context.read<FormProvider>().fetchForms(),
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                firstName.isNotEmpty
                                    ? 'Good work, $firstName'
                                    : 'Form Overview',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage forms, collect responses, and track insights.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textLight,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Create New Form button
                    _CreateFormButton(
                      onPressed: () {
                        forms.createNewForm();
                        if (forms.activeForm != null) {
                          context.push('/builder/${forms.activeForm!.id}');
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Stats row
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.inbox_rounded,
                            label: 'TOTAL RESPONSES',
                            value: forms.totalResponses.toString(),
                            trend: '+18.4% from last month',
                            trendPositive: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.article_rounded,
                            label: 'Total Forms',
                            value: forms.forms.length.toString(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Forms section header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Forms',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              _ViewToggleBtn(
                                icon: Icons.grid_view_rounded,
                                selected: false,
                                onTap: () {},
                              ),
                              _ViewToggleBtn(
                                icon: Icons.list_rounded,
                                selected: true,
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // Loading state
            if (forms.isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading your forms...',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (forms.forms.isEmpty)
              SliverToBoxAdapter(
                child: _EmptyFormsState(
                  onCreateTap: () {
                    forms.createNewForm();
                    if (forms.activeForm != null) {
                      context.push('/builder/${forms.activeForm!.id}');
                    }
                  },
                ),
              )
            else ...[
              // Forms list
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final form = forms.forms[index];
                      return Padding(
                        padding: EdgeInsets.only(
                            bottom: index == forms.forms.length - 1 ? 0 : 10),
                        child: _FormCard(form: form),
                      );
                    },
                    childCount: forms.forms.length,
                  ),
                ),
              ),

              // Recent Activity
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Activity',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ActivityCard(children: const [
                        _ActivityItem(
                          message: 'New response received for ',
                          formName: '"Customer Experience 2024"',
                          time: '2 minutes ago - United States',
                          iconData: Icons.inbox_rounded,
                          iconColor: AppColors.live,
                          iconBg: AppColors.liveBackground,
                        ),
                        _ActivityItem(
                          message: 'Form ',
                          formName: '"Event Registration"',
                          suffix: ' was updated by Sarah L.',
                          time: '1 hour ago - Revision #12',
                          iconData: Icons.edit_rounded,
                          iconColor: AppColors.draft,
                          iconBg: AppColors.draftBackground,
                        ),
                        _ActivityItem(
                          message: 'Analytics exported for ',
                          formName: '"Product Feedback"',
                          time: '4 hours ago - PDF Format',
                          iconData: Icons.download_rounded,
                          iconColor: AppColors.primary,
                          iconBg: AppColors.primaryLight,
                          isLast: true,
                        ),
                      ]),

                      const SizedBox(height: 20),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Create Form Button

class _CreateFormButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _CreateFormButton({required this.onPressed});

  @override
  State<_CreateFormButton> createState() => _CreateFormButtonState();
}

class _CreateFormButtonState extends State<_CreateFormButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _hovered
                  ? [const Color(0xFF0EA5E9), const Color(0xFF2563EB)]
                  : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary
                    .withValues(alpha: _hovered ? 0.30 : 0.18),
                blurRadius: _hovered ? 18 : 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'Create New Form',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Stat Card

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? trend;
  final bool? trendPositive;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.trend,
    this.trendPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textLight,
            ),
          ),
          if (trend != null) const SizedBox(height: 8),
          if (trend != null && trendPositive != null)
            Row(
              children: [
                Icon(
                  trendPositive! ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  size: 13,
                  color: trendPositive! ? AppColors.live : AppColors.danger,
                ),
                const SizedBox(width: 3),
                Text(
                  trend!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: trendPositive! ? AppColors.live : AppColors.danger,
                  ),
                ),
              ],
            )
          else if (trend != null)
            Text(
              trend!,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textLight,
              ),
            ),
        ],
      ),
    );
  }
}

// View Toggle Button

class _ViewToggleBtn extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ViewToggleBtn(
      {required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(
          icon,
          size: 17,
          color: selected ? AppColors.primary : AppColors.textLight,
        ),
      ),
    );
  }
}

// Form Card

class _FormCard extends StatefulWidget {
  final FormModel form;
  const _FormCard({required this.form});

  @override
  State<_FormCard> createState() => _FormCardState();
}

class _FormCardState extends State<_FormCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final formProvider = context.read<FormProvider>();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered ? AppColors.primary.withValues(alpha: 0.35) : AppColors.border,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Form icon
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getFormIcon(widget.form),
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
                                widget.form.title,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusBadge(isLive: widget.form.isLive),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.form.description,
                          style: GoogleFonts.inter(
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
                    icon: const Icon(Icons.more_vert_rounded,
                        color: AppColors.textLight, size: 20),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          formProvider.openFormBuilder(widget.form);
                          context.push('/builder/${widget.form.id}');
                          break;
                        case 'preview':
                          context.push('/form/${widget.form.id}');
                          break;
                        case 'export':
                          context.push('/export/${widget.form.id}');
                          break;
                        case 'delete':
                          formProvider.deleteForm(widget.form.id);
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 16,
                                color: AppColors.textMed),
                            const SizedBox(width: 10),
                            Text('Edit Builder',
                                style: GoogleFonts.inter(fontSize: 14)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'preview',
                        child: Row(
                          children: [
                            const Icon(Icons.open_in_new_rounded, size: 16,
                                color: AppColors.textMed),
                            const SizedBox(width: 10),
                            Text('Preview Form',
                                style: GoogleFonts.inter(fontSize: 14)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            const Icon(Icons.download_rounded, size: 16,
                                color: AppColors.textMed),
                            const SizedBox(width: 10),
                            Text('Export Data',
                                style: GoogleFonts.inter(fontSize: 14)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline_rounded,
                                size: 16, color: AppColors.danger),
                            const SizedBox(width: 10),
                            Text('Delete',
                                style: GoogleFonts.inter(
                                    fontSize: 14, color: AppColors.danger)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Divider(color: AppColors.border.withValues(alpha: 0.7)),
              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(Icons.inbox_outlined,
                      size: 13, color: AppColors.textLight),
                  const SizedBox(width: 5),
                  Text(
                    '${widget.form.responseCount} responses',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textLight),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      formProvider.openFormBuilder(widget.form);
                      context.push('/builder/${widget.form.id}');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Edit',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 12, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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

// Status Badge

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: isLive ? AppColors.live : AppColors.draft,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isLive ? 'Live' : 'Draft',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: isLive ? AppColors.live : AppColors.draft,
            ),
          ),
        ],
      ),
    );
  }
}

// Activity Card + Item

class _ActivityCard extends StatelessWidget {
  final List<Widget> children;
  const _ActivityCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String message;
  final String formName;
  final String time;
  final String? suffix;
  final IconData iconData;
  final Color iconColor;
  final Color iconBg;
  final bool isLast;

  const _ActivityItem({
    required this.message,
    required this.formName,
    required this.time,
    this.suffix,
    required this.iconData,
    required this.iconColor,
    required this.iconBg,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(iconData, size: 16, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textMed),
                        children: [
                          TextSpan(text: message),
                          TextSpan(
                            text: formName,
                            style: GoogleFonts.inter(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          if (suffix != null) TextSpan(text: suffix),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      time,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, color: AppColors.border),
      ],
    );
  }
}

// Empty State

class _EmptyFormsState extends StatelessWidget {
  final VoidCallback onCreateTap;
  const _EmptyFormsState({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.article_outlined,
                  color: AppColors.primary, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              'No forms yet',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Create your first form to start collecting\nresponses from your audience.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textLight,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCreateTap,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Create Your First Form'),
            ),
          ],
        ),
      ),
    );
  }
}



// User Avatar

class _UserAvatar extends StatelessWidget {
  final String name;
  const _UserAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return CircleAvatar(
      radius: 17,
      backgroundColor: AppColors.primary,
      child: Text(
        initials,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}
