import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';

enum RealtimeEventType {
  cardUpdated,
  cardMoved,
  cardDeleted,
  columnAdded,
  columnUpdated,
  columnDeleted,
  commentAdded,
}

class RealtimeEvent {
  final RealtimeEventType type;
  final String boardId;
  final String? columnId;
  final String? cardId;
  final dynamic data;

  RealtimeEvent({
    required this.type,
    required this.boardId,
    this.columnId,
    this.cardId,
    this.data,
  });
}

enum ConnectionStatus { connected, connecting, disconnected }

abstract class RealtimeService {
  Stream<RealtimeEvent> get events;
  Stream<ConnectionStatus> get connectionStatus;

  void emit(RealtimeEvent event);
  void connect();
  void disconnect();
}

class SocketIoRealtimeService implements RealtimeService {
  late IO.Socket socket;
  final _eventController = StreamController<RealtimeEvent>.broadcast();
  final _statusController = StreamController<ConnectionStatus>.broadcast();

  // Backend URL
  static const String serverUrl = 'http://localhost:3000';

  SocketIoRealtimeService() {
    connect();
  }

  @override
  Stream<RealtimeEvent> get events => _eventController.stream;

  @override
  Stream<ConnectionStatus> get connectionStatus => _statusController.stream;

  @override
  void connect() {
    _statusController.add(ConnectionStatus.connecting);

    // Initializing the socket
    socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket']) // Required for most implementations
          .enableAutoConnect()
          .build(),
    );

    // Connection lifecycle handlers
    socket.onConnect((_) {
      debugPrint('Real-time Socket.io connected');
      _statusController.add(ConnectionStatus.connected);
    });

    socket.onDisconnect((_) {
      debugPrint('Real-time Socket.io disconnected');
      _statusController.add(ConnectionStatus.disconnected);
    });

    socket.onConnectError((err) {
      _statusController.add(ConnectionStatus.disconnected);
    });

    // Listen for events from other devices
    socket.on('board_update', (data) {
      try {
        final decoded = data is String ? json.decode(data) : data;
        _eventController.add(
          RealtimeEvent(
            type: RealtimeEventType.values.firstWhere(
              (e) =>
                  e.toString().split('.').last ==
                  (decoded['type'] ?? 'cardUpdated'),
              orElse: () => RealtimeEventType.cardUpdated,
            ),
            boardId: decoded['boardId'] ?? 'any',
            columnId: decoded['columnId'],
            cardId: decoded['cardId'],
            data: decoded['payload'],
          ),
        );
      } catch (e) {
        debugPrint('Error parsing real-time event: $e');
      }
    });
  }

  @override
  void emit(RealtimeEvent event) {
    if (socket.connected) {
      socket.emit('board_update', {
        'type': event.type.toString().split('.').last,
        'boardId': event.boardId,
        'columnId': event.columnId,
        'cardId': event.cardId,
        'payload': event.data,
      });
    }
  }

  @override
  void disconnect() {
    socket.disconnect();
  }
}
