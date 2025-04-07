import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Automatically imply leading is set to true; this will have an automatic back
// button where applicable.
AppBar adaptiveAppBar({required String title}) => AppBar(
      title: Text(title),
      surfaceTintColor: Platform.isIOS ? Colors.transparent : null,
      shadowColor: Platform.isIOS ? CupertinoColors.darkBackgroundGray : null,
      scrolledUnderElevation: Platform.isIOS ? .1 : null,
      toolbarHeight: Platform.isIOS ? 44 : null,
    );
