import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:board_app/core/models/board_models.dart';
import 'package:board_app/features/workspace/repository/workspace_repository.dart';
import 'package:board_app/core/services/realtime_service.dart';
import 'package:board_app/core/services/board_storage_service.dart';
import 'package:board_app/features/auth/providers/auth_provider.dart';

final realtimeServiceProvider = Provider<RealtimeService>(
  (ref) => SocketIoRealtimeService(),
);

final boardStorageProvider = Provider<BoardStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return BoardStorageService(prefs);
});

final workspaceRepositoryProvider = Provider((ref) {
  final realtime = ref.watch(realtimeServiceProvider);
  final storage = ref.watch(boardStorageProvider);
  return WorkspaceRepository(realtime, storage);
});

class BoardDetailState {
  final List<BoardColumn> columns;
  final Map<String, List<BoardCard>> cardsByColumn;
  final bool isLoading;
  final String? error;

  BoardDetailState({
    required this.columns,
    required this.cardsByColumn,
    this.isLoading = false,
    this.error,
  });

  factory BoardDetailState.initial() =>
      BoardDetailState(columns: [], cardsByColumn: {}, isLoading: true);

  BoardDetailState copyWith({
    List<BoardColumn>? columns,
    Map<String, List<BoardCard>>? cardsByColumn,
    bool? isLoading,
    String? error,
  }) {
    return BoardDetailState(
      columns: columns ?? this.columns,
      cardsByColumn: cardsByColumn ?? this.cardsByColumn,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class WorkspaceNotifier extends AsyncNotifier<Map<String, BoardDetailState>> {
  late final WorkspaceRepository _repository;
  late final RealtimeService _realtime;
  StreamSubscription? _eventSubscription;

  @override
  Future<Map<String, BoardDetailState>> build() async {
    _repository = ref.watch(workspaceRepositoryProvider);
    _realtime = ref.watch(realtimeServiceProvider);

    // Close any previous subscription
    _eventSubscription?.cancel();

    // Listen to real-time events from other devices
    _eventSubscription = _realtime.events.listen((event) {
      final currentMap = state.value ?? {};
      if (currentMap.containsKey(event.boardId)) {
        loadBoard(event.boardId, silent: true);
      }
    });

    ref.onDispose(() {
      _eventSubscription?.cancel();
    });

    // Listen to connection status changes for automatic re-sync
    _realtime.connectionStatus.listen((status) {
      if (status == ConnectionStatus.connected) {
        _resyncPendingActions();
      }
    });

    return {};
  }

  Future<void> _resyncPendingActions() async {
    final storage = ref.read(boardStorageProvider);
    final pending = storage.getPendingActions();
    if (pending.isEmpty) return;
    await storage.clearPendingActions();
    state.value?.keys.forEach((boardId) {
      loadBoard(boardId, silent: true);
    });
  }

  Future<void> loadBoard(String boardId, {bool silent = false}) async {
    final currentMap = state.value ?? {};
    if (!silent) {
      state = AsyncValue.data({
        ...currentMap,
        boardId:
            currentMap[boardId]?.copyWith(isLoading: true) ??
            BoardDetailState.initial(),
      });
    }

    try {
      final columns = await _repository.getColumns(boardId);
      final Map<String, List<BoardCard>> cardsMap = {};

      for (final column in columns) {
        final cards = await _repository.getCards(column.id);
        cards.sort((a, b) => a.order.compareTo(b.order));
        cardsMap[column.id] = cards;
      }

      final newState = BoardDetailState(
        columns: columns,
        cardsByColumn: cardsMap,
        isLoading: false,
      );

      state = AsyncValue.data({...state.value ?? {}, boardId: newState});
    } catch (e) {
      state = AsyncValue.data({
        ...state.value ?? {},
        boardId: BoardDetailState(
          columns: [],
          cardsByColumn: {},
          isLoading: false,
          error: e.toString(),
        ),
      });
    }
  }

  Future<void> addColumn(String boardId, String title) async {
    await _repository.createColumn(boardId, title);
    await loadBoard(boardId, silent: true);
  }

  Future<void> addCard(
    String boardId,
    String columnId,
    String title,
    String description, {
    List<String> tags = const [],
    DateTime? dueDate,
  }) async {
    await _repository.createCard(
      columnId,
      title,
      description,
      tags: tags,
      dueDate: dueDate,
    );
    await loadBoard(boardId, silent: true);
  }

  Future<void> updateCard(String boardId, BoardCard card) async {
    await _repository.updateCard(card);
    await loadBoard(boardId, silent: true);
  }

  Future<void> moveCard(
    String boardId,
    String cardId,
    String fromColumnId,
    String toColumnId, {
    int? toIndex,
  }) async {
    final currentMap = state.value ?? {};
    final boardState = currentMap[boardId];
    if (boardState == null) return;

    final updatedCardsByColumn = Map<String, List<BoardCard>>.from(
      boardState.cardsByColumn,
    );

    final fromCards = List<BoardCard>.from(
      updatedCardsByColumn[fromColumnId] ?? [],
    );
    final cardIndex = fromCards.indexWhere((c) => c.id == cardId);
    if (cardIndex == -1) return;

    final card = fromCards.removeAt(cardIndex);
    final updatedCard = card.copyWith(columnId: toColumnId);

    if (fromColumnId == toColumnId) {
      final insertIndex = toIndex ?? fromCards.length;
      fromCards.insert(
        insertIndex > fromCards.length ? fromCards.length : insertIndex,
        updatedCard,
      );
      for (int i = 0; i < fromCards.length; i++) {
        fromCards[i] = fromCards[i].copyWith(order: i);
      }
      updatedCardsByColumn[fromColumnId] = fromCards;
    } else {
      final toCards = List<BoardCard>.from(
        updatedCardsByColumn[toColumnId] ?? [],
      );
      final insertIndex = toIndex ?? toCards.length;
      toCards.insert(
        insertIndex > toCards.length ? toCards.length : insertIndex,
        updatedCard,
      );
      for (int i = 0; i < fromCards.length; i++) {
        fromCards[i] = fromCards[i].copyWith(order: i);
      }
      for (int i = 0; i < toCards.length; i++) {
        toCards[i] = toCards[i].copyWith(order: i);
      }
      updatedCardsByColumn[fromColumnId] = fromCards;
      updatedCardsByColumn[toColumnId] = toCards;
    }

    state = AsyncValue.data({
      ...currentMap,
      boardId: boardState.copyWith(cardsByColumn: updatedCardsByColumn),
    });

    try {
      await _repository.moveCard(
        cardId,
        fromColumnId,
        toColumnId,
        toIndex: toIndex,
      );
      await loadBoard(boardId, silent: true);
    } catch (e) {
      await loadBoard(boardId);
    }
  }

  Future<void> deleteCard(
    String boardId,
    String columnId,
    String cardId,
  ) async {
    await _repository.deleteCard(columnId, cardId);
    await loadBoard(boardId, silent: true);
  }

  Future<void> updateColumn(
    String boardId,
    String columnId,
    String title,
  ) async {
    await _repository.updateColumn(boardId, columnId, title);
    await loadBoard(boardId, silent: true);
  }

  Future<void> deleteColumn(String boardId, String columnId) async {
    await _repository.deleteColumn(boardId, columnId);
    await loadBoard(boardId, silent: true);
  }

  Future<void> addComment({
    required String boardId,
    required String cardId,
    required String text,
    required String userId,
    required String userName,
    String? parentId,
  }) async {
    try {
      await _repository.addComment(
        cardId: cardId,
        text: text,
        userId: userId,
        userName: userName,
        parentId: parentId,
      );
      await loadBoard(boardId, silent: true);
    } catch (e) {
      debugPrint('Error adding comment: $e');
    }
  }

  Future<void> editComment({
    required String boardId,
    required String cardId,
    required String commentId,
    required String newText,
  }) async {
    try {
      await _repository.editComment(cardId, commentId, newText);
      await loadBoard(boardId, silent: true);
    } catch (e) {
      debugPrint('Error editing comment: $e');
    }
  }

  Future<void> deleteComment({
    required String boardId,
    required String cardId,
    required String commentId,
  }) async {
    try {
      await _repository.deleteComment(cardId, commentId);
      await loadBoard(boardId, silent: true);
    } catch (e) {
      debugPrint('Error deleting comment: $e');
    }
  }
}

final workspaceNotifierProvider =
    AsyncNotifierProvider<WorkspaceNotifier, Map<String, BoardDetailState>>(() {
  return WorkspaceNotifier();
});

final boardDetailProvider = Provider.family<BoardDetailState?, String>((
  ref,
  boardId,
) {
  final workspaceMap = ref.watch(workspaceNotifierProvider).value ?? {};
  return workspaceMap[boardId];
});
