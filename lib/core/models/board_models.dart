class Board {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final String ownerId;

  Board({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.ownerId,
  });

  factory Board.fromJson(Map<String, dynamic> json) {
    return Board(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      ownerId: json['ownerId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'ownerId': ownerId,
  };

  Board copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    String? ownerId,
  }) {
    return Board(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      ownerId: ownerId ?? this.ownerId,
    );
  }
}

class BoardColumn {
  final String id;
  final String boardId;
  final String title;
  final int order;

  BoardColumn({
    required this.id,
    required this.boardId,
    required this.title,
    required this.order,
  });

  factory BoardColumn.fromJson(Map<String, dynamic> json) {
    return BoardColumn(
      id: json['id'],
      boardId: json['boardId'],
      title: json['title'],
      order: json['order'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'boardId': boardId,
    'title': title,
    'order': order,
  };

  BoardColumn copyWith({
    String? id,
    String? boardId,
    String? title,
    int? order,
  }) {
    return BoardColumn(
      id: id ?? this.id,
      boardId: boardId ?? this.boardId,
      title: title ?? this.title,
      order: order ?? this.order,
    );
  }
}

class CardComment {
  final String id;
  final String cardId;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;

  CardComment({
    required this.id,
    required this.cardId,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
  });

  factory CardComment.fromJson(Map<String, dynamic> json) {
    return CardComment(
      id: json['id'],
      cardId: json['cardId'],
      userId: json['userId'],
      userName: json['userName'],
      text: json['text'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'cardId': cardId,
    'userId': userId,
    'userName': userName,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };

  CardComment copyWith({
    String? id,
    String? cardId,
    String? userId,
    String? userName,
    String? text,
    DateTime? createdAt,
  }) {
    return CardComment(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class BoardCard {
  final String id;
  final String columnId;
  final String title;
  final String description;
  final List<String> tags;
  final DateTime? dueDate;
  final List<CardComment> comments;
  final int order;

  BoardCard({
    required this.id,
    required this.columnId,
    required this.title,
    required this.description,
    required this.tags,
    this.dueDate,
    this.comments = const [],
    required this.order,
  });

  factory BoardCard.fromJson(Map<String, dynamic> json) {
    return BoardCard(
      id: json['id'],
      columnId: json['columnId'],
      title: json['title'],
      description: json['description'],
      tags: List<String>.from(json['tags'] ?? []),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      comments: (json['comments'] as List? ?? [])
          .map((c) => CardComment.fromJson(c))
          .toList(),
      order: json['order'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'columnId': columnId,
    'title': title,
    'description': description,
    'tags': tags,
    'dueDate': dueDate?.toIso8601String(),
    'comments': comments.map((c) => c.toJson()).toList(),
    'order': order,
  };

  BoardCard copyWith({
    String? id,
    String? columnId,
    String? title,
    String? description,
    List<String>? tags,
    DateTime? dueDate,
    List<CardComment>? comments,
    int? order,
  }) {
    return BoardCard(
      id: id ?? this.id,
      columnId: columnId ?? this.columnId,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      dueDate: dueDate ?? this.dueDate,
      comments: comments ?? this.comments,
      order: order ?? this.order,
    );
  }
}
