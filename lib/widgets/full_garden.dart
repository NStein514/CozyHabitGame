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

class FullGarden extends StatefulWidget {
  const FullGarden({
    super.key,
    required this.placements,
    required this.level,
    required this.backgroundAsset,
    this.editing = false,
    this.selectedPlacementId,
    this.onSelectionChanged,
    this.onTransform,
  });

  final List<PlacedGardenItem> placements;
  final int level;
  final String backgroundAsset;
  final bool editing;
  final String? selectedPlacementId;
  final ValueChanged<String?>? onSelectionChanged;
  final GardenTransformCallback? onTransform;

  @override
  State<FullGarden> createState() => _FullGardenState();
}

class _FullGardenState extends State<FullGarden> {
  Offset _startFocalPoint = Offset.zero;
  double _startX = 0;
  double _startY = 0;
  double _startScale = 1;
  double _startRotation = 0;

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
        builder: (context, constraints) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.editing
              ? () => widget.onSelectionChanged?.call(null)
              : null,
          onScaleStart: widget.editing && _selectedPlacement != null
              ? _startTransform
              : null,
          onScaleUpdate: widget.editing && _selectedPlacement != null
              ? (details) => _updateTransform(details, constraints.biggest)
              : null,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  widget.backgroundAsset,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              for (final placement in widget.placements)
                _GardenCollectible(
                  key: ValueKey(placement.id),
                  placement: placement,
                  gardenSize: constraints.biggest,
                  editing: widget.editing,
                  selected: widget.selectedPlacementId == placement.id,
                  onSelect: () => widget.onSelectionChanged?.call(placement.id),
                ),
              Positioned(
                top: 18,
                left: 18,
                child: GardenLevelBadge(level: widget.level),
              ),
              if (widget.editing)
                Positioned(
                  top: 18,
                  right: 18,
                  child: _EditingBadge(compact: constraints.maxWidth < 440),
                ),
              if (widget.placements.isEmpty)
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
                      widget.editing
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
      ),
    );
  }

  PlacedGardenItem? get _selectedPlacement {
    final id = widget.selectedPlacementId;
    if (id == null) return null;
    for (final placement in widget.placements) {
      if (placement.id == id) return placement;
    }
    return null;
  }

  void _startTransform(ScaleStartDetails details) {
    final placement = _selectedPlacement;
    if (placement == null) return;
    _startFocalPoint = details.focalPoint;
    _startX = placement.x;
    _startY = placement.y;
    _startScale = placement.scale;
    _startRotation = placement.rotation;
  }

  void _updateTransform(ScaleUpdateDetails details, Size gardenSize) {
    final placement = _selectedPlacement;
    if (placement == null) return;
    final delta = details.focalPoint - _startFocalPoint;
    widget.onTransform?.call(
      placement.id,
      x: _startX + delta.dx / gardenSize.width,
      y: _startY + delta.dy / gardenSize.height,
      scale: _startScale * details.scale,
      rotation: _startRotation + details.rotation,
    );
  }
}

class _GardenCollectible extends StatelessWidget {
  const _GardenCollectible({
    super.key,
    required this.placement,
    required this.gardenSize,
    required this.editing,
    required this.selected,
    required this.onSelect,
  });

  final PlacedGardenItem placement;
  final Size gardenSize;
  final bool editing;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final item = gardenCatalog.firstWhere(
      (candidate) => candidate.name == placement.itemName,
    );
    final baseFraction = switch (item.name) {
      'Cherry tree' => .34,
      'Cozy cottage' => .31,
      'Bird bath' || 'Acorn bench' => .25,
      'Red fox' || 'Sleepy cat' => .24,
      'Little snail' || 'Blue butterfly' || 'Garden wind chime' => .17,
      _ => .22,
    };
    final width = gardenSize.width * baseFraction * placement.scale;
    final height = item.name == 'Cherry tree' ? width * 1.22 : width;
    return Positioned(
      left: gardenSize.width * placement.x - width / 2,
      top: gardenSize.height * placement.y - height * .86,
      width: width,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: editing ? onSelect : null,
        child: Transform.rotate(
          angle: placement.rotation,
          child: AnimatedContainer(
            key: Key('garden-item-${placement.id}'),
            duration: const Duration(milliseconds: 160),
            padding: EdgeInsets.all(selected ? 3 : 0),
            decoration: selected
                ? BoxDecoration(
                    color: Colors.white.withValues(alpha: .18),
                    border: Border.all(
                      color: const Color(0xFFFFE6A7),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x80356859),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  )
                : const BoxDecoration(),
            child: Semantics(
              label: item.name,
              image: true,
              selected: selected,
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
    );
  }
}

class _EditingBadge extends StatelessWidget {
  const _EditingBadge({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Select an item, then drag or pinch anywhere',
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 11, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xEFFFFFF5),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.touch_app_outlined, size: 15, color: forest),
          if (!compact) ...[
            const SizedBox(width: 5),
            const Text(
              'Select · drag or pinch anywhere',
              style: TextStyle(color: forest, fontWeight: FontWeight.w800),
            ),
          ],
        ],
      ),
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
