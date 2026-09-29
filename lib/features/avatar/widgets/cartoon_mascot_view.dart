import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/models/mascot_character.dart';
import '../../../core/theme/neo_brutalism.dart';

/// Interactive, animated 2D cartoon mascot widget.
/// Renders the 10 GameLearn AI animal companions using pure Flutter vector graphics.
/// Completely replaces dummy robots with rich animations, blinking, accessories, and squashes.
class CartoonMascotView extends StatefulWidget {
  const CartoonMascotView({
    super.key,
    required this.character,
    this.accessory = MascotAccessory.none,
    this.mood = MascotMood.idle,
    this.size = 110,
    this.isAnimated = true,
    this.onTap,
  });

  final MascotCharacter character;
  final MascotAccessory accessory;
  final MascotMood mood;
  final double size;
  final bool isAnimated;
  final VoidCallback? onTap;

  @override
  State<CartoonMascotView> createState() => _CartoonMascotViewState();
}

class _CartoonMascotViewState extends State<CartoonMascotView>
    with TickerProviderStateMixin {
  late final AnimationController _idleController;
  late final AnimationController _jumpController;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (widget.isAnimated) {
      _idleController.repeat();
    }

    _jumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  @override
  void didUpdateWidget(CartoonMascotView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimated && !_idleController.isAnimating) {
      _idleController.repeat();
    } else if (!widget.isAnimated && _idleController.isAnimating) {
      _idleController.stop();
    }

    if (widget.mood == MascotMood.celebrating && oldWidget.mood != MascotMood.celebrating) {
      _triggerJump();
    }
  }

  void _triggerJump() {
    _jumpController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _idleController.dispose();
    _jumpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final animated = widget.isAnimated && !reduce;

    return GestureDetector(
      onTap: () {
        _triggerJump();
        widget.onTap?.call();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_idleController, _jumpController]),
        builder: (context, _) {
          final idleVal = animated ? _idleController.value : 0.0;
          final jumpVal = _jumpController.value;

          // Vertical float bobbing
          final double bob = animated ? math.sin(idleVal * 2 * math.pi) * 3.5 : 0.0;

          // Wing / arm wave
          double wave = 0.0;
          if (widget.mood == MascotMood.waving || animated) {
            wave = math.sin(idleVal * 4 * math.pi) * 0.16;
          }

          // Blinking: quick natural blink around 50% cycle
          double blink = 0.0;
          if (animated && idleVal > 0.46 && idleVal < 0.52) {
            blink = 1.0;
          }
          if (widget.mood == MascotMood.focused) {
            blink = 0.4; // focused narrowed eyes
          }

          // Jump celebration spring physics
          double jump = 0.0;
          double scaleX = 1.0;
          double scaleY = 1.0;
          double rotation = 0.0;
          bool isCheering = false;

          if (_jumpController.isAnimating) {
            isCheering = true;
            jump = -math.sin(jumpVal * math.pi) * 16.0;
            // Squash and stretch
            scaleY = 1.0 + math.sin(jumpVal * math.pi) * 0.18;
            scaleX = 1.0 - math.sin(jumpVal * math.pi) * 0.10;
            blink = 1.0; // Happy closed eyes when jumping
          } else if (widget.mood == MascotMood.celebrating) {
            isCheering = true;
            jump = -math.sin(idleVal * 4 * math.pi).abs() * 10.0;
            scaleY = 1.0 + math.sin(idleVal * 4 * math.pi).abs() * 0.12;
            scaleX = 1.0 - math.sin(idleVal * 4 * math.pi).abs() * 0.06;
            rotation = math.sin(idleVal * 4 * math.pi) * 0.05;
            blink = 0.8;
          } else if (widget.mood == MascotMood.sad) {
            // Sad droop & heavy sigh animation
            jump = 5.0 + math.sin(idleVal * 2 * math.pi) * 2.0; // sunk down lower
            scaleY = 0.95 + math.sin(idleVal * 2 * math.pi) * 0.02; // squashed/drooped
            scaleX = 1.04;
            rotation = math.sin(idleVal * 2 * math.pi) * 0.03 - 0.03; // tilted down
            blink = 0.5; // drooping eyelids
          } else if (widget.mood == MascotMood.motivating) {
            // Energetic determined bob & power hover
            jump = -math.sin(idleVal * 4 * math.pi).abs() * 6.0;
            scaleY = 1.0 + math.sin(idleVal * 4 * math.pi) * 0.05;
            scaleX = 1.0 - math.sin(idleVal * 4 * math.pi) * 0.03;
            rotation = math.sin(idleVal * 2 * math.pi) * 0.04;
            blink = 0.2; // sharp focused gaze
          }

          return SizedBox(
            width: widget.size,
            height: widget.size * 1.12,
            child: Transform.translate(
              offset: Offset(0, bob + jump),
              child: Transform.rotate(
                angle: rotation,
                child: Transform.scale(
                  scaleX: scaleX,
                  scaleY: scaleY,
                  alignment: Alignment.bottomCenter,
                child: widget.character.imageAsset != null
                    ? Image.asset(
                        widget.character.imageAsset!,
                        width: widget.size,
                        height: widget.size * 1.12,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => CustomPaint(
                          painter: _CartoonMascotPainter(
                            character: widget.character,
                            accessory: widget.accessory,
                            mood: widget.mood,
                            waveAngle: wave,
                            blinkValue: blink,
                            isCheering: isCheering,
                          ),
                        ),
                      )
                    : CustomPaint(
                        painter: _CartoonMascotPainter(
                          character: widget.character,
                          accessory: widget.accessory,
                          mood: widget.mood,
                          waveAngle: wave,
                          blinkValue: blink,
                          isCheering: isCheering,
                        ),
                      ),
                    ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Canvas Painter for all 10 cartoon species with accessories
class _CartoonMascotPainter extends CustomPainter {
  _CartoonMascotPainter({
    required this.character,
    required this.accessory,
    required this.mood,
    required this.waveAngle,
    required this.blinkValue,
    required this.isCheering,
  });

  final MascotCharacter character;
  final MascotAccessory accessory;
  final MascotMood mood;
  final double waveAngle;
  final double blinkValue;
  final bool isCheering;

  static const Color ink = NeoBrutalColors.ink;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 120.0;
    final cx = size.width / 2.0;

    final inkPaint = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final primaryPaint = Paint()
      ..color = character.primaryColor
      ..style = PaintingStyle.fill;

    final secondaryPaint = Paint()
      ..color = character.secondaryColor
      ..style = PaintingStyle.fill;

    final accentPaint = Paint()
      ..color = character.accentColor
      ..style = PaintingStyle.fill;

    final bellyPaint = Paint()
      ..color = character.bellyColor
      ..style = PaintingStyle.fill;

    // 1. Shadow underneath
    final shadowPaint = Paint()..color = ink.withValues(alpha: 0.18);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, size.height - 4 * s), width: 72 * s, height: 12 * s),
      shadowPaint,
    );

    // 2. Character-specific Back Features (Cape, Tail, Horns, Wings)
    _paintBackFeatures(canvas, cx, s, primaryPaint, secondaryPaint, accentPaint, inkPaint);

    // 3. Feet / Paws
    _paintFeet(canvas, cx, s, accentPaint, secondaryPaint, inkPaint);

    // 4. Main Body / Head
    _paintBody(canvas, cx, s, primaryPaint, secondaryPaint, bellyPaint, inkPaint);

    // 5. Ears / Crests / Antennas
    _paintEars(canvas, cx, s, primaryPaint, secondaryPaint, inkPaint);

    // 6. Face: Big Expressive Eyes
    _paintFace(canvas, cx, s, accentPaint, inkPaint);

    // 7. Arms / Wings in front
    _paintArms(canvas, cx, s, primaryPaint, inkPaint);

    // 8. Equipped Accessory
    _paintAccessory(canvas, cx, s, inkPaint);
  }

  void _paintBackFeatures(
    Canvas canvas,
    double cx,
    double s,
    Paint primary,
    Paint secondary,
    Paint accent,
    Paint inkPaint,
  ) {
    // Cape accessory in back
    if (accessory == MascotAccessory.cape) {
      final capePath = Path()
        ..moveTo(cx - 24 * s, 48 * s)
        ..lineTo(cx - 38 * s, 102 * s)
        ..quadraticBezierTo(cx, 114 * s, cx + 38 * s, 102 * s)
        ..lineTo(cx + 24 * s, 48 * s)
        ..close();
      canvas.drawPath(capePath, Paint()..color = const Color(0xFFEF4444));
      canvas.drawPath(capePath, inkPaint);
    }

    // Tails / Back Wings based on species
    if (character.id == 'spark_fox') {
      // Big fluffy bushy fox tail on right
      final tail = Path()
        ..moveTo(cx + 18 * s, 80 * s)
        ..quadraticBezierTo(cx + 56 * s, 70 * s, cx + 54 * s, 42 * s)
        ..quadraticBezierTo(cx + 42 * s, 34 * s, cx + 32 * s, 54 * s)
        ..quadraticBezierTo(cx + 26 * s, 72 * s, cx + 14 * s, 88 * s)
        ..close();
      canvas.drawPath(tail, primary);
      canvas.drawPath(tail, inkPaint);

      // Tail white tip
      final tip = Path()
        ..moveTo(cx + 48 * s, 54 * s)
        ..quadraticBezierTo(cx + 56 * s, 70 * s, cx + 54 * s, 42 * s)
        ..quadraticBezierTo(cx + 42 * s, 34 * s, cx + 38 * s, 46 * s)
        ..close();
      canvas.drawPath(tip, Paint()..color = Colors.white);
      canvas.drawPath(tip, inkPaint);
    } else if (character.id == 'blaze_dragon') {
      // Dragon mythic wings
      final leftWing = Path()
        ..moveTo(cx - 16 * s, 50 * s)
        ..lineTo(cx - 48 * s, 26 * s)
        ..lineTo(cx - 36 * s, 48 * s)
        ..lineTo(cx - 46 * s, 62 * s)
        ..lineTo(cx - 18 * s, 68 * s)
        ..close();
      canvas.drawPath(leftWing, accent);
      canvas.drawPath(leftWing, inkPaint);

      final rightWing = Path()
        ..moveTo(cx + 16 * s, 50 * s)
        ..lineTo(cx + 48 * s, 26 * s)
        ..lineTo(cx + 36 * s, 48 * s)
        ..lineTo(cx + 46 * s, 62 * s)
        ..lineTo(cx + 18 * s, 68 * s)
        ..close();
      canvas.drawPath(rightWing, accent);
      canvas.drawPath(rightWing, inkPaint);
    } else if (character.id == 'milo_monkey') {
      // Curly monkey tail
      final tail = Path()
        ..moveTo(cx + 18 * s, 85 * s)
        ..cubicTo(cx + 48 * s, 92 * s, cx + 52 * s, 50 * s, cx + 38 * s, 50 * s)
        ..cubicTo(cx + 32 * s, 50 * s, cx + 36 * s, 62 * s, cx + 44 * s, 60 * s);
      final tailPaint = Paint()
        ..color = character.primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0 * s
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(tail, tailPaint);
      canvas.drawPath(tail, inkPaint);
    }
  }

  void _paintFeet(Canvas canvas, double cx, double s, Paint accent, Paint secondary, Paint inkPaint) {
    final footColor = character.accentColor;
    final footPaint = Paint()..color = footColor;

    // Left foot
    final leftFoot = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 16 * s, 98 * s), width: 18 * s, height: 10 * s),
      Radius.circular(5 * s),
    );
    canvas.drawRRect(leftFoot, footPaint);
    canvas.drawRRect(leftFoot, inkPaint);

    // Right foot
    final rightFoot = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + 16 * s, 98 * s), width: 18 * s, height: 10 * s),
      Radius.circular(5 * s),
    );
    canvas.drawRRect(rightFoot, footPaint);
    canvas.drawRRect(rightFoot, inkPaint);
  }

  void _paintBody(
    Canvas canvas,
    double cx,
    double s,
    Paint primary,
    Paint secondary,
    Paint belly,
    Paint inkPaint,
  ) {
    // Plump egg/round cartoon body shape
    final bodyRect = Rect.fromCenter(center: Offset(cx, 62 * s), width: 70 * s, height: 72 * s);
    final bodyRRect = RRect.fromRectAndRadius(bodyRect, Radius.circular(34 * s));
    canvas.drawRRect(bodyRRect, primary);
    canvas.drawRRect(bodyRRect, inkPaint);

    // Soft Belly Patch
    final bellyRect = Rect.fromCenter(center: Offset(cx, 74 * s), width: 44 * s, height: 42 * s);
    final bellyRRect = RRect.fromRectAndRadius(bellyRect, Radius.circular(20 * s));
    canvas.drawRRect(bellyRRect, belly);
    canvas.drawRRect(bellyRRect, inkPaint);

    // Subtle belly pattern for owl / turtle
    if (character.id == 'pip_owl') {
      final feather = Path()
        ..moveTo(cx - 8 * s, 72 * s)
        ..quadraticBezierTo(cx - 4 * s, 78 * s, cx, 72 * s)
        ..moveTo(cx + 2 * s, 72 * s)
        ..quadraticBezierTo(cx + 6 * s, 78 * s, cx + 10 * s, 72 * s)
        ..moveTo(cx - 4 * s, 80 * s)
        ..quadraticBezierTo(cx, 86 * s, cx + 4 * s, 80 * s);
      canvas.drawPath(
        feather,
        Paint()
          ..color = const Color(0xFF46A302)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8 * s
          ..strokeCap = StrokeCap.round,
      );
    } else if (character.id == 'toby_turtle') {
      // Shell scute markings
      final shellLine = Path()
        ..moveTo(cx - 12 * s, 74 * s)
        ..lineTo(cx + 12 * s, 74 * s)
        ..moveTo(cx, 62 * s)
        ..lineTo(cx, 86 * s);
      canvas.drawPath(
        shellLine,
        Paint()
          ..color = character.secondaryColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 * s,
      );
    }
  }

  void _paintEars(Canvas canvas, double cx, double s, Paint primary, Paint secondary, Paint inkPaint) {
    if (character.id == 'pip_owl') {
      // Owl cute ear tufts
      final leftTuft = Path()
        ..moveTo(cx - 26 * s, 34 * s)
        ..lineTo(cx - 36 * s, 18 * s)
        ..lineTo(cx - 16 * s, 28 * s)
        ..close();
      canvas.drawPath(leftTuft, primary);
      canvas.drawPath(leftTuft, inkPaint);

      final rightTuft = Path()
        ..moveTo(cx + 26 * s, 34 * s)
        ..lineTo(cx + 36 * s, 18 * s)
        ..lineTo(cx + 16 * s, 28 * s)
        ..close();
      canvas.drawPath(rightTuft, primary);
      canvas.drawPath(rightTuft, inkPaint);
    } else if (character.id == 'spark_fox' || character.id == 'luna_lynx') {
      // Pointed alert fox/cat ears
      final leftEar = Path()
        ..moveTo(cx - 28 * s, 38 * s)
        ..lineTo(cx - 34 * s, 14 * s)
        ..lineTo(cx - 12 * s, 28 * s)
        ..close();
      canvas.drawPath(leftEar, primary);
      canvas.drawPath(leftEar, inkPaint);

      // Inner ear pink/cream
      final innerEar = Path()
        ..moveTo(cx - 26 * s, 34 * s)
        ..lineTo(cx - 30 * s, 19 * s)
        ..lineTo(cx - 16 * s, 28 * s)
        ..close();
      canvas.drawPath(innerEar, Paint()..color = const Color(0xFFFFD1DC));

      final rightEar = Path()
        ..moveTo(cx + 28 * s, 38 * s)
        ..lineTo(cx + 34 * s, 14 * s)
        ..lineTo(cx + 12 * s, 28 * s)
        ..close();
      canvas.drawPath(rightEar, primary);
      canvas.drawPath(rightEar, inkPaint);

      final rightInner = Path()
        ..moveTo(cx + 26 * s, 34 * s)
        ..lineTo(cx + 30 * s, 19 * s)
        ..lineTo(cx + 16 * s, 28 * s)
        ..close();
      canvas.drawPath(rightInner, Paint()..color = const Color(0xFFFFD1DC));
    } else if (character.id == 'barnaby_bear' || character.id == 'milo_monkey') {
      // Round teddy bear / monkey ears
      final earRadius = 11 * s;
      canvas.drawCircle(Offset(cx - 28 * s, 32 * s), earRadius, primary);
      canvas.drawCircle(Offset(cx - 28 * s, 32 * s), earRadius, inkPaint);
      canvas.drawCircle(Offset(cx - 28 * s, 32 * s), earRadius * 0.55, Paint()..color = character.bellyColor);

      canvas.drawCircle(Offset(cx + 28 * s, 32 * s), earRadius, primary);
      canvas.drawCircle(Offset(cx + 28 * s, 32 * s), earRadius, inkPaint);
      canvas.drawCircle(Offset(cx + 28 * s, 32 * s), earRadius * 0.55, Paint()..color = character.bellyColor);
    } else if (character.id == 'blaze_dragon') {
      // Dragon Golden Horns
      final leftHorn = Path()
        ..moveTo(cx - 24 * s, 32 * s)
        ..quadraticBezierTo(cx - 34 * s, 10 * s, cx - 40 * s, 12 * s)
        ..quadraticBezierTo(cx - 26 * s, 22 * s, cx - 14 * s, 28 * s)
        ..close();
      canvas.drawPath(leftHorn, Paint()..color = const Color(0xFFFBBF24));
      canvas.drawPath(leftHorn, inkPaint);

      final rightHorn = Path()
        ..moveTo(cx + 24 * s, 32 * s)
        ..quadraticBezierTo(cx + 34 * s, 10 * s, cx + 40 * s, 12 * s)
        ..quadraticBezierTo(cx + 26 * s, 22 * s, cx + 14 * s, 28 * s)
        ..close();
      canvas.drawPath(rightHorn, Paint()..color = const Color(0xFFFBBF24));
      canvas.drawPath(rightHorn, inkPaint);
    } else if (character.id == 'astra_griffin') {
      // Griffin Golden Crown Feathers
      final crest = Path()
        ..moveTo(cx - 10 * s, 28 * s)
        ..lineTo(cx, 12 * s)
        ..lineTo(cx + 10 * s, 28 * s)
        ..close();
      canvas.drawPath(crest, Paint()..color = const Color(0xFFFACC15));
      canvas.drawPath(crest, inkPaint);
    }
  }

  void _paintFace(Canvas canvas, double cx, double s, Paint accent, Paint inkPaint) {
    final eyeY = 52 * s;
    final eyeSpacing = 16 * s;
    final eyeRadius = 11.5 * s;

    // Happy smiling squinted eyes (celebrating/squint)
    if (blinkValue >= 0.8 || isCheering) {
      // Left smile curve eye
      final leftEyePath = Path()
        ..moveTo(cx - eyeSpacing - 9 * s, eyeY + 2 * s)
        ..quadraticBezierTo(cx - eyeSpacing, eyeY - 7 * s, cx - eyeSpacing + 9 * s, eyeY + 2 * s);
      final squintPaint = Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2 * s
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(leftEyePath, squintPaint);

      // Right smile curve eye
      final rightEyePath = Path()
        ..moveTo(cx + eyeSpacing - 9 * s, eyeY + 2 * s)
        ..quadraticBezierTo(cx + eyeSpacing, eyeY - 7 * s, cx + eyeSpacing + 9 * s, eyeY + 2 * s);
      canvas.drawPath(rightEyePath, squintPaint);
    } else {
      // Big expressive Duolingo style cartoon eyes
      // White sclera
      final leftSclera = Rect.fromCenter(
        center: Offset(cx - eyeSpacing, eyeY),
        width: eyeRadius * 2,
        height: (eyeRadius * 2) * (1.0 - (blinkValue * 0.85)),
      );
      final rightSclera = Rect.fromCenter(
        center: Offset(cx + eyeSpacing, eyeY),
        width: eyeRadius * 2,
        height: (eyeRadius * 2) * (1.0 - (blinkValue * 0.85)),
      );

      final whitePaint = Paint()..color = Colors.white;
      canvas.drawOval(leftSclera, whitePaint);
      canvas.drawOval(leftSclera, inkPaint);
      canvas.drawOval(rightSclera, whitePaint);
      canvas.drawOval(rightSclera, inkPaint);

      // Dark pupils with twinkle stars
      final pupilY = (mood == MascotMood.thinking) ? eyeY - 2 * s : eyeY;
      final pupilPaint = Paint()..color = ink;
      canvas.drawCircle(Offset(cx - eyeSpacing + 1.5 * s, pupilY), 5.5 * s, pupilPaint);
      canvas.drawCircle(Offset(cx + eyeSpacing + 1.5 * s, pupilY), 5.5 * s, pupilPaint);

      // Cute white catchlights
      canvas.drawCircle(Offset(cx - eyeSpacing - 0.5 * s, pupilY - 2 * s), 2.2 * s, whitePaint);
      canvas.drawCircle(Offset(cx + eyeSpacing - 0.5 * s, pupilY - 2 * s), 2.2 * s, whitePaint);
      canvas.drawCircle(Offset(cx - eyeSpacing + 3.0 * s, pupilY + 1.5 * s), 1.2 * s, whitePaint);
      canvas.drawCircle(Offset(cx + eyeSpacing + 3.0 * s, pupilY + 1.5 * s), 1.2 * s, whitePaint);
    }

    // Beak / Snout / Mouth
    if (character.id == 'pip_owl' || character.id == 'pippin_penguin' || character.id == 'astra_griffin') {
      // Cute triangular bird beak
      final beak = Path()
        ..moveTo(cx - 7 * s, 60 * s)
        ..lineTo(cx + 7 * s, 60 * s)
        ..lineTo(cx, 71 * s)
        ..close();
      canvas.drawPath(beak, Paint()..color = const Color(0xFFF59E0B));
      canvas.drawPath(beak, inkPaint);
    } else if (character.id == 'finley_frog') {
      // Big friendly wide frog mouth
      final frogMouth = Path()
        ..moveTo(cx - 16 * s, 64 * s)
        ..quadraticBezierTo(cx, 74 * s, cx + 16 * s, 64 * s);
      canvas.drawPath(
        frogMouth,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4 * s
          ..strokeCap = StrokeCap.round,
      );
    } else {
      // Snout patch with cute dark nose
      final snoutRect = Rect.fromCenter(center: Offset(cx, 63 * s), width: 18 * s, height: 12 * s);
      canvas.drawRRect(RRect.fromRectAndRadius(snoutRect, Radius.circular(6 * s)), Paint()..color = character.bellyColor);
      canvas.drawRRect(RRect.fromRectAndRadius(snoutRect, Radius.circular(6 * s)), inkPaint);

      // Nose
      canvas.drawCircle(Offset(cx, 61 * s), 2.6 * s, Paint()..color = ink);

      // Smile
      final smile = Path()
        ..moveTo(cx - 4 * s, 65 * s)
        ..quadraticBezierTo(cx, 68 * s, cx + 4 * s, 65 * s);
      canvas.drawPath(
        smile,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8 * s
          ..strokeCap = StrokeCap.round,
      );
    }

    // Blushing rosy cheeks
    final blushPaint = Paint()..color = const Color(0xFFFF6B6B).withValues(alpha: 0.35);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 24 * s, 63 * s), width: 8 * s, height: 5 * s), blushPaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 24 * s, 63 * s), width: 8 * s, height: 5 * s), blushPaint);
  }

  void _paintArms(Canvas canvas, double cx, double s, Paint primary, Paint inkPaint) {
    // Left arm / wing with waving rotation
    canvas.save();
    canvas.translate(cx - 30 * s, 64 * s);
    canvas.rotate(waveAngle - 0.1);
    final leftWing = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-16 * s, 10 * s, -8 * s, 26 * s)
      ..quadraticBezierTo(4 * s, 22 * s, 8 * s, 6 * s)
      ..close();
    canvas.drawPath(leftWing, primary);
    canvas.drawPath(leftWing, inkPaint);
    canvas.restore();

    // Right arm / wing
    canvas.save();
    canvas.translate(cx + 30 * s, 64 * s);
    final rightWing = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(16 * s, 10 * s, 8 * s, 26 * s)
      ..quadraticBezierTo(-4 * s, 22 * s, -8 * s, 6 * s)
      ..close();
    canvas.drawPath(rightWing, primary);
    canvas.drawPath(rightWing, inkPaint);
    canvas.restore();
  }

  void _paintAccessory(Canvas canvas, double cx, double s, Paint inkPaint) {
    switch (accessory) {
      case MascotAccessory.none:
        break;

      case MascotAccessory.crown:
        final crownPath = Path()
          ..moveTo(cx - 18 * s, 24 * s)
          ..lineTo(cx - 20 * s, 8 * s)
          ..lineTo(cx - 10 * s, 16 * s)
          ..lineTo(cx, 4 * s)
          ..lineTo(cx + 10 * s, 16 * s)
          ..lineTo(cx + 20 * s, 8 * s)
          ..lineTo(cx + 18 * s, 24 * s)
          ..close();
        final gold = Paint()..color = const Color(0xFFFBBF24);
        canvas.drawPath(crownPath, gold);
        canvas.drawPath(crownPath, inkPaint);
        // Crown jewels
        canvas.drawCircle(Offset(cx, 16 * s), 2.5 * s, Paint()..color = const Color(0xFFEF4444));
        break;

      case MascotAccessory.wizardHat:
        final hatBrim = Path()
          ..moveTo(cx - 28 * s, 26 * s)
          ..quadraticBezierTo(cx, 22 * s, cx + 28 * s, 26 * s)
          ..quadraticBezierTo(cx, 32 * s, cx - 28 * s, 26 * s);
        final purple = Paint()..color = const Color(0xFF7C3AED);
        canvas.drawPath(hatBrim, purple);
        canvas.drawPath(hatBrim, inkPaint);

        final cone = Path()
          ..moveTo(cx - 18 * s, 25 * s)
          ..lineTo(cx + 6 * s, -8 * s)
          ..lineTo(cx + 18 * s, 25 * s)
          ..close();
        canvas.drawPath(cone, purple);
        canvas.drawPath(cone, inkPaint);

        // Gold star on hat
        canvas.drawCircle(Offset(cx + 6 * s, -8 * s), 3.5 * s, Paint()..color = const Color(0xFFFDE047));
        break;

      case MascotAccessory.goggles:
        final goggleY = 50 * s;
        final lensPaint = Paint()..color = const Color(0xFF06B6D4);
        canvas.drawCircle(Offset(cx - 16 * s, goggleY), 10 * s, lensPaint);
        canvas.drawCircle(Offset(cx - 16 * s, goggleY), 10 * s, inkPaint);
        canvas.drawCircle(Offset(cx + 16 * s, goggleY), 10 * s, lensPaint);
        canvas.drawCircle(Offset(cx + 16 * s, goggleY), 10 * s, inkPaint);
        // Bridge
        canvas.drawRect(Rect.fromCenter(center: Offset(cx, goggleY), width: 8 * s, height: 4 * s), inkPaint);
        break;

      case MascotAccessory.halo:
        final haloPaint = Paint()
          ..color = const Color(0xFFFDE047)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5 * s;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, 14 * s), width: 38 * s, height: 14 * s),
          haloPaint,
        );
        break;

      case MascotAccessory.flower:
        final flowerCenter = Offset(cx + 22 * s, 30 * s);
        final petalPaint = Paint()..color = const Color(0xFFF472B6);
        for (int i = 0; i < 5; i++) {
          final rad = i * 2 * math.pi / 5;
          final px = flowerCenter.dx + math.cos(rad) * 6 * s;
          final py = flowerCenter.dy + math.sin(rad) * 6 * s;
          canvas.drawCircle(Offset(px, py), 4.5 * s, petalPaint);
        }
        canvas.drawCircle(flowerCenter, 3.5 * s, Paint()..color = const Color(0xFFFBBF24));
        break;

      case MascotAccessory.headphones:
        final hpY = 48 * s;
        final band = Path()
          ..moveTo(cx - 28 * s, hpY)
          ..quadraticBezierTo(cx, 16 * s, cx + 28 * s, hpY);
        final bandPaint = Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0 * s
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(band, bandPaint);

        final earCupPaint = Paint()..color = const Color(0xFFEF4444);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - 29 * s, hpY), width: 8 * s, height: 16 * s), Radius.circular(4 * s)),
          earCupPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx - 29 * s, hpY), width: 8 * s, height: 16 * s), Radius.circular(4 * s)),
          inkPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 29 * s, hpY), width: 8 * s, height: 16 * s), Radius.circular(4 * s)),
          earCupPaint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + 29 * s, hpY), width: 8 * s, height: 16 * s), Radius.circular(4 * s)),
          inkPaint,
        );
        break;

      case MascotAccessory.cape:
        // Already painted in back
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _CartoonMascotPainter oldDelegate) {
    return oldDelegate.character != character ||
        oldDelegate.accessory != accessory ||
        oldDelegate.mood != mood ||
        oldDelegate.waveAngle != waveAngle ||
        oldDelegate.blinkValue != blinkValue ||
        oldDelegate.isCheering != isCheering;
  }
}
