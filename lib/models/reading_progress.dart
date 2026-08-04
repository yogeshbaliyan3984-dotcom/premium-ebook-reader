import 'package:hive/hive.dart';

part 'reading_progress.g.dart';

@HiveType(typeId: 3)
class ReadingProgress extends HiveObject {
  @HiveField(0)
  String bookId;

  @HiveField(1)
  int lastPage;

  @HiveField(2)
  int totalPages;

  @HiveField(3)
  DateTime lastReadAt;

  ReadingProgress({
    required this.bookId,
    required this.lastPage,
    required this.totalPages,
    required this.lastReadAt,
  });

  double get percentComplete =>
      totalPages == 0 ? 0 : ((lastPage + 1) / totalPages) * 100;

  int get pagesLeft => totalPages - (lastPage + 1);
}
