import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../settings_screen.dart';

List<Widget> alwaysInActions(BuildContext context) {
  return [
    IconButton(
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (BuildContext context) => const SettingsScreen(),
        ));
      },
      icon: const Icon(Icons.settings),
    ),
  ];
}
