import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> _searchResults = [];
  List<String> _searchProfileImage = [];

  String verificationId = '';
  String smsCode = '';
  bool codeSent = false;

  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // 검색 결과 리스트 가져오기
  List<String> get searchResults => _searchResults;

  // 프로필 이미지 가지고 오기
  List<String> get searchProfileImage => _searchProfileImage;

  // 현재 로그인한 사용자 가져오기
  User? get getCurrentUserId => _auth.currentUser;

  // 현재 사용자 ID 가져오기
  String? get getUserId => _auth.currentUser?.uid;

  // 사용자 로그인 상태 스트림
  //Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 로그인 여부 확인
  //bool get isLoggedIn => _auth.currentUser != null;

  void clearSearchResults() {
    searchResults.clear();
    notifyListeners();
  }

  // 회원가입 시 사용자 정보를 Firestore에 저장
  Future<void> createUserInFirestore(
    User user,
    String token,
    String nickName,
    String name,
    String phone,
    String birthDate,
  ) async {
    try {
      // users 컬렉션에 문서 생성
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid, // Firebase Auth의 고유 ID
        'createdAt': Timestamp.now(), // 생성 시간
        'lastLogin': Timestamp.now(), // 마지막 로그인 시간
        'fcmToken': token, // FCM 토큰
        'nick_name': nickName,
        'name': name,
        'phone': phone,
        'birth_date': birthDate,
        'profile_image': '', // 프로필 이미지 URL
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error creating user document: $e');
      rethrow;
    }
  }

  // FCM 토큰 저장 메서드
  Future<void> saveFCMToken(String token) async {
    try {
      if (getUserId != null) {
        await _firestore.collection('users').doc(getUserId).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error saving FCM token: $e');
      rethrow;
    }
  }

  // firestore에 nick_name 필드의 값 가지고 오는 함수
  Future<String> getNickNameFromFirestore() async {
    try {
      // users 컬렉션에서 문서 가져오기
      DocumentSnapshot documentSnapshot = await _firestore
          .collection('users')
          .doc(_auth.currentUser?.uid)
          .get();
      if (documentSnapshot.exists) {
        // 닉네임 필드 가져오기
        String? fetchedNickName = documentSnapshot.get('nick_name');
        print('Fetched Nickname: $fetchedNickName');
        return fetchedNickName ?? 'Default Nickname';
      } else {
        print('User document does not exist');
        return 'Default Nickname'; // 기본 닉네임 반환
      }
    } catch (e) {
      print('Error fetching user document: $e');
      rethrow;
    }
  }

  // 사용자 검색 메서드
  Future<void> searchNickName(String userNickName) async {
    if (userNickName.isEmpty) return;

    try {
      // users 컬렉션의 모든 문서 가져오기
      final QuerySnapshot result = await _firestore.collection('users').get();

      // uid가 일치하거나 3글자 이상 비슷한 문서 필터링
      _searchResults = result.docs
          .where((doc) {
            String nickName = doc['nick_name'] as String;

            // 정확히 일치하는 경우
            if (nickName == userNickName) return true;

            // 3글자 이상 비슷한지 확인
            int matchCount = 0;
            int minLength = nickName.length < userNickName.length
                ? nickName.length
                : userNickName.length;

            for (int i = 0; i < minLength; i++) {
              if (nickName[i] == userNickName[i]) matchCount++;
            }

            return matchCount >= 3;
          })
          .map((doc) => doc['nick_name'] as String)
          .toList();

      _searchProfileImage = result.docs
          .where((doc) {
            String nickName = doc['nick_name'] as String;

            // 정확히 일치하는 경우
            if (nickName == userNickName) return true;

            // 3글자 이상 비슷한지 확인
            int matchCount = 0;
            int minLength = nickName.length < userNickName.length
                ? nickName.length
                : userNickName.length;

            for (int i = 0; i < minLength; i++) {
              if (nickName[i] == userNickName[i]) matchCount++;
            }

            return matchCount >= 3;
          })
          .map((doc) => doc['profile_image'] as String)
          .toList();

      notifyListeners();
    } catch (e) {
      print('Error searching users: $e');
      rethrow;
    }
  }

  // 전화번호 인증 요청
  Future<void> verifyPhoneNumber(
    String phoneNumber,
    Function(String verificationId, int? resendToken) codeSent,
    Function(String verificationId) codeAutoRetrievalTimeout,
  ) async {
    try {
      print('Phone number: $phoneNumber');
      await _auth.verifyPhoneNumber(
        phoneNumber: "+82$phoneNumber",
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          this.verificationId = verificationId;
          codeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          this.verificationId = verificationId;
          codeAutoRetrievalTimeout(verificationId);
        },
        timeout: const Duration(seconds: 10),
      );
    } catch (e) {
      print(e.toString());
      print('Error verifying phone number: $e');
    }
  }

  // SMS 코드로 로그인
  Future<void> signInWithSmsCode(String smsCode, Function onSuccess) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);
      onSuccess();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error signing in with SMS code: $e');
    }
  }
}
