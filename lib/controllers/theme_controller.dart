import 'package:get/get.dart';

import '../helpers/pref.dart';

//controller for the theme of the app
class ThemeController extends GetxController {
  RxBool isDarkMode = false.obs;

  @override
  void onInit() async {
    super.onInit();
    
    isDarkMode.value = await Pref.isDarkMode;
  }

  //toggles dark mode, so if currently dark mode, switches to light mode, vice-versa
  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;

    Pref.setisDarkMode(isDarkMode.value);
  }
}
