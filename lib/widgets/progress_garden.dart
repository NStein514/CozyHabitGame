import 'package:flutter/material.dart';

import '../garden_store.dart';
import '../theme/cozy_theme.dart';

class ProgressGarden extends StatelessWidget {
  const ProgressGarden({super.key, required this.store});

  final GardenStore store;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: const Color(0xFFCEE6D5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18356859),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: ProgressGardenPainter()),
          ),
          Positioned(
            left: 22,
            top: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .75),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '${(store.dayProgress * 100).round()}% tended',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: forest,
                ),
              ),
            ),
          ),
          Positioned(
            right: 22,
            top: 18,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: store.dayProgress),
              duration: const Duration(milliseconds: 700),
              builder: (context, value, child) => SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: value,
                      strokeWidth: 6,
                      color: forest,
                      backgroundColor: Colors.white54,
                    ),
                    Text(
                      '${store.todayDone}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PlantStage(
                  progress: (store.dayProgress * 3).clamp(0, 1),
                  assetPath: 'assets/images/plants/tulips.png',
                ),
                PlantStage(
                  progress: (store.dayProgress * 3 - .85).clamp(0, 1),
                  assetPath: 'assets/images/plants/sunflower.png',
                ),
                PlantStage(
                  progress: (store.dayProgress * 3 - 1.7).clamp(0, 1),
                  assetPath: 'assets/images/plants/daisies.png',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PlantStage extends StatelessWidget {
  const PlantStage({
    super.key,
    required this.progress,
    required this.assetPath,
  });

  final double progress;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final visibleProgress = .16 + progress * .84;
    return SizedBox(
      width: 82,
      height: 92,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: 58,
              height: 13,
              decoration: BoxDecoration(
                color: const Color(0xFF7A5B3B),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: const Color(0xFF4D5730), width: 2),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 4,
            child: AnimatedScale(
              scale: .25 + progress * .75,
              alignment: Alignment.bottomCenter,
              duration: const Duration(milliseconds: 550),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: visibleProgress,
                duration: const Duration(milliseconds: 350),
                child: Image.asset(
                  assetPath,
                  height: 84,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressGardenPainter extends CustomPainter {
  const ProgressGardenPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFF9EFCB);
    canvas.drawCircle(Offset(size.width * .82, 32), 26, paint);
    paint.color = const Color(0xFF9EC8A6);
    canvas.drawOval(Rect.fromLTWH(-30, 100, size.width * .78, 130), paint);
    paint.color = const Color(0xFF7FAE8B);
    canvas.drawOval(
      Rect.fromLTWH(size.width * .35, 94, size.width * .8, 140),
      paint,
    );
    paint.color = Colors.white.withValues(alpha: .45);
    for (var index = 0; index < 14; index++) {
      canvas.drawCircle(
        Offset((index * 47) % size.width, 28 + (index * 31) % 90),
        index.isEven ? 2.5 : 1.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ProgressGardenPainter oldDelegate) => false;
}
