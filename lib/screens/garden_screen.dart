import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../garden_store.dart';
import '../models.dart';
import '../theme/cozy_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/full_garden.dart';

class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key, required this.store});

  final GardenStore store;

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> {
  bool editing = false;
  bool editorTrayOpen = true;
  String? selectedPlacementId;

  GardenStore get store => widget.store;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PagePadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionEyebrow('Your little haven'),
                        Text(
                          store.gardenName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  DewPill(value: store.dew),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: const Key('garden-editor-toggle'),
                  onPressed: () => setState(() {
                    editing = !editing;
                    editorTrayOpen = editing;
                    selectedPlacementId = null;
                  }),
                  icon: Icon(
                    editing ? Icons.check_rounded : Icons.edit_rounded,
                  ),
                  label: Text(editing ? 'Done' : 'Edit garden'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: FullGarden(
                  placements: store.placedItems,
                  level: store.level,
                  backgroundAsset: store.selectedBackground.assetPath,
                  editing: editing,
                  selectedPlacementId: selectedPlacementId,
                  onSelectionChanged: (id) =>
                      setState(() => selectedPlacementId = id),
                  onTransform: store.transformPlacedItem,
                  onRemoveSelected: _removeSelected,
                ),
              ),
              if (editing && editorTrayOpen)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _GardenEditorTray(
                    store: store,
                    onPlace: _placeAndSelect,
                    onRename: _renameGarden,
                    onHide: () => setState(() => editorTrayOpen = false),
                  ),
                ),
              if (editing && !editorTrayOpen)
                Positioned(
                  right: 24,
                  bottom: 18,
                  child: FilledButton.icon(
                    onPressed: () => setState(() => editorTrayOpen = true),
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('Inventory'),
                  ),
                ),
            ],
          ),
        ),
        _GardenSummary(store: store, editing: editing),
      ],
    );
  }

  void _placeAndSelect(GardenItem item) {
    if (!store.placeItem(item.name)) return;
    setState(() => selectedPlacementId = store.placedItems.last.id);
  }

  void _removeSelected() {
    final id = selectedPlacementId;
    if (id == null) return;
    store.removePlacedItem(id);
    setState(() => selectedPlacementId = null);
  }

  Future<void> _renameGarden() async {
    final value = await showDialog<String>(
      context: context,
      builder: (context) => _RenameGardenDialog(initialName: store.gardenName),
    );
    if (value != null) store.updateSettings(gardenName: value);
  }
}

class _RenameGardenDialog extends StatefulWidget {
  const _RenameGardenDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameGardenDialog> createState() => _RenameGardenDialogState();
}

class _RenameGardenDialogState extends State<_RenameGardenDialog> {
  late final TextEditingController controller = TextEditingController(
    text: widget.initialName,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Name your garden'),
    content: TextField(
      key: const Key('garden-name-field'),
      controller: controller,
      autofocus: true,
      maxLength: 32,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Garden name',
        hintText: 'My cozy garden',
      ),
      onSubmitted: _save,
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('save-garden-name'),
        onPressed: () => _save(controller.text),
        child: const Text('Save'),
      ),
    ],
  );

  void _save(String value) {
    if (value.trim().isNotEmpty) Navigator.pop(context, value);
  }
}

class _GardenEditorTray extends StatelessWidget {
  const _GardenEditorTray({
    required this.store,
    required this.onPlace,
    required this.onRename,
    required this.onHide,
  });

  final GardenStore store;
  final ValueChanged<GardenItem> onPlace;
  final VoidCallback onRename;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    final owned = gardenCatalogByDewCost()
        .where((item) => store.quantityOwned(item.name) > 0)
        .toList();
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: .97),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24356859),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Garden editor',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                key: const Key('rename-garden'),
                tooltip: 'Rename garden',
                onPressed: onRename,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.drive_file_rename_outline_rounded),
              ),
              IconButton(
                tooltip: 'Hide editor tray',
                onPressed: onHide,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
            ],
          ),
          Text(
            'Garden background',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: gardenBackgrounds
                  .where((bg) => store.ownedBackgrounds.contains(bg.id))
                  .length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final backgrounds = gardenBackgrounds
                    .where((bg) => store.ownedBackgrounds.contains(bg.id))
                    .toList();
                final background = backgrounds[index];
                return ChoiceChip(
                  label: Text(background.name),
                  selected: store.selectedBackgroundId == background.id,
                  onSelected: (_) => store.selectBackground(background.id),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Inventory · tap to place',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 7),
          SizedBox(
            height: 72,
            child: owned.isEmpty
                ? const Center(child: Text('Find decorations in Discover.'))
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: owned.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final item = owned[index];
                      final available = store.availableCount(item.name);
                      return Tooltip(
                        message: available > 0
                            ? 'Place ${item.name}'
                            : 'All copies are placed',
                        child: InkWell(
                          key: Key('place-${item.name}'),
                          onTap: available > 0 ? () => onPlace(item) : null,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 67,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: available > 0
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest
                                  : Colors.black.withValues(alpha: .05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0x1F356859),
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: available > 0 ? 1 : .35,
                                    child: item.assetPath == null
                                        ? FittedBox(child: Text(item.emoji))
                                        : Image.asset(
                                            item.assetPath!,
                                            fit: BoxFit.contain,
                                          ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: forest,
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: Text(
                                      '$available',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _GardenSummary extends StatelessWidget {
  const _GardenSummary({required this.store, required this.editing});

  final GardenStore store;
  final bool editing;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 58,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 14),
      child: Row(
        children: [
          const Icon(CupertinoIcons.sparkles, color: Color(0xFFD99B3D)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              editing
                  ? 'Arrange freely — your layout stays where you leave it'
                  : '${store.todayDone} caring moments today',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '${store.placedItems.length} placed',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}
