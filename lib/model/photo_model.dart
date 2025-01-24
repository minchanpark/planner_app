import 'package:cloud_firestore/cloud_firestore.dart';

class PhotoModel {
  final String imageUrl;
  final Timestamp createdAt;
  final String userNickname;
  final List<String> userIds;
  final String userId;
  final String audioUrl; // 음성 녹음 URL 필드 추가

  PhotoModel({
    required this.imageUrl,
    required this.createdAt,
    required this.userNickname,
    required this.userIds,
    required this.userId,
    required this.audioUrl, // 선택적 필드로 추가
  });

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'userNickname': userNickname,
      'userIds': userIds,
      'userId': userId,
      'audioUrl': audioUrl, // 맵에 추가
    };
  }

  factory PhotoModel.fromDocument(DocumentSnapshot doc) {
    return PhotoModel(
      imageUrl: doc['imageUrl'],
      createdAt: doc['createdAt'],
      userNickname: doc['userNickname'],
      userIds: List<String>.from(doc['userIds']),
      userId: doc['userId'],
      audioUrl: doc['audioUrl'], // 문서에서 필드 가져오기
    );
  }
}
