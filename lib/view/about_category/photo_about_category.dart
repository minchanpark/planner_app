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

  const CategoryScreenPhoto({Key? key, required this.categoryId})
      : super(key: key);

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

    // 로컬 변수에 할당 (원본 코드에서 사용)
    final audiourl = audioViewModel.audioFilePath;

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<String>(
          future: categoryViewModel.getCategoryName(widget.categoryId),
          builder: (context, categoryNameSnapshot) {
            if (categoryNameSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (categoryNameSnapshot.hasError) {
              return const Text('예상치 못한 에러가 발생했습니다. 앱을 다시 실행하세요.');
            } else if (!categoryNameSnapshot.hasData ||
                categoryNameSnapshot.data == null) {
              return const Text('카테고리 이름을 먼저 설정하세요!');
            } else {
              return Text(categoryNameSnapshot.data!);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera),
            onPressed: () async {
              try {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CameraScreen(
                      pageName: 'category',
                      categoryId: widget.categoryId,
                    ),
                  ),
                );
              } catch (e) {
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
      body: FutureBuilder<String>(
        future: authViewModel.getNickNameFromFirestore(),
        builder: (context, nicknameSnapshot) {
          // 현재는 nicknameSnapshot을 UI에서 직접 사용하지 않으므로
          // 원본 코드처럼 결과와 상관없이 다음 위젯(SingleChildScrollView)을 빌드합니다.
          return SingleChildScrollView(
            child: StreamBuilder<List<PhotoModel>>(
              stream: categoryViewModel.getPhotosStream(widget.categoryId),
              builder: (context, photosSnapshot) {
                if (photosSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (photosSnapshot.hasError) {
                  return Center(
                      child: Text('Error: ${photosSnapshot.error.toString()}'));
                }

                final photos = photosSnapshot.data ?? [];
                if (photos.isEmpty) {
                  return const Center(child: Text('아직 등록된 사진이 없습니다.'));
                }

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
                          child: const Text('recap 영상 만들기'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            categoryViewModel
                                .suggestNextCategory(widget.categoryId);
                          },
                          child: const Text('카테고리 추천'),
                        ),
                      ],
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2열
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: photos.length,
                      itemBuilder: (context, index) {
                        final photo = photos[index];
                        if (photo.imageUrl.isEmpty) {
                          return const SizedBox();
                        }

                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(),
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: GestureDetector(
                            onTap: () {
                              // 사진 상세보기 & 음성녹음 재생
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
                                          audioPlayer = AudioPlayer();
                                          if (audiourl != null) {
                                            audioPlayer!.play(
                                              UrlSource(photo.audioUrl),
                                            );
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Audio URL is not available'),
                                              ),
                                            );
                                          }
                                        },
                                        child: const Text('음성녹음 듣기'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
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
