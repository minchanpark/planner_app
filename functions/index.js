const functions = require("firebase-functions/v1");
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();

exports.sendNotificationOnCondition = functions.firestore
    .document("categories/{categoryId}/photos/{photoId}")
    .onCreate(async (snapshot, context) => {
        try {
            // 새로운 사진 데이터 가져오기
            const newPhotoData = snapshot.data();

            console.log("newPhotoData:", newPhotoData);

            const userDoc = await db.collection("users").doc(newPhotoData.userId).get();
            const userData = userDoc.data();

            const fcmToken = userData.fcmToken;

            console.log("FCM 토큰:", fcmToken);

            // 메시지 생성
            const message = {
                token: fcmToken,
                notification: {
                    title: `사진이 업로드 되었습니다!`,
                    body: "카테고리 사진이 추가되었습니다. 지금 확인하세요!"
                },
                data: {
                    imageUrl: newPhotoData.imageUrl,
                    userId: newPhotoData.userId
                }
            };

            console.log("생성된 메시지:", message);

            // 메시지 전송
            const response = await admin.messaging().send(message);
            console.log("알림 전송 성공:", response);
        } catch (error) {
            console.error("알림 전송 실패:", error);
        }
    });