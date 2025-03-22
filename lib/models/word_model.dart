//model for the word in the dictionary
class WordModel {
  late final String id; //unique id
  late final String word; //the "word" in the dictionary entry
  late final List<String> category; //categories that describe this entry
  late final List<String> refId; //ids of any related word
  late final String vFileName; //filename for the word sign video
  late final String definition; //definition of the word
  bool isBookmarked; //bookmark check

  WordModel({
    required this.id,
    required this.word,
    required this.category,
    required this.refId,
    required this.vFileName,
    required this.definition,
    this.isBookmarked = false,
  });

  //factory to automatically turn the entry from the dictionary into an app-readable object
  factory WordModel.fromJson(Map<String, dynamic> json) {
    return WordModel(
      id: json['id'] ?? '',
      word: json['word'] ?? '',
      category:
          (json['category'] is String)
              ? json['category'].split('|')
              : List<String>.from(
                json['category'] ?? [],
              ), 
      refId:
          (json['refId'] is String)
              ? json['refId'].split('|')
              : List<String>.from(
                json['refId'] ?? [],
              ),
      vFileName: json['vFileName'] ?? '', 
      definition: json['definition'] ?? '', 
      isBookmarked: json['isBookmarked'] ?? false, 
    );
  }

  //turns word object into dictionary entry
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'category': category.join('|'), 
      'refId': refId.join('|'), 
      'definition': definition,
      'vFileName': vFileName,
      'isBookmarked': isBookmarked,
    };
  }
}
