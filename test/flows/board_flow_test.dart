import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:board_app/main.dart';
import 'package:board_app/features/boards/providers/board_provider.dart';
import 'package:board_app/features/workspace/providers/workspace_provider.dart';
import 'package:board_app/core/models/board_models.dart';
import 'package:board_app/features/boards/repository/board_repository.dart';
import 'package:board_app/features/workspace/repository/workspace_repository.dart';
import 'package:board_app/core/services/realtime_service.dart';
import 'package:board_app/features/auth/providers/auth_provider.dart';
import 'package:board_app/core/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:board_app/core/services/token_storage_service.dart';

class MockBoardRepository extends Mock implements BoardRepository {}

class MockWorkspaceRepository extends Mock implements WorkspaceRepository {}

class MockRealtimeService extends Mock implements RealtimeService {}

class MockTokenStorage extends Mock implements TokenStorageService {}

class MockAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    return AuthState(
      status: AuthStatus.authenticated,
      user: User(
        id: 1,
        email: 'test@example.com',
        name: 'Test User',
        walletBalance: 0.0,
      ),
    );
  }
}

void main() {
  late MockBoardRepository boardRepo;
  late MockWorkspaceRepository workspaceRepo;
  late MockRealtimeService realtime;
  late MockTokenStorage tokenStorage;

  setUpAll(() {
    registerFallbackValue(
      BoardCard(
        id: '',
        columnId: '',
        title: '',
        description: '',
        tags: [],
        order: 0,
      ),
    );
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    boardRepo = MockBoardRepository();
    workspaceRepo = MockWorkspaceRepository();
    realtime = MockRealtimeService();
    tokenStorage = MockTokenStorage();

    when(() => tokenStorage.isLoggedIn).thenReturn(true);
    when(() => realtime.events).thenAnswer((_) => const Stream.empty());
    when(
      () => realtime.connectionStatus,
    ).thenAnswer((_) => const Stream.empty());
  });

  testWidgets('Integration Flow: Create Board and navigate to details', (
    WidgetTester tester,
  ) async {
    final mockBoard = Board(
      id: 'b1',
      title: 'New Integration Board',
      description: 'Test Desc',
      createdAt: DateTime.now(),
      ownerId: 'u1',
    );

    int getBoardsCallCount = 0;
    when(() => boardRepo.getBoards()).thenAnswer((_) async {
      getBoardsCallCount++;
      if (getBoardsCallCount > 1) {
        return [mockBoard];
      }
      return [];
    });

    when(
      () => boardRepo.createBoard(any(), any()),
    ).thenAnswer((_) async => mockBoard);

    when(() => workspaceRepo.getColumns('b1')).thenAnswer(
      (_) async => [
        BoardColumn(id: 'c1', boardId: 'b1', title: 'To Do', order: 0),
      ],
    );
    when(() => workspaceRepo.getCards('c1')).thenAnswer((_) async => []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          boardRepositoryProvider.overrideWithValue(boardRepo),
          workspaceRepositoryProvider.overrideWithValue(workspaceRepo),
          realtimeServiceProvider.overrideWithValue(realtime),
          authNotifierProvider.overrideWith(() => MockAuthNotifier()),
          tokenStorageProvider.overrideWithValue(tokenStorage),
        ],
        child: const MyApp(),
      ),
    );

    // Wait for splash screen delay
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('No Boards Found'), findsOneWidget);

    // Open Bottom Sheet
    await tester.tap(find.text('Create New Board'));
    await tester.pumpAndSettle();

    // Fill Form
    await tester.enterText(
      find.byType(TextField).at(0),
      'New Integration Board',
    );
    await tester.enterText(find.byType(TextField).at(1), 'Test Desc');

    // Tap Create button
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    // Verify board card appeared on screen
    expect(find.text('New Integration Board'), findsOneWidget);

    // Navigate to Detail Screen
    await tester.tap(find.text('New Integration Board'));
    await tester.pumpAndSettle();

    // Verify we reached the detail screen
    expect(find.text('To Do'), findsOneWidget);
    expect(find.text('New Integration Board'), findsAtLeast(1));
  });
}
