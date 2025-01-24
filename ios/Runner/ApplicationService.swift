import Foundation
import Flutter

class ApplicationService {
    static let instance = ApplicationService() // Singleton

    private var methodChannel: FlutterMethodChannel?

    private init() {}

    func setMethodChannel(methodChannel: FlutterMethodChannel) {
        self.methodChannel = methodChannel
        print("MethodChannel이 설정되었습니다.")
    }

    func sendDataToFlutter(data: String) {
        guard let methodChannel = methodChannel else {
            print("MethodChannel이 설정되지 않았습니다.")
            return
        }

        methodChannel.invokeMethod("receiveData", arguments: data) { result in
            if let error = result as? FlutterError {
                print("Flutter로 데이터 전송 실패: \(error.message ?? "알 수 없는 오류")")
            } else {
                print("Flutter로 데이터 전송 성공!")
            }
        }
    }
}
