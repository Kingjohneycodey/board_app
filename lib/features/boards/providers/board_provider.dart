import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:board_app/core/models/board_models.dart';
import 'package:board_app/features/boards/repository/board_repository.dart';

final boardRepositoryProvider = Provider((ref) => BoardRepository());

class BoardNotifier extends AsyncNotifier<List<Board>> {
  @override
  Future<List<Board>> build() async {
    return ref.watch(boardRepositoryProvider).getBoards();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final repository = ref.read(boardRepositoryProvider);
    state = await AsyncValue.guard(() => repository.getBoards());
  }

  Future<void> addBoard(String title, String description) async {
    state = const AsyncValue.loading();
    final repository = ref.read(boardRepositoryProvider);
    state = await AsyncValue.guard(() async {
      await repository.createBoard(title, description);
      return repository.getBoards();
    });
  }

  Future<void> deleteBoard(String id) async {
    state = const AsyncValue.loading();
    final repository = ref.read(boardRepositoryProvider);
    state = await AsyncValue.guard(() async {
      await repository.deleteBoard(id);
      return repository.getBoards();
    });
  }

  Future<void> updateBoard(String id, String title, String description) async {
    state = const AsyncValue.loading();
    final repository = ref.read(boardRepositoryProvider);
    state = await AsyncValue.guard(() async {
      await repository.updateBoard(id, title, description);
      return repository.getBoards();
    });
  }
}

final boardNotifierProvider = AsyncNotifierProvider<BoardNotifier, List<Board>>(
  () {
    return BoardNotifier();
  },
);
