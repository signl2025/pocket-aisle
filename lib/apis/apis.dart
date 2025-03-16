import 'dart:io';

//path provider is platform-agnostic path provider for app-related pathings 
//(like documents folder in windows or data folder in android)
//dio package is for downloading files
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../helpers/pref.dart';
import '../models/word_model.dart';

class APIs {
  static String dictionaryLink =
      "https://raw.githubusercontent.com/signl2025/pocket-aisle-repo/main/dictionary.csv"; //link for dictionary
  static String vRepoLink =
      "https://raw.githubusercontent.com/signl2025/pocketaislevids/main/"; //link for video repository

  //returns the time the file in the link last got updated
  static Future<DateTime?> _getRemoteLastModified(String url) async {
    var response = await Dio().head(url);

    if (response.headers['last-modified'] != null) {
      return HttpDate.parse(response.headers['last-modified']!.first);
    }

    return null;
  }

  //checks if dictionary was updated
  static Future<bool> _isDictionaryUpdated() async {
    DateTime? remoteLastModified = await _getRemoteLastModified(dictionaryLink);
    if (remoteLastModified == null) return false;

    DateTime? localLastModified = Pref.dictionaryLastUpdated;

    //return true if no local last modified || false if online file is later than local
    return localLastModified == null || remoteLastModified.isAfter(localLastModified); 
  }

  //returns the dictionary
  static Future<List<WordModel>> getDictionary(BuildContext context) async {
    List<WordModel> dictionary = [];
    File dictionaryFile = await getDictionaryFile();
    bool isCorrupted = await _isDictionaryCorrupted(dictionaryFile);
    bool needsUpdate = await _isDictionaryUpdated();

    //download dictionary if either
    if (isCorrupted || needsUpdate) {
      await _downloadDictionary(context);
      Pref.setDictionaryLastUpdated(DateTime.now());
    }

    //if existent, decipher the contents of the file for the database
    if (await dictionaryFile.exists()) {
      final jsonList = await csvFileToJson(dictionaryFile.path);
      dictionary = jsonList.map((e) => WordModel.fromJson(e)).toList();
    }

    //updates the database to match the contents of the current dictionary
    Pref.dictionary = dictionary;

    return dictionary;
  }

  //downloads the dictionary
  static Future<void> _downloadDictionary(BuildContext context) async {
    final path = await _localPath;
    final file = File(p.join(path, 'dictionary.csv'));

    await Dio().download(dictionaryLink, file.path);
  }

  //why two downloadvideo methods? One is for access on other files, other is for actually downloading video
  static Future<String> downloadWordVideo(String wordFileName) async {
    final path = await getVideoPathForPlatform();
    final videoFile = File(p.join(path, wordFileName)); //combines the path and the words file name as destination for download

    //if the video already exists, return the video's path
    if (await videoFile.exists()) {
      return videoFile.path;
    }

    //only if manual download is activated, bypass autodl check
    if (Pref.isManualDownload || await Pref.isAutoDownloadEnabled || await Pref.isAutoDownloadMissingEnabled) {
      return _downloadVideo(videoFile, wordFileName);
    }

    return "asdasdgewtwt"; //unique string representing error, cannot be "error" because the word error exists. 
  }

  //downloads the video, into the videofilepath, videofilename is for logging time downloaded
  static Future<String> _downloadVideo(File videoFile,String videoFileName) async {
    final videoUrl = '$vRepoLink$videoFileName';

    try {
      await Dio().download(videoUrl, videoFile.path);
      Pref.setVideoLastUpdated(videoFileName, DateTime.now());

      if (await _isVideoCorrupted(videoFile)) {
        await Dio().download(videoUrl, videoFile.path);
        Pref.setVideoLastUpdated(videoFileName, DateTime.now());
      }

      return videoFile.path; 
    } catch (e) {
      return "asdasdgewtwt"; 
    }
  }

  //checks if video is corrupted
  static Future<bool> _isVideoCorrupted(File videoFile) async {
    if (!await videoFile.exists()) return true; //if video doesn;t exist i guess it is corrupted of some form
    if (await videoFile.length() < 1000) return true;  //if video is too short in bytes, then its probably not a video

    try {
      final fileStream = videoFile.openRead(0, 12);
      final bytes = await fileStream.first;
      if (!(bytes[4] == 0x66 &&
          bytes[5] == 0x74 &&
          bytes[6] == 0x79 &&
          bytes[7] == 0x70)) { //checks if videofile is truly a video
        return true;
      }
    } catch (e) {
      return true;
    }

    return false; 
  }

  //set the manualdownloadflag to true
  static void setManualDownloadFlag() {
    Pref.isManualDownload = true;
  }

  //resets the manualdownloadflag to false
  static void resetManualDownloadFlag() {
    Pref.isManualDownload = false;
  }

  //get video path for any platform
  static Future<String> getVideoPathForPlatform() async {
    if (Platform.isAndroid) { 
      final videoDir = Directory(p.join(await _localPath, 'videos')); //leads to android/data/com.example.pocket-aisle/files/videos

      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true); //creates the folder if it doesn;t exist, recursive to make sure entire path exists
      }

      return videoDir.path;
    } else {
      final videoDir = Directory(p.join(await _localPath, 'videos')); //My Documents/Pocket AISLE/videos

      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }

      return videoDir.path;
    }
  }

  //returns platform-specific local path 
  static Future<String> get _localPath async {
    if (Platform.isAndroid) {
      final directory = await getExternalStorageDirectory(); //leads to android/data/com.example.pocket-aisle/files

      return p.join(directory!.path);
    } else {
      final directory = await getApplicationDocumentsDirectory(); //My Documents/Pocket AISLE/

      return p.join(directory.path, 'Pocket AISLE');
    }
  }

  //returns the dictionary file from the application's documents folder
  static Future<File> getDictionaryFile() async {
    final path = await _localPath;

    return File(p.join(path, 'dictionary.csv'));
  }

  //checks if dictionary is corrupt
  static Future<bool> _isDictionaryCorrupted(File dictionaryFile) async {
    if (!await dictionaryFile.exists()) return true;

    if (await dictionaryFile.length() == 0) return true;

    //if not do this
    try {
      final jsonList = await csvFileToJson(dictionaryFile.path);

      return jsonList.isEmpty;
    } catch (e) {
      return true;
    }
  }

  //manual conversion of dictionary csv to a json format readable by the hive's box
  static Future<List<Map<String, dynamic>>> csvFileToJson(String filePath) async {
    File file = File(filePath);
    String csvString = await file.readAsString(); //reads the file as a string, non-readable by the box
    List<Map<String, dynamic>> jsonList = [];
    List<String> rows = csvString.split('\n');  //separates rows by each newline

    rows = rows.where((row) => row.isNotEmpty).toList(); //eliminates empty rows

    List<String> headers = rows[0].split(',',); //takes the headers off the file

    for (int i = 1; i < rows.length; i++) { //starts at 1 to skip the headers
      List<String> columns = _parseCsvRow(rows[i]);  //separates columns by comma
      Map<String, dynamic> rowMap = {}; //row representation that is of json format

      for (int j = 0; j < headers.length; j++) {
        rowMap[headers[j]] = columns.length > j ? columns[j] : ''; //jsonify's the row
      }

      jsonList.add(rowMap); //adds the jsonified row to the jsonlist
    }

    return jsonList; //returns the dictionary file in json format
  }

  //makes it so that any content inside any cell in the csv that has a comma gets read properly
  static List<String> _parseCsvRow(String row) {
    List<String> values = [];
    bool insideQuotes = false;
    String currentValue = '';

    for (int i = 0; i < row.length; i++) {
      if (row[i] == '"' && (i == 0 || row[i - 1] != '\\')) {
        insideQuotes = !insideQuotes; //toggles when the current value is inside quote marks
      } else if (row[i] == ',' && !insideQuotes) {
        values.add(currentValue.replaceAll('"', '')); //if not inside quotes, comma is delimiter and value is added anyways
        currentValue = '';  //clears currentvalue so other values in the row can be checked
      } else {
        currentValue += row[i];  //
      }
    }

    values.add(currentValue.replaceAll('"', '')); //removes quotation marks
    return values;
  }
}
