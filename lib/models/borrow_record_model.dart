class BorrowRecordModel {
  final String id;
  final String bookId;
  final String bookTitle;
  final String userId;
  final String userName;
  final String locationId;
  final String reason;
  final DateTime borrowedAt;
  final DateTime dueDate;
  final DateTime? returnedAt;
  final String? summary;
  final int? summaryScore;
  final int? rating;
  final String? review;
  final bool isOverdue;
  final String status;
  final int pointsAwarded;

  BorrowRecordModel({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.userId,
    required this.userName,
    required this.locationId,
    required this.reason,
    required this.borrowedAt,
    required this.dueDate,
    this.returnedAt,
    this.summary,
    this.summaryScore,
    this.rating,
    this.review,
    required this.isOverdue,
    required this.status,
    required this.pointsAwarded,
  });

  bool get isActive => status == 'borrowed' || status == 'overdue';
  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;

  factory BorrowRecordModel.fromJson(Map<String, dynamic> json) {
    return BorrowRecordModel(
      id: json['id'],
      bookId: json['book_id'],
      bookTitle: json['book_title'],
      userId: json['user_id'],
      userName: json['user_name'],
      locationId: json['location_id'],
      reason: json['reason'],
      borrowedAt: DateTime.parse(json['borrowed_at']),
      dueDate: DateTime.parse(json['due_date']),
      returnedAt: json['returned_at'] != null ? DateTime.parse(json['returned_at']) : null,
      summary: json['summary'],
      summaryScore: json['summary_score'],
      rating: json['rating'],
      review: json['review'],
      isOverdue: json['is_overdue'] ?? false,
      status: json['status'] ?? 'borrowed',
      pointsAwarded: json['points_awarded'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'book_id': bookId,
      'book_title': bookTitle,
      'user_id': userId,
      'user_name': userName,
      'location_id': locationId,
      'reason': reason,
      'borrowed_at': borrowedAt.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'returned_at': returnedAt?.toIso8601String(),
      'summary': summary,
      'summary_score': summaryScore,
      'rating': rating,
      'review': review,
      'is_overdue': isOverdue,
      'status': status,
      'points_awarded': pointsAwarded,
    };
  }
}
