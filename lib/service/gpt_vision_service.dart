import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GPTVisionService {
  final Dio _dio = Dio();

  static String get apiKey => dotenv.env['API_KEY'] ?? '';
  static String get baseUrl => "https://api.openai.com/v1";

  Future<String> encodeImage(File image) async {
    final bytes = await image.readAsBytes();
    return base64Encode(bytes);
  }

  Future<String> getRecommendationFromImages(
      String categoryName, List<String> base64Images) async {
    try {
      // 이미지 목록을 user content 형식에 맞게 변환
      List<Map<String, dynamic>> messageContent = [];
      messageContent.add({
        "type": "text",
        "text":
            "현재 카테고리는 '$categoryName' 입니다. 아래 사진들을 보고 요약과 함께 '다음에는 ∼∼(사진과 카테고리 이름을 보고 추천할 카테고리)을 해보시는 것은 어떤가요?' 형태의 제안 문구를 JSON으로만 응답해주세요."
      });
      // 이미지 추가
      for (String base64Image in base64Images) {
        messageContent.add({
          "type": "image_url",
          "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
        });
      }

      final requestData = {
        "model": "gpt-4-vision-preview",
        "messages": [
          {
            "role": "system",
            "content":
                "You are a helpful assistant that can see images and provide a short summary and a suggestion phrase in Korean."
          },
          {
            "role": "user",
            "content": messageContent,
          },
        ],
        "max_tokens": 1000,
      };

      print("Request URL: $baseUrl/chat/completions");
      print("Request Data: ${jsonEncode(requestData)}");

      final response = await _dio.post(
        "$baseUrl/chat/completions",
        options: Options(
          headers: {
            HttpHeaders.authorizationHeader: 'Bearer $apiKey',
            HttpHeaders.contentTypeHeader: "application/json",
          },
        ),
        data: jsonEncode(requestData),
      );

      final jsonResponse = response.data;

      if (jsonResponse['error'] != null) {
        throw HttpException(jsonResponse['error']["message"]);
      }

      final String content =
          jsonResponse['choices']?[0]['message']['content'] ?? '';
      int startIndex = content.indexOf('{');
      int endIndex = content.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1) {
        final jsonString = content.substring(startIndex, endIndex + 1);
        final parsed = json.decode(jsonString);

        // {"summary": "...", "recommendation": "..."} 형태라고 가정
        final recommendation = parsed['recommendation'] ?? '';
        return recommendation;
      }

      throw Exception("Failed to parse GPT response");
    } catch (e) {
      print("getRecommendationFromImages error: $e");
      return "에러가 발생했습니다.";
    }
  }
}
