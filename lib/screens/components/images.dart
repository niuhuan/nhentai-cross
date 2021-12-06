import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nhentai/basic/channels/nhentai.dart';
import 'package:nhentai/basic/common/common.dart';
import 'package:nhentai/basic/common/cross.dart';

import '../file_photo_view_screen.dart';

String coverImageUrl(int mediaId) {
  return "https://t.nhentai.net/galleries/$mediaId/cover.${"jpg"}";
}

String pageImageUrl(int mediaId, int num) {
  return "https://i.nhentai.net/galleries/$mediaId/$num.${"jpg"}";
}

class RemoteImage extends StatefulWidget {
  final String url;
  final Size size;
  final BoxFit fit;

  const RemoteImage({
    Key? key,
    required this.url,
    required this.size,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RemoteImageState();
}

class _RemoteImageState extends State<RemoteImage> {
  late final Future<String> _future = nHentai.cacheImageByUrlPath(widget.url);

  @override
  Widget build(BuildContext context) {
    return pathFutureImage(
      _future,
      widget.size.width,
      widget.size.height,
      fit: widget.fit,
      context: context,
    );
  }
}

Widget pathFutureImage(Future<String> future, double? width, double? height,
    {BoxFit fit = BoxFit.cover, BuildContext? context}) {
  return FutureBuilder(
      future: future,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasError) {
          print("${snapshot.error}");
          print("${snapshot.stackTrace}");
          return buildError(width, height);
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return buildLoading(width, height);
        }
        return buildFile(
          snapshot.data!,
          width,
          height,
          fit: fit,
          context: context,
        );
      });
}

Widget buildError(double? width, double? height) {
  return Image(
    image: AssetImage('lib/assets/error.png'),
    width: width,
    height: height,
  );
}

Widget buildLoading(double? width, double? height) {
  double? size;
  if (width != null && height != null) {
    size = width < height ? width : height;
  }
  return SizedBox(
    width: width,
    height: height,
    child: Center(
      child: Icon(
        Icons.downloading,
        size: size,
        color: Colors.grey.shade500.withAlpha(80),
      ),
    ),
  );
}

Widget buildFile(String file, double? width, double? height,
    {BoxFit fit = BoxFit.cover, BuildContext? context}) {
  var image = Image(
    image: FileImage(File(file)),
    width: width,
    height: height,
    errorBuilder: (a, b, c) {
      print("$b");
      print("$c");
      return buildError(width, height);
    },
    fit: fit,
  );
  if (context == null) return image;
  return GestureDetector(
    onLongPress: () async {
      String? choose = await chooseListDialog(context, '请选择', ['预览图片', '保存图片']);
      switch (choose) {
        case '预览图片':
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => FilePhotoViewScreen(file),
          ));
          break;
        case '保存图片':
          saveImage(file, context);
          break;
      }
    },
    child: image,
  );
}

class ScaleNHentaiImage extends StatelessWidget {
  final String url;
  final Size originSize;

  const ScaleNHentaiImage(
      {required this.url, required this.originSize, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        var width = constraints.maxWidth;
        var height =
            constraints.maxWidth * originSize.height / originSize.width;
        return RemoteImage(url: url, size: Size(width, height));
      },
    );
  }
}

class ScaleImageTitle extends StatelessWidget {
  final String title;
  final Size originSize;

  const ScaleImageTitle(
      {required this.title, required this.originSize, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        var width = constraints.maxWidth;
        var height =
            constraints.maxWidth * originSize.height / originSize.width;
        return SizedBox(
          width: width,
          height: height,
          child: Column(
            children: [
              Expanded(child: Container()),
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: const Color(0xAA000000),
                      child: Text(
                        "$title\n",
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
