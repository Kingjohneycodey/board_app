import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:board_app/features/workspace/providers/workspace_provider.dart';
import 'package:board_app/core/models/board_models.dart';
import 'package:board_app/core/theme/app_theme.dart';
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
            onPressed: () => _showAddColumnDialog(context),
          ),
        ],
      ),
      body: detailState == null || detailState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBoard(detailState),
    );
  }

  Widget _buildBoard(BoardDetailState state) {
    if (state.columns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No columns yet'),
            ElevatedButton(
              onPressed: () => _showAddColumnDialog(context),
              child: const Text('Add Column'),
            ),
          ],
        ),
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

  void _showAddColumnDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Column'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Column Title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref
                    .read(workspaceNotifierProvider.notifier)
                    .addColumn(widget.boardId, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
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
                    Text(
                      column.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${cards.length}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
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
                  onPressed: () => _showAddCardDialog(context, ref),
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

  void _showAddCardDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Card'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(hintText: 'Title'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(hintText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                ref
                    .read(workspaceNotifierProvider.notifier)
                    .addCard(
                      boardId,
                      column.id,
                      titleController.text,
                      descController.text,
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
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
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => ref
                      .read(workspaceNotifierProvider.notifier)
                      .deleteCard(boardId, card.columnId, card.id),
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
            if (card.dueDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
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
      child: cardWidget,
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
