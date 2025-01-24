// 필요한 패키지들을 import
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../model/calender_model.dart';
import 'package:home_widget/home_widget.dart';

// 캘린더 관련 데이터를 관리하는 ViewModel 클래스
// ChangeNotifier를 상속받아 상태 변경을 알림
// 캘린더 관련한 비즈니스 로직을 처리하는 클래스이다.
// 여기서 비즈니스 로직(데이터 처리)는 사진 업로드, 사진 가져오기, 캐시 정리 등이 있고, 비즈니스 로직을 처리하고 view 파일들에게 해당 데이터를 보내준다.
class CalendarViewModel extends ChangeNotifier {
  // Firestore 인스턴스 초기화
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Firebase Storage 인스턴스 초기화
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 날짜를 기반으로 Firestore 컬렉션 이름을 생성하는 메서드
  // 이 함수는 단순히 컬렉션의 이름을 툭별하게 지정하기 위한 함수이다.
  // 형식: 'YYYY_MM_DD_photos'
  String _getCollectionName(DateTime date) {
    return '${date.year}_${date.month.toString().padLeft(2, '0')}_${date.day.toString().padLeft(2, '0')}_photos';
  }

  // 사진을 Firebase Storage에 업로드하고 Firestore에 메타데이터를 저장하는 메서드
  Future<void> uploadPhoto(String filePath, DateTime date) async {
    try {
      // 고유한 파일명 생성 (현재 시간의 밀리초)
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      // Storage의 참조 생성
      final ref = _storage.ref().child('photos/$fileName');
      // 파일 업로드
      await ref.putFile(File(filePath));
      // 업로드된 파일의 URL 가져오기
      final imageUrl = await ref.getDownloadURL();

      // PhotoModel 객체 생성
      final photo = CalenderModel(id: fileName, imageUrl: imageUrl, date: date);

      // Firestore에 사진 정보 저장
      await _firestore
          .collection(_getCollectionName(date))
          .doc(fileName)
          .set(photo.toMap());

      // iOS 위젯 업데이트
      // 새로운 사진이 업로드될 때마다 위젯의 이미지도 업데이트
      await HomeWidget.saveWidgetData<String>('imageUrl', imageUrl);
      await HomeWidget.updateWidget(
        iOSName: 'planner_widget',
      );

      // UI 업데이트를 위해 리스너들에게 변경 알림
      notifyListeners();
    } catch (e) {
      print('사진 업로드 중 오류 발생: $e');
    }
  }

  // 특정 날짜의 사진들을 실시간으로 가져오는 Stream
  Stream<List<CalenderModel>> getPhotosForDate(DateTime date) {
    return _firestore
        .collection(_getCollectionName(date))
        .snapshots()
        .map((snapshot) {
      // Firestore 문서들을 PhotoModel 객체로 변환
      return snapshot.docs
          .map((doc) => CalenderModel.fromDocument(doc))
          .toList();
    });
  }

  // 캐시된 이미지들을 정리하는 메서드
  // 앱의 성능 향상과 저장공간 확보를 위해 사용
  Future<void> clearOldCache() async {
    await DefaultCacheManager().emptyCache();
  }

  // 모든 날짜의 사진들을 실시간으로 가져오는 Stream
  // collectionGroup을 사용하여 모든 'photos' 컬렉션의 데이터를 한번에 조회
  Stream<List<CalenderModel>> getAllPhotosStream() {
    return FirebaseFirestore.instance
        .collectionGroup('photos')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CalenderModel.fromDocument(doc))
          .toList();
    });
  }
}
