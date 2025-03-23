import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../apis/apis.dart';
import '../controllers/bookmark_controller.dart';
import '../controllers/categories_controller.dart';
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
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();

    _checkIcons();
    _loadIcons();
    _loadIconColors();
  }

  
  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (_pageController.page! > 0) {
          _pageController.previousPage(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        if (_pageController.page! < (_categoriesController.categories.length / 6).ceil() - 1) {
          _pageController.nextPage(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    }
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
      'bookmark': Icons.bookmark,
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
      'waving_hand': const Color.fromARGB(255, 158, 135, 52),
      'family_restroom': Colors.pinkAccent,
      '123': Colors.lightGreen,
      'palette': Colors.orange,
      'tour': Colors.deepOrange,
      'bookmark': Colors.indigo,
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
                title: 'Pocket\n AISLE',
                onMenuPressed: () {
                  _scaffoldKey.currentState?.openDrawer(); //opens menu
                },
              ),
            ],
          ),
        ),
        drawer: _buildDrawer(), //drawer = the menu that pops up when clicking menu button
        body: SizedBox.expand(
          child: 
            _buildContent(),
        ),
      );
  }

  //builds the content
  Widget _buildContent() {
    return Obx(() {
      if (_selectedWord.value != null) {
        return WordScreen(
          word: _selectedWord.value!,
          onBack: () => _selectedWord.value = null,
        );
      }

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
            child: _searchQuery.value.isNotEmpty
                ? _buildSearchResults() // show search results if there's input
                : _selectedCategory.value.isNotEmpty
                    ? _buildCategoryWords() // show words of a selected category
                    : _buildCategoryGrid(), // show category grid by default
          ),
        ],
      );
    });
  }

  Widget _buildSearchResults() {
    List<WordModel> filteredWords = _dictController.dictionary
        .where(
          (word) => word.word.toLowerCase().contains(
            _searchQuery.value.toLowerCase(),
          ),
        )
        .toList();

    if (filteredWords.isEmpty) {
      return Center(child: Text('No words found'));
    }

    return ListView.builder(
      itemCount: filteredWords.length,
      itemBuilder: (context, index) {
        WordModel word = filteredWords[index];

        return _buildWordTile(word);
      },
    );
  }

  Widget _buildCategoryGrid() {
    return Focus(
      autofocus: true,
      onKey: (node, event) {
        _handleKeyEvent(event);
        return KeyEventResult.handled;
      },
      child: Obx(() {
        if (_categoriesController.categories.isEmpty) {
          return Center(child: Text('No categories found'));
        }

        List<String> categories = _categoriesController.categories;
        int itemsPerPage = 6; // 2x3 grid
        int totalPages = (categories.length / itemsPerPage).ceil();

        return Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              if (event.scrollDelta.dy > 0) {
                // Scroll down -> Next page
                if (_pageController.page! < totalPages - 1) {
                  _pageController.nextPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              } else if (event.scrollDelta.dy < 0) {
                // Scroll up -> Previous page
                if (_pageController.page! > 0) {
                  _pageController.previousPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              }
            }
          },
          child: PageView.builder(
            controller: _pageController,
            itemCount: totalPages,
            physics: BouncingScrollPhysics(), // Improves feel on touchscreens
            itemBuilder: (context, pageIndex) {
              int startIndex = pageIndex * itemsPerPage;
              int endIndex = (startIndex + itemsPerPage).clamp(0, categories.length);
              List<String> pageCategories = categories.sublist(startIndex, endIndex);

              return GridView.builder(
                physics: NeverScrollableScrollPhysics(), // Prevents conflicts
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 columns
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                padding: EdgeInsets.all(10),
                itemCount: pageCategories.length,
                itemBuilder: (context, index) {
                  String category = pageCategories[index];

                  return GestureDetector(
                    onTap: () {
                      _selectedCategory.value = category;
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: _colorMap[category] ?? Colors.grey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _iconMap[category] ?? Icons.category,
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
            },
          ),
        );
      }),
    );
  }

  Widget _buildCategoryWords() {
    List<WordModel> words = _selectedCategory.value == "Bookmarks"
        ? _bookmarkController.bookmarks
        : _dictController.dictionary.where(
            (word) => word.category.contains(_selectedCategory.value),
          ).toList();

    return Column(
      children: [
        ListTile(
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              _selectedCategory.value = '';
            },
          ),
          title: Text(_selectedCategory.value),
        ),
        Expanded(
          child: ListView(
            children: words.map((word) => _buildWordTile(word)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildWordTile(WordModel word) {
    return Card(
      child: ListTile(
        title: Text(word.word, style: TextStyle(fontWeight: FontWeight.bold)),
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
                  color: _bookmarkController.isBookmarked(word) ? Colors.indigoAccent : null,
                ),
              ),
              onPressed: () {
                _bookmarkController.toggleBookmark(word);
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                Get.to(() => WordScreen(word: word));
              },
            ),
          ],
        ),
      ),
    );
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
    _searchController.dispose();
    super.dispose();
  }
}
