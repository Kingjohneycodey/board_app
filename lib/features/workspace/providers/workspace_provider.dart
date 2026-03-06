import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:board_app/core/models/board_models.dart';
import 'package:board_app/features/workspace/repository/workspace_repository.dart';

final workspaceRepositoryProvider = Provider((ref) => WorkspaceRepository());

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

  @override
  Future<Map<String, BoardDetailState>> build() async {
    _repository = ref.watch(workspaceRepositoryProvider);
    return {};
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
    String description,
  ) async {
    await _repository.createCard(columnId, title, description);
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
    String toColumnId,
  ) async {
    final currentMap = state.value ?? {};
    final boardState = currentMap[boardId];
    if (boardState == null) return;

    // Optimistic Update
    final fromCards = List<BoardCard>.from(
      boardState.cardsByColumn[fromColumnId] ?? [],
    );
    final cardIndex = fromCards.indexWhere((c) => c.id == cardId);
    if (cardIndex == -1) return;

    final card = fromCards.removeAt(cardIndex);
    final updatedCard = card.copyWith(columnId: toColumnId);
    final toCards = List<BoardCard>.from(
      boardState.cardsByColumn[toColumnId] ?? [],
    );
    toCards.add(updatedCard);

    final updatedCardsByColumn = Map<String, List<BoardCard>>.from(
      boardState.cardsByColumn,
    );
    updatedCardsByColumn[fromColumnId] = fromCards;
    updatedCardsByColumn[toColumnId] = toCards;

    state = AsyncValue.data({
      ...currentMap,
      boardId: boardState.copyWith(cardsByColumn: updatedCardsByColumn),
    });

    try {
      await _repository.moveCard(cardId, fromColumnId, toColumnId);
      // Load silently to sync with server without showing loader
      await loadBoard(boardId, silent: true);
    } catch (e) {
      // Rollback on error
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
