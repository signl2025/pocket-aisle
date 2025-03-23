import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../controllers/bookmark_controller.dart';
import '../controllers/categories_controller.dart';
import '../controllers/dictionary_controller.dart';
import '../helpers/pref.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //fetch dictionary, and validate bookmarks to remove non-existent words
    final DictionaryController dictController = Get.find<DictionaryController>();
    dictController.fetchDictionary(context);
    Pref.validateBookmarks();
    //fetch categories from file
    final CategoriesController catController = Get.find<CategoriesController>();
    catController.fetchCategories(context);
    //fetch bookmarks from pref data
    final BookmarkController bookController = Get.find<BookmarkController>();
    bookController.fetchBookmarks();
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

