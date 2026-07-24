// The VS Code Flutter Widget Preview panel intentionally exposes one entry:
// a complete interactive app playground instead of disconnected components.
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'debug/garden_playground.dart';

@Preview(
  name: 'Cozy Habit Garden — Interactive App',
  group: 'Complete application',
  size: Size(430, 932),
)
Widget cozyHabitGardenInteractivePreview() => const GardenPlayground();
