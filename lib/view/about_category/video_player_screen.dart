import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../view_model/category_view_model.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String categoryId;
  final CategoryViewModel categoryViewModel;

  const VideoPlayerScreen({
    super.key,
    required this.categoryId,
    required this.categoryViewModel,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  Future<void>? _initializeVideoPlayerFuture;
  bool isLoading = true;
  String? videoUrl;

  @override
  void initState() {
    super.initState();
    _fetchVideoUrl();
  }

  Future<void> _fetchVideoUrl() async {
    videoUrl = await widget.categoryViewModel
        .checkPhotoCountAndPerformAction(widget.categoryId);
    if (videoUrl != null && videoUrl != 'invalid url') {
      _initializeVideoPlayer(videoUrl!);
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _initializeVideoPlayer(String videoUrl) async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
    _initializeVideoPlayerFuture = _controller!.initialize().then((_) {
      setState(() {
        isLoading = false; // 초기화가 완료되면 로딩 상태를 false로 설정
      });
    });
    _controller!.setLooping(true); // 반복 재생 설정 (선택사항)
  }

  @override
  void dispose() {
    _controller?.dispose(); // 컨트롤러 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('카테고리 동영상 플레이어'),
      ),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : videoUrl == null || videoUrl == 'invalid url'
                ? Text('비디오를 불러올 수 없습니다.')
                : FutureBuilder(
                    future: _initializeVideoPlayerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        // 비디오 재생 위젯
                        return AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        );
                      } else {
                        // 로딩 인디케이터 표시
                        return CircularProgressIndicator();
                      }
                    },
                  ),
      ),
      floatingActionButton: isLoading ||
              videoUrl == null ||
              videoUrl == 'invalid url'
          ? null
          : FloatingActionButton(
              onPressed: () {
                setState(() {
                  // 비디오 재생/일시정지 토글
                  _controller!.value.isPlaying
                      ? _controller!.pause()
                      : _controller!.play();
                });
              },
              child: Icon(
                _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            ),
    );
  }
}
