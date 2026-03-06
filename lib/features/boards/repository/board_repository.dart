import 'package:board_app/core/models/board_models.dart';

class BoardRepository {
  final List<Board> _mockBoards = [
    Board(
      id: '1',
      title: 'Product Roadmap',
      description: 'Q2 2026 Mobile App Strategy',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ownerId: 'user1',
    ),
    Board(
      id: '2',
      title: 'Design System',
      description: 'UI/UX Guidelines and Assets',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ownerId: 'user1',
    ),
    Board(
      id: '3',
      title: 'Marketing Campaign',
      description: 'Social Media and Email Strategy',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ownerId: 'user1',
    ),
  ];

  Future<List<Board>> getBoards() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network
    return List.from(_mockBoards);
  }

  Future<Board> createBoard(String title, String description) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newBoard = Board(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      ownerId: 'user1',
    );
    _mockBoards.insert(0, newBoard);
    return newBoard;
  }

  Future<void> deleteBoard(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockBoards.removeWhere((board) => board.id == id);
  }

  Future<void> updateBoard(String id, String title, String description) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _mockBoards.indexWhere((board) => board.id == id);
    if (index != -1) {
      _mockBoards[index] = _mockBoards[index].copyWith(
        title: title,
        description: description,
      );
    }
  }
}
