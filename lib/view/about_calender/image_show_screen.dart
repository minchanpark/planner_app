import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_model/calendar_view_model.dart';
import '../../model/calender_model.dart';

class ImageShowPage extends StatelessWidget {
  final DateTime date;
  final String pageTitle;

  const ImageShowPage({
    required this.date,
    required this.pageTitle,
  });

  @override
  Widget build(BuildContext context) {
    final calendarViewModel = Provider.of<CalendarViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
      ),
      // StreamBuilder를 사용하여 선택된 날짜의 사진들을 실시간으로 가져옴
      body: StreamBuilder<List<CalenderModel>>(
        stream: calendarViewModel.getPhotosForDate(date),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final photos = snapshot.data ?? [];

          if (photos.isEmpty) {
            return Center(child: Text('이 날짜에 저장된 사진이 없습니다.'));
          }

          // GridView를 사용하여 사진들을 그리드 형태로 표시
          return GridView.builder(
            padding: EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 한 줄에 2개의 사진
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  photo.imageUrl,
                  fit: BoxFit.cover,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
