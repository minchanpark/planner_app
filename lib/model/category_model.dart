import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  static const String collectionName = 'categories';

  final String id; // Firestore document ID
  final String name;
  final List<String> mates;

  CategoryModel({
    required this.id,
    required this.name,
    required this.mates,
  });

  // Firestore 문서를 CategoryModel 객체로 변환
  factory CategoryModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      mates: List<String>.from(data['mates'] ?? []),
    );
  }

  // CategoryModel 객체를 Firestore에 저장할 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'mates': mates,
    };
  }
}
