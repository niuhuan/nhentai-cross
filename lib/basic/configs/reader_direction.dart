import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:nhentai/basic/channels/nhentai.dart';
import 'package:nhentai/basic/common/common.dart';

enum ReaderDirection {
  topToBottom,
  leftToRight,
  rightToLeft,
}

const _propertyName = "readerDirection";
late ReaderDirection _readerDirection;

Future initReaderDirection() async {
  _readerDirection = _fromString(await nHentai.loadProperty(_propertyName, ""));
}

ReaderDirection _fromString(String valueForm) {
  for (var value in ReaderDirection.values) {
    if (value.toString() == valueForm) {
      return value;
    }
  }
  return ReaderDirection.values.first;
}

ReaderDirection currentReaderDirection() {
  return _readerDirection;
}

String readerDirectionName(ReaderDirection direction, BuildContext context) {
  switch (direction) {
    case ReaderDirection.topToBottom:
      return AppLocalizations.of(context)!.topToBottom;
    case ReaderDirection.leftToRight:
      return AppLocalizations.of(context)!.leftToRight;
    case ReaderDirection.rightToLeft:
      return AppLocalizations.of(context)!.rightToLeft;
  }
}

Future chooseReaderDirection(BuildContext context) async {
  final Map<String, ReaderDirection> map = {};
  for (var element in ReaderDirection.values) {
    map[readerDirectionName(element, context)] = element;
  }
  final newReaderDirection = await chooseMapDialog(
    context,
    map,
    AppLocalizations.of(context)!.chooseReaderDirection,
  );
  if (newReaderDirection != null) {
    await nHentai.saveProperty(_propertyName, "$newReaderDirection");
    _readerDirection = newReaderDirection;
  }
}
