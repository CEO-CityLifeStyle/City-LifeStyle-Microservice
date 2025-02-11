class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.createdAt,
    this.isRead = false,
  });

  final int id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final String createdAt;
  final bool isRead;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as int,
        title: json['title'] as String,
        body: json['body'] as String,
        type: json['type'] as String,
        data: json['data'] as Map<String, dynamic>? ?? {},
        createdAt: json['createdAt'] as String,
        isRead: json['isRead'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type,
        'data': data,
        'createdAt': createdAt,
        'isRead': isRead,
      };
}
