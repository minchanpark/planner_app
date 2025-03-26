import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:planner/model/photo_model.dart';
import 'package:planner/view_model/audio_view_model.dart';
import '../service/gpt_vision_service.dart';
import 'auth_view_model.dart';

class CategoryViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final List<String> _selectedNames = [];

  List<String> get selectedNames => _selectedNames;

  String audioUrl = '';

  /// 모든 카테고리 데이터를 가져오면서
  /// 각 카테고리의 첫번째 사진 URL과 프로필 이미지들을 함께 합친 스트림
  Stream<List<Map<String, dynamic>>> streamUserCategoriesWithDetails(
    String nickName,
    AuthViewModel authViewModel,
  ) {
    return _firestore
        .collection('categories')
        .where('mates', arrayContains: nickName)
        .snapshots()
        .asyncMap((querySnapshot) async {
      final results = <Map<String, dynamic>>[];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final categoryId = doc.id;
        final mates = (data['mates'] as List).cast<String>();

        // 첫번째 사진 URL을 한 번만 Future로 가져오기
        final photosSnapshot = await _firestore
            .collection('categories')
            .doc(categoryId)
            .collection('photos')
            .orderBy('createdAt', descending: false)
            .limit(1)
            .get();

        String? firstPhotoUrl;
        if (photosSnapshot.docs.isNotEmpty) {
          firstPhotoUrl =
              photosSnapshot.docs.first.data()['imageUrl'] as String?;
        }

        // mates에 해당하는 프로필 이미지 목록 가져오기 (한 번만 Future로 처리)
        final profileImages = await (() async {
          if (mates.isEmpty) return [];
          final completer = Completer<List<String>>();
          final subscription = authViewModel.getprofileImages(mates).listen(
            (urls) {
              completer.complete(urls.cast<String>());
            },
            onError: (e) {
              completer.completeError(e);
            },
          );
          return completer.future.whenComplete(() => subscription.cancel());
        })();

        results.add({
          'id': categoryId,
          'name': data['name'],
          'mates': mates,
          'firstPhotoUrl': firstPhotoUrl,
          'profileImages': profileImages,
        });
      }
      return results;
    });
  }

  //// filepath: /Users/mac/Documents/planner_app/lib/view_model/category_view_model.dart
  /// 특정 카테고리 내의 photos 서브컬렉션에서
  /// 가장 이전(오래된) 사진의 URL을 가져오는 함수.
  /// createdAt 필드를 기준으로 오름차순 정렬하여 첫 번째 사진의 imageUrl을 반환합니다.
  Stream<String?> getFirstPhotoUrlStream(String categoryId) {
    return _firestore
        .collection('categories')
        .doc(categoryId)
        .collection('photos')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data()['imageUrl'] as String?;
      }
      return null;
    });
  }

  void toggleName(String name) {
    if (_selectedNames.contains(name)) {
      _selectedNames.remove(name);
    } else {
      _selectedNames.add(name);
    }
    notifyListeners();
  }

  void clearSelectedNames() {
    _selectedNames.clear();
    notifyListeners();
  }

  Future<void> saveEditedPhoto(
    Future<ui.Image> capturedImageFuture,
    String categoryId,
    String nickName,
    String? audioFilePath,
    AudioViewModel audioViewModel,
    String captionString,
  ) async {
    try {
      // 캡처된 이미지 Future 완료
      final capturedImage = await capturedImageFuture;
      final byteData =
          await capturedImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      // 임시 디렉토리에 파일 저장
      final appDir = await getApplicationDocumentsDirectory();
      final filePath =
          '${appDir.path}/${DateTime.now().millisecondsSinceEpoch}_edited.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      // 음성 파일 처리 (있다면)

      if (audioFilePath != null) {
        // 예시: AudioViewModel에 있는 업로드 함수를 사용하거나 여기서 직접 업로드
        audioUrl =
            await audioViewModel.uploadAudioToFirestorage(categoryId, nickName);
      }

      // 사진 업로드 (context 의존성이 제거된 uploadPhoto로 처리)
      await uploadPhoto(
        categoryId,
        nickName,
        filePath,
        audioUrl,
        captionString,
      );
    } catch (e) {
      debugPrint('Error saving edited photo: $e');
    }
  }

  /// uploadPhoto의 context 매개변수를 제거하여 UI와 분리한 버전
  Future<void> uploadPhoto(
    String categoryId,
    String nickName,
    String filePath,
    String audioUrl,
    String captionString,
  ) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final file = File(filePath);

    if (!file.existsSync()) {
      debugPrint('File does not exist: $filePath');
      return;
    }

    try {
      // 1) Firebase Storage 업로드
      final ref = _storage.ref().child('categories_photos/$fileName');
      await ref.putFile(file);
      final imageUrl = await ref.getDownloadURL();

      // 2) 카테고리의 'userId' 목록 가져오기
      final categoryDoc =
          await _firestore.collection('categories').doc(categoryId).get();
      final List<String> userIds =
          List<String>.from(categoryDoc['userId'] ?? []);

      // 3) 기존에 받아온 닉네임과 추가 데이터로 PhotoModel 생성
      final categoryRef = _firestore.collection('categories').doc(categoryId);
      final photoRef = categoryRef.collection('photos').doc();
      final photoId = photoRef.id;

      final photo = PhotoModel(
        imageUrl: imageUrl,
        createdAt: Timestamp.now(),
        userNickname: nickName,
        userIds: userIds,
        userId: '', // 필요 시 현재 사용자 ID 또는 관련 값을 할당
        audioUrl: audioUrl,
        id: photoId,
        //captionString: captionString,
      );

      // 4) Firestore에 사진 정보 저장
      await photoRef.set(photo.toMap());
      notifyListeners();
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      rethrow;
    }
  }

  /// 특정 사진의 오디오 URL 가져오기
  Future<String?> getPhotoAudioUrl(String categoryId, String photoId) async {
    try {
      final doc = await _firestore
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

  /// 모든 카테고리의 사진 통계를 가져오기
  Future<Map<String, int>> fetchCategoryStatistics() async {
    final categoriesSnapshot = await _firestore.collection('categories').get();
    return _getCategoryStats(categoriesSnapshot);
  }

  /// 저장된 사진이 가장 적은 카테고리의 'name' 가져오기
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

  /// 각 카테고리의 사진 개수 계산 (헬퍼 함수)
  Future<Map<String, int>> _getCategoryStats(
      QuerySnapshot categoriesSnapshot) async {
    final Map<String, int> categoryStats = {};
    for (final category in categoriesSnapshot.docs) {
      final photosSnapshot = await _firestore
          .collection('categories')
          .doc(category.id)
          .collection('photos')
          .get();
      categoryStats[category.id] = photosSnapshot.size;
    }
    return categoryStats;
  }

  /// 특정 카테고리의 이름 가져오기
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

  /// 특정 유저 닉네임을 포함하는 카테고리 목록을 스트림으로 반환
  Stream<List<Map<String, dynamic>>> streamUserCategories(String nickName) {
    // Firestore의 snapshots()를 이용해 실시간 업데이트를 감지합니다.
    return _firestore
        .collection('categories')
        .where('mates', arrayContains: nickName)
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs
            .map((doc) =>
                {'id': doc.id, 'name': doc['name'], 'mates': doc['mates']})
            .toList());
  }

  /// 새 카테고리 생성
  Future<void> createCategory(
    String name,
    List mates,
    String userId,
  ) async {
    try {
      await _firestore.collection('categories').add({
        'name': name,
        'mates': mates,
        'userId': [userId],
      });
      notifyListeners();
    } catch (e) {
      debugPrint('카테고리 생성 오류: $e');
      rethrow;
    }
  }

  /// 카테고리에 사용자 닉네임 추가
  Future<void> addUserToCategory(String categoryId, String nickName) async {
    await _updateCategoryField(categoryId, 'mates', nickName);
  }

  /// 카테고리에 사용자 UID 추가
  Future<void> addUidToCategory(String categoryId, String uid) async {
    await _updateCategoryField(categoryId, 'userId', uid);
  }

  /// 카테고리의 특정 필드에 배열 형태로 값 업데이트 (헬퍼 함수)
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

  /// 특정 카테고리에 사진 업로드
  /*Future<void> uploadPhoto(
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
      return;
    }

    try {
      // 1) Firebase Storage 업로드
      final ref = _storage.ref().child('categories_photos/$fileName');
      await ref.putFile(file);
      final imageUrl = await ref.getDownloadURL();

      // 2) 해당 카테고리의 'userId' 목록 가져오기
      final categoryDoc =
          await _firestore.collection('categories').doc(categoryId).get();
      final List<String> userIds =
          List<String>.from(categoryDoc['userId'] ?? []);

      // 3) 현재 사용자 ID 가져오기
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      // 4) Firestore에 사진 문서 생성
      final categoryRef = _firestore.collection('categories').doc(categoryId);
      final photoRef = categoryRef.collection('photos').doc();
      final photoId = photoRef.id;

      // 5) PhotoModel 인스턴스 생성
      final photo = PhotoModel(
        imageUrl: imageUrl,
        createdAt: Timestamp.now(),
        userNickname: nickName,
        userIds: userIds,
        userId: authViewModel.getUserId!,
        audioUrl: audioUrl,
        id: photoId,
      );

      // 6) Firestore에 사진 정보 저장
      await photoRef.set(photo.toMap());
      notifyListeners();
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      rethrow;
    }
  }*/

  /// 특정 사진 문서의 ID 가져오기
  Future<String?> getPhotoDocumentId(String categoryId, String imageUrl) async {
    try {
      final querySnapshot = await _firestore
          .collection('categories')
          .doc(categoryId)
          .collection('photos')
          .where('imageUrl', isEqualTo: imageUrl)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting photo document ID: $e');
      return null;
    }
  }

  /// 로컬 이미지 파일을 Firebase Storage에 업로드하고 URL 반환
  Future<String> uploadImageToFirebase(String filePath) async {
    final file = File(filePath);
    final storageRef =
        _storage.ref().child('images/${DateTime.now().toIso8601String()}');
    await storageRef.putFile(file);
    return storageRef.getDownloadURL();
  }

  /// 특정 카테고리의 사진 목록(스트림) 가져오기
  Stream<List<PhotoModel>> getPhotosStream(String categoryId) {
    return _firestore
        .collection('categories')
        .doc(categoryId)
        .collection('photos')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(PhotoModel.fromDocument).toList());
  }

  /// 사진이 6개 이상이면 → 비디오 생성 후 업로드, 최종 URL 반환
  Future<String> checkPhotoCountAndPerformAction(String categoryId) async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .doc(categoryId)
          .collection('photos')
          .get();

      if (snapshot.docs.length >= 6) {
        debugPrint('[INFO] 사진이 6개 이상입니다. 비디오를 생성합니다.');

        final photoModels = snapshot.docs.map(PhotoModel.fromDocument).toList();
        final imageUrls = photoModels.map((photo) => photo.imageUrl).toList();
        debugPrint('[INFO] 이미지 URL 목록: $imageUrls');

        final tempDir = await getTemporaryDirectory();

        // 1) 사진 다운로드
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

  /// 이미지들을 순차적으로 다운로드
  Future<List<File>> _downloadImages(
      List<String> imageUrls, Directory tempDir) async {
    return Future.wait(imageUrls.map((url) => _downloadImage(url, tempDir)));
  }

  /// 단일 이미지 다운로드
  Future<File> _downloadImage(String url, Directory tempDir) async {
    final response = await HttpClient().getUrl(Uri.parse(url));
    final bytes =
        await consolidateHttpClientResponseBytes(await response.close());
    final fileName = url.split('/').last;
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// 이미지 파일들 리사이즈
  Future<List<File>> _resizeImages(
      List<File> imageFiles, Directory tempDir) async {
    return Future.wait(imageFiles.map((file) => _resizeImage(file, tempDir)));
  }

  /// 단일 이미지 리사이즈
  Future<File> _resizeImage(File imageFile, Directory tempDir) async {
    final bytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(bytes);
    if (originalImage == null) return imageFile;

    final resizedBytes = img.encodeJpg(
      img.copyResize(originalImage, width: 1280, height: 720),
    );
    final resizedFilePath =
        '${tempDir.path}/${imageFile.uri.pathSegments.last}';
    final resizedFile = File(resizedFilePath);
    await resizedFile.writeAsBytes(resizedBytes);

    return resizedFile;
  }

  /// 이미지 파일들을 이어붙여 비디오 생성
  Future<File> _createVideoFromImages(
      List<File> imageFiles, Directory tempDir) async {
    final videoFilePath = '${tempDir.path}/output_video.mp4';
    final textFilePath = '${tempDir.path}/input.txt';
    final textFile = File(textFilePath);

    final lines = <String>[];
    // FFMPEG concat용 텍스트 파일 작성
    for (int i = 0; i < imageFiles.length; i++) {
      lines.add("file '${imageFiles[i].path}'");
      lines.add("duration 2");
    }
    // 마지막 이미지를 2초 더 보여주기
    lines.add("file '${imageFiles.last.path}'");

    await textFile.writeAsString(lines.join('\n'));

    final ffmpegCommand = [
      '-y',
      '-f',
      'concat',
      '-safe',
      '0',
      '-i',
      textFilePath,
      '-vsync',
      'vfr',
      '-preset',
      'ultrafast',
      '-crf',
      '28',
      '-pix_fmt',
      'yuv420p',
      videoFilePath,
    ].join(' ');

    await FFmpegKit.execute(ffmpegCommand);
    return File(videoFilePath);
  }

  /// 비디오 파일을 Firebase Storage에 업로드 후 URL 반환
  Future<String> _uploadVideo(File videoFile) async {
    final ref = _storage
        .ref()
        .child('categories_videos/${videoFile.path.split('/').last}');
    await ref.putFile(videoFile);
    return ref.getDownloadURL();
  }

  /// GPT Vision API를 통해 다음 카테고리 추천
  Future<void> suggestNextCategory(String categoryId) async {
    try {
      // 1) 카테고리 이름 가져오기
      final categoryName = await getCategoryName(categoryId);
      debugPrint('[INFO] 카테고리 이름: $categoryName');

      // 2) 카테고리 사진 데이터 가져오기
      final snapshot = await _firestore
          .collection('categories')
          .doc(categoryId)
          .collection('photos')
          .get();
      final photos = snapshot.docs.map(PhotoModel.fromDocument).toList();
      debugPrint('[INFO] 가져온 사진 개수: ${photos.length}');

      // 사진 4장 미만이면 종료
      if (photos.length < 4) {
        debugPrint('[INFO] 사진이 아직 4장 미만입니다.');
        return;
      }

      // 3) 앞 4장의 이미지를 base64로 변환
      final base64Images = <String>[];
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

  /// 이미지 URL → base64 인코딩
  Future<String> _convertImageToBase64(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      return base64Encode(response.bodyBytes);
    } else {
      throw Exception('Failed to download image: $imageUrl');
    }
  }
}
