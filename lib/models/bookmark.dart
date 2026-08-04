import 'package:hive/hive.dart';

part 'bookmark.g.dart';

@HiveType(typeId: 1)
class Bookmark extends HiveObject {
  @HiveField(0)
  String bookId;

  @HiveField(1)
  int pageNumber;

  @HiveField(2)
  String label;

  @HiveField(3)
  DateTime createdAt;

  Bookmark({
    required this.bookId,
    required this.pageNumber,
    required this.label,
    required this.createdAt,
  });
}
