// From flutter_map: https://github.com/fleaflet/flutter_map/blob/cdb3b230376d1452b03e90f2d49ad2c26979244d/example/lib/widgets/drawer/floating_menu_button.dart
import 'package:flutter/material.dart';

class FloatingMenuButton extends StatelessWidget {
  const FloatingMenuButton({super.key, this.button});

  final Widget? button;
  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      start: 16,
      top: 16,
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(999),
            // TODO: remove this
          ),
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              button ??
                  // Default: " Open drawer of scaffold."
                  IconButton(
                    onPressed: () => Scaffold.of(context).openDrawer(),
                    icon: const Icon(Icons.menu_rounded),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
