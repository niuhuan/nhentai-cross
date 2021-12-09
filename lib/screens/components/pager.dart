import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nhentai/basic/entities/entities.dart';
import 'package:nhentai/screens/comic_info_screen.dart';
import 'package:waterfall_flow/waterfall_flow.dart';

import 'images.dart';

class Pager extends StatefulWidget {
  final FutureOr<ComicPageData> Function(int page) onPage;

  const Pager({required this.onPage, Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PageState();
}

class _PageState extends State<Pager> {
  late ScrollController _controller;
  int _currentPage = 1;
  bool _lastPage = false;
  final List<ComicSimple> _data = [];
  var _joining = false;
  late Future _joinFuture;

  Future _join() async {
    try {
      setState(() {
        _joining = true;
      });
      var response = await widget.onPage(_currentPage);
      _data.addAll(response.records);
      _currentPage++;
      if (response.pageCount <= _currentPage) {
        _lastPage = true;
      }
    } finally {
      setState(() {
        _joining = false;
      });
    }
  }

  void _next() {
    setState(() {
      _joinFuture = _join();
    });
  }

  void _onScroll() {
    if (_joining || _lastPage) {
      return;
    }
    if (_controller.position.pixels < _controller.position.maxScrollExtent) {
      return;
    }
    _next();
  }

  @override
  void initState() {
    _joinFuture = _join();
    _controller = ScrollController();
    _controller.addListener(_onScroll);
    super.initState();
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const int crossCount = 2;
    return WaterfallFlow.builder(
      controller: _controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      itemCount: _data.length + 1,
      gridDelegate: const SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossCount,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
      ),
      itemBuilder: (BuildContext context, int index) {
        if (index >= _data.length) {
          return _buildLoadingCard();
        }
        return _buildImageCard(_data[index]);
      },
    );
  }

  Widget _buildLoadingCard() {
    return FutureBuilder(
      future: _joinFuture,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Card(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: const CupertinoActivityIndicator(
                    radius: 14,
                  ),
                ),
                Text(AppLocalizations.of(context)!.loading),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          print("${snapshot.error}");
          print("${snapshot.stackTrace}");
          return Card(
            child: InkWell(
              onTap: _next,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    child: const Icon(Icons.sync_problem_rounded),
                  ),
                  Text(AppLocalizations.of(context)!.errorAndTapRetry),
                ],
              ),
            ),
          );
        }
        return Container();
      },
    );
  }

  Widget _buildImageCard(ComicSimple item) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) {
            return ComicInfoScreen(item.id, item.title);
          },
        ));
      },
      child: Card(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return ScaleNHentaiImage(
              url: item.thumb,
              originSize: Size(
                item.thumbWidth.toDouble(),
                item.thumbHeight.toDouble(),
              ),
            );
          },
        ),
      ),
    );
  }
}
