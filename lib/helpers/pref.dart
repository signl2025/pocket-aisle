import 'dart:convert';

//hive flutter is for database reasons, stores the application's data
//shared preferences is for the settings of the app, and other such things
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/bookmark_controller.dart';
import '../models/word_model.dart';

//pref helper class, so that everything in the app can communicate properly
class Pref {
  static late Box _box; //contains the data for the app

  static Future<void> initializeHive() async {
    await Hive.initFlutter(); //initializes the database
    
    _box = await Hive.openBox('data'); //opens the box so that it can be interacted with
  }

  //returns the current dark mode setting, also is a variable
  static Future<bool> get isDarkMode async {
    return SharedPreferences.getInstance().then((prefs) {
      return prefs.getBool('isDarkMode') ?? false;
    });
  }

  //changes the current dark mode setting
  static Future<void> setisDarkMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', enabled);
  }

  //returns the current autodl setting, also is a variable
  static Future<bool> get isAutoDownloadEnabled async {
    return SharedPreferences.getInstance().then((prefs) {
      return prefs.getBool('autoDownload') ?? false;
    });
  }

  //changes the current autodl setting
  static Future<void> setAutoDownloadEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('autoDownload', enabled);
  }
  
  //returns the current autodl setting, also is a variable
  static Future<bool> get isAutoDownloadMissingEnabled async {
    return SharedPreferences.getInstance().then((prefs) {
      return prefs.getBool('autoDownloadMissing') ?? false;
    });
  }

  //changes the current autodl setting
  static Future<void> setAutoDownloadMissingEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('autoDownloadMissing', enabled);
  }

  //returns the current manualdownload setting
  static bool get isManualDownload {
    return _box.get('isManualDownload', defaultValue: true);
  }

  //changes the current manualdownload setting
  static set isManualDownload(bool value) {
    _box.put('isManualDownload', value);
  }

  //returns the current dictionary content
  static List<WordModel> get dictionary {
    final data = _box.get('dictionary');
    if (data == null) {
      return [];
    }
    try {
      final decodedData = jsonDecode(data); //decodes the data from the box

      //returns a list of word objects from the decoded data
      return List<WordModel>.from(
        decodedData.map((i) => WordModel.fromJson(i)),
      );
    } catch (e) {
      return [];
    }
  }

  //returns the current dictionary content
  static List<String> get categories {
    final data = _box.get('categories');
    if (data == null) {
      return [];
    }
    try {
      final decodedData = jsonDecode(data); //decodes the data from the box
      
      //returns a list of word objects from the decoded data
      return List<String>.from(
        decodedData,
      );
    } catch (e) {
      return [];
    }
  }

  //changes the current dictionary content (the list of word objects)
  static set categories(List<String> c) {
    try {
      String encodedData = jsonEncode(c); //encodes the data into the box

      //puts the encoded data into the box, replacing the value of the 'dictionary' in the box
      _box.put('categories', encodedData); 
    } catch (e) {
    }
  }

  //changes the current dictionary content (the list of word objects)
  static set dictionary(List<WordModel> w) {
    try {
      String encodedData = jsonEncode(w); //encodes the data into the box

      //puts the encoded data into the box, replacing the value of the 'dictionary' in the box
      _box.put('dictionary', encodedData); 
    } catch (e) {
    }
  }

  //method to validate bookmarks against the dictionary
  static void validateBookmarks() {
    final List<WordModel> dictionaryWords = dictionary;  // Get the current dictionary

    //retrieve current bookmarks and filter them
    final List<WordModel> currentBookmarks = bookmarks;

    //only keep words that exist in the dictionary
    final List<WordModel> validBookmarks = currentBookmarks
        .where((bookmark) => dictionaryWords.any((word) => word.word == bookmark.word))
        .toList();

    //save the filtered bookmarks back
    bookmarks = validBookmarks;
    
    //make sure the bookmark controller updates its bookmarks as well to reflect validation
    final bookmarkController = Get.find<BookmarkController>();
    bookmarkController.fetchBookmarks();
  }

  //returns the current bookmarks content
  static List<WordModel> get bookmarks {
    final data = _box.get('bookmarks');
    if (data == null) {
      return [];
    }
    try {
      final decodedData = jsonDecode(data);

      return List<WordModel>.from(
        decodedData.map((i) => WordModel.fromJson(i)),
      );
    } catch (e) {
      return [];
    }
  }

  //changes the current bookmarks content list
  static set bookmarks(List<WordModel> w) {
    try {
      _box.put('bookmarks', jsonEncode(w));
    } catch (e) {
    }
  }

  //get timestamp of when dictionary last get updated
  static DateTime? get dictionaryLastUpdated {
    final timestamp = _box.get('dictionaryLastUpdated');
    
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  //set timestamp of when dictionary last get updated
  static void setDictionaryLastUpdated(DateTime time) {
    _box.put('dictionaryLastUpdated', time.toIso8601String());
  }

  static DateTime? getVideoLastUpdated(String fileName) {
    final timestamp = _box.get('videoLastUpdated_$fileName');

    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  static void setVideoLastUpdated(String fileName, DateTime time) {
    _box.put('videoLastUpdated_$fileName', time.toIso8601String());
  }
}
