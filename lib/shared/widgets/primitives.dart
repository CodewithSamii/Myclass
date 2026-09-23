import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../design_system/tokens.dart';

void feedback(BuildContext context, String message) => ScaffoldMessenger.of(
  context,
).showSnackBar(SnackBar(content: Text(message)));
Future<T?> openPage<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(CupertinoPageRoute(builder: (_) => page));
Future<T?> openSheet<T>(
  BuildContext context,
  Widget child, {
  bool scroll = true,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: scroll,
  useSafeArea: true,
  showDragHandle: true,
  builder: (c) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(c).bottom),
    child: child,
  ),
);

class Label extends StatelessWidget {
  const Label(this.text, {super.key, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: context.type.labelSmall?.copyWith(
      color: color ?? context.colors.secondary,
    ),
  );
}

class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.border = true,
    this.radius = Shape.medium,
    this.onTap,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final bool border;
  final double radius;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: color ?? context.colors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(
        color: border ? context.colors.line : Colors.transparent,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.busy = false,
    this.icon = CupertinoIcons.arrow_right,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: busy ? null : onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (busy) ...[
            SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: context.colors.secondary,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(child: Text(label)),
          if (icon != null && !busy) ...[
            const SizedBox(width: 12),
            Icon(icon, size: 17),
          ],
        ],
      ),
    ),
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.trailing,
    this.action,
    this.onAction,
  });
  final String title;
  final Widget? trailing;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 12),
    child: Row(
      children: [
        Expanded(child: Text(title, style: context.type.titleLarge)),
        ?trailing,
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    ),
  );
}

class PageHeader extends StatelessWidget {
  const PageHeader(
    this.title, {
    super.key,
    this.eyebrow,
    this.subtitle,
    this.actions = const [],
  });
  final String title;
  final String? eyebrow, subtitle;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[Label(eyebrow!), const SizedBox(height: 8)],
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: Text(title, style: context.type.headlineLarge)),
            ...actions,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: context.type.bodyMedium?.copyWith(
              color: context.colors.secondary,
            ),
          ),
        ],
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState(
    this.title,
    this.message, {
    super.key,
    this.icon = CupertinoIcons.calendar,
    this.action,
    this.onAction,
  });
  final String title, message;
  final IconData icon;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 26, color: context.colors.faint),
        const SizedBox(height: 16),
        Text(title, style: context.type.titleLarge),
        const SizedBox(height: 6),
        Text(
          message,
          style: context.type.bodyMedium?.copyWith(
            color: context.colors.secondary,
          ),
        ),
        if (action != null) ...[
          const SizedBox(height: 12),
          TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ],
    ),
  );
}

class ErrorNotice extends StatelessWidget {
  const ErrorNotice(this.text, {super.key, this.onRetry});
  final String text;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Surface(
    color: context.colors.redBg,
    border: false,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          CupertinoIcons.exclamationmark_circle,
          size: 18,
          color: context.colors.red,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: context.type.bodyMedium?.copyWith(color: context.colors.red),
          ),
        ),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

class Skeleton extends StatelessWidget {
  const Skeleton({super.key, this.rows = 4});
  final int rows;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < rows; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: context.colors.subtle,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 170,
                      height: 13,
                      color: context.colors.subtle,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 110,
                      height: 9,
                      color: context.colors.subtle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class Badge extends StatelessWidget {
  const Badge(this.label, {super.key, this.color, this.background, this.icon});
  final String label;
  final Color? color, background;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: background ?? context.colors.subtle,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: color ?? context.colors.secondary),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: context.type.bodySmall?.copyWith(
            color: color ?? context.colors.secondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class ChoiceBar<T> extends StatelessWidget {
  const ChoiceBar({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
  });
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: context.colors.subtle,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        for (final v in values)
          Expanded(
            child: Semantics(
              selected: v == selected,
              button: true,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(v);
                },
                child: AnimatedContainer(
                  duration: Motion.fast,
                  curve: Motion.curve,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: v == selected
                        ? context.colors.surface
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: v == selected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .035),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    label(v),
                    textAlign: TextAlign.center,
                    style: context.type.labelMedium?.copyWith(
                      color: v == selected
                          ? context.colors.ink
                          : context.colors.secondary,
                      fontWeight: v == selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class SettingsRow extends StatelessWidget {
  const SettingsRow(
    this.title, {
    super.key,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
  });
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: context.colors.secondary),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.type.bodyLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: context.type.bodyMedium?.copyWith(
                      color: context.colors.secondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing ??
              Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: context.colors.faint,
              ),
        ],
      ),
    ),
  );
}

class DetailPage extends StatelessWidget {
  const DetailPage({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
  });
  final String title;
  final Widget child;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), actions: actions),
    body: SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: child,
        ),
      ),
    ),
  );
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.label, this.child, {super.key});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.type.labelMedium),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirm,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(confirm),
          ),
        ],
      ),
    ) ??
    false;
