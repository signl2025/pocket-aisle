import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:pocket_aisle/controllers/categories_controller.dart';

import '../controllers/dictionary_controller.dart'; // For navigation

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final DictionaryController dictController =Get.find<DictionaryController>();
    dictController.fetchDictionary(context);
    final CategoriesController catController =Get.find<CategoriesController>();
    catController.fetchCategories(context);
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

