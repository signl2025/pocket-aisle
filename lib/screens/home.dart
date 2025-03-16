import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/dictionary_controller.dart';
import '../controllers/bookmark_controller.dart';
import '../models/word_model.dart';
import '../widgets/custom_app_bar.dart';
import 'word.dart';

//HomeScreen represents the Home screen of the app, because it doesn't really track any previous action
class HomeScreen extends StatelessWidget {
  //scaffold key stores the state of the menu scaffold
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final DictionaryController _dictionaryController =Get.find<DictionaryController>();
  final BookmarkController _bookmarkController = Get.find<BookmarkController>();

  HomeScreen({super.key});

  //gets random words from the pool of words in the dictionary that aren't bookmarked
  //random is the random number generator
  List<WordModel> getRandomWords() {
    final random = Random();
    final dictionary = _dictionaryController.dictionary;
    final bookmarks = _bookmarkController.bookmarks;
    final randomPool =(dictionary.toSet().difference(bookmarks.toSet())).toList();

    if (randomPool.isEmpty) {
      return [
        WordModel(
          id: '',
          word: "",
          category: [],
          refId: '',
          vFileName: '',
          definition: "",
        ),
      ];
    }

    List<WordModel> randomWords = [];

    //technically, scalable to any size other than 3
    for (int i = 0; i < 3; i++) {
      randomWords.add(randomPool[random.nextInt(randomPool.length)]);
    }

    return randomWords;
  }

  //get random bookmarked word
  WordModel getRandomBookmarked() {
    final random = Random();
    final bookmarks = _bookmarkController.bookmarks;

    if (bookmarks.isEmpty) {
      return WordModel(
        id: '',
        word: "",
        category: [],
        refId: '',
        vFileName: '',
        definition: "",
      );
    }

    return bookmarks[random.nextInt(bookmarks.length)];
  }

  @override
  Widget build(BuildContext context) {
    //initializes the displayed dictionary content, if any
    if (_dictionaryController.dictionary.isEmpty) {
      _dictionaryController.fetchDictionary(context);
    }

    //the contents of home screen
    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(
          title: 'Home',
          onMenuPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() {
              if (_dictionaryController.dictionary.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    "Learn a Sign",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                );
              }
              return SizedBox.shrink();
            }),

            Obx(() {
              if (_dictionaryController.dictionary.isNotEmpty) {
                final randomWords = getRandomWords();
                return Column(
                  children:
                      randomWords.map((randomWord) {
                        return Card(
                          child: ListTile(
                            title: Text(
                              randomWord.word,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('${randomWord.category.join(', ')}\n${randomWord.definition}'), //category + newline + definition
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Obx(
                                    () => Icon(_bookmarkController.isBookmarked(randomWord) //check if word is bookmarked
                                            ? Icons.bookmark_remove //if bookmarked, replace bookmark icon with remove
                                            : Icons.bookmark_add_outlined, //if not bookmarked, replace icon with add
                                      color:
                                          _bookmarkController.isBookmarked(randomWord)
                                            ? Colors.indigoAccent
                                            : null,
                                    ),
                                  ),
                                  onPressed: () {
                                    _bookmarkController.toggleBookmark(
                                      randomWord,
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward),
                                  onPressed: () {
                                    Get.to(
                                      () => WordScreen(word: randomWord), //redirects to the word screen for the selected
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                );
              }
              return SizedBox.shrink(); 
            }),

            const SizedBox(height: 20),

            Obx(() {
              if (_bookmarkController.bookmarks.isNotEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    "Review a Sign",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                );
              }
              return SizedBox.shrink();
            }),

            Obx(() {
              if (_bookmarkController.bookmarks.isNotEmpty) {
                final bookmarkedWord = getRandomBookmarked();
                return Card(
                  child: ListTile(
                    title: Text(
                      bookmarkedWord.word,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text('${bookmarkedWord.category.join(', ')}\n${bookmarkedWord.definition}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Obx(
                            () => Icon(
                              _bookmarkController.isBookmarked(bookmarkedWord)
                                  ? Icons.bookmark_remove
                                  : Icons.bookmark_add_outlined,
                              color:
                                  _bookmarkController.isBookmarked(
                                        bookmarkedWord,
                                      )
                                      ? Colors.indigoAccent
                                      : null,
                            ),
                          ),
                          onPressed: () {
                            _bookmarkController.toggleBookmark(bookmarkedWord);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () {
                            Get.to(
                              () => WordScreen(word: bookmarkedWord),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SizedBox.shrink();
            }),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile( //menu item for home
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
            ListTile( //menu item for dictionary
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
            ListTile( //menu item for settings
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
