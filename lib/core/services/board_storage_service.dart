import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:board_app/core/models/board_models.dart';

class BoardStorageService {
  static const String _boardsKey = 'cached_boards';
  static const String _columnsKey = 'cached_columns_';
  static const String _cardsKey = 'cached_cards_';
  static const String _offlineActionsKey = 'offline_actions';

  final SharedPreferences _prefs;

  BoardStorageService(this._prefs);

  /// Cache boards list
  Future<void> saveBoards(List<Board> boards) async {
    final boardsJson = jsonEncode(boards.map((b) => b.toJson()).toList());
    await _prefs.setString(_boardsKey, boardsJson);
  }

  /// Get cached boards
  List<Board> getBoards() {
    final boardsJson = _prefs.getString(_boardsKey);
    if (boardsJson != null) {
      try {
        final List<dynamic> boardsList = jsonDecode(boardsJson);
        return boardsList.map((b) => Board.fromJson(b)).toList();
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  /// Cache columns for a board
  Future<void> saveColumns(String boardId, List<BoardColumn> columns) async {
    final columnsJson = jsonEncode(columns.map((c) => c.toJson()).toList());
    await _prefs.setString('$_columnsKey$boardId', columnsJson);
  }

  /// Get cached columns
  List<BoardColumn> getColumns(String boardId) {
    final columnsJson = _prefs.getString('$_columnsKey$boardId');
    if (columnsJson != null) {
      try {
        final List<dynamic> columnsList = jsonDecode(columnsJson);
        return columnsList.map((c) => BoardColumn.fromJson(c)).toList();
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  /// Cache cards for a column
  Future<void> saveCards(String columnId, List<BoardCard> cards) async {
    final cardsJson = jsonEncode(cards.map((c) => c.toJson()).toList());
    await _prefs.setString('$_cardsKey$columnId', cardsJson);
  }

  /// Get cached cards
  List<BoardCard> getCards(String columnId) {
    final cardsJson = _prefs.getString('$_cardsKey$columnId');
    if (cardsJson != null) {
      try {
        final List<dynamic> cardsList = jsonDecode(cardsJson);
        return cardsList.map((c) => BoardCard.fromJson(c)).toList();
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  /// Queue an offline action
  Future<void> queueAction(Map<String, dynamic> action) async {
    final actionsJson = _prefs.getString(_offlineActionsKey) ?? '[]';
    final List<dynamic> actions = jsonDecode(actionsJson);
    actions.add({
      ...action,
      'timestamp': DateTime.now().toIso8601String(),
    });
    await _prefs.setString(_offlineActionsKey, jsonEncode(actions));
  }

  /// Get and clear pending offline actions
  List<Map<String, dynamic>> getPendingActions() {
    final actionsJson = _prefs.getString(_offlineActionsKey) ?? '[]';
    try {
      final List<dynamic> actions = jsonDecode(actionsJson);
      return actions.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearPendingActions() async {
    await _prefs.remove(_offlineActionsKey);
  }
}
