import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:nhentai/basic/configs/img_address.dart';
import 'package:nhentai/basic/configs/reader_direction.dart';
import 'package:nhentai/basic/configs/themes.dart';
import 'package:nhentai/basic/configs/version.dart';
import 'package:nhentai/basic/configs/web_address.dart';

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
    await initWebAddressConfig();
    await initImgAddressConfig();
    await initReaderDirection();
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (BuildContext context) => ComicsScreen(),
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
