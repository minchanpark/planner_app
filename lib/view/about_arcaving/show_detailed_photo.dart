//// filepath: /Users/mac/Documents/planner_app/lib/view/about_arcaving/show_detailed_photo.dart
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../model/photo_model.dart';
import '../../view_model/category_view_model.dart';

class ShowDetailedPhoto extends StatefulWidget {
  final List<PhotoModel> photos;
  final int initialIndex;
  final String categoryName;
  final String categoryId;

  const ShowDetailedPhoto({
    super.key,
    required this.photos,
    this.initialIndex = 0,
    required this.categoryName,
    required this.categoryId,
  });

  @override
  State<ShowDetailedPhoto> createState() => _ShowDetailedPhotoState();
}

class _ShowDetailedPhotoState extends State<ShowDetailedPhoto> {
  @override
  Widget build(BuildContext context) {
    CategoryViewModel categoryViewModel =
        Provider.of<CategoryViewModel>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
        title: Text(
          widget.categoryName,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              '수정하기',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: PageView.builder(
        controller: PageController(initialPage: widget.initialIndex),
        itemCount: widget.photos.length,
        itemBuilder: (context, index) {
          final photo = widget.photos[index];
          return Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Image.network(
                    photo.imageUrl,
                    width: 343,
                    height: 571,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 12,
                    child: Container(
                      color: Color.fromRGBO(0, 0, 0, 0.3),
                      child: Text(
                        DateFormat('yyyy.MM.dd')
                            .format(photo.createdAt.toDate()),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 500,
                    left: 270,
                    child: IconButton(
                      onPressed: () async {
                        String? photoId =
                            await categoryViewModel.getPhotoDocumentId(
                          widget.categoryId,
                          photo.imageUrl,
                        );
                        String? audioUrl = await categoryViewModel
                            .getPhotoAudioUrl(widget.categoryId, photoId!);
                        if (audioUrl != null) {
                          final player = AudioPlayer();
                          await player.play(UrlSource(audioUrl));
                        }
                      },
                      icon: Image.asset(
                        'assets/voice.png',
                        width: 52,
                        height: 52,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
