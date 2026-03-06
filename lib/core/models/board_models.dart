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
}

class BoardCard {
  final String id;
  final String columnId;
  final String title;
  final String description;
  final List<String> tags;
  final DateTime? dueDate;
  final int order;

  BoardCard({
    required this.id,
    required this.columnId,
    required this.title,
    required this.description,
    required this.tags,
    this.dueDate,
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
    'order': order,
  };

  BoardCard copyWith({
    String? id,
    String? columnId,
    String? title,
    String? description,
    List<String>? tags,
    DateTime? dueDate,
    int? order,
  }) {
    return BoardCard(
      id: id ?? this.id,
      columnId: columnId ?? this.columnId,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      dueDate: dueDate ?? this.dueDate,
      order: order ?? this.order,
    );
  }
}
