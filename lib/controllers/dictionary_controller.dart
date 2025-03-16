import 'dart:io';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../apis/apis.dart';
import '../helpers/pref.dart';
import '../models/word_model.dart';


//controller for the dictionary, for uniformity and coherence throughout the app
class DictionaryController extends GetxController {
  var dictionary = <WordModel>[].obs; //another way of declaring an rx list of object type, obs is property for observable

  @override
  void onInit() {
    super.onInit();
  }

  //gets the contents of the ditionary file and assings it when necessary
  Future<void> fetchDictionary(BuildContext context) async {
    try {
      final fetchedDictionary = await APIs.getDictionary(context); //context means 'in this part of the application process'

      fetchedDictionary.sort((a, b) => a.word.compareTo(b.word)); //sorts the dictionary

      dictionary.assignAll(fetchedDictionary); //same as before but from the newly fetched dictionary
      
      Pref.dictionary = fetchedDictionary;

      Pref.validateBookmarks(); //validate bookmarks after reading dictionary
      
      update();

      if (await Pref.isAutoDownloadEnabled) {
        downloadMissingVideos();
      }
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

  //downloads missing video files while autodl is enabled
  Future<void> downloadMissingVideos() async {
    for (var word in dictionary) {
      if (await Pref.isAutoDownloadMissingEnabled) {
        final videoPath = await APIs.getVideoPathForPlatform();
        final videoFile = File(p.join(videoPath, word.vFileName));

        if (!await videoFile.exists()) {
          await APIs.downloadWordVideo(word.vFileName);
        } 
      } else {
        break; //ends the loop if autodl is disabled while the loop is going on
      }
    }
  }
}
