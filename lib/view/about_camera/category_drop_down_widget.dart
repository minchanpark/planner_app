import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../view_model/auth_view_model.dart';
import '../../view_model/category_view_model.dart';

/// 카테고리 드롭다운 위젯 (분리하여 재사용성과 가독성 향상)
class CategoryDropdownWidget extends StatefulWidget {
  const CategoryDropdownWidget({super.key});

  @override
  State<CategoryDropdownWidget> createState() => _CategoryDropdownWidgetState();
}

class _CategoryDropdownWidgetState extends State<CategoryDropdownWidget> {
  String dropdownValue = '';
  String categoryId = '';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: Provider.of<AuthViewModel>(context, listen: false)
          .getNickNameFromFirestore(),
      builder: (context, nickSnapshot) {
        if (nickSnapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(width: 150, child: Text(''));
        }
        if (!nickSnapshot.hasData) {
          return const SizedBox(
              width: 150,
              child: Center(
                  child: Text(
                '아직 카테고리가 없습니다.',
                style: TextStyle(color: Colors.white),
              )));
        }
        final nickName = nickSnapshot.data!;
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: Provider.of<CategoryViewModel>(context, listen: false)
              .streamUserCategories(nickName),
          builder: (context, catSnapshot) {
            if (catSnapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(width: 150, child: Text(''));
            }
            if (catSnapshot.hasError ||
                !catSnapshot.hasData ||
                catSnapshot.data!.isEmpty) {
              return const SizedBox(
                  width: 150,
                  child: Center(
                      child: Text(
                    '아직 카테고리가 없습니다.',
                    style: TextStyle(color: Colors.white),
                  )));
            }
            final categories = catSnapshot.data!;
            // 초기값은 사용자가 선택하지 않은 경우 한 번만 설정
            if (dropdownValue.isEmpty && categories.isNotEmpty) {
              dropdownValue = categories.first['name'] as String;
              categoryId = categories.first['id'] as String;
            }
            return SizedBox(
              width: 150,
              child: DropdownMenu<String>(
                initialSelection: dropdownValue,
                inputDecorationTheme: const InputDecorationTheme(
                  enabledBorder:
                      OutlineInputBorder(borderSide: BorderSide.none),
                ),
                trailingIcon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                ),
                selectedTrailingIcon: const Icon(
                  Icons.keyboard_arrow_up,
                  color: Colors.white,
                ),
                menuStyle: MenuStyle(
                  backgroundColor: WidgetStateProperty.all(Color(0xff232121)),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                textStyle: const TextStyle(color: Colors.white, fontSize: 20),
                dropdownMenuEntries: categories.map<DropdownMenuEntry<String>>(
                    (Map<String, dynamic> category) {
                  return DropdownMenuEntry<String>(
                    value: category['name'] as String,
                    label: category['name'] as String,
                    style: ButtonStyle(
                      foregroundColor: WidgetStateProperty.all(
                        dropdownValue == category['name']
                            ? Colors.white
                            : Colors.grey,
                      ),
                    ),
                  );
                }).toList(),
                onSelected: (String? value) {
                  if (value != null) {
                    setState(() {
                      dropdownValue = value;
                      final selectedCategory = categories.firstWhere(
                        (element) => element['name'] == value,
                        orElse: () => {'id': ''},
                      );
                      categoryId = selectedCategory['id'] as String;
                    });
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}
