import 'package:flutter/material.dart';
import 'dart:math' as math;

class CustomProgressBar extends StatelessWidget {
  final Duration currentTime;
  final Duration totalTime;
  final Function(Duration) onSeek;

  const CustomProgressBar({
    super.key,
    required this.currentTime,
    required this.totalTime,
    required this.onSeek,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final currentSeconds = currentTime.inSeconds.toDouble();
    final totalSeconds = totalTime.inSeconds > 0 ? totalTime.inSeconds.toDouble() : 1.0;
    final progress = currentSeconds / totalSeconds;

    return Column(
      children: [
        GestureDetector(
          onHorizontalDragUpdate: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final position = details.localPosition.dx;
            final percent = math.max(0, math.min(1, position / box.size.width));
            final seekPosition = Duration(seconds: (percent * totalSeconds).round());
            onSeek(seekPosition);
          },
          child: Container(
            height: 30,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
            ),
            clipBehavior: Clip.antiAlias,
            child: CustomPaint(
              painter: StripedProgressBarPainter(
                progress: progress,
                stripeColor1: Colors.yellow,
                stripeColor2: Colors.black,
                progressColor: const Color.fromRGBO(255, 0, 0, 0.5),
              ),
              child: Align(
                alignment: Alignment(math.min(2 * progress - 1, 1), 0),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(currentTime),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              Text(
                _formatDuration(totalTime),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StripedProgressBarPainter extends CustomPainter {
  final double progress;
  final Color stripeColor1;
  final Color stripeColor2;
  final Color progressColor;
  final double stripeWidth = 15.0;
  final double stripeAngle = -45;

  StripedProgressBarPainter({
    required this.progress, 
    required this.stripeColor1, 
    required this.stripeColor2,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Draw the background
    paint.color = Colors.black;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );

    // Calculate stripe width accounting for angle
    final double effectiveWidth = stripeWidth * 1.5;
    
    // Draw the striped pattern
    for (double i = -size.height; i < size.width + size.height; i += effectiveWidth) {
      // First stripe
      paint.color = stripeColor1;
      final pathA = Path()
        ..moveTo(i, 0)
        ..lineTo(i + effectiveWidth, 0)
        ..lineTo(i + effectiveWidth - size.height, size.height)
        ..lineTo(i - size.height, size.height)
        ..close();
      canvas.drawPath(pathA, paint);
      
      // Second stripe
      paint.color = stripeColor2;
      final pathB = Path()
        ..moveTo(i + effectiveWidth, 0)
        ..lineTo(i + effectiveWidth * 2, 0)
        ..lineTo(i + effectiveWidth * 2 - size.height, size.height)
        ..lineTo(i + effectiveWidth - size.height, size.height)
        ..close();
      canvas.drawPath(pathB, paint);
    }

    // Draw a semi-transparent progress overlay
    if (progress > 0) {
      paint.color = progressColor;
      final progressWidth = size.width * progress;
      canvas.drawRect(
        Rect.fromLTWH(0, 0, progressWidth, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(StripedProgressBarPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
