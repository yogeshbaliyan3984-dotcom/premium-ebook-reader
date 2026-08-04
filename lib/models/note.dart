import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 2)
class Note extends HiveObject {
  @HiveField(0)
  String bookId;

  @HiveField(1)
  int pageNumber;

  @HiveField(2)
  String text;

  @HiveField(3)
  String? highlightedSnippet;

  @HiveField(4)
  DateTime createdAt;

  Note({
    required this.bookId,
    required this.pageNumber,
    required this.text,
    this.highlightedSnippet,
    required this.createdAt,
  });
}
