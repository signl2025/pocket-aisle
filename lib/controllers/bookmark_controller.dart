import 'package:get/get.dart';

import '../helpers/pref.dart';
import '../models/word_model.dart';

//controllerr for bookmark functionality
class BookmarkController extends GetxController {
  var bookmarks = <WordModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchBookmarks();
  }

  //fetches bookmarks from stored database
  void fetchBookmarks() {
    bookmarks.assignAll(Pref.bookmarks);
  }

  //toggles bookmark status for the word
  void toggleBookmark(WordModel word) {
    if (isBookmarked(word)) { //if bookmarked already, remove. otherwise vice verssa
      bookmarks.removeWhere((w) => w.word == word.word); //removes word from list
    } else {
      bookmarks.add(word); //adds word into bookmark
    }

    bookmarks.sort((a, b) => a.word.compareTo(b.word)); //sorts the bookmarks

    Pref.bookmarks = bookmarks.toList(); //updates bookmark in stored database
    
    update(); //rebuilds getbuilder, required
  }

  //checks if word is bookmarked
  bool isBookmarked(WordModel word) {
    return bookmarks.any((w) => w.word == word.word);
  }
}
