import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
//import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:lottie/lottie.dart';
//import 'package:flutter/foundation.dart' as foundation;
import '../../model/editable_text_model.dart';
import '../../theme/theme.dart';
import '../../view_model/auth_view_model.dart';
import '../../view_model/category_view_model.dart';
import '../../view_model/audio_view_model.dart';

class PhotoEditorScreen extends StatefulWidget {
  final String imagePath;

  const PhotoEditorScreen({
    Key? key,
    required this.imagePath,
  }) : super(key: key);

  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  final GlobalKey _globalKey = GlobalKey();

  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;

  // 텍스트 요소 리스트
  final List<EditableTextElement> _textElements = [];

  // 이모지 피커 표시 여부
  //bool _showEmojiPicker = false;

  String dropdownValue = '';

  String categoryId = '';

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
  /*void _onEmojiSelected(Emoji emoji) {
    setState(() {
      _showEmojiPicker = false;
      // 새로운 이모지 요소 추가
      _textElements.add(
        EditableTextElement(
          text: emoji.emoji,
          position: const Offset(50, 50), // 초기 위치 설정
          controller: TextEditingController(text: emoji.emoji),
          focusNode: FocusNode(),
          isEmoji: true,
        ),
      );
    });
  }*/

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final audioViewModel = Provider.of<AudioViewModel>(context);
    final isRecording = audioViewModel.isRecording;

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white, //색변경
        ),
        title: Text(
          'SOI',
          style: TextStyle(color: AppTheme.lightTheme.colorScheme.secondary),
        ),
        actions: [_photoEditButton()],
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        toolbarHeight: 70,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 51),

                // 캡처 영역
                Stack(
                  children: [
                    RepaintBoundary(
                      key: _globalKey,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(widget.imagePath),
                          width: (261 / 393) * mediaQuery.size.width,
                          height: (451 / 852) * mediaQuery.size.height,
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 250,
                      left: 75,
                      child: isRecording
                          ? SizedBox(
                              height: 100,
                              child: Lottie.asset(
                                'assets/recording_ui.json',
                                repeat: true,
                                animate: true,
                              ),
                            )
                          : SizedBox(),
                    ),
                  ],
                ),

                // 상단 버튼들
                //Positioned(top: 20, left: 20, child: _photoEditButton()),

                TextField(
                  style: AppTheme.lightTheme.textTheme.labelMedium!.copyWith(
                    color: Color(0xff535252),
                  ),
                  decoration: InputDecoration(
                    hintText: '켑션 추가하기...',
                    hintStyle:
                        AppTheme.lightTheme.textTheme.labelMedium!.copyWith(
                      color: Color(0xff535252),
                    ),
                    border: InputBorder.none,
                  ),
                  textAlign: TextAlign.center,
                ),

                // 하단(혹은 특정 위치)의 기능 아이콘들(이모지, 텍스트, 오디오 등)
                //_customImage(audioViewModel),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () async {
                        if (isRecording) {
                          await audioViewModel.stopRecording();
                        } else {
                          await audioViewModel.startRecording();
                        }
                      },
                      icon: SizedBox(
                        width: 52,
                        height: 52,
                        child: Image.asset(
                          'assets/recording_ui.png',
                        ),
                      ),
                    ),
                  ],
                ),

                // 이모지 피커
                /* if (_showEmojiPicker)
                  Align(
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
                          bottomActionBarConfig: const BottomActionBarConfig(),
                          searchViewConfig: const SearchViewConfig(),
                        ),
                      ),
                    ),
                  ),*/
              ],
            ),
          );
        },
      ),
    );
  }

  /// 카테고리 드롭다운: Provider를 통해 카테고리 목록을 가져와 표시
  /*_categoryDropDown() {
    // 먼저 FutureBuilder를 사용하여 현재 로그인 유저의 닉네임을 가져옵니다.
    return FutureBuilder<String>(
      future: Provider.of<AuthViewModel>(context, listen: false)
          .getNickNameFromFirestore(),
      builder: (context, nickSnapshot) {
        // 닉네임을 불러오는 동안 빈 공간을 반환합니다.
        if (nickSnapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(width: 150, child: Text(''));
        }
        // 로그인 정보가 없으면 안내 메시지 표시
        if (!nickSnapshot.hasData) {
          return SizedBox(
            width: 150,
            child: Center(
              child: Text(
                '아직 카테고리가 없습니다.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }
        final nickName = nickSnapshot.data!;
        // 닉네임을 이용해 실시간 업데이트 스트림을 구독합니다.
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: Provider.of<CategoryViewModel>(context, listen: false)
              .streamUserCategories(nickName),
          builder: (context, catSnapshot) {
            // 스트림 구독 중이면 빈 공간 반환
            if (catSnapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(width: 150, child: Text(''));
            }
            // 에러나 데이터가 없으면 안내 메시지 표시
            if (catSnapshot.hasError ||
                !catSnapshot.hasData ||
                catSnapshot.data!.isEmpty) {
              return SizedBox(
                width: 150,
                child: Center(
                  child: Text(
                    '아직 카테고리가 없습니다.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            }
            final categories = catSnapshot.data!;
            // 드롭다운 초기값 설정 (아직 값이 없으면 첫번째 항목 설정)
            if (dropdownValue.isEmpty) {
              dropdownValue = categories.first['name'] as String;
              categoryId = categories.first['id'] as String;
            }
            return SizedBox(
              width: 150,
              child: DropdownMenu<String>(
                initialSelection: dropdownValue,
                inputDecorationTheme: InputDecorationTheme(
                  enabledBorder:
                      OutlineInputBorder(borderSide: BorderSide.none),
                ),
                trailingIcon: Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                ),
                selectedTrailingIcon: Icon(
                  Icons.keyboard_arrow_up,
                  color: Colors.white,
                ),
                menuStyle: MenuStyle(
                  backgroundColor: WidgetStateProperty.all(Color(0xff232121)),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                textStyle: TextStyle(color: Colors.white, fontSize: 20),
                // 드롭다운 메뉴 항목 구성: 각 항목은 'name'과 'id'를 포함하는 Map입니다.
                dropdownMenuEntries: categories.map<DropdownMenuEntry<String>>(
                    (Map<String, dynamic> category) {
                  return DropdownMenuEntry<String>(
                    value: category['name'] as String,
                    label: category['name'] as String,
                    style: ButtonStyle(
                      foregroundColor: WidgetStateProperty.all(
                        dropdownValue == category['name']
                            ? Colors.white
                            : Colors.grey,
                      ),
                    ),
                  );
                }).toList(),
                // 항목 선택 시 선택된 항목의 'name'과 대응되는 'id'를 저장합니다.
                onSelected: (String? value) {
                  if (value != null) {
                    setState(() {
                      dropdownValue = value;
                      final selectedCategory = categories.firstWhere(
                        (element) => element['name'] == value,
                        orElse: () => {'id': ''},
                      );
                      categoryId = selectedCategory['id'] as String;
                    });
                  }
                },
              ),
            );
          },
        );
      },
    );
  }*/

  /*Widget _customImage(AudioViewModel audioViewModel) {
    final isRecording = audioViewModel.isRecording;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 이모지 버튼
        /*IconButton(
          onPressed: () {
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
        // 브러시 버튼
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
        // 텍스트 추가 버튼
        IconButton(
          onPressed: () {
            _addText();
          },
          icon: Image.asset(
            'assets/text.png',
            width: 52,
            height: 52,
          ),
        ),*/
        // 녹음 버튼
        IconButton(
          onPressed: () async {
            if (isRecording) {
              await audioViewModel.stopRecording();
            } else {
              await audioViewModel.startRecording();
            }
          },
          icon: SizedBox(
            width: 52,
            height: 52,
            child: Image.asset(
              'assets/recording_ui.png',
            ),
          ),
        ),
        /* IconButton(
          onPressed: () {},
          icon: SizedBox(
            width: 52,
            height: 52,
            child: Image.asset(
              'assets/plus_menu.png',
            ),
          ),
        ),*/
      ],
    );
  }*/

  /// 상단 '공유하기' / '추가하기 +' 버튼
  Widget _photoEditButton() {
    return Row(
      children: [
        //_categoryDropDown(),
        //SizedBox(width: 90),
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.share, color: Colors.white),
        ),
        IconButton(
          onPressed: () async {
            // 1. 캡처 영역 데이터를 미리 가져옵니다.
            final boundary = _globalKey.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;
            if (boundary == null) return;
            final capturedImageFuture = boundary.toImage(pixelRatio: 2.0);

            // 2. 필요한 Provider 데이터도 미리 받아옵니다.
            final categoryViewModel =
                Provider.of<CategoryViewModel>(context, listen: false);
            final authViewModel =
                Provider.of<AuthViewModel>(context, listen: false);
            final audioViewModel =
                Provider.of<AudioViewModel>(context, listen: false);

            // 3. 카테고리 id와 닉네임 등 미리 캡처 (필요 시)
            final currentCategoryId = categoryId;
            final nickName = await authViewModel.getNickNameFromFirestore();
            final audioFilePath = audioViewModel.audioFilePath;

            // 4. 화면을 즉시 pop 합니다.
            Navigator.pop(context);

            // 5. pop 이후에 백그라운드로 저장 작업을 진행합니다.
            categoryViewModel.saveEditedPhoto(
              capturedImageFuture,
              currentCategoryId,
              nickName,
              audioFilePath,
            );
          },
          icon: Icon(Icons.file_download_outlined, color: Colors.white),
        )
      ],
    );
  }

  // 텍스트 추가 시 호출되는 메서드
  /*void _addText() {
    setState(() {
      // 새로운 텍스트 요소 추가
      _textElements.add(
        EditableTextElement(
          text: '',
          position: const Offset(50, 50), // 초기 위치 설정
          controller: TextEditingController(),
          focusNode: FocusNode(),
          isEmoji: false,
        ),
      );
    });
  }*/

  /// 수정된 텍스트/이모지 요소 위젯
  /*Widget _buildEditableText(EditableTextElement element) {
    return Positioned(
      left: element.position.dx,
      top: element.position.dy,
      child: GestureDetector(
        // 드래그로 위치 이동 가능
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
          constraints: const BoxConstraints(
            maxWidth: 300, // 텍스트 컨테이너 최대 너비
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
                contentPadding: const EdgeInsets.all(8),
                hintText: element.isEmoji ? '' : '텍스트를 입력하세요',
                hintStyle: const TextStyle(
                  color: Colors.white70,
                  fontSize: 24,
                ),
                border: InputBorder.none,
              ),
              textAlign: TextAlign.center,
              maxLines: null,
            ),
          ),
        ),
      ),
    );
  }*/
}
