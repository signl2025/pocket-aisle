import 'package:get/get.dart';

import '../helpers/pref.dart';
import 'dictionary_controller.dart';

//controller for autodownload
class AutoDownloadController extends GetxController {
  final dictController = Get.find<DictionaryController>();
  RxBool isAutoDownloadEnabled = true.obs;
  RxBool isAutoDownloadMissingEnabled = true.obs;

  @override
  void onInit() async {
    super.onInit();
    
    isAutoDownloadEnabled.value = await Pref.isAutoDownloadEnabled;
    isAutoDownloadMissingEnabled.value = await Pref.isAutoDownloadMissingEnabled;

    if (isAutoDownloadMissingEnabled.value) {
      dictController.downloadMissingVideos();
    }
  }

  // Toggle the auto-download missing setting
  // Why not just put autodownload here?
  //Answer: Already made it in dictionary controller, too much migration.
  //        Plus moving things from dictionary_controller to here would mean
  //        I'd still have to import this controller there. Might as well.
  void toggleAutoDownloadMissing() {
    isAutoDownloadMissingEnabled.value = !isAutoDownloadMissingEnabled.value;
    Pref.setAutoDownloadMissingEnabled(isAutoDownloadMissingEnabled.value);

    if (isAutoDownloadMissingEnabled.value) {
      dictController.downloadMissingVideos();
    }
  }
  
  void toggleAutoDownload() {
    isAutoDownloadEnabled.value = !isAutoDownloadEnabled.value;
    Pref.setAutoDownloadEnabled(isAutoDownloadEnabled.value);

    if (isAutoDownloadEnabled.value) {
      dictController.downloadMissingVideos();
    }
  }
}
