import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:planner/theme/theme.dart';
import 'package:planner/view/about_camera/photo_editor_screen.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:planner/view_model/category_view_model.dart';
import 'package:planner/view_model/auth_view_model.dart';

class CameraScreen extends StatefulWidget {
  final String categoryName;
  final String categoryId;

  const CameraScreen({super.key, this.categoryName = '', this.categoryId = ''});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  late List<CameraDescription> cameras;
  int selectedCameraIndex = 0;
  FlashMode _currentFlashMode = FlashMode.off;
  IconData flashIcon = MingCute.flash_fill;
  Color flashColor = Colors.white;
  bool _isFlashAvailable = false;

  //드롭다운 메뉴의 값을 담는 변수
  String dropdownValue = '';

  String categoryId = '';

  @override
  void initState() {
    super.initState();
    // 전달받은 값이 있다면 초기값 설정 (한 번만)
    if (widget.categoryName.isNotEmpty) {
      dropdownValue = widget.categoryName;
      categoryId = widget.categoryId;
    }
    _initializeCamera(); // 카메라 초기화 등 기타 작업
  }

  @override
  void dispose() {
    if (_cameraController!.value.isInitialized) {
      _cameraController!.dispose();
    }
    super.dispose();
  }

  /// 카메라를 초기화하고 첫 번째 카메라를 설정하는 함수
  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _setCamera(selectedCameraIndex);
      } else {
        print('No cameras available');
      }
      // 플래시 모드가 현재 설정값과 다르면 변경
      if (_cameraController!.value.flashMode != _currentFlashMode) {
        await _cameraController!.setFlashMode(_currentFlashMode);
      }
    } catch (e) {
      print('Camera initialization error: $e');
    }
  }

  /// 특정 인덱스의 카메라를 세팅하는 함수
  void _setCamera(int index) {
    // 기존 컨트롤러가 있다면 dispose 처리
    if (_cameraController != null) {
      _cameraController!.dispose();
    }
    _cameraController = CameraController(
      cameras[index],
      ResolutionPreset.high,
    );
    _initializeControllerFuture =
        _cameraController!.initialize().catchError((e) {
      print('Error initializing camera: $e');
    });
    setState(() {});
  }

  /// 사진 촬영 후 PhotoEditorScreen으로 이동하는 함수
  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _cameraController!.takePicture();
      print('사진 촬영 완료: ${image.path}');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoEditorScreen(
            imagePath: image.path,
            categoryId: categoryId,
          ),
        ),
      );
    } catch (e) {
      print(e);
    }
  }

  /// 카메라 전환 함수 (전면/후면 카메라 등의 전환)
  Future<void> _switchCamera() async {
    if (cameras.isEmpty) return;

    // 다음 카메라로 인덱스 업데이트
    selectedCameraIndex = (selectedCameraIndex + 1) % cameras.length;

    await _cameraController?.dispose();
    _cameraController = CameraController(
      cameras[selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _cameraController!.initialize();

    // 플래시 지원 여부 확인 후 플래시 모드 설정
    _isFlashAvailable = _cameraController!.value.flashMode == FlashMode.off ||
        _cameraController!.value.flashMode == FlashMode.auto ||
        _cameraController!.value.flashMode == FlashMode.always;
    print('플래시 지원 여부: $_isFlashAvailable');
    print('현재 플래시 모드1: ${_cameraController!.value.flashMode}');

    if (_isFlashAvailable) {
      await _cameraController!.setFlashMode(_currentFlashMode);
    }
    setState(() {});
  }

  /// 플래시 모드를 토글하는 함수
  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;

    FlashMode newFlashMode;
    switch (_currentFlashMode) {
      case FlashMode.off:
        newFlashMode = FlashMode.torch;
        flashIcon = MingCute.flash_fill;
        flashColor = Colors.yellow;
        break;
      case FlashMode.always:
        newFlashMode = FlashMode.off;
        flashIcon = MingCute.flash_fill;
        flashColor = Colors.white;
        break;
      default:
        newFlashMode = FlashMode.off;
        flashIcon = MingCute.flash_fill;
        flashColor = Colors.white;
    }

    try {
      await _cameraController!.setFlashMode(newFlashMode);
      setState(() {
        _currentFlashMode = newFlashMode;
      });
      print('플래시 모드 변경 완료?: $newFlashMode');
      print('현재 플래시 모드2: ${_currentFlashMode}');
    } catch (e) {
      print('플래시 모드 변경 오류: $e');
    }
  }

  /// 카메라 미리보기 위젯 (플랫폼별 회전 및 미러링 적용)
  Widget _buildCameraPreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    // 현재 디바이스의 회전 정보
    var mediaQuery = MediaQuery.of(context);
    var rotation = mediaQuery.orientation;
    int rotationDegrees = rotation == Orientation.portrait ? 0 : 180;

    return Transform(
      transform: Matrix4.identity()
        ..rotateY(0) // 전면 카메라인 경우 좌우 반전 적용 가능
        ..rotateZ(rotationDegrees * math.pi / 180),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: (363 / 393) * mediaQuery.size.width, // 화면 너비의 비율 설정
          height: (627 / 852) * mediaQuery.size.height, // 화면 높이의 비율 설정
          child: AspectRatio(
            aspectRatio: _cameraController!.value.aspectRatio,
            child: CameraPreview(_cameraController!),
          ),
        ),
      ),
    );
  }

  /// 카메라 제어 버튼(플래시, 드롭다운, 카메라 전환)이 모여있는 위젯
  Widget _buildCameraControls() {
    return Row(
      children: [
        // 플래시 토글 버튼
        IconButton(
          onPressed: _toggleFlash,
          icon: Icon(
            flashIcon,
            color: flashColor,
            size: 30,
          ),
        ),
        SizedBox(width: 50),

        // 카테고리 선택 드롭다운
        _categoryDropDown(),
        SizedBox(width: 30),

        // 카메라 전환 버튼
        IconButton(
          onPressed: _switchCamera,
          icon: Image.asset(
            'assets/camera_turn.png',
            width: 30,
            height: 30,
          ),
        )
      ],
    );
  }

  /// 카테고리 드롭다운: Provider를 통해 카테고리 목록을 가져와 표시
  _categoryDropDown() {
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

            // dropdownValue가 아직 설정되어 있지 않다면 초기값 설정
            if (dropdownValue.isEmpty && categories.isNotEmpty) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      appBar: AppBar(
        // 커스텀 앱바: 뒤로가기, 타이틀, 및 추가 버튼 포함
        automaticallyImplyLeading: false,
        title: Text(
          'SOI',
          style: TextStyle(color: AppTheme.lightTheme.colorScheme.secondary),
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        toolbarHeight: 70,
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          // 카메라 초기화 완료 후 카메라 프리뷰 및 컨트롤 위치 지정
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              alignment: Alignment.topCenter,
              children: [
                // 카메라 미리보기 위치
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCameraPreview(),
                  ],
                ),
                // 상단 카메라 제어 버튼 위치
                Positioned(
                  top: 16,
                  child: _buildCameraControls(),
                ),
                // 하단 촬영 버튼 위치
                Positioned(
                  top: (512 / 852) * MediaQuery.of(context).size.height,
                  child: GestureDetector(
                    onTap: _takePicture,
                    child: SizedBox(
                      height: 65,
                      width: 65,
                      child: Image.asset(
                        'assets/camera_button.png',
                        width: 65,
                        height: 65,
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else {
            // 카메라 초기화 중 로딩 인디케이터 표시
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
