import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pocket_aisle/controllers/categories_controller.dart';

import '../apis/apis.dart';
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
  final CategoriesController _categoriesController = Get.find<CategoriesController>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Map<String, IconData> _iconMap = {};
  Map<String, Color> _colorMap = {};

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

    _checkIcons();
    _loadIcons();
    _loadIconColors();
  }

  Future<void> _checkIcons() async{
    File categoriesFile = await APIs.getCategoriesFile();
    if(!await categoriesFile.exists()){
      await APIs.getCategories(context);
    }
  }

  Future<void> _loadIcons() async{
    File categoriesFile = await APIs.getCategoriesFile();
    if(await categoriesFile.exists()){
      String data = await categoriesFile.readAsString();
      Map<String, dynamic> jsonMap = jsonDecode(data.toString());
      setState(() {
        _iconMap = jsonMap.map((key, value) => MapEntry(key, _getIcon(value)));
      });
    }
  }

  Future<void> _loadIconColors() async{
    File categoriesFile = await APIs.getCategoriesFile();
    if(await categoriesFile.exists()){
      String data = await categoriesFile.readAsString();
      Map<String, dynamic> jsonMap = jsonDecode(data);
      setState(() {
        _colorMap = jsonMap.map((key, value) => MapEntry(key, _getColor(value)));
      });
    }
  }

  IconData _getIcon(String iconName) {
    return {
      'abc': Icons.abc,
      'school': Icons.school,
      'fastfood': Icons.fastfood,
      'mood': Icons.mood,
      'pets': Icons.pets,
      'calendar_month': Icons.calendar_month,
      'waving_hand': Icons.waving_hand,
      'family_restroom': Icons.family_restroom,
      '123': Icons.onetwothree,
      'palette': Icons.palette,
      'tour': Icons.tour,
    }[iconName] ?? Icons.help;
  }

  Color _getColor(String colorName) {
    return {
      'abc': Colors.blueGrey,
      'school': Colors.blue,
      'fastfood': Colors.red,
      'mood': Colors.green,
      'pets': Colors.brown,
      'calendar_month': Colors.grey,
      'waving_hand': Colors.yellow,
      'family_restroom': Colors.black,
      '123': Colors.lightGreen,
      'palette': Colors.orange,
      'tour': Colors.deepOrange,
    }[colorName] ?? Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    //initializes the displayed dictionary content, if any
    if (_dictController.dictionary.isEmpty) {
      _dictController.fetchDictionary(context);
    }

    if (_categoriesController.categories.isEmpty){
      _categoriesController.fetchCategories(context);
    }
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
              title: ' Assistive Instruction for \nSign Language Education',
              onMenuPressed: () {
                _scaffoldKey.currentState?.openDrawer(); //opens menu
              },
            ),
            Wrap(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab( //tab for categories
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.category),
                          Text('Categories'),
                        ],
                      ),
                    ),
                    Tab( //tab for search
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search),
                          Text('Search'),
                        ],
                      ),
                    ),
                    Tab( //tab for bookmarks
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bookmarks),
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
            _buildCategoriesTab(),
            _buildSearchTab(),
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
    //initializes the displayed dictionary content, if any
    if (_dictController.dictionary.isEmpty) {
      _dictController.fetchDictionary(context);
    }

    if (_categoriesController.categories.isEmpty){
      _categoriesController.fetchCategories(context);
    }
    return Obx(() {
      if (_selectedWord.value != null) {
        return WordScreen(
          word: _selectedWord.value!,
          onBack: () => _selectedWord.value = null,
        );
      }

      //if no words satisfy your search entry
      if (_categoriesController.categories.isEmpty) {
        return Center(child: Text('No categories found'));
      }

      //if you haven't selected a category yet, display all categories
      if (_selectedCategory.value.isEmpty) { 
        return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ), 
            itemCount: _categoriesController.categories.length,
            itemBuilder: (context, index) {
              var category = _categoriesController.categories[index];
              return GestureDetector(
                onTap: () {
                  _selectedCategory.value = category;
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _colorMap[category],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _iconMap[category],
                        size: 80,
                        color: Colors.white,
                      ),
                      SizedBox(height: 8),
                      Text(
                        category,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
      } else { //else show the contents of that category
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
            leading: Icon(Icons.local_library),
            title: const Text(
              'Home',
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
