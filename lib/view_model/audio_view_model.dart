import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AudioViewModel extends ChangeNotifier {
  FlutterSoundRecorder? _recorder; // FlutterSoundRecorder 인스턴스
  bool _isRecording = false; // 녹음 상태를 나타내는 변수
  String? _audioFilePath; // 임시로 저장된 녹음 파일 경로

  // 생성자: FlutterSoundRecorder 인스턴스를 초기화하고 오디오 세션을 엽니다.
  AudioViewModel() {
    _recorder = FlutterSoundRecorder();
    _openRecorder();
  }

  // 오디오 세션을 열고 마이크 권한을 요청하는 비동기 메서드
  Future<void> _openRecorder() async {
    await Permission.microphone.request(); // 마이크 권한 요청
    await _recorder!.openRecorder(); // 오디오 세션 열기
  }

  // 녹음을 시작하는 비동기 메서드
  Future<void> startRecording() async {
    final String path =
        'audio_${DateTime.now().millisecondsSinceEpoch}.aac'; // 파일 경로 설정
    await _recorder!.startRecorder(toFile: path); // 녹음 시작
    _isRecording = true; // 녹음 상태 업데이트
    notifyListeners(); // 상태 변경 알림
  }

  // 녹음을 중지하고 파일 경로를 임시로 저장하는 비동기 메서드
  Future<void> stopRecording() async {
    final String? path = await _recorder!.stopRecorder(); // 녹음 중지 및 파일 경로 가져오기
    _isRecording = false; // 녹음 상태 업데이트
    if (path != null) {
      _audioFilePath = path; // 파일 경로를 임시로 저장
    }
    notifyListeners(); // 상태 변경 알림
  }

  // Firebase Storage에 오디오 파일을 업로드하고 URL을 반환하는 함수
  Future<String> uploadAudioToFirestore(
      String categoryId, String nickName) async {
    if (_audioFilePath == null) {
      throw Exception('No audio file to upload');
    }

    final fileName = nickName + DateTime.now().second.toString();
    final file = File(_audioFilePath!);

    // 파일이 존재하는지 확인합니다.
    if (!file.existsSync()) {
      print('File does not exist: $_audioFilePath');
      return '파일이 없습니다.';
    }

    // Firebase Storage에 파일을 업로드합니다.
    final ref =
        FirebaseStorage.instance.ref().child('categories_audio/$fileName');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // 녹음 상태를 반환하는 getter
  bool get isRecording => _isRecording;

  // 임시로 저장된 녹음 파일 경로를 반환하는 getter
  String? get audioFilePath => _audioFilePath;

  // 오디오 세션을 닫고 리소스를 해제하는 메서드
  @override
  void dispose() {
    _recorder!.closeRecorder(); // 오디오 세션 닫기
    _recorder = null; // FlutterSoundRecorder 인스턴스 해제
    super.dispose();
  }
}
