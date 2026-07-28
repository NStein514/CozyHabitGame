import 'package:flutter/material.dart';

import '../garden_store.dart';
import '../models.dart';

class CatalogCard extends StatelessWidget {
  const CatalogCard({super.key, required this.item, required this.store});

  final GardenItem item;
  final GardenStore store;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final quantity = store.quantityOwned(item.name);
    final owned = quantity > 0;
    final canBuy = store.dew >= item.cost;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: owned
                      ? scheme.primaryContainer
                      : scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: item.assetPath == null
                    ? Text(item.emoji, style: const TextStyle(fontSize: 48))
                    : Padding(
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          item.assetPath!,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _showDetails(context),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Icon(
                    Icons.info_outline,
                    size: 15,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            Text(
              item.kind,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            if (owned)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  'Owned ×$quantity',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canBuy ? () => _purchase(context) : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: Text('${owned ? 'Buy another · ' : ''}💧 ${item.cost}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _purchase(BuildContext context) {
    if (!store.buy(item)) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${item.emoji} ${item.name} was added to your inventory.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showDetails(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: item.assetPath == null
            ? Text(item.emoji, style: const TextStyle(fontSize: 48))
            : Image.asset(item.assetPath!, width: 110, height: 110),
        title: Text(item.name),
        content: Text(item.description, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
