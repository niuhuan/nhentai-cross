import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:nhentai/basic/channels/nhentai.dart';
import 'package:nhentai/basic/common/common.dart';

const _propertyName = "proxy";
late String _proxy;

Future initProxy() async {
  _proxy = await nHentai.getProxy();
}

String currentProxy() {
  return _proxy;
}

Future chooseProxy(BuildContext context) async {
  final newProxy = await displayTextInputDialog(
      context,
      AppLocalizations.of(context)!.proxy,
      "socks5://host:port/",
      _proxy,
      AppLocalizations.of(context)!.inputProxyDesc);
  if (newProxy != null) {
    await nHentai.saveProperty(_propertyName, newProxy);
    _proxy = newProxy;
  }
}

Widget proxySetting() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return ListTile(
        title: Text(
          AppLocalizations.of(context)!.proxy,
        ),
        subtitle: Text(_proxy),
        onTap: () async {
          await chooseProxy(context);
          setState(() {});
        },
      );
    },
  );
}
