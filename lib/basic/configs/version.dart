import 'package:flutter/gestures.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:async' show Future;
import 'dart:convert';
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:nhentai/basic/channels/nhentai.dart';
import 'package:nhentai/basic/common/common.dart';
import 'package:nhentai/basic/common/cross.dart';
import 'package:nhentai/screens/components/Badged.dart';

const _releasesUrl = "https://github.com/niuhuan/nhentai-cross/releases";
const _versionUrl =
    "https://api.github.com/repos/niuhuan/nhentai-cross/releases/latest";
const _versionAssets = 'lib/assets/version.txt';
RegExp _versionExp = RegExp(r"^v\d+\.\d+.\d+$");

late String _version;
String? _latestVersion;
String? _latestVersionInfo;

const _propertyName = "checkVersionPeriod";
late int _period = -1;

Future initVersion() async {
  // 当前版本
  try {
    _version = (await rootBundle.loadString(_versionAssets)).trim();
  } catch (e) {
    _version = "dirty";
  }
  // 检查周期
  _period = int.parse(await nHentai.loadProperty(_propertyName, "0"));
  if (_period > 0) {
    if (DateTime.now().millisecondsSinceEpoch > _period) {
      await nHentai.saveProperty(_propertyName, "0");
      _period = 0;
    }
  }
}

var versionEvent = Event<EventArgs>();

String currentVersion() {
  return _version;
}

String? latestVersion() {
  return _latestVersion;
}

String? latestVersionInfo() {
  return _latestVersionInfo;
}

Future autoCheckNewVersion() {
  if (_period != 0) {
    // -1 不检查, >0 未到检查时间
    return Future.value();
  }
  return _versionCheck();
}

Future manualCheckNewVersion(BuildContext context) async {
  try {
    defaultToast(context, AppLocalizations.of(context)!.checkingNewVersion);
    await _versionCheck();
    defaultToast(context, AppLocalizations.of(context)!.success);
  } catch (e) {
    defaultToast(context, AppLocalizations.of(context)!.failed + " : $e");
  }
}

bool dirtyVersion() {
  return !_versionExp.hasMatch(_version);
}

// maybe exception
Future _versionCheck() async {
  if (_versionExp.hasMatch(_version)) {
    var json = jsonDecode(await nHentai.httpGet(_versionUrl));
    if (json["name"] != null) {
      String latestVersion = (json["name"]);
      if (latestVersion != _version) {
        _latestVersion = latestVersion;
        _latestVersionInfo = json["body"] ?? "";
      }
    }
  } // else dirtyVersion
  versionEvent.broadcast();
}

String _periodText(BuildContext context) {
  if (_period < 0) {
    return AppLocalizations.of(context)!.disabled;
  }
  if (_period == 0) {
    return AppLocalizations.of(context)!.enabled;
  }
  return AppLocalizations.of(context)!.nextTime +
      " : " +
      formatDateTimeToDateTime(
        DateTime.fromMillisecondsSinceEpoch(_period),
      );
}

Future _choosePeriod(BuildContext context) async {
  var result = await chooseMapDialog(
    context,
    {
      AppLocalizations.of(context)!.enable: 0,
      AppLocalizations.of(context)!.aWeek: 1,
      AppLocalizations.of(context)!.aMonth: 2,
      AppLocalizations.of(context)!.aYear: 3,
      AppLocalizations.of(context)!.disable: 4,
    },
    AppLocalizations.of(context)!.autoCheckNewVersion,
    // todo tips: "重启后红点会消失",
  );
  switch (result) {
    case 0:
      await nHentai.saveProperty(_propertyName, "0");
      _period = 0;
      break;
    case 1:
      var time = DateTime.now().millisecondsSinceEpoch + (1000 * 3600 * 24 * 7);
      await nHentai.saveProperty(_propertyName, "$time");
      _period = time;
      break;
    case 2:
      var time =
          DateTime.now().millisecondsSinceEpoch + (1000 * 3600 * 24 * 30);
      await nHentai.saveProperty(_propertyName, "$time");
      _period = time;
      break;
    case 3:
      var time =
          DateTime.now().millisecondsSinceEpoch + (1000 * 3600 * 24 * 365);
      await nHentai.saveProperty(_propertyName, "$time");
      _period = time;
      break;
    case 4:
      await nHentai.saveProperty(_propertyName, "-1");
      _period = -1;
      break;
  }
}

Widget autoUpdateCheckSetting() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return ListTile(
        title: Text(AppLocalizations.of(context)!.autoCheckNewVersion),
        subtitle: Text(_periodText(context)),
        onTap: () async {
          await _choosePeriod(context);
          setState(() {});
        },
      );
    },
  );
}

String formatDateTimeToDateTime(DateTime c) {
  try {
    return "${add0(c.year, 4)}-${add0(c.month, 2)}-${add0(c.day, 2)} ${add0(c.hour, 2)}:${add0(c.minute, 2)}";
  } catch (e) {
    return "-";
  }
}

class VersionInfo extends StatefulWidget {
  const VersionInfo({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _VersionInfoState();
}

class _VersionInfoState extends State<VersionInfo> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '软件版本 : $_version',
            style: const TextStyle(
              height: 1.3,
            ),
          ),
          Row(
            children: [
              const Text(
                "检查更新 : ",
                style: TextStyle(
                  height: 1.3,
                ),
              ),
              "dirty" == _version
                  ? _buildDirty()
                  : _buildNewVersion(_latestVersion),
              Expanded(child: Container()),
            ],
          ),
          _buildNewVersionInfo(_latestVersionInfo),
        ],
      ),
    );
  }

  Widget _buildNewVersion(String? latestVersion) {
    if (latestVersion != null) {
      return Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              child: Badged(
                child: Container(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    latestVersion,
                    style: const TextStyle(height: 1.3),
                  ),
                ),
                badge: "1",
              ),
            ),
            const TextSpan(text: "  "),
            TextSpan(
              text: "去下载",
              style: TextStyle(
                height: 1.3,
                color: Theme.of(context).colorScheme.primary,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => openUrl(_releasesUrl),
            ),
          ],
        ),
      );
    }
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: "未检测到新版本", style: TextStyle(height: 1.3)),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.all(4),
              margin: const EdgeInsets.only(left: 3, right: 3),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
          ),
          TextSpan(
            text: "检查更新",
            style: TextStyle(
              height: 1.3,
              color: Theme.of(context).colorScheme.primary,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => manualCheckNewVersion(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDirty() {
    return Text.rich(
      TextSpan(
        text: "下载RELEASE版",
        style: TextStyle(
          height: 1.3,
          color: Theme.of(context).colorScheme.primary,
        ),
        recognizer: TapGestureRecognizer()..onTap = () => openUrl(_releasesUrl),
      ),
    );
  }

  Widget _buildNewVersionInfo(String? latestVersionInfo) {
    if (latestVersionInfo != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const Text("更新内容:"),
          Container(
            padding: EdgeInsets.all(15),
            child: Text(
              latestVersionInfo,
              style: TextStyle(),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(),
        Container(
          padding: EdgeInsets.all(15),
          child: Text.rich(
            TextSpan(
              text: "去RELEASE仓库",
              style: TextStyle(
                height: 1.3,
                color: Theme.of(context).colorScheme.primary,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => openUrl(_releasesUrl),
            ),
          ),
        ),
      ],
    );
  }
}
