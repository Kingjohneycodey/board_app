import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:board_app/features/boards/view/boards_screen.dart';
import 'package:board_app/features/boards/providers/board_provider.dart';
import 'package:board_app/core/models/board_models.dart';
import 'package:board_app/core/widgets/app_skeletons.dart';

void main() {
  late List<Board> mockBoards;

  setUp(() {
    mockBoards = [
      Board(
        id: '1',
        title: 'Project Alpha',
        description: 'First test board',
        createdAt: DateTime.now(),
        ownerId: 'u1',
      ),
      Board(
        id: '2',
        title: 'Project Beta',
        description: 'Second test board',
        createdAt: DateTime.now(),
        ownerId: 'u1',
      ),
    ];
  });

  Widget createTestWidget(List overrides) {
    return ProviderScope(
      overrides: overrides.cast(),
      child: const MaterialApp(
        home: BoardsScreen(),
      ),
    );
  }

  testWidgets('BoardsScreen shows loading state initially', (WidgetTester tester) async {
    await tester.pumpWidget(
      createTestWidget([
        boardNotifierProvider.overrideWith(() => MockNotifierPending()),
      ]),
    );

    expect(find.byType(BoardListSkeleton), findsOneWidget);
  });

  testWidgets('BoardsScreen shows list of boards when data is available', (WidgetTester tester) async {
    await tester.pumpWidget(
      createTestWidget([
        boardNotifierProvider.overrideWith(() => MockNotifierSuccess(mockBoards)),
      ]),
    );

    await tester.pumpAndSettle();

    expect(find.text('Project Alpha'), findsOneWidget);
    expect(find.text('Project Beta'), findsOneWidget);
    expect(find.text('First test board'), findsOneWidget);
  });

  testWidgets('BoardsScreen shows empty state when no boards', (WidgetTester tester) async {
    await tester.pumpWidget(
      createTestWidget([
        boardNotifierProvider.overrideWith(() => MockNotifierSuccess([])),
      ]),
    );

    await tester.pumpAndSettle();

    expect(find.text('No Boards Found'), findsOneWidget);
    expect(find.text('Create New Board'), findsOneWidget);
  });
}

class MockNotifierPending extends BoardNotifier {
  @override
  Future<List<Board>> build() => Future.any([]); // Never completes for test
}

class MockNotifierSuccess extends BoardNotifier {
  final List<Board> boards;
  MockNotifierSuccess(this.boards);

  @override
  Future<List<Board>> build() async => boards;
}
