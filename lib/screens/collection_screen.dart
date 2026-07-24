import 'package:flutter/material.dart';

import '../garden_store.dart';
import '../models.dart';
import '../widgets/background_card.dart';
import '../widgets/catalog_card.dart';
import '../widgets/common_widgets.dart';

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key, required this.store});

  final GardenStore store;

  @override
  Widget build(BuildContext context) {
    return PagePadding(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionEyebrow('Garden journal'),
                      Text(
                        'Discover',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ],
                  ),
                ),
                DewPill(value: store.dew),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 18),
              child: Text(
                'Spend dew earned from your daily habits to welcome something new.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Garden scenes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 5),
                Text(
                  'Collect new settings, then choose one while editing your garden.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 236,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: gardenBackgrounds.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => BackgroundCard(
                      background: gardenBackgrounds[index],
                      store: store,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Plants, friends & decorations',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: .77,
            ),
            itemCount: gardenCatalog.length,
            itemBuilder: (context, index) =>
                CatalogCard(item: gardenCatalog[index], store: store),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }
}
