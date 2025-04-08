import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:os_detect/os_detect.dart' as os_detect;

// Automatically imply leading is set to true; this will have an automatic back
// button where applicable.
AppBar adaptiveAppBar({required String title}) {
  final apple = os_detect.isMacOS || os_detect.isIOS;
  return AppBar(
    title: Text(title),
    surfaceTintColor: (apple) ? Colors.transparent : null,
    shadowColor: (apple) ? CupertinoColors.darkBackgroundGray : null,
    scrolledUnderElevation: (apple) ? .1 : null,
    toolbarHeight: (apple) ? 44 : null,
  );
}
