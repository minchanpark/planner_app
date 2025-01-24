import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:planner/model/photo_model.dart';
import 'package:provider/provider.dart';

import '../service/gpt_vision_service.dart';
import 'auth_view_model.dart';

class CategoryViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 특정 사진의 오디오 URL을 가져오는 함수
  Future<String?> getPhotoAudioUrl(String categoryId, String photoId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('categories')
          .doc(categoryId)
          .collection('photos')
          .doc(photoId)
          .get();
      return doc['audioUrl'] as String?;
    } catch (e) {
      debugPrint('오디오 URL 가져오기 오류: $e');
      return null;
    }
  }

  /// 모든 카테고리의 사진 통계를 가져오는 함수
  Future<Map<String, int>> fetchCategoryStatistics() async {
    final categoriesSnapshot = await _firestore.collection('categories').get();
    return _getCategoryStats(categoriesSnapshot);
  }

  /// 저장된 사진이 가장 적은 카테고리를 가져오는 함수
  Future<String?> getLeastSavedCategory() async {
    final categoriesSnapshot = await _firestore.collection('categories').get();
    final categoryStats = await _getCategoryStats(categoriesSnapshot);

    if (categoryStats.isEmpty) return null;

    final leastSavedCategoryId =
        categoryStats.entries.reduce((a, b) => a.value < b.value ? a : b).key;

    final categoryDoc = await _firestore
        .collection('categories')
        .doc(leastSavedCategoryId)
        .get();

    return categoryDoc.exists ? categoryDoc.data()!['name'] as String? : null;
  }

  /// 각 카테고리의 사진 개수를 계산하는 헬퍼 함수
  Future<Map<String, int>> _getCategoryStats(
      QuerySnapshot categoriesSnapshot) async {
    final Map<String, int> categoryStats = {};
    for (var category in categoriesSnapshot.docs) {
      final categoryId = category.id;
      final photosSnapshot = await _firestore
          .collection('categories')
          .doc(categoryId)
          .collection('photos')
          .get();
      categoryStats[categoryId] = photosSnapshot.size;
    }
    return categoryStats;
  }

  /// 특정 카테고리의 이름을 가져오는 함수
  Future<String> getCategoryName(String categoryId) async {
    try {
      final doc =
          await _firestore.collection('categories').doc(categoryId).get();
      if (!doc.exists) {
        throw Exception('해당 카테고리가 존재하지 않습니다.');
      }
      return doc['name'] as String;
    } catch (e) {
      debugPrint('카테고리 이름 가져오기 오류: $e');
      rethrow;
    }
  }

  /// 특정 유저가 속한 카테고리를 가져오는 함수
  Future<List<Map<String, dynamic>>> fetchUserCategories(
      String nickName) async {
    try {
      final querySnapshot = await _firestore
          .collection('categories')
          .where('mates', arrayContains: nickName)
          .get();

      return querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['name'],
        };
      }).toList();
    } catch (e) {
      debugPrint('유저 카테고리 가져오기 오류: $e');
      rethrow;
    }
  }

  /// 새 카테고리를 생성하는 함수
  Future<void> createCategory(
    String name,
    String nickName,
    String userId,
  ) async {
    try {
      await _firestore.collection('categories').add({
        'name': name,
        'mates': [nickName],
        'userId': [userId],
      });
      notifyListeners();
    } catch (e) {
      debugPrint('카테고리 생성 오류: $e');
      rethrow;
    }
  }

  /// 카테고리에 유저 닉네임 추가
  Future<void> addUserToCategory(String categoryId, String nickName) async {
    await _updateCategoryField(categoryId, 'mates', nickName);
  }

  /// 카테고리에 유저 ID 추가
  Future<void> addUidToCategory(String categoryId, String uid) async {
    await _updateCategoryField(categoryId, 'userId', uid);
  }

  /// 카테고리의 특정 필드 값을 업데이트하는 헬퍼 함수
  Future<void> _updateCategoryField(
    String categoryId,
    String field,
    String value,
  ) async {
    try {
      final categoryRef = _firestore.collection('categories').doc(categoryId);
      await categoryRef.update({
        field: FieldValue.arrayUnion([value]),
      });
      notifyListeners();
    } catch (e) {
      debugPrint('카테고리 필드 업데이트 오류: $e');
      rethrow;
    }
  }

  /// 특정 카테고리에 사진을 업로드하는 함수
  Future<String> uploadPhoto(
    String categoryId,
    String nickName,
    String filePath,
    String audioUrl,
    BuildContext context,
  ) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final file = File(filePath);

    if (!file.existsSync()) {
      debugPrint('File does not exist: $filePath');
      return '';
    }

    try {
      // 1) Firebase Storage 업로드
      final ref = _storage.ref().child('categories_photos/$fileName');
      await ref.putFile(file);
      final imageUrl = await ref.getDownloadURL();

      // 2) 카테고리 문서 가져오기 (유저 IDs)
      final categoryDoc =
          await _firestore.collection('categories').doc(categoryId).get();
      final List<String> userIds =
          List<String>.from(categoryDoc['userId'] ?? []);

      // 3) 현재 사용자 ID 가져오기
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      // 4) PhotoModel 생성
      final photo = PhotoModel(
        imageUrl: imageUrl,
        createdAt: Timestamp.now(),
        userNickname: nickName,
        userIds: userIds,
        userId: authViewModel.getUserId!,
        audioUrl: audioUrl,
      );

      // 5) Firestore에 사진 정보 저장
      final categoryRef = _firestore.collection('categories').doc(categoryId);
      await categoryRef.collection('photos').doc(fileName).set(photo.toMap());

      notifyListeners();
      return fileName;
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      rethrow;
    }
  }

  /// Firebase Storage에 이미지를 업로드하고 URL 반환
  Future<String> uploadImageToFirebase(String filePath) async {
    final file = File(filePath);
    final storageRef =
        _storage.ref().child('images/${DateTime.now().toIso8601String()}');
    final uploadTask = storageRef.putFile(file);
    await uploadTask;
    return storageRef.getDownloadURL();
  }

  /// 특정 카테고리의 사진 스트림을 반환하는 함수
  Stream<List<PhotoModel>> getPhotosStream(String categoryId) {
    return _firestore
        .collection('categories')
        .doc(categoryId)
        .collection('photos')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PhotoModel.fromDocument(doc)).toList());
  }

  /// 사진 개수를 확인하고, 6개 이상이면 비디오 생성 후 업로드
  Future<String> checkPhotoCountAndPerformAction(String categoryId) async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .doc(categoryId)
          .collection('photos')
          .get();

      if (snapshot.docs.length >= 6) {
        debugPrint('[INFO] 사진이 6개 이상입니다. 비디오를 생성합니다.');

        final photoModels =
            snapshot.docs.map((doc) => PhotoModel.fromDocument(doc)).toList();

        final imageUrls = photoModels.map((photo) => photo.imageUrl).toList();
        debugPrint('[INFO] 이미지 URL 목록: $imageUrls');

        final tempDir = await getTemporaryDirectory();

        // 1) 사진들을 다운로드 (File)
        final imageFiles = await _downloadImages(imageUrls, tempDir);

        // 2) 리사이즈
        final resizedImageFiles = await _resizeImages(imageFiles, tempDir);

        // 3) 비디오 생성
        final videoFile =
            await _createVideoFromImages(resizedImageFiles, tempDir);

        // 4) 비디오 업로드 후 URL 반환
        final videoUrl = await _uploadVideo(videoFile);
        debugPrint('[INFO] 비디오 생성 및 업로드 완료: $videoUrl');
        return videoUrl;
      }
    } catch (e) {
      debugPrint('Error checking photo count: $e');
    }
    return 'invalid url';
  }

  /// 이미지 URL 리스트를 받아서 파일로 다운로드
  Future<List<File>> _downloadImages(
    List<String> imageUrls,
    Directory tempDir,
  ) async {
    final futures = imageUrls.map((url) => _downloadImage(url, tempDir));
    return Future.wait(futures);
  }

  /// 단일 이미지 URL을 받아서 파일로 다운로드
  Future<File> _downloadImage(String url, Directory tempDir) async {
    final response = await HttpClient().getUrl(Uri.parse(url));
    final bytes =
        await consolidateHttpClientResponseBytes(await response.close());

    final fileName = url.split('/').last;
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// 이미지 파일들을 리사이즈
  Future<List<File>> _resizeImages(
      List<File> imageFiles, Directory tempDir) async {
    return Future.wait(imageFiles.map((file) => _resizeImage(file, tempDir)));
  }

  /// 단일 이미지 파일 리사이즈
  Future<File> _resizeImage(File imageFile, Directory tempDir) async {
    final bytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(bytes);
    if (originalImage == null) return imageFile;

    final resizedImage =
        img.copyResize(originalImage, width: 1280, height: 720);
    final resizedBytes = img.encodeJpg(resizedImage);

    final resizedFilePath =
        '${tempDir.path}/${imageFile.uri.pathSegments.last}';
    final resizedFile = File(resizedFilePath);
    await resizedFile.writeAsBytes(resizedBytes);

    return resizedFile;
  }

  /// 이미지 파일 리스트로 비디오 파일 생성
  Future<File> _createVideoFromImages(
    List<File> imageFiles,
    Directory tempDir,
  ) async {
    final videoFilePath = '${tempDir.path}/output_video.mp4';
    final textFilePath = '${tempDir.path}/input.txt';
    final textFile = File(textFilePath);

    final lines = <String>[];

    // FFMPEG concat 형식에 맞게 작성
    for (int i = 0; i < imageFiles.length; i++) {
      final path = imageFiles[i].path;
      lines.add("file '$path'");
      lines.add("duration 2");
    }
    // 마지막 이미지를 2초 더 보여주기
    lines.add("file '${imageFiles.last.path}'");

    await textFile.writeAsString(lines.join('\n'));

    final ffmpegCommand = '-y -f concat -safe 0 -i $textFilePath '
        '-vsync vfr -preset ultrafast -crf 28 -pix_fmt yuv420p $videoFilePath';

    await FFmpegKit.execute(ffmpegCommand);
    return File(videoFilePath);
  }

  /// 비디오 파일을 Firebase Storage에 업로드하고 URL을 반환
  Future<String> _uploadVideo(File videoFile) async {
    final ref = _storage
        .ref()
        .child('categories_videos/${videoFile.path.split('/').last}');
    await ref.putFile(videoFile);
    return ref.getDownloadURL();
  }

  /// GPT Vision API로부터 다음 카테고리에 대한 제안
  Future<void> suggestNextCategory(String categoryId) async {
    try {
      // 1) 카테고리 이름 가져오기
      final categoryName = await getCategoryName(categoryId);
      debugPrint('[INFO] 카테고리 이름: $categoryName');

      // 2) Firestore에서 사진 데이터 가져오기
      final snapshot = await _firestore
          .collection('categories')
          .doc(categoryId)
          .collection('photos')
          .get();

      final photos =
          snapshot.docs.map((doc) => PhotoModel.fromDocument(doc)).toList();

      debugPrint('[INFO] 가져온 사진 개수: ${photos.length}');
      if (photos.length < 4) {
        debugPrint('[INFO] 사진이 아직 4장 미만입니다.');
        return;
      }

      // 3) 4장의 이미지를 base64로 변환 (임시)
      final List<String> base64Images = [];
      for (int i = 0; i < 4; i++) {
        final base64Data = await _convertImageToBase64(photos[i].imageUrl);
        base64Images.add(base64Data);
      }
      debugPrint('[INFO] Base64 변환 완료 (개수: ${base64Images.length})');

      // 4) GPT Vision API 호출
      final gptVisionService = GPTVisionService();
      final recommendation = await gptVisionService.getRecommendationFromImages(
        categoryName,
        base64Images,
      );
      debugPrint('[INFO] GPT로부터 받은 제안: $recommendation');
    } catch (e) {
      debugPrint('Error suggesting next category: $e');
    }
  }

  /// 이미지 URL → base64 변환
  Future<String> _convertImageToBase64(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      return base64Encode(response.bodyBytes);
    } else {
      throw Exception('Failed to download image: $imageUrl');
    }
  }
}
