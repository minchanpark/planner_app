//// filepath: /Users/mac/Documents/planner_app/lib/view/about_arcaving/show_photo.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../theme/theme.dart';
import '../../view_model/category_view_model.dart';
import '../../model/photo_model.dart';
import 'show_detailed_photo.dart'; // 상세 화면 임포트

class ShowPhotoScreen extends StatelessWidget {
  final String categoryId; // 카테고리 ID를 외부에서 전달
  final String categoryName; // 카테고리 이름을 외부에서 전달

  const ShowPhotoScreen(
      {Key? key, required this.categoryId, required this.categoryName})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categoryViewModel =
        Provider.of<CategoryViewModel>(context, listen: false);
    final random = Random();

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white, //색변경
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              categoryName,
              style: const TextStyle(color: Colors.white),
            ),
            IconButton(
              icon: const Icon(Icons.calendar_month, color: Colors.white),
              onPressed: () {
                // 필요한 동작 구현
              },
            ),
          ],
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      ),
      body: StreamBuilder<List<PhotoModel>>(
        stream: categoryViewModel.getPhotosStream(categoryId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final photos = snapshot.data ?? [];
          if (photos.isEmpty) {
            return const Center(
                child:
                    Text('사진이 없습니다.', style: TextStyle(color: Colors.white)));
          }

          // MasonryGridView를 사용하여 사진들을 다양한 높이로 배치
          return MasonryGridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            padding: const EdgeInsets.all(8.0),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              // 랜덤 높이: 200 ~ 350 사이 (예시)
              final randomHeight = 90 + random.nextInt(110);
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShowDetailedPhoto(
                        photos: photos,
                        initialIndex: index,
                        categoryName: categoryName,
                        categoryId: categoryId,
                      ),
                    ),
                  );
                },
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    SizedBox(
                      width: 169,
                      height: randomHeight.toDouble(),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          photo.imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat('yyyy.MM.dd').format(photo.createdAt.toDate()),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
