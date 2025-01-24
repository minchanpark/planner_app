import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../view_model/calendar_view_model.dart';
import '../../model/calender_model.dart';
import '../about_camera/camera_screen.dart';
import 'image_show_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // 선택된 날짜를 저장할 변수
  DateTime? _selectedDay;
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final calendarViewModel = Provider.of<CalendarViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_a_photo),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => CameraScreen(
                          pageName: "caleder",
                        )),
              );
            },
          ),
        ],
      ),
      // StreamBuilder를 사용하여 선택된 날짜의 사진들을 실시간으로 가져옴
      body: StreamBuilder<List<CalenderModel>>(
        // 선택된 날짜가 없으면 현재 날짜의 사진을 가져옴
        stream:
            calendarViewModel.getPhotosForDate(_selectedDay ?? DateTime.now()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // 에러 처리
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // 사진이 없는 경우 처리
          final photos = snapshot.data ?? [];

          return TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,

            // 선택된 날짜 표시
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },

            // 날짜 선택 시 호출되는 콜백
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },

            calendarFormat: CalendarFormat.month,
            // 날짜별 마커 표시를 위한 이벤트 로더
            eventLoader: (day) {
              return photos
                  .where((photo) => isSameDay(photo.date, day))
                  .toList();
            },

            // 달력 각 날짜에 표시할 마커 빌더
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  final recentPhoto = events.last as CalenderModel;
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImageShowPage(
                              date: date, // 선택된 날짜 전달
                              pageTitle:
                                  '${date.year}년 ${date.month}월 ${date.day}일의 사진들',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: recentPhoto.imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          );
        },
      ),
    );
  }
}
