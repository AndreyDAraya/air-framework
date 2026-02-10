import 'package:flutter/foundation.dart';
import '../state/air.dart';
import '../communication/event_bus.dart';
import '../di/di.dart';

/// CLI interface for DevTools
/// MEJORA-015: CLI Interactivo
///
/// Provides a command-line interface for debugging and interacting with
/// the Air Framework at runtime.
///
/// Example:
/// ```dart
/// final cli = DevToolsCLI();
///
/// // Process commands
/// cli.execute('state get user.profile');
/// cli.execute('pulse auth.logout');
/// cli.execute('di list');
/// cli.execute('help');
/// ```
class DevToolsCLI {
  static final DevToolsCLI _instance = DevToolsCLI._();
  factory DevToolsCLI() => _instance;
  DevToolsCLI._();

  /// Command history
  final List<String> _history = [];
  final int _maxHistory = 100;

  /// Get command history
  List<String> get history => List.unmodifiable(_history);

  /// Execute a command and return the result
  CLIResult execute(String command) {
    if (!kDebugMode) {
      return CLIResult.error('DevTools CLI is only available in debug mode');
    }

    // Add to history
    _history.add(command);
    if (_history.length > _maxHistory) {
      _history.removeAt(0);
    }

    final parts = command.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) {
      return CLIResult.error('Empty command');
    }

    final cmd = parts[0].toLowerCase();
    final args = parts.length > 1 ? parts.sublist(1) : <String>[];

    try {
      switch (cmd) {
        case 'help':
        case '?':
          return _help();
        case 'state':
          return _state(args);
        case 'pulse':
          return _pulse(args);
        case 'di':
          return _di(args);
        case 'events':
          return _events(args);
        case 'clear':
          return _clear(args);
        case 'history':
          return _showHistory();
        default:
          return CLIResult.error(
            'Unknown command: $cmd. Type "help" for available commands.',
          );
      }
    } catch (e) {
      return CLIResult.error('Error: $e');
    }
  }

  CLIResult _help() {
    return CLIResult.success('''
Air DevTools CLI Commands:

  state get <key>        - Get state value
  state set <key> <json> - Set state value (JSON format)
  state list             - List all state keys
  state remove <key>     - Remove state key

  pulse <signal> [json]  - Emit a signal with optional data

  di list                - List registered dependencies
  di get <type>          - Check if dependency is registered

  snap start             - Start recording snapshots
  snap stop              - Stop recording
  snap list              - List snapshots
  snap jump <index>      - Jump to snapshot

  events history         - Show event history
  events signals         - Show signal history

  clear state            - Clear all state
  clear history          - Clear command history

  history                - Show command history
  help                   - Show this help
''');
  }

  CLIResult _state(List<String> args) {
    if (args.isEmpty) {
      return CLIResult.error(
        'Usage: state <get|set|list|remove> [key] [value]',
      );
    }

    final subCmd = args[0].toLowerCase();

    switch (subCmd) {
      case 'get':
        if (args.length < 2) {
          return CLIResult.error('Usage: state get <key>');
        }
        final key = args[1];
        final controller = Air().debugStates[key];
        if (controller == null) {
          return CLIResult.error('State "$key" not found');
        }
        return CLIResult.success('$key = ${controller.value}');

      case 'set':
        if (args.length < 3) {
          return CLIResult.error('Usage: state set <key> <value>');
        }
        final key = args[1];
        final valueStr = args.sublist(2).join(' ');
        // Try to parse as JSON, otherwise use string
        dynamic value;
        try {
          // Simple value parsing
          if (valueStr == 'true') {
            value = true;
          } else if (valueStr == 'false') {
            value = false;
          } else if (valueStr == 'null') {
            value = null;
          } else if (double.tryParse(valueStr) != null) {
            value = double.parse(valueStr);
          } else {
            value = valueStr;
          }
        } catch (_) {
          value = valueStr;
        }
        Air()
            .state(key, initialValue: value)
            .setValue(value, sourceModuleId: 'cli');
        return CLIResult.success('Set $key = $value');

      case 'list':
        final keys = Air().debugStates.keys.toList()..sort();
        if (keys.isEmpty) {
          return CLIResult.success('No state keys registered');
        }
        return CLIResult.success(
          'State keys:\n${keys.map((k) => '  - $k').join('\n')}',
        );

      case 'remove':
        if (args.length < 2) {
          return CLIResult.error('Usage: state remove <key>');
        }
        final key = args[1];
        Air().dispose(key);
        return CLIResult.success('Removed state "$key"');

      default:
        return CLIResult.error('Unknown state subcommand: $subCmd');
    }
  }

  CLIResult _pulse(List<String> args) {
    if (args.isEmpty) {
      return CLIResult.error('Usage: pulse <signal> [data]');
    }

    final signal = args[0];
    dynamic data;

    if (args.length > 1) {
      final dataStr = args.sublist(1).join(' ');
      // Simple value parsing
      if (dataStr == 'true') {
        data = true;
      } else if (dataStr == 'false') {
        data = false;
      } else if (dataStr == 'null') {
        data = null;
      } else if (double.tryParse(dataStr) != null) {
        data = double.parse(dataStr);
      } else {
        data = dataStr;
      }
    }

    Air().pulse(action: signal, params: data, sourceModuleId: 'cli');
    return CLIResult.success(
      'Emitted pulse "$signal"${data != null ? " with data: $data" : ""}',
    );
  }

  CLIResult _di(List<String> args) {
    if (args.isEmpty) {
      return CLIResult.error('Usage: di <list|get> [type]');
    }

    final subCmd = args[0].toLowerCase();

    switch (subCmd) {
      case 'list':
        final types = AirDI().debugRegisteredTypes;
        if (types.isEmpty) {
          return CLIResult.success('No dependencies registered');
        }
        return CLIResult.success(
          'Registered types:\n${types.map((t) => '  - $t').join('\n')}',
        );

      case 'info':
        final info = AirDI().debugRegistrationInfo;
        if (info.isEmpty) {
          return CLIResult.success('No dependencies registered');
        }
        final lines = info.entries.map(
          (e) => '  - ${e.key} (owner: ${e.value ?? "unknown"})',
        );
        return CLIResult.success('Dependencies:\n${lines.join('\n')}');

      default:
        return CLIResult.error('Unknown di subcommand: $subCmd');
    }
  }

  CLIResult _events(List<String> args) {
    if (args.isEmpty) {
      return CLIResult.error('Usage: events <history|signals>');
    }

    final subCmd = args[0].toLowerCase();

    switch (subCmd) {
      case 'history':
        final events = EventBus().eventHistory;
        if (events.isEmpty) {
          return CLIResult.success('No events in history');
        }
        final lines = events.map(
          (e) => '  ${e.timestamp} - ${e.runtimeType} from ${e.sourceModuleId}',
        );
        return CLIResult.success('Event history:\n${lines.join('\n')}');

      case 'signals':
        final signals = EventBus().signalHistory;
        if (signals.isEmpty) {
          return CLIResult.success('No signals in history');
        }
        final lines = signals.map(
          (s) =>
              '  ${s.timestamp} - "${s.name}" from ${s.sourceModuleId ?? "unknown"}',
        );
        return CLIResult.success('Signal history:\n${lines.join('\n')}');

      default:
        return CLIResult.error('Unknown events subcommand: $subCmd');
    }
  }

  CLIResult _clear(List<String> args) {
    if (args.isEmpty) {
      return CLIResult.error('Usage: clear <state|history>');
    }

    final subCmd = args[0].toLowerCase();

    switch (subCmd) {
      case 'state':
        Air().clear();
        return CLIResult.success('Cleared all state');

      case 'history':
        _history.clear();
        return CLIResult.success('Cleared command history');

      default:
        return CLIResult.error('Unknown clear subcommand: $subCmd');
    }
  }

  CLIResult _showHistory() {
    if (_history.isEmpty) {
      return CLIResult.success('No command history');
    }
    final lines = _history.asMap().entries.map(
      (e) => '  [${e.key}] ${e.value}',
    );
    return CLIResult.success('Command history:\n${lines.join('\n')}');
  }
}

/// Result of a CLI command
class CLIResult {
  final bool success;
  final String message;

  CLIResult._(this.success, this.message);

  factory CLIResult.success(String message) => CLIResult._(true, message);
  factory CLIResult.error(String message) => CLIResult._(false, message);

  @override
  String toString() => message;
}
