import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:nhentai/basic/channels/nhentai.dart';
import 'package:nhentai/basic/common/common.dart';

enum ReaderType {
  webtoon,
  gallery,
}

const _propertyName = "readerType";
late ReaderType _readerType;

Future initReaderType() async {
  _readerType = _fromString(await nHentai.loadProperty(_propertyName, ""));
}

ReaderType _fromString(String valueForm) {
  for (var value in ReaderType.values) {
    if (value.toString() == valueForm) {
      return value;
    }
  }
  return ReaderType.values.first;
}

ReaderType currentReaderType() {
  return _readerType;
}

String readerTypeName(ReaderType type, BuildContext context) {
  switch (type) {
    case ReaderType.webtoon:
      return AppLocalizations.of(context)!.webtoon;
    case ReaderType.gallery:
      return AppLocalizations.of(context)!.gallery;
  }
}

Future chooseReaderType(BuildContext context) async {
  final Map<String, ReaderType> map = {};
  for (var element in ReaderType.values) {
    map[readerTypeName(element, context)] = element;
  }
  final newReaderType = await chooseMapDialog(
    context,
    map,
    AppLocalizations.of(context)!.chooseReaderType,
  );
  if (newReaderType != null) {
    await nHentai.saveProperty(_propertyName, "$newReaderType");
    _readerType = newReaderType;
  }
}
