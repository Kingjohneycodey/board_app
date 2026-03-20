import 'package:board_app/core/models/board_models.dart';
import 'package:board_app/core/services/realtime_service.dart';
import 'package:board_app/core/services/board_storage_service.dart';

class WorkspaceRepository {
  final RealtimeService _realtime;
  final BoardStorageService _storage;

  WorkspaceRepository(this._realtime, this._storage);
  final Map<String, List<BoardColumn>> _mockColumns = {
    // '1': [
    //   BoardColumn(id: 'c1', boardId: '1', title: 'To Do', order: 0),
    //   BoardColumn(id: 'c2', boardId: '1', title: 'In Progress', order: 1),
    //   BoardColumn(id: 'c3', boardId: '1', title: 'Done', order: 2),
    // ],
  };

  final Map<String, List<BoardCard>> _mockCards = {
    // 'c1': [
    //   BoardCard(
    //     id: 'k1',
    //     columnId: 'c1',
    //     title: 'Design UI Mockups',
    //     description:
    //         'Create high-fidelity mockups for the new mobile app dashboard.',
    //     tags: ['Design', 'Mobile'],
    //     dueDate: DateTime.now().add(const Duration(days: 3)),
    //     order: 0,
    //   ),
    //   BoardCard(
    //     id: 'k2',
    //     columnId: 'c1',
    //     title: 'Set up CI/CD',
    //     description:
    //         'Configure GitHub Actions for automated testing and deployment.',
    //     tags: ['DevOps'],
    //     order: 1,
    //   ),
    // ],
    // 'c2': [
    //   BoardCard(
    //     id: 'k3',
    //     columnId: 'c2',
    //     title: 'API Integration',
    //     description: 'Implement the authentication flow using JWT.',
    //     tags: ['Backend'],
    //     dueDate: DateTime.now().add(const Duration(days: 1)),
    //     order: 0,
    //   ),
    // ],
    // 'c3': [],
  };

  Future<List<BoardColumn>> getColumns(String boardId) async {
    // Try to load from cache first
    final cached = _storage.getColumns(boardId);
    if (cached.isNotEmpty) {
      // Background update mock
      _mockColumns[boardId] = List.from(cached);
    }

    await Future.delayed(const Duration(milliseconds: 500));
    final columns = List.from(_mockColumns[boardId] ?? []);

    // Update cache
    if (columns.isNotEmpty) {
      await _storage.saveColumns(boardId, columns.cast<BoardColumn>());
    }

    return columns.cast<BoardColumn>();
  }

  Future<List<BoardCard>> getCards(String columnId) async {
    // Try to load from cache first
    final cached = _storage.getCards(columnId);
    if (cached.isNotEmpty) {
      _mockCards[columnId] = List.from(cached);
    }

    await Future.delayed(const Duration(milliseconds: 300));
    final cards = List.from(_mockCards[columnId] ?? []);

    // Update cache
    if (cards.isNotEmpty) {
      await _storage.saveCards(columnId, cards.cast<BoardCard>());
    }

    return cards.cast<BoardCard>();
  }

  Future<BoardColumn> createColumn(String boardId, String title) async {
    final columns = _mockColumns[boardId] ?? [];
    final nextOrder = columns.length;
    final newColumn = BoardColumn(
      id: 'c${DateTime.now().millisecondsSinceEpoch}',
      boardId: boardId,
      title: title,
      order: nextOrder,
    );
    _mockColumns[boardId] = [...columns, newColumn];

    // Persist to storage
    await _storage.saveColumns(boardId, _mockColumns[boardId]!);

    _realtime.emit(
      RealtimeEvent(
        type: RealtimeEventType.columnAdded,
        boardId: boardId,
        columnId: newColumn.id,
        data: newColumn,
      ),
    );

    return newColumn;
  }

  Future<BoardCard> createCard(
    String columnId,
    String title,
    String description, {
    List<String> tags = const [],
    DateTime? dueDate,
  }) async {
    final cards = _mockCards[columnId] ?? [];
    final nextOrder = cards.length;
    final newCard = BoardCard(
      id: 'k${DateTime.now().millisecondsSinceEpoch}',
      columnId: columnId,
      title: title,
      description: description,
      tags: tags,
      dueDate: dueDate,
      order: nextOrder,
    );
    _mockCards[columnId] = [...cards, newCard];

    // Persist to storage
    await _storage.saveCards(columnId, _mockCards[columnId]!);

    _realtime.emit(
      RealtimeEvent(
        type: RealtimeEventType.cardUpdated,
        boardId: 'any',
        columnId: columnId,
        cardId: newCard.id,
        data: newCard,
      ),
    );

    return newCard;
  }

  Future<void> moveCard(
    String cardId,
    String fromColumnId,
    String toColumnId, {
    int? toIndex,
  }) async {
    final fromCards = _mockCards[fromColumnId] ?? [];
    final cardIndex = fromCards.indexWhere((c) => c.id == cardId);

    if (cardIndex != -1) {
      final card = fromCards.removeAt(cardIndex);
      final updatedCard = card.copyWith(columnId: toColumnId);

      if (fromColumnId == toColumnId) {
        final insertIndex = toIndex ?? fromCards.length;
        fromCards.insert(
          insertIndex > fromCards.length ? fromCards.length : insertIndex,
          updatedCard,
        );
      } else {
        final toCards = _mockCards[toColumnId] ?? [];
        final insertIndex = toIndex ?? toCards.length;
        toCards.insert(
          insertIndex > toCards.length ? toCards.length : insertIndex,
          updatedCard,
        );
        _mockCards[toColumnId] = toCards;
      }

      // Update orders in affected columns
      for (int i = 0; i < fromCards.length; i++) {
        fromCards[i] = fromCards[i].copyWith(order: i);
      }
      _mockCards[fromColumnId] = fromCards;

      if (fromColumnId != toColumnId) {
        final toCards = _mockCards[toColumnId]!;
        for (int i = 0; i < toCards.length; i++) {
          toCards[i] = toCards[i].copyWith(order: i);
        }
        _mockCards[toColumnId] = toCards;
      }

      _realtime.emit(
        RealtimeEvent(
          type: RealtimeEventType.cardMoved,
          boardId: 'any',
          columnId: toColumnId,
          cardId: cardId,
          data: {
            'fromColumnId': fromColumnId,
            'toColumnId': toColumnId,
            'toIndex': toIndex,
          },
        ),
      );
    }
  }

  Future<void> updateCard(BoardCard card) async {
    final cards = _mockCards[card.columnId] ?? [];
    final index = cards.indexWhere((c) => c.id == card.id);
    if (index != -1) {
      cards[index] = card;
      _mockCards[card.columnId] = List.from(cards);

      _realtime.emit(
        RealtimeEvent(
          type: RealtimeEventType.cardUpdated,
          boardId: 'any',
          columnId: card.columnId,
          cardId: card.id,
          data: card,
        ),
      );
    }
  }

  Future<void> deleteCard(String columnId, String cardId) async {
    final cards = _mockCards[columnId] ?? [];
    cards.removeWhere((c) => c.id == cardId);
    _mockCards[columnId] = List.from(cards);
  }

  Future<void> updateColumn(
    String boardId,
    String columnId,
    String title,
  ) async {
    final columns = _mockColumns[boardId] ?? [];
    final index = columns.indexWhere((c) => c.id == columnId);
    if (index != -1) {
      columns[index] = columns[index].copyWith(title: title);
      _mockColumns[boardId] = List.from(columns);
    }
  }

  Future<CardComment> addComment({
    required String cardId,
    required String text,
    required String userId,
    required String userName,
    String? parentId,
  }) async {
    // Find the card to update its local mock state
    BoardCard? targetCard;
    String? targetColumnId;

    for (final colId in _mockCards.keys) {
      final cards = _mockCards[colId]!;
      final index = cards.indexWhere((c) => c.id == cardId);
      if (index != -1) {
        targetCard = cards[index];
        targetColumnId = colId;
        break;
      }
    }

    if (targetCard == null || targetColumnId == null) {
      throw Exception('Card not found');
    }

    // Parse mentions from text (simple @name parser for demonstration)
    final mentions = RegExp(r'@(\w+)')
        .allMatches(text)
        .map((m) => m.group(1)!)
        .toList();

    final newComment = CardComment(
      id: 'cmt${DateTime.now().millisecondsSinceEpoch}',
      cardId: cardId,
      userId: userId,
      userName: userName,
      text: text,
      createdAt: DateTime.now(),
      parentId: parentId,
      mentions: mentions,
    );

    final updatedCard = targetCard.copyWith(
      comments: [...targetCard.comments, newComment],
    );

    // Update in-memory
    final colCards = _mockCards[targetColumnId]!;
    final cardIndex = colCards.indexWhere((c) => c.id == cardId);
    colCards[cardIndex] = updatedCard;

    // Persist to storage
    await _storage.saveCards(targetColumnId, colCards);

    _realtime.emit(RealtimeEvent(
      type: RealtimeEventType.commentAdded,
      boardId: 'any',
      columnId: targetColumnId,
      cardId: cardId,
      data: newComment.toJson(),
    ));

    return newComment;
  }

  Future<void> editComment(String cardId, String commentId, String newText) async {
    for (final colId in _mockCards.keys) {
      final cards = _mockCards[colId]!;
      final cardIndex = cards.indexWhere((c) => c.id == cardId);
      if (cardIndex != -1) {
        final card = cards[cardIndex];
        final commentIndex = card.comments.indexWhere((c) => c.id == commentId);
        if (commentIndex != -1) {
          final updatedComments = List<CardComment>.from(card.comments);
          updatedComments[commentIndex] = updatedComments[commentIndex].copyWith(
            text: newText,
            isEdited: true,
          );
          
          final updatedCard = card.copyWith(comments: updatedComments);
          cards[cardIndex] = updatedCard;
          
          await _storage.saveCards(colId, cards);
          
          _realtime.emit(RealtimeEvent(
            type: RealtimeEventType.cardUpdated, // Using updated as generic sync
            boardId: 'any',
            columnId: colId,
            cardId: cardId,
            data: updatedCard.toJson(),
          ));
          return;
        }
      }
    }
  }

  Future<void> deleteComment(String cardId, String commentId) async {
    for (final colId in _mockCards.keys) {
      final cards = _mockCards[colId]!;
      final cardIndex = cards.indexWhere((c) => c.id == cardId);
      if (cardIndex != -1) {
        final card = cards[cardIndex];
        final updatedComments = card.comments.where((c) => c.id != commentId).toList();
        
        final updatedCard = card.copyWith(comments: updatedComments);
        cards[cardIndex] = updatedCard;
        
        await _storage.saveCards(colId, cards);
        
        _realtime.emit(RealtimeEvent(
          type: RealtimeEventType.cardUpdated,
          boardId: 'any',
          columnId: colId,
          cardId: cardId,
          data: updatedCard.toJson(),
        ));
        return;
      }
    }
  }

  Future<void> deleteColumn(String boardId, String columnId) async {
    final columns = _mockColumns[boardId] ?? [];
    columns.removeWhere((c) => c.id == columnId);
    _mockColumns[boardId] = List.from(columns);
    _mockCards.remove(columnId);
  }
}
