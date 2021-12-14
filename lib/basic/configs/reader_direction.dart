import 'package:flutter/material.dart';
import 'package:nhentai/basic/channels/nhentai.dart';
import 'package:nhentai/basic/common/common.dart';

enum ReaderDirection {
  topBottom,
  leftRight,
  rightLeft,
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

Future chooseReaderDirection(BuildContext context) async {
  final newReaderDirection =
      await chooseListDialog(context, "title", ReaderDirection.values);
  if (newReaderDirection != null) {
    await nHentai.saveProperty(_propertyName, "$newReaderDirection");
    _readerDirection = newReaderDirection;
  }
}
