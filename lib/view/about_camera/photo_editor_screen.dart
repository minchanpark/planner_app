import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart'; // 추가
import '../../model/editable_text_model.dart';
import '../../theme/theme.dart';
import '../../view_model/auth_view_model.dart';
import '../../view_model/calendar_view_model.dart';
import '../../view_model/category_view_model.dart';
import '../../view_model/audio_view_model.dart';
import 'package:flutter/foundation.dart' as foundation;

class PhotoEditorScreen extends StatefulWidget {
  final String imagePath;
  final String pageName;
  final categoryId;

  const PhotoEditorScreen({
    super.key,
    required this.imagePath,
    required this.pageName,
    this.categoryId,
  });

  @override
  _PhotoEditorScreenState createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  final GlobalKey _globalKey = GlobalKey();

  // 텍스트 요소 리스트
  List<EditableTextElement> _textElements = [];

  // 이모지 피커 표시 여부
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // 모든 텍스트 요소의 컨트롤러와 포커스 노드를 해제
    for (var element in _textElements) {
      element.controller.dispose();
      element.focusNode.dispose();
    }
    super.dispose();
  }

  // 이모지 선택 시 호출되는 메서드
  void _onEmojiSelected(Emoji emoji) {
    setState(() {
      _showEmojiPicker = false;
      // 새로운 이모지 요소 추가
      _textElements.add(
        EditableTextElement(
          text: emoji.emoji,
          position: Offset(50, 50), // 초기 위치 설정
          controller: TextEditingController(text: emoji.emoji),
          focusNode: FocusNode(),
          isEmoji: true,
        ),
      );
    });
  }

  // 텍스트 추가 시 호출되는 메서드
  void _addText() {
    setState(() {
      // 새로운 텍스트 요소 추가
      _textElements.add(
        EditableTextElement(
          text: '',
          position: Offset(50, 50), // 초기 위치 설정
          controller: TextEditingController(),
          focusNode: FocusNode(),
          isEmoji: false,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context);
    final audioViewModel = Provider.of<AudioViewModel>(context);
    final categoryViewModel = Provider.of<CategoryViewModel>(context);

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'SOI',
          style: TextStyle(color: AppTheme.lightTheme.colorScheme.secondary),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.add,
              size: 35,
              color: AppTheme.lightTheme.colorScheme.secondary,
            ),
          ),
        ],
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        toolbarHeight: 70,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() {
            _showEmojiPicker = false;
          });
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                RepaintBoundary(
                  key: _globalKey,
                  child: Stack(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius:
                                BorderRadius.circular(16), // 테두리 반경 적용
                            child: Image.file(
                              File(widget.imagePath),
                              width: (363 / 393) *
                                  mediaQuery.size.width, // 화면 너비의 90% 정도로 설정
                              height: (627 / 852) *
                                  mediaQuery.size.height, // 화면 높이의 70% 정도로 설정
                              fit: BoxFit.fill,
                            ),
                          ),
                        ],
                      ),
                      // 모든 텍스트 요소 렌더링
                      ..._textElements
                          .map((element) => _buildEditableText(element))
                          .toList(),
                    ],
                  ),
                ),
                Positioned(left: 125, top: 20, child: _photoEditButton()),
                Positioned(
                    top: 400,
                    left: 50,
                    child: _customImage(audioViewModel, categoryViewModel)),
                // 이모지 피커 추가
                _showEmojiPicker
                    ? Align(
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          height: 250,
                          child: EmojiPicker(
                            onEmojiSelected: (category, emoji) {
                              _onEmojiSelected(emoji);
                            },
                            config: Config(
                              height: 250,
                              checkPlatformCompatibility: true,
                              emojiViewConfig: EmojiViewConfig(
                                // Issue: https://github.com/flutter/flutter/issues/28894
                                emojiSizeMax: 28 *
                                    (foundation.defaultTargetPlatform ==
                                            TargetPlatform.iOS
                                        ? 1.20
                                        : 1.0),
                              ),
                              viewOrderConfig: const ViewOrderConfig(
                                top: EmojiPickerItem.categoryBar,
                                middle: EmojiPickerItem.emojiView,
                                bottom: EmojiPickerItem.searchBar,
                              ),
                              skinToneConfig: const SkinToneConfig(),
                              categoryViewConfig: const CategoryViewConfig(),
                              bottomActionBarConfig:
                                  const BottomActionBarConfig(),
                              searchViewConfig: const SearchViewConfig(),
                            ),
                          ),
                        ),
                      )
                    : SizedBox(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _customImage(
      AudioViewModel audioViewModel, CategoryViewModel categoryViewModel) {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            // 이모지 피커 토글
            setState(() {
              _showEmojiPicker = !_showEmojiPicker;
            });
          },
          icon: Image.asset(
            'assets/imoji.png',
            width: 52,
            height: 52,
          ),
        ),
        IconButton(
          onPressed: () {
            // 브러시 기능 추가 시 구현
          },
          icon: Image.asset(
            'assets/brush.png',
            width: 52,
            height: 52,
          ),
        ),
        IconButton(
          onPressed: () {
            // 텍스트 추가
            _addText();
          },
          icon: Image.asset(
            'assets/text.png',
            width: 52,
            height: 52,
          ),
        ),
        IconButton(
          onPressed: () async {
            if (audioViewModel.isRecording) {
              await audioViewModel.stopRecording();
            } else {
              await audioViewModel.startRecording();
            }
          },
          icon: Image.asset(
            'assets/voice.png',
            width: 52,
            height: 52,
          ),
        ),
        if (audioViewModel.audioFilePath != null) Text('Audio recorded'),
      ],
    );
  }

  Widget _photoEditButton() {
    return Row(
      children: [
        ElevatedButton(
          onPressed: () {},
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(
              AppTheme.lightTheme.colorScheme.secondary,
            ),
            elevation: MaterialStateProperty.all(0),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
          child: Text(
            '공유하기',
            style: AppTheme.textTheme.textTheme.labelMedium,
          ),
        ),
        SizedBox(width: 11),
        ElevatedButton(
          onPressed: () async {
            await _saveImageWithText();
            Navigator.pop(context, widget.categoryId);
          },
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(
              AppTheme.lightTheme.colorScheme.secondary,
            ),
            elevation: MaterialStateProperty.all(0),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
          child: Text(
            '추가하기 +',
            style: AppTheme.textTheme.textTheme.labelMedium,
          ),
        ),
      ],
    );
  }

  // 수정된 텍스트 요소 위젯
  Widget _buildEditableText(EditableTextElement element) {
    return Positioned(
      left: element.position.dx,
      top: element.position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            element.position += details.delta;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: element.isEmoji ? Colors.transparent : Colors.black54,
            borderRadius: BorderRadius.circular(8),
          ),
          constraints: BoxConstraints(
            maxWidth: 300, // 컨테이너의 최대 너비 설정
          ),
          child: IntrinsicWidth(
            child: TextField(
              controller: element.controller,
              focusNode: element.focusNode,
              style: TextStyle(
                color: element.isEmoji ? Colors.black : Colors.white,
                fontSize: 24,
              ),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.all(8),
                hintText: element.isEmoji ? '' : '텍스트를 입력하세요',
                hintStyle: TextStyle(
                  color: Colors.white70,
                  fontSize: 24,
                ),
                border: InputBorder.none,
              ),
              textAlign: TextAlign.center,
              maxLines: null, // 여러 줄 허용
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveImageWithText() async {
    final calendarViewModel =
        Provider.of<CalendarViewModel>(context, listen: false);
    final categoryViewModel =
        Provider.of<CategoryViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final audioViewModel = Provider.of<AudioViewModel>(context, listen: false);

    try {
      final boundary = _globalKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        print('RenderRepaintBoundary is null');
        return;
      }

      final ui.Image capturedImage = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await capturedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        print('ByteData is null');
        return;
      }
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final appDir = await getApplicationDocumentsDirectory();
      final filePath =
          '${appDir.path}/${DateTime.now().millisecondsSinceEpoch}_edited.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      await Future.delayed(
          Duration(seconds: 1)); // 파일 시스템이 파일을 쓸 시간을 확보하기 위해 딜레이 추가

      String? audioUrl;
      if (audioViewModel.audioFilePath != null) {
        audioUrl = await audioViewModel.uploadAudioToFirestore(
          widget.categoryId,
          await authViewModel.getNickNameFromFirestore(),
        );
      }

      if (widget.pageName != "category") {
        await calendarViewModel.uploadPhoto(filePath, DateTime.now());
      } else {
        await categoryViewModel.uploadPhoto(
          widget.categoryId,
          await authViewModel.getNickNameFromFirestore(),
          filePath,
          audioUrl ?? '',
          context,
        );
      }
    } catch (e) {
      print('Error saving image: $e');
    }
  }
}
