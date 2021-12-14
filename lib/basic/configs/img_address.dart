import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:nhentai/basic/channels/nhentai.dart';
import 'package:nhentai/basic/common/common.dart';

late List<String> _availableImgAddresses;
late String _imgAddress;

Future<void> initImgAddressConfig() async {
  _availableImgAddresses = await nHentai.availableImgAddresses();
  _imgAddress = await nHentai.getImgAddress();
}

Widget imgAddressSetting() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return ListTile(
        title: Text(AppLocalizations.of(context)!.imgAddress),
        subtitle: Text(currentImgAddressName(context)),
        onTap: () async {
          await chooseImgAddress(context);
          setState(() {});
        },
      );
    },
  );
}

Future chooseImgAddress(BuildContext context) async {
  var none = AppLocalizations.of(context)!.none;
  Map<String, String> map = {};
  map[none] = "";
  for (var element in _availableImgAddresses) {
    map[element] = element;
  }
  var result = await chooseMapDialog<String>(
    context,
    map,
    AppLocalizations.of(context)!.chooseImgAddress,
  );
  if (result != null) {
    nHentai.setImgAddress(result);
    _imgAddress = result;
  }
}

String currentImgAddressName(BuildContext context) =>
    _imgAddress == "" ? AppLocalizations.of(context)!.none : _imgAddress;
