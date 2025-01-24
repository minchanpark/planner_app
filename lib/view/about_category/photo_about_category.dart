//import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:planner/view/about_camera/camera_screen.dart';
import 'package:planner/view_model/audio_view_model.dart';
import 'package:provider/provider.dart';
import '../../model/photo_model.dart';
import '../../view_model/auth_view_model.dart';
import '../../view_model/category_view_model.dart';
import 'video_player_screen.dart';

class CategoryScreenPhoto extends StatefulWidget {
  final String categoryId;

  const CategoryScreenPhoto({super.key, required this.categoryId});

  @override
  State<CategoryScreenPhoto> createState() => _CategoryScreenPhotoState();
}

class _CategoryScreenPhotoState extends State<CategoryScreenPhoto> {
  AudioPlayer? audioPlayer;
  @override
  Widget build(BuildContext context) {
    // Provider를 통해 ViewModel들에 접근
    final categoryViewModel =
        Provider.of<CategoryViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final audioViewModel = Provider.of<AudioViewModel>(context, listen: false);

    final audiourl = audioViewModel.audioFilePath;

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder(
          future: categoryViewModel.getCategoryName(widget.categoryId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('예상치 못한 에러가 발생했습니다. 앱을 다시 실행하세요.');
            } else if (!snapshot.hasData || snapshot.data == null) {
              return Text('카테고리 이름을 먼저 설정하세요!');
            } else {
              return Text(snapshot.data!);
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.camera),
            onPressed: () async {
              try {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraScreen(
                        pageName: 'category', categoryId: widget.categoryId),
                  ),
                );
              } catch (e) {
                // 에러 메시지 표시
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('사진 업로드 중 오류가 발생했습니다: $e'),
                  ),
                );
              }
            },
          ),
        ],
      ),

      // StreamBuilder를 사용하여 Firestore의 실시간 데이터 변경 감지
      body: FutureBuilder<String>(
        future: authViewModel.getNickNameFromFirestore(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          return SingleChildScrollView(
            child: StreamBuilder<List<PhotoModel>>(
              // getPhotosStream: CategoryViewModel에서 정의한 스트림
              // 현재 로그인한 사용자의 사진들을 실시간으로 가져옴
              stream: categoryViewModel.getPhotosStream(widget.categoryId),
              builder: (context, snapshot) {
                // 로딩 중일 때 표시할 위젯
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                // 에러 발생 시 표시할 위젯
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                // 데이터가 없을 때 표시할 위젯
                final photos = snapshot.data ?? [];
                if (photos.isEmpty) {
                  return Center(child: Text('아직 등록된 사진이 없습니다.'));
                }

                // GridView를 사용하여 사진들을 그리드 형태로 표시
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                            onPressed: () async {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VideoPlayerScreen(
                                    categoryId: widget.categoryId,
                                    categoryViewModel: categoryViewModel,
                                  ),
                                ),
                              );
                            },
                            child: Text('recap 영상 만들기')),
                        // 사진 메타데이터를 분석하는 버튼의 onPressed 콜백 수정
                        ElevatedButton(
                          child: Text('카테고리 추천'),
                          onPressed: () async {
                            // gpt를 사용하여서 사진을 인식하는 함수 호출
                            categoryViewModel
                                .suggestNextCategory(widget.categoryId);
                          },
                        ),
                      ],
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.all(8),
                      // 그리드 설정: 2열로 표시
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: photos.length,
                      itemBuilder: (context, index) {
                        final photo = photos[index];
                        // 각 사진을 둥근 모서리의 컨테이너에 표시
                        return (photo.imageUrl.isEmpty)
                            ? SizedBox()
                            : Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(),
                                      blurRadius: 5,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                // 사진을 클릭했을 때의 동작 정의
                                child: GestureDetector(
                                  onTap: () {
                                    // 사진 상세보기 또는 다른 동작 추가 가능
                                    // 여기서 음성녹음을 재생하는 코드 추가
                                    // 음성 녹음을 재생하는 부분을 audioviewmodel에 추가하기?
                                    showDialog(
                                      context: context,
                                      builder: (context) => Dialog(
                                        child: Column(
                                          children: [
                                            SizedBox(
                                              width: double.infinity,
                                              child: Image.network(
                                                photo.imageUrl,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: () async {
                                                // 새로운 AudioPlayer 인스턴스 생성
                                                audioPlayer = AudioPlayer();

                                                if (audiourl != null) {
                                                  audioPlayer!.play(UrlSource(
                                                      photo.audioUrl));
                                                } else {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          'Audio URL is not available'),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: Text('음성녹음 듣기'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    // CachedNetworkImage를 사용하여 이미지 캐싱 처리
                                    child: CachedNetworkImage(
                                      imageUrl: photo.imageUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                      },
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
