import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:nhentai/basic/configs/img_address.dart';
import 'package:nhentai/basic/configs/themes.dart';
import 'package:nhentai/basic/configs/web_address.dart';

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
          webAddressSetting(),
          imgAddressSetting(),
          const Divider(),
        ],
      ),
    );
  }

}
