import 'garden_icon.dart';
import 'package:flutter/material.dart';
import '../theme/cozy_theme.dart';

import '../garden_store.dart';
import '../models.dart';

class BackgroundCard extends StatelessWidget {
  const BackgroundCard({
    super.key,
    required this.background,
    required this.store,
  });

  final GardenBackground background;
  final GardenStore store;

  @override
  Widget build(BuildContext context) {
    final owned = store.ownedBackgrounds.contains(background.id);
    final canBuy = store.dew >= background.cost;
    return SizedBox(
      width: 214,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Image.asset(
                  background.assetPath,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    background.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    background.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 7),
                  if (owned)
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Owned · choose in Garden editor',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: Key('buy-background-${background.id}'),
                        onPressed: canBuy ? () => _buy(context) : null,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          backgroundColor: lightModeFill(
                            context,
                            Theme.of(context).colorScheme.primary,
                          ),
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                        ),
                        child: GardenIllustratedText('💧 ${background.cost}'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _buy(BuildContext context) {
    if (!store.buyBackground(background)) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${background.name} is ready in your Garden editor.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
