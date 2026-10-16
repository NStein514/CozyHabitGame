import 'package:flutter/material.dart';

import '../models.dart';

/// Legacy symbol values remain stable in saved habits; only their presentation
/// changes. All UI symbols now use the garden's illustrated artwork.
class GardenIcon extends StatelessWidget {
  const GardenIcon(this.symbol, {super.key, this.size = 28});

  final String symbol;
  final double size;

  static const atlasPath = 'assets/images/icons/garden_icons.png';
  static const symbols = [
    '🌱',
    '🌿',
    '💧',
    '📖',
    '🧘',
    '👟',
    '🧺',
    '💛',
    '🎨',
    '🔥',
    '🌳',
    '🪴',
    '🧪',
    '🦋',
    '🌙',
    '🌼',
  ];
  static const labels = [
    'Seedling',
    'Leaves',
    'Water',
    'Reading',
    'Meditation',
    'Walking',
    'Home care',
    'Kindness',
    'Creativity',
    'Streak',
    'Tree',
    'Potted plant',
    'Test garden',
    'Butterfly',
    'Moon',
    'Daisy',
  ];

  @override
  Widget build(BuildContext context) {
    final normalized = switch (symbol) {
      '🍃' => '🌿',
      '♥' || '❤️' => '💛',
      _ => symbol,
    };
    final index = symbols.indexOf(normalized);
    if (index < 0) {
      for (final item in gardenCatalog) {
        if (item.emoji == symbol && item.assetPath != null) {
          return Image.asset(
            item.assetPath!,
            width: size,
            height: size,
            fit: BoxFit.contain,
            semanticLabel: item.name,
          );
        }
      }
      return GardenIcon('🌱', size: size);
    }
    return Semantics(
      image: true,
      label: labels[index],
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: size * 4,
              maxWidth: size * 4,
              minHeight: size * 4,
              maxHeight: size * 4,
              child: Transform.translate(
                offset: Offset(-(index % 4) * size, -(index ~/ 4) * size),
                child: Image.asset(
                  atlasPath,
                  width: size * 4,
                  height: size * 4,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline artwork preserves wrapping and text scaling in prices and messages.
class GardenIllustratedText extends StatelessWidget {
  const GardenIllustratedText(this.text, {super.key, this.style});
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final symbols = {
      ...GardenIcon.symbols,
      '🍃',
      '♥',
      '❤️',
      ...gardenCatalog.map((item) => item.emoji),
    }.toList()..sort((a, b) => b.length.compareTo(a.length));
    final pattern = RegExp(symbols.map(RegExp.escape).join('|'));
    final spans = <InlineSpan>[];
    var end = 0;
    final fontSize =
        style?.fontSize ?? DefaultTextStyle.of(context).style.fontSize ?? 14;
    final iconSize = MediaQuery.textScalerOf(context).scale(fontSize) * 1.4;
    for (final match in pattern.allMatches(text)) {
      if (match.start > end) {
        spans.add(TextSpan(text: text.substring(end, match.start)));
      }
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GardenIcon(match.group(0)!, size: iconSize),
        ),
      );
      end = match.end;
    }
    if (end < text.length) spans.add(TextSpan(text: text.substring(end)));
    return Text.rich(TextSpan(children: spans), style: style);
  }
}
