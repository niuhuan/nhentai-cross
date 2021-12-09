import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nhentai/basic/channels/nhentai.dart';
import 'package:nhentai/screens/comic_search_screen.dart';
import 'package:nhentai/screens/components/pager.dart';

import 'components/actions.dart';

class ComicsScreen extends StatefulWidget {
  late final ComicSearchStruct searchStruct;

  ComicsScreen({ComicSearchStruct? searchStruct, Key? key}) : super(key: key) {
    if (searchStruct != null) {
      this.searchStruct = searchStruct;
    } else {
      this.searchStruct = ComicSearchStruct();
    }
  }

  @override
  State<StatefulWidget> createState() => _ComicsScreenState();
}

class _ComicsScreenState extends State<ComicsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.searchStruct.dumpSearchString() == ""
              ? AppLocalizations.of(context)!.allComics
              : widget.searchStruct.dumpSearchString(),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              ComicSearchStruct? struct = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (BuildContext context) =>
                      ComicSearchScreen(widget.searchStruct),
                ),
              );
              if (struct != null) {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (BuildContext context) =>
                      ComicsScreen(searchStruct: struct),
                ));
              }
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.archive),
          ),
          ...alwaysInActions(context),
        ],
      ),
      body: Pager(
        onPage: (int page) {
          return nHentai.comicsBySearchRaw(
            widget.searchStruct.dumpSearchString(),
            page,
          );
        },
      ),
    );
  }
}
