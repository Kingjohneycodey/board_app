import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:board_app/features/workspace/providers/workspace_provider.dart';
import 'package:board_app/features/workspace/repository/workspace_repository.dart';
import 'package:board_app/core/models/board_models.dart';
import 'package:board_app/core/services/realtime_service.dart';

class MockWorkspaceRepository extends Mock implements WorkspaceRepository {}
class MockRealtimeService extends Mock implements RealtimeService {}

void main() {
  late WorkspaceRepository repository;
  late RealtimeService realtime;
  late ProviderContainer container;

  setUp(() {
    repository = MockWorkspaceRepository();
    realtime = MockRealtimeService();
    
    when(() => realtime.events).thenAnswer((_) => const Stream.empty());
    when(() => realtime.connectionStatus).thenAnswer((_) => const Stream.empty());

    container = ProviderContainer(
      overrides: [
        workspaceRepositoryProvider.overrideWithValue(repository),
        realtimeServiceProvider.overrideWithValue(realtime),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('WorkspaceNotifier Tests', () {
    test('loadBoard updates state with columns and cards', () async {
      const boardId = 'board1';
      final columns = [
        BoardColumn(id: 'c1', boardId: boardId, title: 'To Do', order: 0),
      ];
      final cards = [
        BoardCard(
          id: 'k1',
          columnId: 'c1',
          title: 'Test Card',
          description: 'Desc',
          tags: [],
          order: 0,
        ),
      ];

      when(() => repository.getColumns(boardId)).thenAnswer((_) async => columns);
      when(() => repository.getCards('c1')).thenAnswer((_) async => cards);

      await container.read(workspaceNotifierProvider.future);
      final notifier = container.read(workspaceNotifierProvider.notifier);
      
      await notifier.loadBoard(boardId);

      final state = container.read(workspaceNotifierProvider).requireValue;
      
      expect(state.containsKey(boardId), true);
      expect(state[boardId]!.columns.length, 1);
      expect(state[boardId]!.cardsByColumn['c1']!.length, 1);
      expect(state[boardId]!.cardsByColumn['c1']![0].title, 'Test Card');
    });

    test('addCard calls repository and reconciles local state', () async {
      const boardId = 'board1';
      const columnId = 'c1';
      final newCard = BoardCard(
        id: 'new_id',
        columnId: columnId,
        title: 'New Card',
        description: 'New Desc',
        tags: ['urgent'],
        order: 0,
      );
      
      when(() => repository.createCard(
            any(), any(), any(), any(),
            tags: any(named: 'tags'), 
            dueDate: any(named: 'dueDate'),
          )).thenAnswer((_) async => newCard);
      
      when(() => repository.getColumns(boardId)).thenAnswer((_) async => [
        BoardColumn(id: columnId, boardId: boardId, title: 'To Do', order: 0)
      ]);
      when(() => repository.getCards(columnId)).thenAnswer((_) async => [newCard]);

      await container.read(workspaceNotifierProvider.future);
      final notifier = container.read(workspaceNotifierProvider.notifier);
      
      await notifier.addCard(boardId, columnId, 'New Card', 'New Desc', tags: ['urgent']);

      verify(() => repository.createCard(
        boardId, 
        columnId, 
        'New Card', 
        'New Desc', 
        tags: ['urgent'],
        dueDate: any(named: 'dueDate'),
      )).called(1);

      final state = container.read(workspaceNotifierProvider).requireValue;
      final boardState = state[boardId];
      
      expect(boardState, isNotNull);
      expect(boardState!.cardsByColumn[columnId], contains(newCard));
      expect(boardState.cardsByColumn[columnId]![0].title, 'New Card');
    });

    test('loadBoard handles repository errors gracefully', () async {
      const boardId = 'error_board';
      
      await container.read(workspaceNotifierProvider.future);
      final notifier = container.read(workspaceNotifierProvider.notifier);

      when(() => repository.getColumns(boardId)).thenThrow(Exception('Failed to fetch columns'));

      await notifier.loadBoard(boardId);
      
      final stateValue = container.read(workspaceNotifierProvider).requireValue;
      final boardState = stateValue[boardId];
      
      expect(boardState, isNotNull);
      expect(boardState!.error, contains('Failed to fetch columns'));
      expect(boardState.isLoading, false);
    });
  });
}
