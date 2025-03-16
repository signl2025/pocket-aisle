import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../apis/apis.dart';
import '../controllers/autodl_controller.dart';
import '../controllers/dictionary_controller.dart';
import '../controllers/theme_controller.dart';
import '../helpers/pref.dart';
import '../widgets/custom_app_bar.dart';

//creates the settings screen
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final DictionaryController _dictController = Get.find<DictionaryController>();

  final RxBool _isDarkModeRx = false.obs;
  final RxBool _isAutoDownloadEnabledRx = false.obs;

  @override
  void initState() {
    super.initState();

    _loadDarkModeSetting();
    _loadAutoDownloadSetting();
  }

  //gets darkmode setting from preferences stored in device
  void _loadDarkModeSetting() async {
    bool isDarkMode = await Pref.isDarkMode;
    _isDarkModeRx.value = isDarkMode;
  }

  //gets autodownload setting from preferences stored in device
  void _loadAutoDownloadSetting() async {
    bool autoDownloadEnabled = await Pref.isAutoDownloadEnabled;
    _isAutoDownloadEnabledRx.value = autoDownloadEnabled;
  }
  
  //deletes the current dictionary, so it gets replaced right away with latest file
  Future<void> deleteCurrentDictionary() async {
    if (await checkOnlineDictionary()) {
      File file = await APIs.getDictionaryFile();
      if(await file.exists()){
        String oldFilePath = file.path.replaceAll(".csv", '_old.csv'); //path for renamed old file
        await file.copy(oldFilePath); //duplicating old dictionary
        File oldFile = File(oldFilePath); //variable for the old dictionary

        file.delete();
        await _dictController.fetchDictionary(context); //redownload and update dictionary content
        
        if(await file.exists()){ //if download was successful, delete old file
          oldFile.delete();
          _showSuccessDialog();
        }else{ //otherwise, revert to old file
          oldFile.rename(file.path);
          _showFailDialog();
        }
      }
    }else{ //if no internet
      _showFailDialog();
    }
  }

  //checks if connected to the internet
  Future<bool> checkOnlineDictionary() async {
    try {
      final result = await InternetAddress.lookup('example.com'); //dont know why replacing this with the dictionary link doesnt work
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
        }
      } on SocketException catch (_) {
        return false;
      }
    return false;
  }

  //shows a dialog when you press the update icon, but only if successful
  Future<void> _showSuccessDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Succeeded!'),
          icon: Icon(
            Icons.verified, 
            color: Colors.green,
          ),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Dictionary updated successfully!'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  //shows a dialog when you press the update icon, but fail edition
  Future<void> _showFailDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Failed!'),
          icon: Icon(
            Icons.error, 
            color: Colors.red,
          ),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Dictionary failed to update'),
                Text('Please check your internet connection'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final AutoDownloadController autoDownloadController = Get.find<AutoDownloadController>();

    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(
          title: 'Settings',
          onMenuPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      body: Padding( //actual content of the setting screen starts here
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "App Theme",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            Obx(() {
              return SwitchListTile(
                title: const Text('Dark Mode'),
                value: themeController.isDarkMode.value,
                onChanged: (bool value) {
                  themeController.toggleTheme(); //sends message to themecontroller to toggle theme
                },
              );
            }),
            const SizedBox(height: 20),
            Text(
              "Auto Download Videos",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            Obx(() {
              return SwitchListTile(
                title: const Text('Enable Auto-Download'),
                value: autoDownloadController.isAutoDownloadEnabled.value,
                onChanged: (bool value) {
                  autoDownloadController.toggleAutoDownload(); //same as toggle above but for autodl
                  if(!value){
                    autoDownloadController.isAutoDownloadMissingEnabled.value = false; //disable below if this is off
                  }
                },
              );
            }),
            Obx(() {
              return SwitchListTile(
                title: Text(
                  'Automatically download missing videos',
                  style: TextStyle(
                    color: autoDownloadController.isAutoDownloadEnabled.value //toggles color of text to reflect if allowed
                      ? Colors.black
                      : Colors.grey,
                  ),
                ),
                value: autoDownloadController.isAutoDownloadMissingEnabled.value,
                onChanged: (bool value) {
                    autoDownloadController.isAutoDownloadEnabled.value //checks if autodl is enabled, if so, allow autodl missing
                      ? autoDownloadController.toggleAutoDownloadMissing()
                      : null;
                },
              );
            }),
            const SizedBox(height: 20),
            Text(
              "Update Dictionary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            ListTile(
            title: Text('Update Current Dictionary File'),
            trailing: IconButton(
              onPressed: () {
                deleteCurrentDictionary();
              },
            icon: Icon(Icons.update)),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              leading: Icon(Icons.home_filled),
              title: const Text(
                'Home',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(context); 
                Get.toNamed('/'); 
              },
            ),
            ListTile(
              leading: Icon(Icons.local_library),
              title: const Text(
                'Dictionary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(context); 
                Get.toNamed(
                  '/dictionary',
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: const Text(
                'Settings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(context); 
                Get.toNamed('/settings'); 
              },
            ),
          ],
        ),
      ),
    );
  }
}
