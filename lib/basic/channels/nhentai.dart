import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:nhentai/basic/entities/entities.dart';

const nHentai = NHentai._();

class NHentai {
  const NHentai._();

  static const _channel = MethodChannel("nhentai");

  /// 平铺调用, 为了直接与golang进行通信
  Future<String> _flatInvoke(String method, dynamic params) async {
    return await _channel.invokeMethod("flatInvoke", {
      "method": method,
      "params": params is String ? params : jsonEncode(params),
    });
  }

  /// 可用的网站分流
  Future<List<String>> availableWebAddresses() async {
    List list = jsonDecode(await _flatInvoke("availableWebAddresses", ""));
    return list.map((e) => e as String).toList();
  }

  /// 可用的图片分流
  Future<List<String>> availableImgAddresses() async {
    List list = jsonDecode(await _flatInvoke("availableImgAddresses", ""));
    return list.map((e) => e as String).toList();
  }

  /// 设置代理
  Future setProxy(String proxyUrl) {
    return _flatInvoke("setProxy", proxyUrl);
  }

  /// 获取代理
  Future<String> getProxy() {
    return _flatInvoke("getProxy", "");
  }

  /// 设置网站分流
  Future setWebAddress(String host) {
    return _flatInvoke("setWebAddress", host);
  }

  /// 获取网站分流
  Future<String> getWebAddress() {
    return _flatInvoke("getWebAddress", "");
  }

  /// 设置图片分流
  Future setImgAddress(String host) {
    return _flatInvoke("setImgAddress", host);
  }

  /// 获取图片分流
  Future<String> getImgAddress() {
    return _flatInvoke("getImgAddress", "");
  }

  /// 获取漫画
  Future<ComicPageData> comics(int page) async {
    return ComicPageData.fromJson(
      jsonDecode(await _flatInvoke("comics", "$page")),
    );
  }

  /// 获取漫画
  Future<ComicPageData> comicsByTagName(String tagName, int page) async {
    return ComicPageData.fromJson(jsonDecode(
      await _flatInvoke("comicsByTagName", {
        "tag_name": tagName,
        "page": page,
      }),
    ));
  }

  /// 获取漫画
  Future<ComicPageData> comicsBySearchRaw(String raw, int page) async {
    return ComicPageData.fromJson(jsonDecode(
      await _flatInvoke("comicsBySearchRaw", {
        "raw": raw,
        "page": page,
      }),
    ));
  }

  /// 漫画详情
  Future<ComicInfo> comicInfo(int comicId) async {
    return ComicInfo.formJson(jsonDecode(
      await _flatInvoke("comicInfo", "$comicId"),
    ));
  }

  /// 加载图片 (返回路径)
  Future<String> cacheImageByUrlPath(String url) async {
    return await _flatInvoke("cacheImageByUrlPath", url);
  }

  /// 手机端保存图片
  Future saveFileToImage(String path) async {
    //todo
  }

  /// 桌面端保存图片
  Future convertImageToJPEG100(String path, String folder) async {
    //todo
  }

  /// 安卓版本号
  Future<int> androidVersion() async {
    //todo
    return 0;
  }

  /// 读取配置文件
  Future<String> loadProperty(String propertyName, String defaultValue) async {
    return await _flatInvoke("loadProperty", {
      "name": propertyName,
      "defaultValue": defaultValue,
    });
  }

  /// 保存配置文件
  Future<dynamic> saveProperty(String propertyName, String value) {
    return _flatInvoke("saveProperty", {
      "name": propertyName,
      "value": value,
    });
  }
}
