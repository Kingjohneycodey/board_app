import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:board_app/features/workspace/providers/workspace_provider.dart';
import 'package:board_app/features/boards/providers/board_provider.dart';
import 'package:board_app/features/profile/providers/profile_provider.dart';
import 'package:board_app/core/models/board_models.dart';
import 'package:board_app/core/theme/app_theme.dart';
import 'package:board_app/core/widgets/app_state_widgets.dart';
import 'package:intl/intl.dart';
import 'package:board_app/core/services/realtime_service.dart';
import 'package:board_app/core/widgets/app_skeletons.dart';
import 'package:board_app/core/widgets/app_notifications.dart';

class BoardDetailScreen extends ConsumerStatefulWidget {
  final String boardId;
  const BoardDetailScreen({super.key, required this.boardId});

  @override
  ConsumerState<BoardDetailScreen> createState() => _BoardDetailScreenState();
}

class _BoardDetailScreenState extends ConsumerState<BoardDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(workspaceNotifierProvider.notifier)
          .loadBoard(widget.boardId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(boardDetailProvider(widget.boardId));
    final board = ref
        .watch(boardNotifierProvider)
        .value
        ?.firstWhere(
          (b) => b.id == widget.boardId,
          orElse: () => Board(
            id: '',
            title: 'Board Details',
            description: '',
            createdAt: DateTime.now(),
            ownerId: '',
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(board?.title ?? 'Board Details'),
        actions: [
          _ConnectionStatusIndicator(),
          IconButton(
            icon: const Icon(Icons.view_column_outlined),
            onPressed: () => _showColumnBottomSheet(context),
          ),
        ],
      ),
      body: _buildBody(detailState),
    );
  }

  Widget _buildBody(BoardDetailState? state) {
    if (state == null || state.isLoading) {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) => const ColumnSkeleton(),
      );
    }

    if (state.error != null) {
      return AppErrorWidget(
        message: state.error!,
        onRetry: () => ref
            .read(workspaceNotifierProvider.notifier)
            .loadBoard(widget.boardId),
      );
    }

    if (state.columns.isEmpty) {
      return _buildEmptyState();
    }

    final columnIds = state.columns.map((c) => c.id).toList();
    return _buildBoard(columnIds);
  }

  Widget _buildEmptyState() {
    return AppEmptyState(
      icon: Icons.view_column_outlined,
      title: 'Empty Board',
      description:
          'Start by adding a column (like "To Do" or "Done") to organize your tasks.',
      actionLabel: 'Add First Column',
      onAction: () => _showColumnBottomSheet(context),
    );
  }

  Widget _buildBoard(List<String> columnIds) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      itemCount: columnIds.length,
      itemBuilder: (context, index) {
        return _BoardColumn(
          columnId: columnIds[index],
          boardId: widget.boardId,
          // Use key to help Flutter identify columns during reordering
          key: ValueKey(columnIds[index]),
        );
      },
    );
  }

  void _showColumnBottomSheet(BuildContext context, {BoardColumn? column}) {
    final controller = TextEditingController(text: column?.title);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _BaseFormBottomSheet(
        title: column == null ? 'Add Column' : 'Rename Column',
        submitLabel: column == null ? 'Add' : 'Rename',
        onSubmit: () async {
          if (controller.text.isNotEmpty) {
            if (column == null) {
              await ref
                  .read(workspaceNotifierProvider.notifier)
                  .addColumn(widget.boardId, controller.text.trim());
              if (context.mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    AppNotifications.showSuccess(
                      context,
                      'Column added successfully',
                    );
                  }
                });
              }
            } else {
              await ref
                  .read(workspaceNotifierProvider.notifier)
                  .updateColumn(
                    widget.boardId,
                    column.id,
                    controller.text.trim(),
                  );
              if (context.mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    AppNotifications.showSuccess(
                      context,
                      'Column updated successfully',
                    );
                  }
                });
              }
            }
          }
        },
        child: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Column Title',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  void _showDeleteColumnConfirmation(
    BuildContext context,
    WidgetRef ref,
    BoardColumn column,
  ) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setState) => Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Icon(
                  Icons.delete_forever,
                  size: 48,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Delete Column?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to delete "${column.title}" and all its cards?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: isDeleting
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isDeleting
                            ? null
                            : () async {
                                setState(() => isDeleting = true);
                                try {
                                  await ref
                                      .read(workspaceNotifierProvider.notifier)
                                      .deleteColumn(widget.boardId, column.id);
                                  if (context.mounted) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          if (context.mounted) {
                                            AppNotifications.showSuccess(
                                              context,
                                              'Column deleted',
                                            );
                                          }
                                        });
                                    Navigator.pop(context);
                                  }
                                } finally {
                                  if (context.mounted) {
                                    setState(() => isDeleting = false);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isDeleting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Delete',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCardFormBottomSheet(
    BuildContext context,
    WidgetRef ref,
    BoardColumn column, {
    BoardCard? card,
  }) {
    final titleController = TextEditingController(text: card?.title);
    final descController = TextEditingController(text: card?.description);
    final tagsController = TextEditingController(text: card?.tags.join(', '));
    DateTime? selectedDate = card?.dueDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _BaseFormBottomSheet(
        title: card == null ? 'Add Card' : 'Edit Card',
        submitLabel: card == null ? 'Add' : 'Save Changes',
        onSubmit: () async {
          if (titleController.text.isNotEmpty) {
            final tags = tagsController.text
                .split(',')
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .toList();
            if (card == null) {
              await ref
                  .read(workspaceNotifierProvider.notifier)
                  .addCard(
                    widget.boardId,
                    column.id,
                    titleController.text.trim(),
                    descController.text.trim(),
                    tags: tags,
                    dueDate: selectedDate,
                  );
              if (context.mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    AppNotifications.showSuccess(
                      context,
                      'Card added successfully',
                    );
                  }
                });
              }
            } else {
              await ref
                  .read(workspaceNotifierProvider.notifier)
                  .updateCard(
                    widget.boardId,
                    card.copyWith(
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      tags: tags,
                      dueDate: selectedDate,
                    ),
                  );
              if (context.mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    AppNotifications.showSuccess(
                      context,
                      'Card updated successfully',
                    );
                  }
                });
              }
            }
          }
        },
        child: Column(
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Card Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tagsController,
              decoration: InputDecoration(
                labelText: 'Tags (comma separated)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (context, setPickerState) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today, size: 20),
                  title: Text(
                    selectedDate == null
                        ? 'Set Deadline'
                        : 'Deadline: ${DateFormat('MMM d, yyyy').format(selectedDate!)}',
                    style: TextStyle(
                      color: selectedDate == null ? Colors.grey : null,
                    ),
                  ),
                  trailing: selectedDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setPickerState(() {
                            selectedDate = null;
                          }),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365 * 2),
                      ),
                    );
                    if (picked != null) {
                      setPickerState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardColumn extends ConsumerWidget {
  final String columnId;
  final String boardId;

  const _BoardColumn({
    super.key,
    required this.columnId,
    required this.boardId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final column = ref.watch(
      boardDetailProvider(boardId).select((s) {
        if (s == null) return null;
        try {
          return s.columns.firstWhere((c) => c.id == columnId);
        } catch (_) {
          return null;
        }
      }),
    );

    final cards = ref.watch(
      boardDetailProvider(
        boardId,
      ).select((s) => s?.cardsByColumn[columnId] ?? []),
    );

    if (column == null) return const SizedBox.shrink();

    return DragTarget<BoardCard>(
      onWillAcceptWithDetails: (details) => details.data.columnId != column.id,
      onAcceptWithDetails: (details) {
        SystemSound.play(SystemSoundType.click);
        ref
            .read(workspaceNotifierProvider.notifier)
            .moveCard(
              boardId,
              details.data.id,
              details.data.columnId,
              column.id,
            );
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 300,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty
                ? AppTheme.primaryColor.withValues(alpha: 0.1)
                : (Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[900]?.withValues(alpha: 0.5)
                      : Colors.grey[100]),
            borderRadius: BorderRadius.circular(16),
            border: candidateData.isNotEmpty
                ? Border.all(color: AppTheme.primaryColor, width: 2)
                : null,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        column.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert,
                        size: 20,
                        color: Colors.grey,
                      ),
                      onSelected: (value) {
                        if (value == 'rename') {
                          (context
                                  .findAncestorStateOfType<
                                    _BoardDetailScreenState
                                  >())
                              ?._showColumnBottomSheet(context, column: column);
                        } else if (value == 'delete') {
                          final screenState = context
                              .findAncestorStateOfType<
                                _BoardDetailScreenState
                              >();
                          if (screenState != null) {
                            screenState._showDeleteColumnConfirmation(
                              context,
                              ref,
                              column,
                            );
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'rename',
                          child: Text('Rename'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount:
                      cards.length + 1, // Add space for dropping at the end
                  itemBuilder: (context, index) {
                    if (index == cards.length) {
                      // Bottom drop area
                      return DragTarget<BoardCard>(
                        key: ValueKey(
                          'dt_bottom_${column.id}',
                        ), // Bottom area key
                        onWillAcceptWithDetails: (details) => true,
                        onAcceptWithDetails: (details) {
                          SystemSound.play(SystemSoundType.click);
                          ref
                              .read(workspaceNotifierProvider.notifier)
                              .moveCard(
                                boardId,
                                details.data.id,
                                details.data.columnId,
                                column.id,
                                toIndex: cards.length,
                              );
                        },
                        builder: (context, candidateData, rejectedData) =>
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: candidateData.isNotEmpty ? 80 : 20,
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: candidateData.isNotEmpty
                                    ? AppTheme.primaryColor.withValues(
                                        alpha: 0.1,
                                      )
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: candidateData.isNotEmpty
                                    ? Border.all(
                                        color: AppTheme.primaryColor,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: candidateData.isNotEmpty
                                  ? const Center(
                                      child: Icon(
                                        Icons.add_circle_outline,
                                        color: AppTheme.primaryColor,
                                      ),
                                    )
                                  : null,
                            ),
                      );
                    }

                    final card = cards[index];
                    return DragTarget<BoardCard>(
                      key: ValueKey(
                        'dt_${card.id}',
                      ), // Use unique key for the target
                      onWillAcceptWithDetails: (details) =>
                          details.data.id != card.id,
                      onAcceptWithDetails: (details) {
                        SystemSound.play(SystemSoundType.click);
                        ref
                            .read(workspaceNotifierProvider.notifier)
                            .moveCard(
                              boardId,
                              details.data.id,
                              details.data.columnId,
                              column.id,
                              toIndex: index,
                            );
                      },
                      builder: (context, candidateData, rejectedData) {
                        final isHovered = candidateData.isNotEmpty;
                        return Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: isHovered ? 80 : 0,
                              margin: EdgeInsets.only(
                                bottom: isHovered ? 8 : 0,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.05,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.3,
                                  ),
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: isHovered
                                  ? const Center(
                                      child: Icon(
                                        Icons.add_circle_outline,
                                        color: AppTheme.primaryColor,
                                        size: 24,
                                      ),
                                    )
                                  : null,
                            ),
                            RepaintBoundary(
                              key: ValueKey(card.id),
                              child: _CardItem(card: card, boardId: boardId),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextButton.icon(
                  onPressed: () =>
                      (context
                              .findAncestorStateOfType<
                                _BoardDetailScreenState
                              >())
                          ?._showCardFormBottomSheet(context, ref, column),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Card'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CardItem extends ConsumerWidget {
  final BoardCard card;
  final String boardId;
  const _CardItem({required this.card, required this.boardId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardWidget = Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    card.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        final screenState = context
                            .findAncestorStateOfType<_BoardDetailScreenState>();
                        final columnWidget = context
                            .findAncestorWidgetOfExactType<_BoardColumn>();
                        if (screenState != null && columnWidget != null) {
                          // We need the columnId from the ancestor widget to get its data
                          final column = ref.read(
                            boardDetailProvider(boardId).select(
                              (s) => s?.columns.firstWhere(
                                (c) => c.id == columnWidget.columnId,
                              ),
                            ),
                          );
                          if (column != null) {
                            screenState._showCardFormBottomSheet(
                              context,
                              ref,
                              column,
                              card: card,
                            );
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () =>
                          _showDeleteCardConfirmation(context, ref),
                    ),
                  ],
                ),
              ],
            ),
            if (card.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                card.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            if (card.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: card.tags.map((tag) => _TagBadge(tag: tag)).toList(),
              ),
            ],
            if (card.dueDate != null || card.comments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (card.dueDate != null) ...[
                    const Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d').format(card.dueDate!),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (card.comments.isNotEmpty) ...[
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${card.comments.length}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );

    return LongPressDraggable<BoardCard>(
      data: card,
      feedback: Transform.rotate(
        angle: 0.05,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
          child: SizedBox(
            width: 280,
            child: Opacity(opacity: 0.9, child: cardWidget),
          ),
        ),
      ),
      onDragStarted: () {
        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.click);
      },
      childWhenDragging: Opacity(opacity: 0.3, child: cardWidget),
      child: InkWell(
        onTap: () => _showCardDetailsBottomSheet(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: cardWidget,
      ),
    );
  }

  void _showCardDetailsBottomSheet(BuildContext context, WidgetRef ref) {
    final commentController = TextEditingController();
    final focusNode = FocusNode();
    String? replyingToCommentId;
    String? replyingToUserName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isSendingComment = false;
        return StatefulBuilder(
          builder: (context, setSheetState) => Consumer(
            builder: (context, ref, child) {
              final detailState = ref.watch(boardDetailProvider(boardId));
              BoardCard? currentCard;
              if (detailState != null) {
                for (final entry in detailState.cardsByColumn.entries) {
                  final found = entry.value.where((c) => c.id == card.id);
                  if (found.isNotEmpty) {
                    currentCard = found.first;
                    break;
                  }
                }
              }

              final displayCard = currentCard ?? card;

              return Container(
                height: MediaQuery.of(context).size.height * 0.8,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.all(24),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        displayCard.title,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(Icons.close),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'In column: ${detailState?.columns.firstWhere(
                                        (c) => c.id == displayCard.columnId,
                                        orElse: () => BoardColumn(id: '', boardId: '', title: '-', order: 0),
                                      ).title ?? ""}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 24),
                                if (displayCard.description.isNotEmpty) ...[
                                  const Text(
                                    'Description',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    displayCard.description,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                if (displayCard.tags.isNotEmpty) ...[
                                  const Text(
                                    'Tags',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: displayCard.tags
                                        .map((tag) => _TagBadge(tag: tag))
                                        .toList(),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                if (displayCard.dueDate != null) ...[
                                  const Text(
                                    'Deadline',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        size: 18,
                                        color: Colors.redAccent,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormat(
                                          'MMMM d, yyyy',
                                        ).format(displayCard.dueDate!),
                                        style: const TextStyle(
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                const Divider(),
                                const SizedBox(height: 16),
                                const Text(
                                  'Comments',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ]),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            sliver: displayCard.comments.isEmpty
                                ? const SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'No comments yet',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                  )
                                : SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final topLevelComments = displayCard
                                            .comments
                                            .where((c) => c.parentId == null)
                                            .toList();
                                        if (index >= topLevelComments.length) {
                                          return null;
                                        }

                                        final comment = topLevelComments[index];
                                        final replies = displayCard.comments
                                            .where(
                                              (c) => c.parentId == comment.id,
                                            )
                                            .toList();

                                        return _CommentThread(
                                          comment: comment,
                                          replies: replies,
                                          boardId: boardId,
                                          cardId: displayCard.id,
                                          onReply: (parentId) {
                                            setSheetState(() {
                                              replyingToCommentId = parentId;
                                              replyingToUserName =
                                                  comment.userName;
                                            });
                                            focusNode.requestFocus();
                                          },
                                        );
                                      },
                                      childCount: displayCard.comments
                                          .where((c) => c.parentId == null)
                                          .length,
                                    ),
                                  ),
                          ),
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 100),
                          ),
                        ],
                      ),
                    ),
                    if (replyingToCommentId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        color: AppTheme.primaryColor.withValues(alpha: 0.05),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.reply,
                              size: 14,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Replying to $replyingToUserName',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 14),
                              onPressed: () => setSheetState(() {
                                replyingToCommentId = null;
                                replyingToUserName = null;
                              }),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 12,
                        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: commentController,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                hintText: replyingToCommentId != null
                                    ? 'Write a reply...'
                                    : 'Write a comment...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.blue[800]
                                    : Colors.grey[100],
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                              ),
                              maxLines: null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          isSendingComment
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  onPressed: () async {
                                    if (commentController.text
                                        .trim()
                                        .isNotEmpty) {
                                      final text = commentController.text
                                          .trim();
                                      final parentId = replyingToCommentId;

                                      setSheetState(
                                        () => isSendingComment = true,
                                      );

                                      try {
                                        final userProfile = ref.read(
                                          userProfileProvider,
                                        );
                                        await ref
                                            .read(
                                              workspaceNotifierProvider
                                                  .notifier,
                                            )
                                            .addComment(
                                              boardId: boardId,
                                              cardId: displayCard.id,
                                              text: text,
                                              userId:
                                                  userProfile?.id.toString() ??
                                                  'mock_user',
                                              userName:
                                                  userProfile?.name ??
                                                  'John Doe',
                                              parentId: parentId,
                                            );

                                        commentController.clear();
                                        setSheetState(() {
                                          replyingToCommentId = null;
                                          replyingToUserName = null;
                                        });
                                        focusNode.unfocus();

                                        if (context.mounted) {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                                if (context.mounted) {
                                                  AppNotifications.showSuccess(
                                                    context,
                                                    'Comment posted',
                                                  );
                                                }
                                              });
                                        }
                                      } finally {
                                        if (context.mounted) {
                                          setSheetState(
                                            () => isSendingComment = false,
                                          );
                                        }
                                      }
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.send,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showDeleteCardConfirmation(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setState) => Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Icon(
                  Icons.delete_forever,
                  size: 48,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Delete Card?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to delete "${card.title}"?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: isDeleting
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isDeleting
                            ? null
                            : () async {
                                setState(() => isDeleting = true);
                                try {
                                  await ref
                                      .read(workspaceNotifierProvider.notifier)
                                      .deleteCard(
                                        boardId,
                                        card.columnId,
                                        card.id,
                                      );
                                  if (context.mounted) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          if (context.mounted) {
                                            AppNotifications.showSuccess(
                                              context,
                                              'Card deleted',
                                            );
                                          }
                                        });
                                    Navigator.pop(context);
                                  }
                                } finally {
                                  if (context.mounted) {
                                    setState(() => isDeleting = false);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isDeleting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Delete',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TagBadge extends StatelessWidget {
  final String tag;
  const _TagBadge({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _BaseFormBottomSheet extends StatefulWidget {
  final String title;
  final String submitLabel;
  final Future<void> Function() onSubmit;
  final Widget child;

  const _BaseFormBottomSheet({
    required this.title,
    required this.submitLabel,
    required this.onSubmit,
    required this.child,
  });

  @override
  State<_BaseFormBottomSheet> createState() => _BaseFormBottomSheetState();
}

class _BaseFormBottomSheetState extends State<_BaseFormBottomSheet> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 24),
          widget.child,
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() => _isLoading = true);
                      try {
                        await widget.onSubmit();
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      widget.submitLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionStatusIndicator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final realtime = ref.watch(realtimeServiceProvider);
    return StreamBuilder<ConnectionStatus>(
      stream: realtime.connectionStatus,
      initialData: ConnectionStatus.connecting,
      builder: (context, snapshot) {
        final status = snapshot.data ?? ConnectionStatus.disconnected;
        final color = switch (status) {
          ConnectionStatus.connected => Colors.green,
          ConnectionStatus.connecting => Colors.orange,
          ConnectionStatus.disconnected => Colors.red,
        };
        final label = switch (status) {
          ConnectionStatus.connected => 'Online',
          ConnectionStatus.connecting => 'Connecting...',
          ConnectionStatus.disconnected => 'Offline',
        };

        return Tooltip(
          message: 'Real-time status: $label',
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 4,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CommentThread extends ConsumerWidget {
  final CardComment comment;
  final List<CardComment> replies;
  final String boardId;
  final String cardId;
  final Function(String) onReply;

  const _CommentThread({
    required this.comment,
    required this.replies,
    required this.boardId,
    required this.cardId,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CommentItem(
          comment: comment,
          boardId: boardId,
          cardId: cardId,
          onReply: () => onReply(comment.id),
        ),
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Column(
              children: replies
                  .map(
                    (reply) => _CommentItem(
                      comment: reply,
                      boardId: boardId,
                      cardId: cardId,
                      isReply: true,
                      onReply: () => onReply(comment.id),
                    ),
                  )
                  .toList(),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _CommentItem extends ConsumerWidget {
  final CardComment comment;
  final String boardId;
  final String cardId;
  final bool isReply;
  final VoidCallback onReply;

  const _CommentItem({
    required this.comment,
    required this.boardId,
    required this.cardId,
    this.isReply = false,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMe =
        ref.watch(userProfileProvider)?.id.toString() == comment.userId ||
        comment.userId == 'mock_user' ||
        comment.userId.isEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.translate(
            offset: Offset(0, isReply ? 9.0 : 4.0),
            child: CircleAvatar(
              radius: isReply ? 14 : 18,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Text(
                comment.userName.isNotEmpty
                    ? comment.userName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: isReply ? 11 : 13,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.translate(
                  offset: Offset(0, isReply ? 0.0 : -2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            comment.userName[0].toUpperCase() +
                                comment.userName.substring(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat(
                              'MMM d, HH:mm',
                            ).format(comment.createdAt),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                          if (comment.isEdited) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(edited)',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (isMe)
                        IconButton(
                          icon: const Icon(
                            Icons.more_horiz,
                            size: 18,
                            color: Colors.grey,
                          ),
                          onPressed: () => _showCommentActions(context, ref),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.zero,
                      topRight: const Radius.circular(16),
                      bottomLeft: const Radius.circular(16),
                      bottomRight: const Radius.circular(16),
                    ),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.1),
                    ),
                  ),
                  child: _CommentText(text: comment.text),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: GestureDetector(
                    onTap: onReply,
                    child: const Text(
                      'Reply',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCommentActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
              margin: const EdgeInsets.only(bottom: 24),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Comment'),
              onTap: () {
                Navigator.pop(context);
                _showEditCommentSheet(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Delete Comment',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCommentSheet(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: comment.text);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Comment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "What's on your mind?",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref
                          .read(workspaceNotifierProvider.notifier)
                          .editComment(
                            boardId: boardId,
                            cardId: cardId,
                            commentId: comment.id,
                            newText: controller.text,
                          );
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setState) => Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                const Icon(
                  Icons.delete_forever,
                  size: 48,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Delete Comment?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Are you sure you want to delete this comment? This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: isDeleting
                            ? null
                            : () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isDeleting
                            ? null
                            : () async {
                                setState(() => isDeleting = true);
                                try {
                                  await ref
                                      .read(workspaceNotifierProvider.notifier)
                                      .deleteComment(
                                        boardId: boardId,
                                        cardId: cardId,
                                        commentId: comment.id,
                                      );
                                  if (context.mounted) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          if (context.mounted) {
                                            AppNotifications.showSuccess(
                                              context,
                                              'Comment deleted',
                                            );
                                          }
                                        });
                                    Navigator.pop(context);
                                  }
                                } finally {
                                  if (context.mounted) {
                                    setState(() => isDeleting = false);
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isDeleting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Delete',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CommentText extends StatelessWidget {
  final String text;
  const _CommentText({required this.text});

  @override
  Widget build(BuildContext context) {
    final List<TextSpan> spans = [];
    final words = text.split(' ');

    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.startsWith('@')) {
        spans.add(
          TextSpan(
            text: '$word ',
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else {
        spans.add(TextSpan(text: '$word '));
      }
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color,
          fontSize: 14,
          height: 1.4,
        ),
        children: spans,
      ),
    );
  }
}
