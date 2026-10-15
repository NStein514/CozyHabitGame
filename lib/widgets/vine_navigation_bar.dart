import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One continuous vine enters from the screen edge and curls around its target.
class VineNavigationBar extends StatefulWidget {
  const VineNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  State<VineNavigationBar> createState() => _VineNavigationBarState();
}

class _VineNavigationBarState extends State<VineNavigationBar>
    with SingleTickerProviderStateMixin {
  late final _growth = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 680),
  );
  ui.Image? _runner;
  ui.Image? _frame;
  bool _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _loadArt();
  }

  Future<ui.Image> _decode(String path) async {
    final bytes = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  Future<void> _loadArt() async {
    final images = await Future.wait([
      _decode('assets/images/navigation/vine_runner.png'),
      _decode('assets/images/navigation/vine_frame.png'),
    ]);
    if (!mounted) {
      for (final image in images) {
        image.dispose();
      }
      return;
    }
    setState(() {
      _runner = images[0];
      _frame = images[1];
    });
    _startGrowth();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion) _growth.value = 1;
  }

  @override
  void didUpdateWidget(covariant VineNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) _startGrowth();
  }

  void _startGrowth() {
    if (_runner == null) return;
    if (_reducedMotion) {
      _growth.value = 1;
    } else {
      _growth.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _growth.dispose();
    _runner?.dispose();
    _frame?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      NavigationBar(
        height: 74,
        selectedIndex: widget.selectedIndex,
        onDestinationSelected: widget.onDestinationSelected,
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        destinations: widget.destinations,
      ),
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: 49,
        child: IgnorePointer(
          child: ExcludeSemantics(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _growth,
                builder: (context, _) => CustomPaint(
                  key: const Key('navigation-growing-vine'),
                  painter: VineGrowthPainter(
                    runner: _runner,
                    frame: _frame,
                    progress: _growth.value,
                    selectedIndex: widget.selectedIndex,
                    count: widget.destinations.length,
                    direction: Directionality.of(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class VineGrowthPainter extends CustomPainter {
  const VineGrowthPainter({
    required this.runner,
    required this.frame,
    required this.progress,
    required this.selectedIndex,
    required this.count,
    required this.direction,
  });
  final ui.Image? runner;
  final ui.Image? frame;
  final double progress;
  final int selectedIndex;
  final int count;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    if (runner == null || frame == null || progress == 0) return;
    final visualIndex = direction == TextDirection.ltr
        ? selectedIndex
        : count - 1 - selectedIndex;
    final centerX = size.width * (visualIndex + .5) / count;
    final stemProgress = Curves.easeOutCubic.transform(
      (progress / .58).clamp(0.0, 1.0),
    );
    final curlProgress = Curves.easeInOut.transform(
      ((progress - .58) / .42).clamp(0.0, 1.0),
    );
    final paint = Paint()..filterQuality = FilterQuality.medium;
    final width = math.min(74.0, size.width / count - 2);
    final joinX = centerX + width * .30;
    // Crop only transparent margins at render time; retain the original artwork.
    final source = Rect.fromLTWH(
      0,
      runner!.height * .32,
      runner!.width.toDouble(),
      runner!.height * .34,
    );
    canvas.save();
    // Enter at the physical right edge, expanding toward the selected tab.
    canvas.clipRect(
      Rect.fromLTRB(
        size.width - (size.width - joinX) * stemProgress,
        0,
        size.width,
        size.height,
      ),
    );
    final vertices = ui.Vertices(
      ui.VertexMode.triangleStrip,
      [
        Offset(joinX, -2),
        Offset(joinX, 22),
        Offset(size.width + 12, 7),
        Offset(size.width + 12, 13),
      ],
      textureCoordinates: [
        source.topLeft,
        source.bottomLeft,
        source.topRight,
        source.bottomRight,
      ],
    );
    final branchPaint = Paint()
      ..filterQuality = FilterQuality.medium
      ..shader = ImageShader(
        runner!,
        TileMode.clamp,
        TileMode.clamp,
        Matrix4.identity().storage,
      );
    canvas.drawVertices(vertices, BlendMode.srcOver, branchPaint);
    vertices.dispose();
    canvas.restore();
    if (curlProgress == 0) return;
    final center = Offset(centerX, 25);
    final bounds = Rect.fromCenter(center: center, width: width, height: 48);
    canvas.save();
    if (curlProgress < 1) {
      final sweep = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: 70),
          -math.pi / 4,
          -math.pi * 2 * curlProgress,
          false,
        )
        ..close();
      canvas.clipPath(sweep);
    }
    canvas.drawImageRect(
      frame!,
      Rect.fromLTWH(
        frame!.width * .015,
        frame!.height * .10,
        frame!.width * .97,
        frame!.height * .74,
      ),
      bounds,
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant VineGrowthPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      selectedIndex != oldDelegate.selectedIndex ||
      runner != oldDelegate.runner ||
      frame != oldDelegate.frame ||
      count != oldDelegate.count ||
      direction != oldDelegate.direction;
}
