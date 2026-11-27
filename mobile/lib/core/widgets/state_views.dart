import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../errors.dart';
import '../theme/tokens.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator.adaptive());
}

/// Placeholder rows while a list loads.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListView.separated(
      padding: const EdgeInsets.all(Space.lg),
      itemCount: count,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, _) => const SizedBox(height: Space.md),
      itemBuilder: (_, _) => Container(
        height: 64,
        decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(Radii.lg)),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.icon, required this.title, this.body, this.action});

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(Space.lg),
              decoration: BoxDecoration(color: c.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: c.primary),
            ),
            const SizedBox(height: Space.lg),
            Text(title, style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            if (body != null) ...[
              const SizedBox(height: Space.sm),
              Text(body!, style: context.text.bodyMedium?.copyWith(color: c.textMuted), textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: Space.xl), action!],
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return EmptyView(
      icon: Icons.cloud_off_rounded,
      title: describeError(l, error),
      action: onRetry == null ? null : OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text(l.commonRetry)),
    );
  }
}

void showMessage(BuildContext context, String message, {bool error = false, SnackBarAction? action}) {
  final c = context.colors;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? c.danger : null,
      action: action,
    ));
}

void showError(BuildContext context, Object error) =>
    showMessage(context, describeError(AppLocalizations.of(context), error), error: true);
