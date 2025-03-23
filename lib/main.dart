//the get package is for state management, controller stuff, and routing
//the media kit is for playing videos
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'common/theme.dart';
import 'controllers/autodl_controller.dart';
import 'controllers/bookmark_controller.dart';
import 'controllers/categories_controller.dart';
import 'controllers/dictionary_controller.dart';
import 'controllers/theme_controller.dart';
import 'helpers/pref.dart';
import 'models/word_model.dart';
import 'screens/dictionary.dart';
import 'screens/home.dart';
import 'screens/settings.dart';
import 'screens/word.dart';
import 'services/permission_service.dart';

void main() async {
  //initialize everything, flutter first, then the video player, then the database
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await Pref.initializeHive();

  // Initialize window manager for desktop platforms
  if (!GetPlatform.isMobile) {
    await windowManager.ensureInitialized();
    
    WindowOptions windowOptions = WindowOptions(
      size: Size(325, 650), // Set window size (Width x Height)
      center: true, // Center the window on screen
      minimumSize: Size(325, 650), // Optional: Set a minimum window size
      alwaysOnTop: false,
      titleBarStyle: TitleBarStyle.normal, // Keep the title bar
    );
    
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  //start controllers for each
  //controllers control behavior of widgets, and also help pass on data from pref to wherever its needed
  Get.put(DictionaryController());
  Get.put(BookmarkController());
  Get.put(ThemeController());
  Get.put(AutoDownloadController());
  Get.put(CategoriesController());

  bool isDarkMode = await Pref.isDarkMode;
  bool isAutoDownloadEnabled = await Pref.isAutoDownloadEnabled;

  runApp(
    MyApp(isDarkMode: isDarkMode, isAutoDownloadEnabled: isAutoDownloadEnabled),
  );

  //get permission, for android
  PermissionService.requestPermissions();
}

class MyApp extends StatelessWidget {
  final bool isDarkMode;
  final bool isAutoDownloadEnabled;

  MyApp({
    super.key,
    required this.isDarkMode,
    required this.isAutoDownloadEnabled,
  });

  //RxBool vs bool, RxBool is to make sure the changes are immediately reflected in the app
  final RxBool _isDarkMode = false.obs;
  final RxBool _isAutoDownloadEnabled = false.obs;

  @override
  Widget build(BuildContext context) {
    //get.find finds the controller of the specified type
    final themeController = Get.find<ThemeController>();
    final autoDownloadController = Get.find<AutoDownloadController>();
    
    _isDarkMode.value = isDarkMode;
    _isAutoDownloadEnabled.value = isAutoDownloadEnabled;
    themeController.isDarkMode.value = isDarkMode;
    autoDownloadController.isAutoDownloadEnabled.value = isAutoDownloadEnabled;

    //obx = observable, so that the state of whatever is inside the obx changes appropriately
    return Obx(() {
      return GetMaterialApp(
        title: 'Pocket AISLE',
        theme: themeController.isDarkMode.value ? darkTheme : lightTheme, 
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => HomeScreen()), //router for home
          GetPage(name: '/dictionary', page: () => DictionaryScreen()), //router for dictionary
          GetPage(name: '/settings', page: () => SettingsScreen()), //router for settings
          GetPage(
            name: '/dictionary/:word',
            page: () {
              final WordModel word = Get.arguments;
              return WordScreen(word: word);
            },
          ),//router for the wordscreen, for each word
        ],
      );
    });
  }
}
