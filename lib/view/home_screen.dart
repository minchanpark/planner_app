import 'package:flutter/material.dart';
import 'package:planner/view/about_camera/camera_screen.dart';
import 'package:provider/provider.dart';
import '../theme/theme.dart';
import '../view_model/auth_view_model.dart';
import '../view_model/category_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final categoryViewModel =
        Provider.of<CategoryViewModel>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'SOI',
          style: TextStyle(color: AppTheme.lightTheme.colorScheme.secondary),
        ),
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        toolbarHeight: 70,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/category_add_screen');
            },
            icon: Icon(
              Icons.add,
              size: 35,
              color: AppTheme.lightTheme.colorScheme.secondary,
            ),
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: authViewModel.getNickNameFromFirestore(),
        builder: (context, nickSnapshot) {
          if (nickSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!nickSnapshot.hasData) {
            return Center(child: Text('로그인 정보가 없습니다.'));
          }
          final nickName = nickSnapshot.data!;
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: categoryViewModel.streamUserCategories(nickName),
            builder: (context, catSnapshot) {
              if (catSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (catSnapshot.hasError) {
                return Center(
                  child: Text('카테고리를 불러오는데 오류가 발생했습니다.'),
                );
              }
              final categories = catSnapshot.data ?? [];
              if (categories.isEmpty) {
                return Center(
                    child: Text(
                  '등록된 카테고리가 없습니다.',
                  style: TextStyle(color: Colors.white),
                ));
              }
              return ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return ListTile(
                    title: Text(
                      category['name'],
                      style: TextStyle(
                        color: AppTheme.lightTheme.colorScheme.secondary,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CameraScreen(
                            categoryName: category['name'],
                            categoryId: category['id'],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
