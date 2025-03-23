import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../controllers/bookmark_controller.dart';
import '../controllers/categories_controller.dart';
import '../controllers/dictionary_controller.dart';
import '../helpers/pref.dart';

class HomeScreen extends StatelessWidget {
  Future<void> initialize(BuildContext context) async{
    //fetch dictionary, and validate bookmarks to remove non-existent words
    final DictionaryController dictController = Get.find<DictionaryController>();
    await dictController.fetchDictionary(context);
    Pref.validateBookmarks();
    //fetch categories from file
    final CategoriesController catController = Get.find<CategoriesController>();
    await catController.fetchCategories(context);
    //fetch bookmarks from pref data
    final BookmarkController bookController = Get.find<BookmarkController>();
    bookController.fetchBookmarks();
  }
  @override
  Widget build(BuildContext context) {
    initialize(context);
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          Get.toNamed('/dictionary');
        },
        child: Center(
          child: SvgPicture.asset(
            "assets/images/bg.svg",
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
}

