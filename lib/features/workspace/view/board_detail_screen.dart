import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:board_app/features/workspace/providers/workspace_provider.dart';
import 'package:board_app/core/models/board_models.dart';
import 'package:board_app/core/theme/app_theme.dart';
import 'package:board_app/core/widgets/app_state_widgets.dart';
import 'package:intl/intl.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Board Details'),
        actions: [
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
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
        ),
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

    return _buildBoard(state);
  }

  Widget _buildBoard(BoardDetailState state) {
    if (state.columns.isEmpty) {
      return AppEmptyState(
        icon: Icons.view_column_outlined,
        title: 'Empty Board',
        description:
            'Start by adding a column (like "To Do" or "Done") to organize your tasks.',
        actionLabel: 'Add First Column',
        onAction: () => _showColumnBottomSheet(context),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      itemCount: state.columns.length,
      itemBuilder: (context, index) {
        final column = state.columns[index];
        final cards = state.cardsByColumn[column.id] ?? [];
        return _BoardColumn(
          column: column,
          cards: cards,
          boardId: widget.boardId,
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
      builder: (context) => _BaseFormBottomSheet(
        title: column == null ? 'Add Column' : 'Rename Column',
        submitLabel: column == null ? 'Add' : 'Rename',
        onSubmit: () async {
          if (controller.text.isNotEmpty) {
            if (column == null) {
              await ref
                  .read(workspaceNotifierProvider.notifier)
                  .addColumn(widget.boardId, controller.text.trim());
            } else {
              await ref
                  .read(workspaceNotifierProvider.notifier)
                  .updateColumn(
                    widget.boardId,
                    column.id,
                    controller.text.trim(),
                  );
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
}

class _BoardColumn extends ConsumerWidget {
  final BoardColumn column;
  final List<BoardCard> cards;
  final String boardId;

  const _BoardColumn({
    required this.column,
    required this.cards,
    required this.boardId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DragTarget<BoardCard>(
      onWillAcceptWithDetails: (details) => details.data.columnId != column.id,
      onAcceptWithDetails: (details) {
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
                ? AppTheme.primaryColor.withOpacity(0.1)
                : (Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[900]?.withOpacity(0.5)
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
                          _showDeleteColumnConfirmation(context, ref);
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
                  itemCount: cards.length,
                  itemBuilder: (context, index) =>
                      _CardItem(card: cards[index], boardId: boardId),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton.icon(
                  onPressed: () => _showCardFormBottomSheet(context, ref),
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

  void _showDeleteColumnConfirmation(BuildContext context, WidgetRef ref) {
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
                                      .deleteColumn(boardId, column.id);
                                  if (context.mounted) Navigator.pop(context);
                                } finally {
                                  if (context.mounted)
                                    setState(() => isDeleting = false);
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
    WidgetRef ref, {
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
      builder: (context) => _BaseFormBottomSheet(
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
                    boardId,
                    column.id,
                    titleController.text.trim(),
                    descController.text.trim(),
                    tags: tags,
                    dueDate: selectedDate,
                  );
            } else {
              await ref
                  .read(workspaceNotifierProvider.notifier)
                  .updateCard(
                    boardId,
                    card.copyWith(
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      tags: tags,
                      dueDate: selectedDate,
                    ),
                  );
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
                        final columnState = context
                            .findAncestorWidgetOfExactType<_BoardColumn>();
                        if (columnState != null) {
                          columnState._showCardFormBottomSheet(
                            context,
                            ref,
                            card: card,
                          );
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
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 280, child: cardWidget),
      ),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer(
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: Text(
                                      'No comments yet',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ),
                              )
                            : SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final comment = displayCard.comments[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: AppTheme.primaryColor
                                              .withOpacity(0.1),
                                          child: Text(
                                            comment.userName.isNotEmpty
                                                ? comment.userName[0]
                                                      .toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    comment.userName,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    DateFormat(
                                                      'MMM d, HH:mm',
                                                    ).format(comment.createdAt),
                                                    style: TextStyle(
                                                      color: Colors.grey[500],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                comment.text,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }, childCount: displayCard.comments.length),
                              ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
                        color: Colors.black.withOpacity(0.05),
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
                          decoration: InputDecoration(
                            hintText: 'Write a comment...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800]
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
                      IconButton(
                        onPressed: () async {
                          if (commentController.text.trim().isNotEmpty) {
                            final text = commentController.text.trim();
                            commentController.clear();
                            await ref
                                .read(workspaceNotifierProvider.notifier)
                                .addComment(boardId, displayCard, text);
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
                                  if (context.mounted) Navigator.pop(context);
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
        color: AppTheme.primaryColor.withOpacity(0.1),
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
                        if (mounted) Navigator.pop(context);
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
