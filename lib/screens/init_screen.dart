import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:nhentai/basic/configs/proxy.dart';
import 'package:nhentai/basic/configs/reader_direction.dart';
import 'package:nhentai/basic/configs/reader_type.dart';
import 'package:nhentai/basic/configs/themes.dart';
import 'package:nhentai/basic/configs/version.dart';
import 'comic_info_screen.dart';
import 'comics_screen.dart';

class InitScreen extends StatefulWidget {
  const InitScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  @override
  void initState() {
    _init();
    super.initState();
  }

  Future<void> _init() async {
    await initVersion();
    autoCheckNewVersion();
    await initTheme();
    await initProxy();
    await initReaderType();
    await initReaderDirection();

    late Widget gotoScreen;
    String? initUrl;
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final appLinks = AppLinks();
        initUrl = (await appLinks.getInitialAppLink())?.toString();
        // Use the uri and warn the user, if it is not correct,
        // but keep in mind it could be `null`.
      } on FormatException {
        // Handle exception by warning the user their action did not succeed
        // return?
      }
    }
    if (initUrl != null) {
      RegExp regExp = RegExp(r"^https://nhentai\.net/g/(\d+)/$");
      final matches = regExp.allMatches(initUrl!);
      if (matches.isNotEmpty) {
        final id = int.parse(matches.first.group(1)!);
        gotoScreen = ComicInfoScreen(id, "");
      } else {
        gotoScreen = ComicsScreen();
      }
    } else {
      gotoScreen = ComicsScreen();
    }

    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (BuildContext context) => gotoScreen,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: const Color(0xff313131),
        ),
        SafeArea(
          child: Column(
            children: [
              Expanded(child: Container()),
              Material(
                color: const Color(0x00000000),
                child: Text(
                  AppLocalizations.of(context)!.initializing,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          child: Center(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                var size = constraints.maxWidth < constraints.maxHeight
                    ? constraints.maxWidth
                    : constraints.maxHeight;
                size /= 2;
                return SizedBox(
                  width: size,
                  height: size,
                  child: Image.asset(
                    "lib/assets/startup.png",
                    width: size,
                    height: size,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
