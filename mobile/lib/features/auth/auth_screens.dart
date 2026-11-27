import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

import '../../core/errors.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/state_views.dart';
import '../../l10n/gen/app_localizations.dart';
import '../settings/settings_controller.dart';
import 'auth_controller.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateEmail(AppLocalizations l, String? v) => _emailPattern.hasMatch((v ?? '').trim()) ? null : l.authInvalidEmail;

/// Mirrors the Supabase Auth policy (min 8, letters + digits).
String? validatePassword(AppLocalizations l, String? v) {
  final s = v ?? '';
  final ok = s.length >= 8 && RegExp(r'[A-Za-z]').hasMatch(s) && RegExp(r'\d').hasMatch(s);
  return ok ? null : l.authPasswordRule;
}

class _AuthScaffold extends StatelessWidget {
  const _AuthScaffold({required this.title, required this.subtitle, required this.children});

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Space.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.lg),
                      child: Image.asset('assets/brand/icon-1024.png', width: 64, height: 64, semanticLabel: 'Mock GPS'),
                    ),
                  ),
                  const SizedBox(height: Space.lg),
                  Text(title, style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: Space.sm),
                  Text(subtitle, style: context.text.bodyMedium?.copyWith(color: c.textMuted)),
                  const SizedBox(height: Space.xl),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Submit extends StatelessWidget {
  const _Submit({required this.label, required this.busy, required this.onPressed});

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: busy ? null : onPressed,
        child: busy ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(label),
      );
}

mixin _Busy<T extends StatefulWidget> on State<T> {
  bool busy = false;

  Future<void> run(Future<void> Function() action) async {
    setState(() => busy = true);
    try {
      await action();
    } on AuthException catch (e) {
      if (mounted) showMessage(context, describeAuthError(AppLocalizations.of(context), e), error: true);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> with _Busy {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final blocked = ref.watch(authProvider.select((s) => s.blockedCode));
    return _AuthScaffold(
      title: l.authSignInTitle,
      subtitle: l.authSignInSubtitle,
      children: [
        if (blocked == 'account_disabled') ...[
          Card(child: Padding(padding: const EdgeInsets.all(Space.lg), child: Text(l.errorAccountDisabled))),
          const SizedBox(height: Space.lg),
        ],
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(children: [
              TextFormField(
                controller: _email,
                decoration: InputDecoration(labelText: l.authEmail),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                validator: (v) => validateEmail(l, v),
              ),
              const SizedBox(height: Space.md),
              TextFormField(
                controller: _password,
                decoration: InputDecoration(labelText: l.authPassword),
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _submit(),
                validator: (v) => (v ?? '').isEmpty ? l.authPasswordRule : null,
              ),
            ]),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: () => context.push('/auth/forgot'), child: Text(l.authForgotPassword)),
        ),
        const SizedBox(height: Space.sm),
        _Submit(label: l.authSignIn, busy: busy, onPressed: _submit),
        const SizedBox(height: Space.md),
        TextButton(onPressed: () => context.go('/auth/sign-up'), child: Text(l.authNoAccount)),
      ],
    );
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    run(() => ref.read(authProvider.notifier).signIn(_email.text, _password.text));
  }
}

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> with _Busy {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _AuthScaffold(
      title: l.authSignUpTitle,
      subtitle: l.authSignUpSubtitle,
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(children: [
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: l.authDisplayName, helperText: l.commonOptional),
                autofillHints: const [AutofillHints.name],
                textInputAction: TextInputAction.next,
                maxLength: 80,
              ),
              const SizedBox(height: Space.sm),
              TextFormField(
                controller: _email,
                decoration: InputDecoration(labelText: l.authEmail),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                validator: (v) => validateEmail(l, v),
              ),
              const SizedBox(height: Space.md),
              TextFormField(
                controller: _password,
                decoration: InputDecoration(labelText: l.authPassword, helperText: l.authPasswordRule, helperMaxLines: 2),
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                validator: (v) => validatePassword(l, v),
              ),
            ]),
          ),
        ),
        const SizedBox(height: Space.xl),
        _Submit(label: l.authSignUp, busy: busy, onPressed: _submit),
        const SizedBox(height: Space.md),
        TextButton(onPressed: () => context.go('/auth/sign-in'), child: Text(l.authHaveAccount)),
      ],
    );
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    run(() async {
      final needsConfirmation = await ref.read(authProvider.notifier).signUp(
            _email.text,
            _password.text,
            displayName: _name.text.trim(),
            language: ref.read(settingsProvider).user.language,
          );
      if (needsConfirmation && mounted) context.go('/auth/check-email?email=${Uri.encodeComponent(_email.text.trim())}');
    });
  }
}

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> with _Busy {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _AuthScaffold(
      title: l.authResetTitle,
      subtitle: _sent ? l.authResetSent : l.authResetSubtitle,
      children: [
        if (!_sent) ...[
          Form(
            key: _form,
            child: TextFormField(
              controller: _email,
              decoration: InputDecoration(labelText: l.authEmail),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => validateEmail(l, v),
            ),
          ),
          const SizedBox(height: Space.xl),
          _Submit(
            label: l.authSendResetLink,
            busy: busy,
            onPressed: () {
              if (!_form.currentState!.validate()) return;
              run(() async {
                await ref.read(authProvider.notifier).sendPasswordReset(_email.text);
                setState(() => _sent = true);
              });
            },
          ),
        ] else
          OutlinedButton(onPressed: () => context.go('/auth/sign-in'), child: Text(l.authSignIn)),
      ],
    );
  }
}

class NewPasswordScreen extends ConsumerStatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> with _Busy {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _AuthScaffold(
      title: l.authNewPasswordTitle,
      subtitle: l.authPasswordRule,
      children: [
        Form(
          key: _form,
          child: TextFormField(
            controller: _password,
            decoration: InputDecoration(labelText: l.authNewPassword),
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            validator: (v) => validatePassword(l, v),
          ),
        ),
        const SizedBox(height: Space.xl),
        _Submit(
          label: l.commonSave,
          busy: busy,
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            run(() async {
              await ref.read(authProvider.notifier).setNewPassword(_password.text);
              if (mounted) showMessage(this.context, l.authPasswordUpdated);
            });
          },
        ),
      ],
    );
  }
}

class CheckEmailScreen extends ConsumerStatefulWidget {
  const CheckEmailScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<CheckEmailScreen> createState() => _CheckEmailScreenState();
}

class _CheckEmailScreenState extends ConsumerState<CheckEmailScreen> with _Busy {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return _AuthScaffold(
      title: l.authCheckEmailTitle,
      subtitle: l.authCheckEmailBody(widget.email),
      children: [
        OutlinedButton(
          onPressed: busy
              ? null
              : () => run(() async {
                    await ref.read(authProvider.notifier).resendConfirmation(widget.email);
                    if (mounted) showMessage(this.context, l.authEmailResent);
                  }),
          child: Text(l.authResendEmail),
        ),
        const SizedBox(height: Space.md),
        TextButton(onPressed: () => context.go('/auth/sign-in'), child: Text(l.authSignIn)),
      ],
    );
  }
}
