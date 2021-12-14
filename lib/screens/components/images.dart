import 'package:flutter/foundation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nhentai/basic/channels/nhentai.dart';
import 'package:nhentai/basic/common/common.dart';
import 'package:nhentai/basic/common/cross.dart';

import '../file_photo_view_screen.dart';
import 'dart:ui' as ui show Codec;

String coverImageUrl(int mediaId) {
  return "https://t.nhentai.net/galleries/$mediaId/cover.${"jpg"}";
}

String pageImageUrl(int mediaId, int num) {
  return "https://i.nhentai.net/galleries/$mediaId/$num.${"jpg"}";
}

class NHentaiImageProvider extends ImageProvider<NHentaiImageProvider> {
  final String url;
  final double scale;

  NHentaiImageProvider(this.url, {this.scale = 1.0});

  @override
  ImageStreamCompleter load(key, DecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key),
      scale: key.scale,
    );
  }

  @override
  Future<NHentaiImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<NHentaiImageProvider>(this);
  }

  Future<ui.Codec> _loadAsync(NHentaiImageProvider key) async {
    assert(key == this);
    var path = await nHentai.cacheImageByUrlPath(url);
    var data = await File(path).readAsBytes();
    return PaintingBinding.instance!.instantiateImageCodec(data);
  }
}

class NHentaiImage extends StatefulWidget {
  final String url;
  final Size size;
  final BoxFit fit;
  final bool disablePreview;

  const NHentaiImage({
    Key? key,
    required this.url,
    required this.size,
    this.fit = BoxFit.cover,
    this.disablePreview = false,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NHentaiImageState();
}

class _NHentaiImageState extends State<NHentaiImage> {
  late final Future<String> _future = nHentai.cacheImageByUrlPath(widget.url);

  @override
  Widget build(BuildContext context) {
    return pathFutureImage(
      _future,
      widget.size.width,
      widget.size.height,
      fit: widget.fit,
      context: context,
      disablePreview: widget.disablePreview,
    );
  }
}

Widget pathFutureImage(Future<String> future, double? width, double? height,
    {required BuildContext context,
    BoxFit fit = BoxFit.cover,
    bool disablePreview = false}) {
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
          disablePreview: disablePreview,
        );
      });
}

Widget buildError(double? width, double? height) {
  return Image(
    image: const AssetImage('lib/assets/error.png'),
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
    {required BuildContext context,
    BoxFit fit = BoxFit.cover,
    bool disablePreview = false}) {
  var image = Image(
    image: FileImage(File(file)),
    width: width,
    height: height,
    errorBuilder: (context, obj, stackTrace) {
      print("$obj");
      print("$stackTrace");
      return buildError(width, height);
    },
    fit: fit,
  );
  if (disablePreview) return image;
  return GestureDetector(
    onLongPress: () async {
      final previewImageText = AppLocalizations.of(context)!.previewImage;
      final saveImageText = AppLocalizations.of(context)!.saveImage;
      final chooseActionText = AppLocalizations.of(context)!.chooseAction;
      int? choose = await chooseMapDialog(
        context,
        {
          previewImageText: 1,
          saveImageText: 2,
        },
        chooseActionText,
      );
      switch (choose) {
        case 1:
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => FilePhotoViewScreen(file),
          ));
          break;
        case 2:
          saveImage(file, context);
          break;
      }
    },
    child: image,
  );
}

class HorizontalStretchNHentaiImage extends StatelessWidget {
  final String url;
  final Size originSize;

  const HorizontalStretchNHentaiImage(
      {required this.url, required this.originSize, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        var width = constraints.maxWidth;
        var height =
            constraints.maxWidth * originSize.height / originSize.width;
        return NHentaiImage(url: url, size: Size(width, height));
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
