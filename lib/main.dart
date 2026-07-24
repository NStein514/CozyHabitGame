import 'package:flutter/material.dart';
import 'garden_app.dart';
import 'garden_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(CozyGardenApp(store: GardenStore()));
}
