import 'dart:async';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// 오디오 녹음/업로드 로직을 담당하는 ViewModel
class AudioViewModel extends ChangeNotifier {
  FlutterSoundRecorder? _recorder; // 녹음기 인스턴스
  bool _isRecording = false; // 녹음 중인지 여부
  String? _audioFilePath; // 녹음된 파일 경로

  // 녹음 시간 추적
  final Duration _recordingDuration = Duration.zero;
  Duration get recordingDuration => _recordingDuration;

  // 녹음 시간 갱신용 타이머
  //Timer? _timer;

  // 녹음 시간 문자열 포맷 (예: 00:05, 01:23)
  String get formattedRecordingDuration {
    final minutes =
        _recordingDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        _recordingDuration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // 생성자
  AudioViewModel() {
    _recorder = FlutterSoundRecorder();
    _openRecorder();
  }

  /// 마이크 권한 요청 및 레코더 세션 열기
  Future<void> _openRecorder() async {
    await Permission.microphone.request(); // 마이크 권한 요청
    await _recorder?.openRecorder(); // 오디오 세션 열기
  }

  /// 녹음 시작
  Future<void> startRecording() async {
    final String path =
        '${(await getTemporaryDirectory()).path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder?.startRecorder(toFile: path);
    _isRecording = true;
    notifyListeners(); // 녹음 상태 변경 알림
  }

  /// 녹음 중지
  Future<void> stopRecording() async {
    final String? path = await _recorder?.stopRecorder();
    _isRecording = false;
    if (path != null) {
      _audioFilePath = path;
    }
    notifyListeners(); // 녹음 상태 변경 알림
  }

  /// 녹음 파일을 MP3로 변환
  Future<String> _convertToMp3(String inputFilePath) async {
    final outputFilePath =
        '${(await getTemporaryDirectory()).path}/audio_${DateTime.now().millisecondsSinceEpoch}.mp3';
    final command =
        '-i $inputFilePath -codec:a libmp3lame -qscale:a 2 $outputFilePath';
    await FFmpegKit.execute(command);
    return outputFilePath;
  }

  /// 녹음 파일을 Firebase Storage에 업로드 후 다운로드 URL 반환
  Future<String> uploadAudioToFirestorage(
    String categoryId,
    String nickName,
  ) async {
    if (_audioFilePath == null) {
      throw Exception('No audio file to upload');
    }

    // AAC 파일을 MP3로 변환
    final mp3FilePath = await _convertToMp3(_audioFilePath!);

    // Firebase Storage에 업로드
    final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.mp3';
    final ref =
        FirebaseStorage.instance.ref().child('categories_audio/$fileName');
    final file = File(mp3FilePath);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  /// Getter: 녹음 중인지 여부
  bool get isRecording => _isRecording;

  /// Getter: 오디오 파일 경로
  String? get audioFilePath => _audioFilePath;

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _recorder = null;
    super.dispose();
  }
}
