import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:nhentai/basic/channels/nhentai.dart';
import 'package:nhentai/basic/entities/entities.dart';
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
  late Future<List<ComicInfo>> _future;

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
      ),
      body: ContentBuilder(
        future: _future,
        successBuilder:
            (BuildContext context, AsyncSnapshot<List<ComicInfo>> snapshot) {
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

  Widget _buildImageCard(ComicInfo item) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) {
            return ComicInfoScreen(item.id, item.title.pretty);
          },
        ));
      },
      child: Card(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return ScaleNHentaiImage(
              url: "https://t2.nhentai.net/galleries/${item.mediaId}/thumb.jpg",
              originSize: Size(
                item.images.thumbnail.w.toDouble(),
                item.images.thumbnail.h.toDouble(),
              ),
            );
          },
        ),
      ),
    );
  }
}
