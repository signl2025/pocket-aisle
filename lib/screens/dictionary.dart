import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/bookmark_controller.dart';
import '../controllers/dictionary_controller.dart';
import '../models/word_model.dart';
import '../widgets/custom_app_bar.dart';
import 'word.dart';

//stateful screen for dictionary, because it changes a lot, for tabs and searching and stuff
class DictionaryScreen extends StatefulWidget {
  @override
  _DictionaryScreenState createState() => _DictionaryScreenState();
}

//why singletickerproviderstatemixin? required for tab controller
class _DictionaryScreenState extends State<DictionaryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DictionaryController _dictController = Get.find<DictionaryController>();
  final BookmarkController _bookmarkController = Get.find<BookmarkController>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  //rx vars are for things that are needed for the app to react to user actions
  final TextEditingController _searchController = TextEditingController();
  final RxString _selectedCategory = ''.obs;
  final Rx<WordModel?> _selectedWord = Rx<WordModel?>(null);
  final RxString _searchQuery = ''.obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
    );

    //adds listener to the tab controller, so it can listen to changes for each of the variables needed
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) { //only runs when tabs switch
        setState(() {
          _selectedWord.value = null; 
          _selectedCategory.value = ''; 
          _searchQuery.value = ''; 
        });
        _searchController.clear(); //clears the search bar
      }
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(
          kToolbarHeight + 48,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomAppBar(
              title: 'Dictionary',
              onMenuPressed: () {
                _scaffoldKey.currentState?.openDrawer(); //opens menu
              },
            ),
            Wrap(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab( //tab for search
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search),
                          SizedBox(width: 8),
                          Text('Search'),
                        ],
                      ),
                    ),
                    Tab( //tab for categories
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.category),
                          SizedBox(width: 8),
                          Text('Categories'),
                        ],
                      ),
                    ),
                    Tab( //tab for bookmarks
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bookmarks),
                          SizedBox(width: 8),
                          Text('Bookmarks'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      drawer: _buildDrawer(), //drawer = the menu that pops up when clicking menu button
      body: SizedBox.expand(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildSearchTab(),
            _buildCategoriesTab(),
            _buildBookmarksTab(),
          ],
        ),
      ),
    );
  }

  //builds the search tab
  Widget _buildSearchTab() {
    return Obx(() {
      //selected word is the word you click, if you click one it will change the value of selected word and redirect you
      //if you click the back button on the word screen, you come back to this tab
      if (_selectedWord.value != null) {
        return WordScreen(
          word: _selectedWord.value!,
          onBack: () => _selectedWord.value = null, 
        );
      }

      //the contents of the search tab
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
              onChanged: (query) {
                _searchQuery.value = query;
              },
            ),
          ),
          Expanded(
            child: Obx(() {
              List<WordModel> filteredWords = //finds words that contain what you're searching for
                  _dictController.dictionary
                      .where(
                        (word) => word.word.toLowerCase().contains(
                          _searchQuery.value.toLowerCase(),
                        ),
                      )
                      .toList();

              //if no words satisfy your search entry
              if (filteredWords.isEmpty) {
                return Center(child: Text('No words found'));
              }

              //builds a display for the list of words that satisfy your search
              return ListView.builder(
                itemCount: filteredWords.length,
                itemBuilder: (context, index) {
                  WordModel word = filteredWords[index];

                  return Card( //the displayed content of that word, for this screen
                    child: ListTile(
                      title: Text(
                        word.word,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${word.category.join(', ')}\n${word.definition}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Obx(
                              () => Icon(
                                _bookmarkController.isBookmarked(word)
                                    ? Icons.bookmark_remove
                                    : Icons.bookmark_add_outlined,
                                color:
                                    _bookmarkController.isBookmarked(word)
                                        ? Colors.indigoAccent
                                        : null,
                              ),
                            ),
                            onPressed: () {
                              _bookmarkController.toggleBookmark(word);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: () {
                              Get.to(
                                () => WordScreen(word: word),
                              ); 
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      );
    });
  }

  //builds the categories tab
  Widget _buildCategoriesTab() {
    return Obx(() {
      if (_selectedWord.value != null) {
        return WordScreen(
          word: _selectedWord.value!,
          onBack: () => _selectedWord.value = null,
        );
      }

      //if you haven't selected a category yet, display all categories
      if (_selectedCategory.value.isEmpty) {
        return ListView( //returns only the categories as display, unique because Set and not List
          children:
              _dictController.dictionary
                  .expand((word) => word.category)
                  .toSet()
                  .map(
                    (category) => Card(
                      child: ListTile(
                        title: Text(
                          category,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () {
                            _selectedCategory.value = category; //changes selected category, redirects to contents of category
                          },
                        ),
                      ),
                    ),
                  )
                  .toList(),
        );
      } else {
        return Column(
          children: [
            ListTile(
              leading: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedCategory.value = ''; // Reset selected category, only if you click back
                  });
                },
              ),
              title: Text(_selectedCategory.value),
            ),
            Expanded(
              child: ListView( //lists words in the dictionary that are of the selected category
                children:
                    _dictController.dictionary
                        .where(
                          (word) =>
                              word.category.contains(_selectedCategory.value),
                        )
                        .map(
                          (word) => Card(
                            child: ListTile(
                              title: Text(
                                word.word,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('${word.category.join(', ')}\n${word.definition}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Obx(
                                      () => Icon(
                                        _bookmarkController.isBookmarked(word)
                                            ? Icons.bookmark_remove
                                            : Icons.bookmark_add_outlined,
                                        color:
                                            _bookmarkController.isBookmarked(
                                                  word,
                                                )
                                                ? Colors.indigoAccent
                                                : null,
                                      ),
                                    ),
                                    onPressed: () {
                                      _bookmarkController.toggleBookmark(word);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_forward),
                                    onPressed: () {
                                      Get.to(
                                        () => WordScreen(word: word),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
        );
      }
    });
  }

  //builds the bookmarks tab
  Widget _buildBookmarksTab() {
    return Obx(() {
      final bookmarkedWords = _bookmarkController.bookmarks;

      //checks if there are bookmarked words
      if (bookmarkedWords.isEmpty) {
        return Center(child: Text('No Bookmarked Words'));
      }

      if (_selectedWord.value != null) {
        return WordScreen(
          word: _selectedWord.value!,
          onBack: () => _selectedWord.value = null,
        );
      }

      //shows only the words in the bookmark controller's list
      return ListView.builder(
        itemCount: bookmarkedWords.length,
        itemBuilder: (context, index) {
          WordModel word = bookmarkedWords[index];

          return Card(
            child: ListTile(
              title: Text(
                word.word,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${word.category.join(', ')}\n${word.definition}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Obx(
                      () => Icon(
                        _bookmarkController.isBookmarked(word)
                            ? Icons.bookmark_remove
                            : Icons.bookmark_add_outlined,
                        color:
                            _bookmarkController.isBookmarked(word)
                                ? Colors.indigoAccent
                                : null,
                      ),
                    ),
                    onPressed: () {
                      _bookmarkController.toggleBookmark(word);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () {
                      Get.to(
                        () => WordScreen(word: word),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  //builds the drawer for the menu
  Widget _buildDrawer() {
    return Drawer(
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
              Get.toNamed('/dictionary'); 
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
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
