import 'package:flutter/material.dart';

const kOrange = Color(0xFFFF8A00);
const kYellow = Color(0xFFFFC83D);
const kPanel = Color(0xCC0B0F1A);

/// Full-screen artwork with a dark gradient on top so text stays readable.
/// Replace assets/images/home_bg.jpg with your own picture to change it.
class GameBackground extends StatelessWidget {
  const GameBackground({super.key, required this.child, this.dim = 0.35});

  final Widget child;
  final double dim;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/home_bg.jpg', fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(dim * 0.5),
                Colors.black.withOpacity(dim + 0.25),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// The "ROS OSJA" wordmark.
class GameTitle extends StatelessWidget {
  const GameTitle({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, kYellow, kOrange],
      ).createShader(rect),
      child: Text(
        'ROS OSJA',
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: size * 0.06,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black87, blurRadius: 12, offset: Offset(0, 4))],
        ),
      ),
    );
  }
}

class GameButton extends StatelessWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width,
    this.height = 52,
    this.fontSize = 18,
  });

  final String label;
  final VoidCallback? onPressed;
  final double? width;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kYellow, kOrange],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.85), width: 1.5),
          boxShadow: [
            BoxShadow(color: kOrange.withOpacity(0.45), blurRadius: 18, spreadRadius: 1),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onPressed,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: const Color(0xFF2A1600),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A round avatar made from the player's name: a colour taken from the name
/// plus their initials.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({super.key, required this.name, this.size = 44, this.ring});

  final String name;
  final double size;
  final Color? ring;

  Color _colorFor(String text, {double lightness = 0.5}) {
    var hash = 0;
    for (final unit in text.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return HSLColor.fromAHSL(1, (hash % 360).toDouble(), 0.65, lightness).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final initials = name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_colorFor(name, lightness: 0.62), _colorFor(name, lightness: 0.34)],
        ),
        border: Border.all(color: ring ?? Colors.white70, width: size * 0.06 + 1),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
        ),
      ),
    );
  }
}

class Chip2 extends StatelessWidget {
  const Chip2({super.key, required this.icon, required this.text, this.color = kYellow});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}
