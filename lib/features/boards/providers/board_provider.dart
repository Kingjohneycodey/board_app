import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:board_app/core/models/board_models.dart';
import 'package:board_app/features/boards/repository/board_repository.dart';

final boardRepositoryProvider = Provider((ref) => BoardRepository());

class BoardNotifier extends AsyncNotifier<List<Board>> {
  late final BoardRepository _repository;

  @override
  Future<List<Board>> build() async {
    _repository = ref.watch(boardRepositoryProvider);
    return _repository.getBoards();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getBoards());
  }

  Future<void> addBoard(String title, String description) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.createBoard(title, description);
      return _repository.getBoards();
    });
  }

  Future<void> deleteBoard(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteBoard(id);
      return _repository.getBoards();
    });
  }
}

final boardNotifierProvider = AsyncNotifierProvider<BoardNotifier, List<Board>>(
  () {
    return BoardNotifier();
  },
);
