import 'dart:async';
import 'dart:io';
import 'package:another_xlider/another_xlider.dart';
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:nhentai/basic/channels/nhentai.dart';
import 'package:nhentai/basic/configs/proxy.dart';
import 'package:nhentai/basic/configs/reader_direction.dart';
import 'package:nhentai/basic/configs/reader_type.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:nhentai/basic/entities/entities.dart';
import 'package:nhentai/screens/components/images.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ComicReaderScreen extends StatefulWidget {
  final ComicInfo comicInfo;

  const ComicReaderScreen(this.comicInfo, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ComicReaderScreenState();
}

class _ComicReaderScreenState extends State<ComicReaderScreen> {
  late ReaderType _readerType;
  late ReaderDirection _readerDirection;
  late int _startIndex;
  late Future _future;

  Future _init() async {
    var last = await nHentai.loadLastViewIndexByComicId(widget.comicInfo.id);
    _readerType = currentReaderType();
    _readerDirection = currentReaderDirection();
    _startIndex = last;
  }

  @override
  void initState() {
    _future = _init();
    super.initState();
  }

  Future _reload() async {
    // Navigator.of(context)
    //     .pushReplacement(MaterialPageRoute(builder: (BuildContext context) {
    //   return ComicReaderScreen(widget.comicInfo);
    // }));
    setState(() {
      _future = _init();
    });
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
        final screen = Scaffold(
          backgroundColor: Colors.black,
          body: _ComicReader(
            widget.comicInfo,
            readerType: _readerType,
            readerDirection: _readerDirection,
            reload: _reload,
            startIndex: _startIndex,
          ),
        );
        return readerKeyboardHolder(screen);
      },
    );
  }
}

class _ComicReader extends StatefulWidget {
  final ComicInfo comicInfo;
  final ReaderType readerType;
  final ReaderDirection readerDirection;
  final FutureOr Function() reload;
  final int startIndex;

  const _ComicReader(
    this.comicInfo, {
    required this.readerType,
    required this.readerDirection,
    required this.reload,
    required this.startIndex,
    Key? key,
  }) : super(key: key);

  @override
  // ignore: no_logic_in_create_state
  State<StatefulWidget> createState() {
    switch (readerType) {
      case ReaderType.webtoon:
        return _ComicReaderWebToonState();
      case ReaderType.gallery:
        return _ComicReaderGalleryState();
    }
  }
}

abstract class _ComicReaderState extends State<_ComicReader> {
  late final ReaderDirection _direction = currentReaderDirection();

  Widget _buildViewer();

  _needJumpTo(int pageIndex, bool animation);

  late bool _fullScreen;
  late int _current;
  late int _slider;

  Future _onFullScreenChange(bool fullScreen) async {
    setState(() {
      SystemChrome.setEnabledSystemUIOverlays(
          fullScreen ? [] : SystemUiOverlay.values);
      _fullScreen = fullScreen;
    });
  }

  void _onCurrentChange(int index) {
    if (index != _current) {
      setState(() {
        _current = index;
        _slider = index;
        var _ = nHentai.saveViewIndex(widget.comicInfo, index); // 在后台线程入库
      });
    }
  }

  @override
  void initState() {
    _fullScreen = false;
    _current = widget.startIndex;
    _slider = widget.startIndex;
    _readerControllerEvent.subscribe(_onPageControl);
    super.initState();
  }

  @override
  void dispose() {
    _readerControllerEvent.unsubscribe(_onPageControl);
    if (Platform.isAndroid || Platform.isIOS) {
      SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    }
    super.dispose();
  }

  void _onPageControl(_ReaderControllerEventArgs? args) {
    if (args != null) {
      var event = args.key;
      switch (event) {
        case "UP":
          if (_current > 0) {
            _needJumpTo(_current - 1, true);
          }
          break;
        case "DOWN":
          if (_current < widget.comicInfo.images.pages.length - 1) {
            _needJumpTo(_current + 1, true);
          }
          break;
      }
    }
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
        _fullScreen ? Container() : _buildAppBar(),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              _onFullScreenChange(!_fullScreen);
            },
            child: Container(),
          ),
        ),
        _fullScreen ? Container() : _buildBottomBar(),
        _fullScreen ? Container() : _buildEdgePadding(),
      ],
    );
  }

  Widget _buildAppBar() {
    return AppBar(
      title: Text(widget.comicInfo.title.pretty),
      actions: [
        IconButton(
          onPressed: _onMoreSetting,
          icon: const Icon(Icons.more_horiz),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 45,
      color: const Color(0x88000000),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _buildSlider()),
        ],
      ),
    );
  }

  Widget _buildEdgePadding() {
    return Container(
      color: const Color(0x88000000),
      child: SafeArea(
        top: false,
        child: Container(),
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
            step: const FlutterSliderStep(
              step: 1,
              isPercentRange: false,
            ),
            tooltip: FlutterSliderTooltip(custom: (value) {
              double a = value + 1;
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: ShapeDecoration(
                  color: Colors.black.withAlpha(0xCC),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusDirectional.circular(3)),
                ),
                child: Text(
                  '${a.toInt()}',
                  style: const TextStyle(
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
  _onMoreSetting() async {
    await showMaterialModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xAA000000),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height / 2,
          child: _SettingPanel(),
        );
      },
    );
    if (_direction != currentReaderDirection() ||
        widget.readerType != currentReaderType()) {
      widget.reload();
    }
  }

  //
  double _appBarHeight() {
    return Scaffold.of(context).appBarMaxHeight ?? 0;
  }

  double _bottomBarHeight() {
    return 45;
  }
}

class _SettingPanel extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SettingPanelState();
}

class _SettingPanelState extends State<_SettingPanel> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Row(
          children: [
            _bottomIcon(
              icon: Icons.crop_sharp,
              title: readerDirectionName(currentReaderDirection(), context),
              onPressed: () async {
                await chooseReaderDirection(context);
                setState(() {});
              },
            ),
            _bottomIcon(
              icon: Icons.view_day_outlined,
              title: readerTypeName(currentReaderType(), context),
              onPressed: () async {
                await chooseReaderType(context);
                setState(() {});
              },
            ),
            _bottomIcon(
              icon: Icons.shuffle,
              title: AppLocalizations.of(context)!.proxy,
              onPressed: () async {
                await chooseProxy(context);
                setState(() {});
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _bottomIcon({
    required IconData icon,
    required String title,
    required void Function() onPressed,
  }) {
    return Expanded(
      child: Center(
        child: Column(
          children: [
            IconButton(
              iconSize: 55,
              icon: Column(
                children: [
                  Container(height: 3),
                  Icon(
                    icon,
                    size: 25,
                    color: Colors.white,
                  ),
                  Container(height: 3),
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                  Container(height: 3),
                ],
              ),
              onPressed: onPressed,
            )
          ],
        ),
      ),
    );
  }
}

class _ComicReaderWebToonState extends _ComicReaderState {
  ScrollController? _controller;
  List<double> _offsets = [];
  List<Size> _sizes = [];

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget _buildViewer() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (_direction == ReaderDirection.topToBottom) {
          _offsets = widget.comicInfo.images.pages
              .map((e) => constraints.maxWidth * e.h / e.w)
              .toList()
              .cast<double>();
        } else {
          var height = constraints.maxHeight -
              super._appBarHeight() -
              super._bottomBarHeight() -
              MediaQuery.of(context).padding.bottom;
          _offsets = widget.comicInfo.images.pages
              .map((e) => height * e.w / e.h)
              .toList()
              .cast<double>();
        }
        if (_direction == ReaderDirection.topToBottom) {
          _sizes = widget.comicInfo.images.pages
              .map((e) =>
                  Size(constraints.maxWidth, constraints.maxWidth * e.h / e.w))
              .toList()
              .cast<Size>();
        } else {
          var height = constraints.maxHeight -
              super._appBarHeight() -
              super._bottomBarHeight() -
              MediaQuery.of(context).padding.bottom;
          _sizes = widget.comicInfo.images.pages
              .map((e) => Size(height * e.w / e.h, height))
              .toList()
              .cast<Size>();
        }
        if (_controller == null) {
          _controller = ScrollController(initialScrollOffset: _initOffset());
          _controller!.addListener(_onScroll);
        }
        return ListView.builder(
          scrollDirection: _direction == ReaderDirection.topToBottom
              ? Axis.vertical
              : Axis.horizontal,
          reverse: _direction == ReaderDirection.rightToLeft,
          controller: _controller,
          padding: EdgeInsets.only(
            top: super._appBarHeight(),
            bottom: _direction == ReaderDirection.topToBottom
                ? 130
                : (super._bottomBarHeight() +
                MediaQuery.of(context).padding.bottom)
          ),
          itemCount: widget.comicInfo.images.pages.length,
          itemBuilder: (BuildContext context, int index) {
            return NHentaiImage(
              url: pageImageUrl(widget.comicInfo.mediaId, index + 1),
              size: _sizes[index],
              fit: BoxFit.contain,
            );
          },
        );
      },
    );
  }

  _onScroll() {
    double cOff = _controller!.offset;
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

  double _initOffset() {
    double off = 0;
    for (var i = 1; i <= widget.startIndex && i < _offsets.length; i++) {
      off += _offsets[i - 1];
    }
    return off;
  }

  @override
  _needJumpTo(int pageIndex, bool animation) {
    if (_offsets.length > pageIndex) {
      double off = 0;
      for (int i = 0; i < pageIndex; i++) {
        off += _offsets[i];
      }
      if (animation) {
        _controller?.animateTo(
          off,
          duration: const Duration(milliseconds: 250),
          curve: Curves.ease,
        );
      } else {
        _controller?.jumpTo(off);
      }
    }
  }
}

class _ComicReaderGalleryState extends _ComicReaderState {
  late PageController _pageController;
  late PhotoViewGallery _gallery;

  @override
  void initState() {
    _pageController = PageController(initialPage: widget.startIndex);
    _gallery = PhotoViewGallery.builder(
      scrollDirection: _direction == ReaderDirection.topToBottom
          ? Axis.vertical
          : Axis.horizontal,
      reverse: _direction == ReaderDirection.rightToLeft,
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      loadingBuilder: (context, event) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return buildLoading(constraints.maxWidth, constraints.maxHeight);
        },
      ),
      pageController: _pageController,
      onPageChanged: _onGalleryPageChange,
      itemCount: widget.comicInfo.images.pages.length,
      allowImplicitScrolling: true,
      builder: (BuildContext context, int index) {
        return PhotoViewGalleryPageOptions(
          filterQuality: FilterQuality.high,
          imageProvider: NHentaiImageProvider(
              pageImageUrl(widget.comicInfo.mediaId, index + 1)),
          errorBuilder: (b, e, s) {
            print("$e,$s");
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return buildError(constraints.maxWidth, constraints.maxHeight);
              },
            );
          },
        );
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget _buildViewer() {
    return Column(
      children: [
        Container(height: _fullScreen ? 0 : super._appBarHeight()),
        Expanded(
          child: Stack(
            children: [
              _gallery,
            ],
          ),
        ),
        Container(height: _fullScreen ? 0 : super._bottomBarHeight()),
      ],
    );
  }

  @override
  _needJumpTo(int pageIndex, bool animation) {
    if (animation) {
      _pageController.animateToPage(
        pageIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.ease,
      );
    } else {
      _pageController.jumpToPage(pageIndex);
    }
  }

  void _onGalleryPageChange(int to) {
    super._onCurrentChange(to);
  }
}

////////////////////////////////

// 仅支持安卓
// 监听后会拦截安卓手机音量键
// 仅最后一次监听生效
// event可能为DOWN/UP
Event<_ReaderControllerEventArgs> _readerControllerEvent =
    Event<_ReaderControllerEventArgs>();

class _ReaderControllerEventArgs extends EventArgs {
  final String key;

  _ReaderControllerEventArgs(this.key);
}

const _listVolume = false;

var _volumeListenCount = 0;

void _onVolumeEvent(dynamic args) {
  _readerControllerEvent.broadcast(_ReaderControllerEventArgs("$args"));
}

EventChannel volumeButtonChannel = const EventChannel("volume_button");
StreamSubscription? volumeS;

void addVolumeListen() {
  _volumeListenCount++;
  if (_volumeListenCount == 1) {
    volumeS =
        volumeButtonChannel.receiveBroadcastStream().listen(_onVolumeEvent);
  }
}

void delVolumeListen() {
  _volumeListenCount--;
  if (_volumeListenCount == 0) {
    volumeS?.cancel();
  }
}

Widget readerKeyboardHolder(Widget widget) {
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    widget = RawKeyboardListener(
      focusNode: FocusNode(),
      child: widget,
      autofocus: true,
      onKey: (event) {
        if (event is RawKeyDownEvent) {
          if (event.isKeyPressed(LogicalKeyboardKey.arrowUp)) {
            _readerControllerEvent.broadcast(_ReaderControllerEventArgs("UP"));
          }
          if (event.isKeyPressed(LogicalKeyboardKey.arrowDown)) {
            _readerControllerEvent
                .broadcast(_ReaderControllerEventArgs("DOWN"));
          }
        }
      },
    );
  }
  return widget;
}

////////////////////////////////
