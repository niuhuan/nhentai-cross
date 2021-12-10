import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:nhentai/basic/channels/nhentai.dart';
import 'package:nhentai/basic/entities/entities.dart';
import 'package:nhentai/screens/components/actions.dart';
import 'package:nhentai/screens/components/content_builder.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import 'comic_info_screen.dart';
import 'components/images.dart';

class ComicDownloadsScreen extends StatefulWidget {
  const ComicDownloadsScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ComicDownloadsScreenState();
}

class _ComicDownloadsScreenState extends State<ComicDownloadsScreen> {
  late Future<List<DownloadComicInfo>> _future;

  @override
  void initState() {
    _future = nHentai.listDownloadComicInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.download),
        actions: [
          ...alwaysInActions(),
        ],
      ),
      body: ContentBuilder(
        future: _future,
        successBuilder: (BuildContext context,
            AsyncSnapshot<List<DownloadComicInfo>> snapshot) {
          var crossCount = 2;
          var _data = snapshot.requireData;
          return WaterfallFlow.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            itemCount: _data.length,
            gridDelegate: SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossCount,
              crossAxisSpacing: 0,
              mainAxisSpacing: 0,
            ),
            itemBuilder: (BuildContext context, int index) {
              return _buildImageCard(_data[index]);
            },
          );
        },
        onRefresh: () async {},
      ),
    );
  }

  Widget _buildImageCard(DownloadComicInfo item) {
    return GestureDetector(
      onTap: () {
        if (item.downloadStatus == 4) return;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) {
            return ComicInfoScreen(item.id, item.title.pretty);
          },
        ));
      },
      child: Card(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            var width = constraints.maxWidth;
            var height = constraints.maxWidth *
                item.images.thumbnail.h /
                item.images.thumbnail.w;
            return SizedBox(
              width: width,
              height: height,
              child: Stack(
                children: [
                  RemoteImage(
                    url:
                        "https://t2.nhentai.net/galleries/${item.mediaId}/thumb.jpg",
                    size: Size(width, height),
                  ),
                  _buildDownloadStatus(item.downloadStatus),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDownloadStatus(int downloadStatus) {
    late IconData iconData;
    late Color color;
    switch (downloadStatus) {
      case 1:
        iconData = Icons.download_done_sharp;
        color = Colors.green;
        break;
      case 2:
        iconData = Icons.error_outline;
        color = Colors.yellow;
        break;
      case 3:
        iconData = Icons.auto_delete_outlined;
        color = Colors.red;
        break;
      default:
        iconData = Icons.query_builder;
        color = Colors.grey;
        break;
    }
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        margin: EdgeInsets.only(top: 3, right: 3),
        padding: EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Icon(iconData, color: Colors.white, size: 14),
      ),
    );
  }
}
