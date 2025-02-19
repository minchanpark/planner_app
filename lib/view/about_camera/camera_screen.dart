//// filepath: /Users/mac/Documents/planner_app/lib/view/about_camera/camera_screen.dart
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:planner/theme/theme.dart';
import 'package:planner/view/about_camera/photo_editor_screen.dart';
import 'dart:math' as math;
import 'category_drop_down_widget.dart';

class CameraScreen extends StatefulWidget {
  final String categoryName;
  final String categoryId;

  const CameraScreen({super.key, this.categoryName = '', this.categoryId = ''});

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
  bool _isFlashAvailable = false;

  // 드롭다운 메뉴 관련 상태 변수
  String dropdownValue = '';
  String categoryId = '';

  @override
  void initState() {
    super.initState();
    // 전달받은 값이 있다면 초기값 한 번 설정
    if (widget.categoryName.isNotEmpty) {
      dropdownValue = widget.categoryName;
      categoryId = widget.categoryId;
    }
    _initializeCamera(); // 카메라 초기화
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// 카메라를 초기화하고 첫 번째 카메라를 설정하는 함수
  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _setCamera(selectedCameraIndex);
      } else {
        debugPrint('No cameras available');
      }
      if (_controller != null &&
          _controller!.value.flashMode != _currentFlashMode) {
        await _controller!.setFlashMode(_currentFlashMode);
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  /// 특정 인덱스의 카메라를 세팅하는 함수
  void _setCamera(int index) {
    _controller?.dispose();
    _controller = CameraController(
      cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller!.initialize().catchError((e) {
      debugPrint('Error initializing camera: $e');
    });
    setState(() {});
  }

  /// 사진 촬영 후 PhotoEditorScreen으로 이동하는 함수
  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoEditorScreen(
            imagePath: image.path,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Take picture error: $e');
    }
  }

  /// 카메라 전환 함수
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
    _isFlashAvailable = _controller!.value.flashMode == FlashMode.off ||
        _controller!.value.flashMode == FlashMode.auto ||
        _controller!.value.flashMode == FlashMode.always;
    debugPrint('Flash available: $_isFlashAvailable');
    if (_isFlashAvailable) {
      await _controller!.setFlashMode(_currentFlashMode);
    }
    setState(() {});
  }

  /// 플래시 모드 토글 함수
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
      debugPrint('Flash mode changed: $newFlashMode');
    } catch (e) {
      debugPrint('Flash mode change error: $e');
    }
  }

  /// 카메라 미리보기 위젯
  Widget _buildCameraPreview() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    final mediaQuery = MediaQuery.of(context);
    final rotationDegrees =
        mediaQuery.orientation == Orientation.portrait ? 0 : 180;

    return Transform(
      transform: Matrix4.identity()
        ..rotateY(0)
        ..rotateZ(rotationDegrees * math.pi / 180),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: (363 / 393) * mediaQuery.size.width,
          height: (627 / 852) * mediaQuery.size.height,
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: CameraPreview(_controller!),
          ),
        ),
      ),
    );
  }

  /// 카메라 제어 버튼이 모여있는 위젯
  Widget _buildCameraControls() {
    return Row(
      children: [
        IconButton(
          onPressed: _toggleFlash,
          icon: Icon(
            flashIcon,
            color: flashColor,
            size: 30,
          ),
        ),
        const SizedBox(width: 50),
        // 분리된 드롭다운 위젯 사용
        const CategoryDropdownWidget(),
        const SizedBox(width: 30),
        IconButton(
          onPressed: _switchCamera,
          icon: Image.asset(
            'assets/camera_turn.png',
            width: 30,
            height: 30,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
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
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              alignment: Alignment.topCenter,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [_buildCameraPreview()],
                ),
                Positioned(
                  top: 16,
                  child: _buildCameraControls(),
                ),
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
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
