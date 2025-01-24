import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageUtil {
  static Future<String> uploadAudioToStorage(String path) async {
    final Reference storageRef = FirebaseStorage.instance.ref().child(
        'audio/${DateTime.now().millisecondsSinceEpoch}.aac'); // Firebase Storage 참조 설정
    await storageRef.putFile(File(path)); // 파일 업로드
    return await storageRef.getDownloadURL(); // 업로드된 파일의 URL 반환
  }
}
