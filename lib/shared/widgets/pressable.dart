import 'package:flutter/material.dart';
import '../../core/theme/app_motion.dart';

/// Reusable press-feedback wrapper used across the app to give consistent
/// micro-interaction feedback (scale + opacity) on interactive surfaces
/// without duplicating the GestureDetector+AnimatedScale pattern.
///
/// Honors [AppMotion.reducedMotion] — disables scale when reduced motion
/// is requested by the OS, preserving functional feedback only.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.opacity = 0.6,
    this.behavior = HitTestBehavior.opaque,
    this.semanticsLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final double opacity;
  final HitTestBehavior behavior;
  final String? semanticsLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  void _setHovered(bool v) {
    if (_hovered == v) return;
    setState(() => _hovered = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = AppMotion.reducedMotion(context);
    final double effectiveScale = reduce ? 1.0 : (_pressed ? widget.scale : 1.0);
    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      child: MouseRegion(
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          behavior: widget.behavior,
          onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
          onTapUp: widget.onTap == null ? null : (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: AnimatedScale(
            scale: effectiveScale,
            duration: AppMotion.press,
            curve: AppMotion.easeOut,
            child: AnimatedOpacity(
              opacity: _pressed ? widget.opacity : 1.0,
              duration: AppMotion.press,
              curve: AppMotion.easeOut,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
