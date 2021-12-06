import 'dart:async';

import 'package:another_xlider/another_xlider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nhentai/basic/entities/entities.dart';
import 'package:nhentai/screens/components/images.dart';

class ComicReaderScreen extends StatefulWidget {
  final ComicInfo comicInfo;

  const ComicReaderScreen(this.comicInfo, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ComicReaderScreenState();
}

class _ComicReaderScreenState extends State<ComicReaderScreen> {
  late Future _future;
  bool _fullScreen = false;
  final int _startIndex = 0; // todo 取库

  @override
  void initState() {
    _future = Future.delayed(const Duration(), () {});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(),
          );
        }
        return Scaffold(
          backgroundColor: Colors.black,
          body: _ComicReader(
            widget.comicInfo,
            startIndex: _startIndex,
            fullScreen: _fullScreen,
            onFullScreenChange: _onFullScreenChange,
          ),
        );
      },
    );
  }

  Future _onFullScreenChange(bool fullScreen) async {
    setState(() {
      SystemChrome.setEnabledSystemUIOverlays(
          fullScreen ? [] : SystemUiOverlay.values);
      _fullScreen = fullScreen;
    });
  }
}

class _ComicReader extends StatefulWidget {
  final ComicInfo comicInfo;
  final int startIndex;
  final bool fullScreen;
  final FutureOr Function(bool value) onFullScreenChange;

  const _ComicReader(
    this.comicInfo, {
    Key? key,
    required this.startIndex,
    required this.fullScreen,
    required this.onFullScreenChange,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ComicReaderWebToonState();
}

abstract class _ComicReaderState extends State<_ComicReader> {
  Widget _buildViewer();

  _needJumpTo(int pageIndex, bool animation);

  late int _startIndex;
  late int _current;
  late int _slider;

  void _onCurrentChange(int index) {
    if (index != _current) {
      setState(() {
        _current = index;
        _slider = index;
        _onPositionChange(index);
      });
    }
  }

  _onPositionChange(int index){
    // todo 入库
  }

  @override
  void initState() {
    _startIndex = widget.startIndex;
    _current = _startIndex;
    _slider = _startIndex;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildViewer(),
        _buildFrame(),
      ],
    );
  }

  Widget _buildFrame() {
    return Column(
      children: [
        widget.fullScreen ? Container() : _buildAppBar(),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              widget.onFullScreenChange(!widget.fullScreen);
            },
            child: Container(),
          ),
        ),
        widget.fullScreen ? Container() : _buildBottomBar(),
      ],
    );
  }

  Widget _buildAppBar() {
    return AppBar(
      title: Text(widget.comicInfo.title.pretty),
      actions: [
        IconButton(
          onPressed: _onMoreSetting,
          icon: Icon(Icons.more_horiz),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 45,
      color: Color(0x88000000),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _buildSlider()),
        ],
      ),
    );
  }

  Widget _buildSlider() {
    return Column(
      children: [
        Expanded(child: Container()),
        SizedBox(
          height: 25,
          child: FlutterSlider(
            axis: Axis.horizontal,
            values: [_slider.toDouble()],
            min: 0,
            max: (widget.comicInfo.images.pages.length - 1).toDouble(),
            onDragging: (handlerIndex, lowerValue, upperValue) {
              _slider = (lowerValue.toInt());
            },
            onDragCompleted: (handlerIndex, lowerValue, upperValue) {
              _slider = (lowerValue.toInt());
              if (_slider != _current) {
                _needJumpTo(_slider, false);
              }
            },
            trackBar: FlutterSliderTrackBar(
              inactiveTrackBar: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.grey.shade300,
              ),
              activeTrackBar: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
            step: FlutterSliderStep(
              step: 1,
              isPercentRange: false,
            ),
            tooltip: FlutterSliderTooltip(custom: (value) {
              double a = value + 1;
              return Container(
                padding: EdgeInsets.all(8),
                decoration: ShapeDecoration(
                  color: Colors.black.withAlpha(0xCC),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusDirectional.circular(3)),
                ),
                child: Text(
                  '${a.toInt()}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              );
            }),
          ),
        ),
        Expanded(child: Container()),
      ],
    );
  }

  //
  _onMoreSetting() async {}

  //
  double _appBarHeight() {
    return Scaffold.of(context).appBarMaxHeight ?? 0;
  }

  double _bottomBarHeight() {
    return 45;
  }
}

class _ComicReaderWebToonState extends _ComicReaderState {
  late final ScrollController _controller;
  List<double> _offsets = [];

  @override
  void initState() {
    _controller = ScrollController();
    _controller.addListener(_onScroll);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget _buildViewer() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _offsets = widget.comicInfo.images.pages
            .map((e) => constraints.maxWidth * e.h / e.w)
            .toList()
            .cast<double>();
        return ListView.builder(
          controller: _controller,
          padding: EdgeInsets.only(top: super._appBarHeight(), bottom: 130),
          itemCount: widget.comicInfo.images.pages.length,
          itemBuilder: (BuildContext context, int index) {
            var page = widget.comicInfo.images.pages[index];
            return ScaleNHentaiImage(
              url: pageImageUrl(widget.comicInfo.mediaId, index + 1),
              originSize: Size(
                page.w.toDouble(),
                page.h.toDouble(),
              ),
            );
          },
        );
      },
    );
  }

  _onScroll() {
    double cOff = _controller.offset;
    double off = 0;
    int i = 0;
    for (; i < _offsets.length; i++) {
      if (cOff == off) {
        // 最顶端, 以及每个图片的开始
        // 0 == 0
        super._onCurrentChange(i);
        return;
      }
      // 第二轮, 假设第一张的300px, 现在是299px
      if (cOff < off) {
        super._onCurrentChange(i - 1);
        return;
      }
      off += _offsets[i];
    }
    // 特殊情况1: i = 0, 如果没图片, i = 0
    // 特殊情况2: i = _offset.length 如果下方padding超过一屏 i 最后还++, 但是已经达到了length, 这个index是不存在的
    if (i == 0) {
      return;
    }
    super._onCurrentChange(i - 1);
  }

  @override
  _needJumpTo(int pageIndex, bool animation) {
    if (_offsets.length > pageIndex) {
      double off = 0;
      for (int i = 0; i < pageIndex - 1; i++) {
        off += _offsets[i];
      }
      _controller.jumpTo(off);
    }
  }
}
