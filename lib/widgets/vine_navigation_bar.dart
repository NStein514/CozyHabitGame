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
    duration: const Duration(milliseconds: 800),
  );
  ui.Image? _artwork;
  bool _reducedMotion = false;
  VineScene _from = const VineScene(extent: -.08, crowns: []);
  double _target = .1;

  VineScene get _scene => VineScene.transition(
    _from,
    _target,
    _growth.value,
    widget.destinations.length,
  );

  double get _selectedCenter {
    final index = Directionality.of(context) == TextDirection.ltr
        ? widget.selectedIndex
        : widget.destinations.length - 1 - widget.selectedIndex;
    return (index + .5) / widget.destinations.length;
  }

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
    final artwork = await _decode(
      'assets/images/navigation/vine_navigation.png',
    );
    if (!mounted) {
      artwork.dispose();
      return;
    }
    setState(() => _artwork = artwork);
    _startGrowth();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    final target = _selectedCenter;
    if (target != _target) {
      _from = _scene;
      _target = target;
    }
    if (_reducedMotion) _growth.value = 1;
  }

  @override
  void didUpdateWidget(covariant VineNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) _startGrowth();
  }

  void _startGrowth() {
    _from = _scene;
    _target = _selectedCenter;
    if (_artwork == null) return;
    if (_reducedMotion) {
      _growth.value = 1;
    } else {
      _growth.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _growth.dispose();
    _artwork?.dispose();
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
                    artwork: _artwork,
                    scene: _scene,
                    target: _target,
                    retreat: _from.extent > _target
                        ? math.sin(math.pi * _growth.value)
                        : 0,
                    decay: _from.extent > _target ? _growth.value : 0,
                    ashExtent: _from.extent,
                    count: widget.destinations.length,
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

/// A snapshot lets a new tap continue from the vine's visible position.
@immutable
class VineCrown {
  const VineCrown({
    required this.center,
    this.growth = 1,
    this.opacity = 1,
    this.wilt = 0,
    this.tightness = 0,
  });
  final double center;
  final double growth;
  final double opacity;
  final double wilt;
  final double tightness;
}

@immutable
class VineScene {
  const VineScene({required this.extent, required this.crowns});
  final double extent;
  final List<VineCrown> crowns;

  static VineScene transition(
    VineScene from,
    double target,
    double progress,
    int count,
  ) {
    if (progress == 0) return from;
    final desired = [
      for (var i = 0; i < count; i++)
        if ((i + .5) / count <= target + .001) (i + .5) / count,
    ];
    if (progress == 1) {
      return VineScene(
        extent: target,
        crowns: [
          for (final center in desired)
            VineCrown(
              center: center,
              tightness: center < target - .001 ? 1 : 0,
            ),
        ],
      );
    }
    final retreating = target < from.extent;
    final travel = Curves.easeInOutCubic.transform(
      (progress / .8).clamp(0.0, 1.0),
    );
    final extent = ui.lerpDouble(from.extent, target, travel)!;
    final bloom = Curves.easeInOut.transform(
      retreating
          ? (progress / .45).clamp(0.0, 1.0)
          : ((progress - .58) / .42).clamp(0.0, 1.0),
    );
    final settle = Curves.easeInOut.transform(progress);
    final crowns = <VineCrown>[];
    for (final center in desired) {
      VineCrown? old;
      for (final crown in from.crowns) {
        if ((crown.center - center).abs() < .001) old = crown;
      }
      final active = (center - target).abs() < .001;
      final reveal = active
          ? bloom
          : ((extent - center + .06) / .12).clamp(0.0, 1.0);
      crowns.add(
        VineCrown(
          center: center,
          growth: ui.lerpDouble(old?.growth ?? 0, 1, reveal)!,
          opacity: ui.lerpDouble(old?.opacity ?? 1, 1, settle)!,
          wilt: (old?.wilt ?? 0) * (1 - settle),
          tightness: ui.lerpDouble(
            old?.tightness ?? (active ? 0 : 1),
            active ? 0 : 1,
            settle,
          )!,
        ),
      );
    }
    for (final old in from.crowns) {
      if (old.center <= target + .001) continue;
      final wilt = Curves.easeInOut.transform(progress);
      final dissolve = Curves.easeIn.transform(
        ((progress - .28) / .72).clamp(0.0, 1.0),
      );
      crowns.add(
        VineCrown(
          center: old.center,
          growth: old.growth,
          opacity: old.opacity * (1 - dissolve),
          tightness: old.tightness,
          wilt: ui.lerpDouble(old.wilt, 1, wilt)!,
        ),
      );
    }
    return VineScene(extent: extent, crowns: crowns);
  }
}

class VineGrowthPainter extends CustomPainter {
  const VineGrowthPainter({
    required this.artwork,
    required this.scene,
    required this.target,
    required this.retreat,
    required this.count,
    this.decay = 0,
    this.ashExtent = 0,
  });
  final ui.Image? artwork;
  final VineScene scene;
  final double target;
  final double retreat;
  final int count;
  final double decay;
  final double ashExtent;

  @override
  void paint(Canvas canvas, Size size) {
    final art = artwork;
    if (art == null || scene.extent < 0) return;
    final slot = size.width / count;
    final end = math.min(size.width, scene.extent * size.width + slot * .43);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.save();
    // Rounded, staggered shoots keep the frontier looking alive while paused.
    // The same contour travels with growth, revealing the connected artwork.
    final growingEdge = Path()
      ..moveTo(0, 0)
      ..lineTo(end - 3, 0)
      ..lineTo(end - 3, 15)
      ..cubicTo(end - 3, 18, end + 1, 18, end + 2, 20)
      ..cubicTo(end + 5, 16, end + 8, 19, end + 6, 23)
      ..cubicTo(end + 12, 21, end + 12, 28, end + 7, 28)
      ..cubicTo(end + 8, 32, end + 3, 34, end + 1, 30)
      ..cubicTo(end - 1, 32, end - 3, 34, end - 3, 37)
      ..lineTo(end - 3, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.clipPath(growingEdge);
    // One connected texture, with shared vertices at every loop/connector join.
    // These landmarks align the five hand-painted loop centers with live icons.
    const sourceX = [
      0.0,
      286.0,
      490.0,
      691.0,
      900.0,
      1107.0,
      1320.0,
      1533.0,
      1740.0,
      1959.0,
      2170.0,
    ];
    final positions = <Offset>[];
    final texture = <Offset>[];
    final colors = <Color>[];
    const segments = 320;
    for (var i = 0; i <= segments; i++) {
      final u = i / segments;
      final cell = math.min(count - 1, (u * count).floor());
      // Match the live Material indicator (64 x 32, radius 12), rather than
      // scaling the branch frames proportionally with the whole navigation bar.
      // Keep each connector anchored so the artwork remains continuous.
      const leftEdges = [130.0, 565.0, 980.0, 1405.0, 1810.0];
      const rightEdges = [440.0, 815.0, 1230.0, 1660.0, 2100.0];
      final localX = u * count - cell;
      final halfFrame = math.min(32.0, slot * .48) / slot;
      final knots = [0.0, .5 - halfFrame, .5, .5 + halfFrame, 1.0];
      final sourceKnots = [
        sourceX[cell * 2],
        leftEdges[cell],
        sourceX[cell * 2 + 1],
        rightEdges[cell],
        sourceX[cell * 2 + 2],
      ];
      var span = 0;
      while (span < 3 && localX > knots[span + 1]) {
        span++;
      }
      final sx =
          ui.lerpDouble(
            sourceKnots[span],
            sourceKnots[span + 1],
            (localX - knots[span]) / (knots[span + 1] - knots[span]),
          )! /
          2170 *
          art.width;
      final center = (cell + .5) / count;
      VineCrown crown = VineCrown(center: center);
      for (final candidate in scene.crowns) {
        if ((candidate.center - center).abs() < .001) crown = candidate;
      }
      // Pin connector endpoints to the centerline while gently constricting
      // earlier loops. Neighboring columns share the same texture and geometry.
      final local = u * count - cell;
      final envelope = math.pow(math.sin(math.pi * local), 2).toDouble();
      final squeeze =
          1 - crown.tightness * .10 * envelope - crown.wilt * .30 * envelope;
      final drop = crown.wilt * 7 * envelope;
      final centerY = 25 + drop;
      // Open the loops vertically while keeping their connecting strands fixed.
      final breathingRoom = 4 * envelope;
      positions.addAll([
        Offset(u * size.width, centerY - (25 + breathingRoom) * squeeze),
        Offset(u * size.width, centerY + (24 + breathingRoom) * squeeze),
      ]);
      texture.addAll([
        Offset(sx, art.height * 180 / 725),
        Offset(sx, art.height * 470 / 725),
      ]);
      final tone = (255 * (1 - (crown.wilt * 3).clamp(0.0, 1.0))).round();
      final tint = Color.fromRGBO(tone, tone, tone, crown.opacity);
      colors.addAll([tint, tint]);
    }
    final mesh = ui.Vertices(
      ui.VertexMode.triangleStrip,
      positions,
      textureCoordinates: texture,
      colors: colors,
    );
    final shader = ImageShader(
      art,
      TileMode.clamp,
      TileMode.clamp,
      Matrix4.identity().storage,
    );
    canvas.drawVertices(
      mesh,
      BlendMode.modulate,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..shader = shader,
    );
    mesh.dispose();
    shader.dispose();
    canvas.restore();
    for (final crown in scene.crowns) {
      if (crown.wilt <= 0) continue;
      _paintAsh(
        canvas,
        Rect.fromCenter(
          center: Offset(crown.center * size.width, 25),
          width: slot * .70,
          height: 38,
        ),
        crown.wilt,
        crown.center,
      );
    }
    if (decay > 0 && ashExtent > target) {
      _paintAsh(
        canvas,
        Rect.fromLTRB(
          (target + .1) * size.width,
          20,
          ashExtent * size.width,
          30,
        ),
        decay,
        target,
      );
    }
    canvas.restore();
  }

  void _paintAsh(Canvas canvas, Rect bounds, double decay, double seed) {
    // Deterministic fragments avoid flicker and remain stable across rebuilds.
    for (var i = 0; i < 30; i++) {
      final delay = (i % 6) * .055;
      final age = ((decay - .12 - delay) / (1 - .12 - delay)).clamp(0.0, 1.0);
      if (age <= 0 || age >= 1) continue;
      final angle = i * 2.39996 + seed * 11;
      final origin = Offset(
        bounds.center.dx + math.cos(angle) * bounds.width / 2,
        bounds.center.dy + math.sin(angle) * bounds.height / 2,
      );
      final drift = Offset(math.sin(angle * 2) * age * 15, age * 19);
      final radius = (.65 + (i % 4) * .27) * (1 - age * .65);
      final color = i.isEven
          ? const Color(0xFF141513)
          : const Color(0xFF777970);
      canvas.save();
      canvas.translate(origin.dx + drift.dx, origin.dy + drift.dy);
      canvas.rotate(angle + age * 2);
      final flake = Path()
        ..moveTo(-radius, 0)
        ..lineTo(0, -radius * .8)
        ..lineTo(radius * .65, radius * .35)
        ..lineTo(-radius * .2, radius)
        ..close();
      canvas.drawPath(
        flake,
        Paint()..color = color.withValues(alpha: math.sin(math.pi * age) * .9),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant VineGrowthPainter oldDelegate) =>
      artwork != oldDelegate.artwork ||
      scene != oldDelegate.scene ||
      target != oldDelegate.target ||
      retreat != oldDelegate.retreat ||
      count != oldDelegate.count ||
      decay != oldDelegate.decay ||
      ashExtent != oldDelegate.ashExtent;
}
