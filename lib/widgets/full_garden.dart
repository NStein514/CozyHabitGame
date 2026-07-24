import 'package:flutter/material.dart';

import '../models.dart';
import '../theme/cozy_theme.dart';

typedef GardenTransformCallback =
    void Function(
      String id, {
      double? x,
      double? y,
      double? scale,
      double? rotation,
    });

class FullGarden extends StatelessWidget {
  const FullGarden({
    super.key,
    required this.placements,
    required this.level,
    required this.backgroundAsset,
    this.editing = false,
    this.onTransform,
    this.onRemove,
  });

  final List<PlacedGardenItem> placements;
  final int level;
  final String backgroundAsset;
  final bool editing;
  final GardenTransformCallback? onTransform;
  final ValueChanged<String>? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('garden-canvas'),
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFD8E9D1),
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18356859),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                backgroundAsset,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
            ),
            for (final placement in placements)
              _GardenCollectible(
                key: ValueKey(placement.id),
                placement: placement,
                gardenSize: constraints.biggest,
                editing: editing,
                onTransform: onTransform,
                onRemove: onRemove,
              ),
            Positioned(
              top: 18,
              left: 18,
              child: GardenLevelBadge(level: level),
            ),
            if (editing)
              const Positioned(top: 18, right: 18, child: _EditingBadge()),
            if (placements.isEmpty)
              Positioned(
                left: 24,
                right: 24,
                bottom: 22,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xEFFFFFF5),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    editing
                        ? 'Choose something from your inventory below to place it.'
                        : 'Your garden is ready. Tap Edit garden to make it yours.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: forest,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GardenCollectible extends StatefulWidget {
  const _GardenCollectible({
    super.key,
    required this.placement,
    required this.gardenSize,
    required this.editing,
    this.onTransform,
    this.onRemove,
  });

  final PlacedGardenItem placement;
  final Size gardenSize;
  final bool editing;
  final GardenTransformCallback? onTransform;
  final ValueChanged<String>? onRemove;

  @override
  State<_GardenCollectible> createState() => _GardenCollectibleState();
}

class _GardenCollectibleState extends State<_GardenCollectible> {
  Offset _startFocalPoint = Offset.zero;
  double _startX = 0;
  double _startY = 0;
  double _startScale = 1;
  double _startRotation = 0;

  @override
  Widget build(BuildContext context) {
    final item = gardenCatalog.firstWhere(
      (candidate) => candidate.name == widget.placement.itemName,
    );
    final baseFraction = switch (item.name) {
      'Cherry tree' => .34,
      'Cozy cottage' => .31,
      'Bird bath' => .25,
      'Red fox' || 'Sleepy cat' => .24,
      'Little snail' || 'Blue butterfly' => .17,
      _ => .22,
    };
    final width =
        widget.gardenSize.width * baseFraction * widget.placement.scale;
    final height = item.name == 'Cherry tree' ? width * 1.22 : width;
    return Positioned(
      left: widget.gardenSize.width * widget.placement.x - width / 2,
      top: widget.gardenSize.height * widget.placement.y - height * .86,
      width: width,
      height: height,
      child: GestureDetector(
        onScaleStart: widget.editing ? _startTransform : null,
        onScaleUpdate: widget.editing
            ? (details) {
                final delta = details.focalPoint - _startFocalPoint;
                widget.onTransform?.call(
                  widget.placement.id,
                  x: _startX + delta.dx / widget.gardenSize.width,
                  y: _startY + delta.dy / widget.gardenSize.height,
                  scale: _startScale * details.scale,
                  rotation: _startRotation + details.rotation,
                );
              }
            : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: widget.editing
                    ? BoxDecoration(
                        color: Colors.white.withValues(alpha: .18),
                        border: Border.all(color: Colors.white70, width: 1.5),
                        borderRadius: BorderRadius.circular(18),
                      )
                    : const BoxDecoration(),
                child: Transform.rotate(
                  angle: widget.placement.rotation,
                  child: Semantics(
                    label: item.name,
                    image: true,
                    child: item.assetPath == null
                        ? FittedBox(child: Text(item.emoji))
                        : Image.asset(
                            item.assetPath!,
                            fit: BoxFit.contain,
                            alignment: Alignment.bottomCenter,
                            filterQuality: FilterQuality.medium,
                          ),
                  ),
                ),
              ),
            ),
            if (widget.editing)
              Positioned(
                top: -8,
                right: -8,
                child: Semantics(
                  button: true,
                  label: 'Return ${item.name} to inventory',
                  child: InkWell(
                    onTap: () => widget.onRemove?.call(widget.placement.id),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF8ED),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 5),
                        ],
                      ),
                      child: const Icon(Icons.close, size: 16, color: forest),
                    ),
                  ),
                ),
              ),
            if (widget.editing)
              Positioned(
                left: -8,
                bottom: -8,
                child: _TransformButton(
                  tooltip: 'Rotate ${item.name}',
                  icon: Icons.rotate_right_rounded,
                  onTap: () => widget.onTransform?.call(
                    widget.placement.id,
                    rotation: widget.placement.rotation + .261799,
                  ),
                ),
              ),
            if (widget.editing)
              Positioned(
                right: -8,
                bottom: -8,
                child: _TransformButton(
                  tooltip: 'Resize ${item.name}',
                  icon: Icons.aspect_ratio_rounded,
                  onTap: () => widget.onTransform?.call(
                    widget.placement.id,
                    scale: widget.placement.scale >= 1.7
                        ? .6
                        : widget.placement.scale + .15,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _startTransform(ScaleStartDetails details) {
    _startFocalPoint = details.focalPoint;
    _startX = widget.placement.x;
    _startY = widget.placement.y;
    _startScale = widget.placement.scale;
    _startRotation = widget.placement.rotation;
  }
}

class _TransformButton extends StatelessWidget {
  const _TransformButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: const Color(0xFFFEF8ED),
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 27,
          height: 27,
          child: Icon(icon, size: 16, color: forest),
        ),
      ),
    ),
  );
}

class _EditingBadge extends StatelessWidget {
  const _EditingBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xEFFFFFF5),
      borderRadius: BorderRadius.circular(99),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.open_with_rounded, size: 15, color: forest),
        SizedBox(width: 5),
        Text(
          'Drag · pinch · rotate',
          style: TextStyle(color: forest, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class GardenLevelBadge extends StatelessWidget {
  const GardenLevelBadge({super.key, required this.level});

  final int level;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .86),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      'Garden level $level',
      style: const TextStyle(fontWeight: FontWeight.w800, color: forest),
    ),
  );
}
