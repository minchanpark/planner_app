import 'package:flutter/material.dart';
import 'package:planner/view/about_arcaving/show_photo.dart';
import 'package:provider/provider.dart';
import '../../theme/theme.dart';
import '../../view_model/auth_view_model.dart';
import '../../view_model/category_view_model.dart';

class ShareRecordScreen extends StatefulWidget {
  const ShareRecordScreen({super.key});

  @override
  State<ShareRecordScreen> createState() => _ShareRecordScreenState();
}

class _ShareRecordScreenState extends State<ShareRecordScreen> {
  String? nickName;

  @override
  void initState() {
    super.initState();
    // 이메일이나 닉네임을 미리 가져와요.
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    authViewModel.getNickNameFromFirestore().then((value) {
      setState(() {
        nickName = value;
      });
    });
  }

  Widget _buildProfileRow(Map<String, dynamic> category) {
    // profileImages 리스트 안의 각 항목을 확인해요.
    final List images = category['profileImages'] as List;
    return Row(
      children: images.map<Widget>((imageUrl) {
        // 만약 이미지가 빈 문자열이면, 기본 이미지를 보여줘요.
        if (imageUrl.toString().isEmpty) {
          return SizedBox(
            width: 20,
            height: 20,
            child: Image.asset('assets/profile.png'),
          );
        }
        // 값이 있으면 해당 이미지를 원형으로 보여줘요.
        return SizedBox(
          width: 20,
          height: 20,
          child: CircleAvatar(
            backgroundImage: NetworkImage(imageUrl),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 화면의 너비와 높이를 가져와요.
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // 만약 닉네임을 아직 못 가져왔다면 로딩 중이에요.
    if (nickName == null) {
      return Scaffold(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // 카테고리 정보를 가져오는 스트림을 구독해요.
    final categoryViewModel =
        Provider.of<CategoryViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: categoryViewModel.streamUserCategoriesWithDetails(
            nickName!, authViewModel),
        builder: (context, snapshot) {
          // 데이터가 불러오는 중일때
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          // 에러가 생겼을 때
          if (snapshot.hasError) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final categories = snapshot.data ?? [];
          // 사용자 카테고리만 필터링합니다.
          final userCategories = categories
              .where((category) =>
                  ((category['mates'] as List).contains(nickName) &&
                      category['mates'].length != 1))
              .toList();

          if (userCategories.isEmpty) {
            return const Center(
              child: Text(
                '등록된 카테고리가 없습니다.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: (17 / 393) * MediaQuery.of(context).size.width),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: userCategories.length,
                    itemBuilder: (context, index) {
                      final category = userCategories[index];
                      return Container(
                        decoration: ShapeDecoration(
                          color: const Color(0xFF292929),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ShowPhotoScreen(
                                  categoryId: category['id'],
                                  categoryName: category['name'],
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: [
                                category['firstPhotoUrl'] != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.network(
                                          category['firstPhotoUrl'],
                                          width: 175,
                                          height: 145,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : SizedBox(
                                        width: 175,
                                        height: 145,
                                        child: const Icon(Icons.photo),
                                      ),
                                SizedBox(
                                    height: 8 /
                                        852 *
                                        MediaQuery.of(context).size.height),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      category['name'],
                                      style: TextStyle(
                                        color: AppTheme
                                            .lightTheme.colorScheme.secondary,
                                        fontSize: 16 / 852 * screenHeight,
                                      ),
                                    ),
                                    _buildProfileRow(category),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
