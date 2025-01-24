// Updated `category_select_screen.dart`
import 'package:flutter/material.dart';
import 'package:planner/service/notification_service_category_count.dart';
import 'package:provider/provider.dart';
import '../../view_model/auth_view_model.dart';
import '../../view_model/category_view_model.dart';
import 'category_screen.dart';

class CategorySelectScreen extends StatefulWidget {
  const CategorySelectScreen({super.key});

  @override
  State<CategorySelectScreen> createState() => _CategorySelectScreenState();
}

class _CategorySelectScreenState extends State<CategorySelectScreen> {
  final NotificationServiceCategoryCount _notificationServiceCategoryCount =
      NotificationServiceCategoryCount();

  @override
  void initState() {
    super.initState();
    _notificationServiceCategoryCount.initialize(); // 알림 초기화
    showRecommendationNotification();
  }

  Future<void> showRecommendationNotification() async {
    final categoryViewModel = context.read<CategoryViewModel>();
    final leastSavedCategory = await categoryViewModel.getLeastSavedCategory();

    if (leastSavedCategory != null) {
      _notificationServiceCategoryCount.showNotification(
        '추천 카테고리',
        '$leastSavedCategory 에 더 많은 사진을 추가해보세요!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryViewModel = Provider.of<CategoryViewModel>(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    TextEditingController categoryController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text('카테고리 선택'),
      ),
      body: Column(
        children: [
          TextField(
            controller: categoryController,
            decoration: InputDecoration(
              hintText: '카테고리 추가하기',
              suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () async {
                    print("userId: ${authViewModel.getUserId}");
                    categoryViewModel.createCategory(
                      categoryController.text,
                      await authViewModel.getNickNameFromFirestore(),
                      authViewModel.getUserId!,
                    );
                  }),
            ),
          ),
          Expanded(
            child: FutureBuilder<String>(
              future: authViewModel.getNickNameFromFirestore(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('오류 발생: ${snapshot.error}'));
                }
                final nickName = snapshot.data ?? '';
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: categoryViewModel.fetchUserCategories(nickName),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('오류 발생: ${snapshot.error}'));
                    }
                    final categories = snapshot.data ?? [];
                    return ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return ListTile(
                            title: Text(category['name']),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryScreen(
                                      categoryId: category['id']),
                                ),
                              );
                              print(category['id']);
                            });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
