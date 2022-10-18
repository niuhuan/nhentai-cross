import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:nhentai/basic/configs/proxy.dart';
import 'package:nhentai/basic/configs/themes.dart';
import 'package:nhentai/basic/configs/version.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      body: ListView(
        children: [
          const Divider(),
          themeSetting(context),
          const Divider(),
          proxySetting(),
          const Divider(),
          autoUpdateCheckSetting(),
          const Divider(),
          const VersionInfo(),
          const Divider(),
        ],
      ),
    );
  }
}
