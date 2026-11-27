import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Frosted panel floating above the map (the "liquid glass" surface).
class GlassPanel extends StatelessWidget {
  const GlassPanel({super.key, required this.child, this.padding = const EdgeInsets.all(Space.lg), this.radius = Radii.xl});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surfaceGlass,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: c.border),
            boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 32, offset: Offset(0, 8))],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Round glass icon button for map controls (44×44 touch target).
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({super.key, required this.icon, required this.tooltip, required this.onPressed, this.active = false});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: tooltip,
      child: GlassPanel(
        padding: EdgeInsets.zero,
        radius: 999,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox.square(
              dimension: 48,
              child: Icon(icon, color: active ? c.primary : c.text, semanticLabel: tooltip),
            ),
          ),
        ),
      ),
    );
  }
}
