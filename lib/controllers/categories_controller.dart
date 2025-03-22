import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../apis/apis.dart';
import '../helpers/pref.dart';


//controller for the dictionary, for uniformity and coherence throughout the app
class CategoriesController extends GetxController {
  var categories = <String>[].obs; //another way of declaring an rx list of object type, obs is property for observable

  @override
  void onInit() {
    super.onInit();
  }

  //gets the contents of the ditionary file and assings it when necessary
  Future<void> fetchCategories(BuildContext context) async {
    try {
      final fetchedCategories = await APIs.getCategories(context); //context means 'in this part of the application process'
      fetchedCategories.sort((a, b) => a.compareTo(b)); //sorts the dictionary
      categories.assignAll(fetchedCategories); //same as before but from the newly fetched dictionary
      Pref.categories = fetchedCategories;
      update();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error'
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
