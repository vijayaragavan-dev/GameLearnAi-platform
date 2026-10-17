import 'package:flutter/material.dart';
import '../../core/theme/neo_brutalism.dart';
import '../../core/theme/app_typography.dart';

/// Neo-Brutalist Comic Card with thick 2.5px ink border and hard directional drop shadow.
class BrutalCard extends StatelessWidget {
  const BrutalCard({
    super.key,
    required this.child,
    this.backgroundColor = NeoBrutalColors.surfaceWhite,
    this.borderColor = NeoBrutalColors.ink,
    this.borderWidth = NeoBrutalBorders.standardWidth,
    this.borderRadius = 16.0,
    this.shadowOffset = const Offset(4, 4),
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.onTap,
  });

  final Widget child;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final Offset shadowOffset;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: borderColor,
            offset: shadowOffset,
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      return BrutalPressable(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}

/// Tactile pressable wrapper that simulates mechanical switch action:
/// translates (2, 2) on press into its hard shadow.
class BrutalPressable extends StatefulWidget {
  const BrutalPressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressOffset = const Offset(2.0, 2.0),
  });

  final Widget child;
  final VoidCallback? onTap;
  final Offset pressOffset;

  @override
  State<BrutalPressable> createState() => _BrutalPressableState();
}

class _BrutalPressableState extends State<BrutalPressable> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(
          _isPressed ? widget.pressOffset.dx : 0.0,
          _isPressed ? widget.pressOffset.dy : 0.0,
          0.0,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Neo-Brutalist Action Button with 2.5px ink border and tactile mechanical press.
class BrutalButton extends StatefulWidget {
  const BrutalButton({
    super.key,
    this.text,
    this.label,
    this.onPressed,
    this.onTap,
    this.backgroundColor,
    this.color,
    this.textColor = Colors.white,
    this.icon,
    this.isFullWidth = true,
    this.height = 48.0,
    this.borderRadius = 12.0,
    this.isLoading = false,
  });

  final String? text;
  final String? label;
  final VoidCallback? onPressed;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? color;
  final Color textColor;
  final dynamic icon;
  final bool isFullWidth;
  final double height;
  final double borderRadius;
  final bool isLoading;

  String get effectiveText => text ?? label ?? '';
  VoidCallback? get effectiveOnPressed => onPressed ?? onTap;
  Color get effectiveBg => backgroundColor ?? color ?? NeoBrutalColors.cobaltBlue;

  @override
  State<BrutalButton> createState() => _BrutalButtonState();
}

class _BrutalButtonState extends State<BrutalButton> {
  bool _isPressed = false;

  Widget? _buildIcon(Color effectiveTextColor) {
    if (widget.icon == null) return null;
    if (widget.icon is Widget) return widget.icon as Widget;
    if (widget.icon is IconData) {
      return Icon(widget.icon as IconData, size: 20, color: effectiveTextColor);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.effectiveOnPressed != null && !widget.isLoading;
    final offset = _isPressed && enabled ? const Offset(2, 2) : const Offset(4, 4);
    final effectiveTextColor = enabled ? widget.textColor : NeoBrutalColors.inkSecondary;
    final iconWidget = _buildIcon(effectiveTextColor);

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.effectiveOnPressed?.call();
            }
          : null,
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        transform: Matrix4.translationValues(
          _isPressed && enabled ? 2.0 : 0.0,
          _isPressed && enabled ? 2.0 : 0.0,
          0.0,
        ),
        width: widget.isFullWidth ? double.infinity : null,
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: enabled ? widget.effectiveBg : NeoBrutalColors.inkSecondary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: NeoBrutalColors.ink, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: NeoBrutalColors.ink,
              offset: offset,
              blurRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (iconWidget != null) ...[
                      iconWidget,
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.effectiveText.toUpperCase(),
                      style: TextStyle(
                        fontFamily: AppTypography.displayFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: effectiveTextColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Comic Editorial Badge / Chip with 2px border and hard shadow
class ComicBadge extends StatelessWidget {
  const ComicBadge({
    super.key,
    required this.text,
    this.backgroundColor = NeoBrutalColors.xpYellow,
    this.textColor = NeoBrutalColors.ink,
    this.icon,
    this.borderRadius = 8.0,
    this.fontSize = 11.0,
  });

  final String text;
  final Color backgroundColor;
  final Color textColor;
  final Widget? icon;
  final double borderRadius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: NeoBrutalColors.ink, width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: NeoBrutalColors.ink,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 4),
          ],
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontFamily: AppTypography.displayFamily,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Speech Balloon with authentic comic pointer triangle notch
class SpeechBalloon extends StatelessWidget {
  const SpeechBalloon({
    super.key,
    required this.text,
    this.backgroundColor = Colors.white,
    this.borderColor = NeoBrutalColors.ink,
    this.textColor = NeoBrutalColors.ink,
    this.notchLeft = true,
  });

  final String text;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final bool notchLeft;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SpeechBalloonPainter(
        color: backgroundColor,
        borderColor: borderColor,
        notchLeft: notchLeft,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          notchLeft ? 18.0 : 14.0,
          10.0,
          notchLeft ? 14.0 : 18.0,
          10.0,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: AppTypography.bodyFamily,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: textColor,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _SpeechBalloonPainter extends CustomPainter {
  _SpeechBalloonPainter({
    required this.color,
    required this.borderColor,
    required this.notchLeft,
  });

  final Color color;
  final Color borderColor;
  final bool notchLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        notchLeft ? 8.0 : 0.0,
        0,
        size.width - 8.0,
        size.height,
      ),
      const Radius.circular(12),
    );

    // Hard drop shadow
    final shadowRRect = rrect.shift(const Offset(2.5, 2.5));
    canvas.drawRRect(shadowRRect, shadowPaint);

    // Fill
    canvas.drawRRect(rrect, fillPaint);

    // Notch pointer
    final path = Path();
    if (notchLeft) {
      path.moveTo(8.0, 16.0);
      path.lineTo(0.0, 22.0);
      path.lineTo(8.0, 28.0);
    } else {
      path.moveTo(size.width - 8.0, 16.0);
      path.lineTo(size.width, 22.0);
      path.lineTo(size.width - 8.0, 28.0);
    }
    path.close();

    canvas.drawPath(path, fillPaint);

    // Border strokes
    canvas.drawRRect(rrect, borderPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SpeechBalloonPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.notchLeft != notchLeft;
}

/// Mascot Avatar with comic frame and status star badge
class MascotAvatar extends StatelessWidget {
  const MascotAvatar({
    super.key,
    this.emoji = '🦊',
    this.backgroundColor = NeoBrutalColors.pastelOrange,
    this.size = 46.0,
  });

  final String emoji;
  final Color backgroundColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(size * 0.32),
            border: Border.all(color: NeoBrutalColors.ink, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: NeoBrutalColors.ink,
                offset: Offset(2.5, 2.5),
                blurRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: Text(
              emoji,
              style: TextStyle(fontSize: size * 0.52),
            ),
          ),
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            width: size * 0.4,
            height: size * 0.4,
            decoration: BoxDecoration(
              color: NeoBrutalColors.pastelGreen,
              shape: BoxShape.circle,
              border: Border.all(color: NeoBrutalColors.ink, width: 1.5),
            ),
            child: Center(
              child: Text(
                '★',
                style: TextStyle(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.bold,
                  color: NeoBrutalColors.ink,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Mascot Dialogue Banner combining avatar and speech balloon
class MascotDialogueBanner extends StatelessWidget {
  const MascotDialogueBanner({
    super.key,
    required this.message,
    this.emoji = '🦊',
    this.avatarColor = NeoBrutalColors.pastelOrange,
  });

  final String message;
  final String emoji;
  final Color avatarColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MascotAvatar(
          emoji: emoji,
          backgroundColor: avatarColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SpeechBalloon(
            text: message,
            backgroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
