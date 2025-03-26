import 'package:flutter/material.dart';

class SpeechBubble extends StatelessWidget {
  final Widget child;
  final Color color;

  const SpeechBubble({
    super.key,
    required this.child,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The main bubble
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: child,
        ),
        // The tail
        CustomPaint(
          painter: _SpeechBubbleTailPainter(color: color),
          child: const SizedBox(width: 20, height: 10),
        ),
      ],
    );
  }
}

class _SpeechBubbleTailPainter extends CustomPainter {
  final Color color;

  _SpeechBubbleTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final Path path = Path();
    // Draw a simple triangle pointing downward.
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
