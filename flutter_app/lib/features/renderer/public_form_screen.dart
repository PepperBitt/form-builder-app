import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/form_provider.dart';
import '../../providers/response_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models.dart';
import 'widgets/dynamic_field.dart';
import '../../app.dart' show appName;

class PublicFormScreen extends StatefulWidget {
  final String formId;
  const PublicFormScreen({super.key, required this.formId});

  @override
  State<PublicFormScreen> createState() => _PublicFormScreenState();
}

class _PublicFormScreenState extends State<PublicFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _answers = {};
  bool _submitted = false;
  bool _isSubmitting = false;
  FormModel? _form;

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadForm();
=======
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final forms = context.read<FormProvider>();
      try {
        final cached = forms.forms.firstWhere((f) => f.id == widget.formId);
        setState(() => _form = cached);
        if (cached.fields.isEmpty) {
          await forms.loadFormById(widget.formId);
          if (mounted && forms.activeForm != null) {
            setState(() => _form = forms.activeForm);
          }
        }
      } catch (_) {
        await forms.loadFormById(widget.formId);
        if (mounted && forms.activeForm != null) {
          setState(() => _form = forms.activeForm);
        }
      }
>>>>>>> f442cb97373811afd72ea0d7efb74cd9af016a87
    });
  }

  Future<void> _loadForm() async {
    final forms = context.read<FormProvider>();
    final active = forms.activeForm;

    if (active != null && active.id == widget.formId && active.fields.isNotEmpty) {
      setState(() => _form = active);
      return;
    }

    await forms.loadFormById(widget.formId);
    if (!mounted) return;
    setState(() => _form = forms.activeForm);
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);
    await context.read<ResponseProvider>().submitResponse(
          widget.formId,
          _answers,
          formFields: _form!.fields,
        );
    setState(() {
      _isSubmitting = false;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_form == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_submitted) {
      return _SuccessScreen(formTitle: _form!.title);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: const _ArchitectLogo(),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _form!.isLive ? AppColors.liveBackground : AppColors.draftBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _form!.isLive ? '● LIVE' : 'PREVIEW',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _form!.isLive ? AppColors.live : AppColors.draft,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Form header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _form!.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (_form!.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _form!.description,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textLight),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Fields
            ..._form!.fields.asMap().entries.map((entry) {
              final index = entry.key;
              final field = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: DynamicField(
                  field: field,
                  questionNumber: index + 1,
                  onSaved: (value) => _answers[field.id] = value,
                ),
              );
            }),
            const SizedBox(height: 8),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text(
                        'Submit Response',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Branding
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Powered by ',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  Text(
                    appName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Success Screen ────────────────────────────────────────────────────────
class _SuccessScreen extends StatelessWidget {
  final String formTitle;
  const _SuccessScreen({required this.formTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.liveBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 40, color: AppColors.live),
              ),
              const SizedBox(height: 24),
              const Text(
                'Thank you!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your response to "$formTitle" has been recorded successfully.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textLight,
                ),
              ),
              const SizedBox(height: 32),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Architect Logo ─────────────────────────────────────────────────────────
class _ArchitectLogo extends StatelessWidget {
  const _ArchitectLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GridIcon(),
        const SizedBox(width: 8),
        Text(appName,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
      ],
    );
  }
}

class _GridIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
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

class _Square extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(2),
        ),
      );
}
