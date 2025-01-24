import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:planner/theme/theme.dart';
//import 'package:permission_handler/permission_handler.dart';
import 'package:planner/view/about_camera/photo_editor_screen.dart';
import 'dart:math' as math;

class CameraScreen extends StatefulWidget {
  final String pageName;
  final categoryId;

  const CameraScreen({super.key, required this.pageName, this.categoryId});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  late List<CameraDescription> cameras;
  int selectedCameraIndex = 0;
  FlashMode _currentFlashMode = FlashMode.off;
  IconData flashIcon = MingCute.flash_fill;
  Color flashColor = Colors.white;
  bool _isFlashAvailable = false; // 플래시 지원 여부

  @override
  void initState() {
    super.initState();
    //_checkAndRequestPermissions();
    _initializeCamera();
  }

  @override
  void dispose() {
    if (_controller!.value.isInitialized) {
      _controller!.dispose();
    }
    super.dispose();
  }

  // 카메라 초기화하는 함수
  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _setCamera(selectedCameraIndex);
      } else {
        print('No cameras available');
      }

      if (_controller!.value.flashMode != _currentFlashMode) {
        await _controller!.setFlashMode(_currentFlashMode);
      }
    } catch (e) {
      print('Camera initialization error: $e');
    }
  }

  void _setCamera(int index) {
    if (_controller != null) {
      _controller!.dispose();
    }
    _controller = CameraController(
      cameras[index],
      ResolutionPreset.high,
    );

    _initializeControllerFuture = _controller!.initialize().catchError((e) {
      print('Error initializing camera: $e');
    });

    setState(() {});
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoEditorScreen(
            imagePath: image.path,
            pageName: widget.pageName,
            categoryId: widget.categoryId,
          ),
        ),
      );
    } catch (e) {
      print(e);
    }
  }

  // 카메라 전환 메서드
  Future<void> _switchCamera() async {
    if (cameras.isEmpty) return;

    selectedCameraIndex = (selectedCameraIndex + 1) % cameras.length;

    await _controller?.dispose();

    _controller = CameraController(
      cameras[selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();

    // 플래시 지원 여부 확인
    _isFlashAvailable = _controller!.value.flashMode == FlashMode.off ||
        _controller!.value.flashMode == FlashMode.auto ||
        _controller!.value.flashMode == FlashMode.always;

    print('플래시 지원 여부: $_isFlashAvailable');
    print('현재 플래시 모드1: ${_controller!.value.flashMode}');

    if (_isFlashAvailable) {
      await _controller!.setFlashMode(_currentFlashMode);
    }

    setState(() {});
  }

  // 플래시 토글 메서드
  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

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
      await _controller!.setFlashMode(newFlashMode);
      setState(() {
        _currentFlashMode = newFlashMode;
      });

      print('플래시 모드 변경 완료?: $newFlashMode');
      print('현재 플래시 모드2: ${_currentFlashMode}');
    } catch (e) {
      print('플래시 모드 변경 오류: $e');
    }
  }

  // 카메라 미리보기의 회전 및 미러링 적용
  Widget _buildCameraPreview() {
    // 카메라 컨트롤러가 초기화되지 않았을 경우 로딩 표시
    if (_controller == null || !_controller!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    // 현재 디바이스의 회전 상태 가져오기
    var mediaQuery = MediaQuery.of(context);
    var rotation = mediaQuery.orientation;

    // 회전 각도 계산
    int rotationDegrees = 0;
    switch (rotation) {
      case Orientation.portrait:
        rotationDegrees = 0;
        break;
      case Orientation.landscape:
        rotationDegrees = 180;
        break;
    }

    return Transform(
      transform: Matrix4.identity()
        ..rotateY(0) // 전면 카메라일 경우 좌우반전
        ..rotateZ(rotationDegrees * math.pi / 180), // 디바이스 회전에 따른 회전
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: (363 / 393) * mediaQuery.size.width, // 화면 너비의 90% 정도로 설정
          height: (627 / 852) * mediaQuery.size.height, // 화면 높이의 70% 정도로 설정

          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: CameraPreview(_controller!),
          ),
        ),
      ),
    );
  }

  // 카메라 제어 버튼 모음
  // 플래시 버튼, 카메라 전환 버튼, 촬영 버튼을 모은 위젯들임.
  // 촬영 버튼은 따로 메서드로 분리하여 가독성 향상
  Widget _buildCameraControls() {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            _toggleFlash();
          },
          icon: Icon(
            flashIcon,
            color: flashColor,
            size: 30,
          ), // 더 적절한 아이콘 사용
        ),
        SizedBox(width: 232),
        IconButton(
          onPressed: () {
            _switchCamera();
          },
          icon: Image.asset(
            'assets/camera_turn.png',
            width: 30,
            height: 30,
          ),
        )
      ],
    );
  }

  /* GestureDetector(
          onTap: _takePicture, // 별도의 메서드로 분리하여 가독성 향상
          child: Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 5,
              ),
            ),
          ),
        ),*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: AppTheme.lightTheme.colorScheme.secondary),
          onPressed: () {
            Navigator.pop(context, widget.categoryId); // 파라미터 전달
          },
        ),
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
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              alignment: Alignment.topCenter,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCameraPreview(),
                  ],
                ),
                Positioned(
                  top: 16,
                  child: _buildCameraControls(),
                ),
                Positioned(
                  top: (512 / 852) * MediaQuery.of(context).size.height,
                  child: GestureDetector(
                    onTap: _takePicture, // 별도의 메서드로 분리하여 가독성 향상
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
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
