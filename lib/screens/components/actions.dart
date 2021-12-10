import 'package:flutter/material.dart';
import 'package:nhentai/basic/configs/version.dart';

import '../settings_screen.dart';
import 'Badged.dart';

List<Widget> alwaysInActions() {
  return [
    _SettingsAction(),
  ];
}

class _SettingsAction extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SettingsActionState();
}

class _SettingsActionState extends State<_SettingsAction> {
  @override
  void initState() {
    versionEvent.subscribe(_setState);
    super.initState();
  }

  @override
  void dispose() {
    versionEvent.unsubscribe(_setState);
    super.dispose();
  }

  void _setState(_) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (BuildContext context) => const SettingsScreen(),
        ));
      },
      icon: Badged(
        child: const Icon(Icons.settings),
        badge: latestVersion() == null ? null : "1",
      ),
    );
  }
}
