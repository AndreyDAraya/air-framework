import 'package:flutter_test/flutter_test.dart';
import 'package:air_framework/framework/communication/event_bus.dart';

// Custom test event
class TestEvent extends ModuleEvent {
  final String message;

  TestEvent({required super.sourceModuleId, required this.message});
}

class AnotherEvent extends ModuleEvent {
  final int value;

  AnotherEvent({required super.sourceModuleId, required this.value});
}

void main() {
  // Initialize binding for tests that use SchedulerBinding
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EventBus Subscription Tests', () {
    setUp(() {
      EventBus().clearAll();
    });

    test('Subscribe and receive event', () {
      String? receivedMessage;

      EventBus().on<TestEvent>((event) {
        receivedMessage = event.message;
      });

      EventBus().emit(TestEvent(sourceModuleId: 'test', message: 'hello'));

      expect(receivedMessage, 'hello');
    });

    test('Subscribe to specific event type only', () {
      int testEventCount = 0;
      int anotherEventCount = 0;

      EventBus().on<TestEvent>((event) {
        testEventCount++;
      });

      EventBus().on<AnotherEvent>((event) {
        anotherEventCount++;
      });

      EventBus().emit(TestEvent(sourceModuleId: 'test', message: 'hello'));

      expect(testEventCount, 1);
      expect(anotherEventCount, 0);
    });

    test('Multiple subscribers receive same event', () {
      int subscriber1 = 0;
      int subscriber2 = 0;

      EventBus().on<TestEvent>((event) {
        subscriber1++;
      });

      EventBus().on<TestEvent>((event) {
        subscriber2++;
      });

      EventBus().emit(TestEvent(sourceModuleId: 'test', message: 'hello'));

      expect(subscriber1, 1);
      expect(subscriber2, 1);
    });

    test('Cancel subscription stops receiving events', () {
      int count = 0;

      final subscription = EventBus().on<TestEvent>((event) {
        count++;
      });

      EventBus().emit(TestEvent(sourceModuleId: 'test', message: 'first'));
      EventBus().cancel(subscription);
      EventBus().emit(TestEvent(sourceModuleId: 'test', message: 'second'));

      expect(count, 1);
    });

    test('hasSubscribers returns correct status', () {
      expect(EventBus().hasSubscribers<TestEvent>(), isFalse);

      EventBus().on<TestEvent>((event) {});

      expect(EventBus().hasSubscribers<TestEvent>(), isTrue);
    });

    test('subscriberCount returns correct count', () {
      expect(EventBus().subscriberCount<TestEvent>(), 0);

      EventBus().on<TestEvent>((event) {});
      EventBus().on<TestEvent>((event) {});

      expect(EventBus().subscriberCount<TestEvent>(), 2);
    });
  });

  group('EventBus Signal Tests', () {
    setUp(() {
      EventBus().clearAll();
    });

    test('Emit and receive signal', () {
      dynamic receivedData;

      EventBus().onSignal('test.signal', (data) {
        receivedData = data;
      });

      EventBus().emitSignal('test.signal', data: 'hello');

      expect(receivedData, 'hello');
    });

    test('Signal with map data', () {
      Map<String, dynamic>? receivedData;

      EventBus().onSignal('user.login', (data) {
        receivedData = data as Map<String, dynamic>;
      });

      EventBus().emitSignal('user.login', data: {'email': 'test@test.com'});

      expect(receivedData?['email'], 'test@test.com');
    });

    test('Signal without data', () {
      bool called = false;

      EventBus().onSignal('app.refresh', (data) {
        called = true;
      });

      EventBus().emitSignal('app.refresh');

      expect(called, isTrue);
    });
  });

  group('EventBus Module Cleanup Tests', () {
    setUp(() {
      EventBus().clearAll();
    });

    test('Cancel all subscriptions from a module', () {
      int module1Count = 0;
      int module2Count = 0;

      EventBus().on<TestEvent>((event) {
        module1Count++;
      }, subscriberModuleId: 'module1');

      EventBus().on<TestEvent>((event) {
        module2Count++;
      }, subscriberModuleId: 'module2');

      EventBus().cancelModuleSubscriptions('module1');
      EventBus().emit(TestEvent(sourceModuleId: 'test', message: 'hello'));

      expect(module1Count, 0);
      expect(module2Count, 1);
    });

    test('Cancel module signal subscriptions', () {
      int count = 0;

      EventBus().onSignal('test.signal', (data) {
        count++;
      }, subscriberModuleId: 'module1');

      EventBus().cancelModuleSubscriptions('module1');
      EventBus().emitSignal('test.signal');

      expect(count, 0);
    });
  });

  group('EventBus History Tests', () {
    setUp(() {
      EventBus().clearAll();
    });

    test('Event history is recorded', () {
      EventBus().emit(TestEvent(sourceModuleId: 'test', message: 'hello'));

      expect(EventBus().eventHistory.length, 1);
    });

    test('Signal history is recorded', () {
      EventBus().emitSignal('test.signal', data: 'hello');

      expect(EventBus().signalHistory.length, 1);
      expect(EventBus().signalHistory.first.name, 'test.signal');
    });

    test('Get recent events of specific type', () {
      EventBus().emit(TestEvent(sourceModuleId: 'test', message: 'first'));
      EventBus().emit(AnotherEvent(sourceModuleId: 'test', value: 1));
      EventBus().emit(TestEvent(sourceModuleId: 'test', message: 'second'));

      final recentTestEvents = EventBus().getRecentEvents<TestEvent>();

      expect(recentTestEvents.length, 2);
    });
  });

  group('EventBus Async Emit Tests', () {
    setUp(() {
      EventBus().clearAll();
    });

    test('Emit async delivers event', () async {
      String? receivedMessage;

      EventBus().on<TestEvent>((event) {
        receivedMessage = event.message;
      });

      await EventBus().emitAsync(
        TestEvent(sourceModuleId: 'test', message: 'async hello'),
      );

      expect(receivedMessage, 'async hello');
    });
  });

  group('EventBus Middleware Tests', () {
    test('Add event middleware increases count', () {
      final initialCount = EventBus().eventMiddlewareCount;

      EventBus().addMiddleware((event, next) {
        next(event);
      });

      expect(EventBus().eventMiddlewareCount, initialCount + 1);
    });

    test('Add signal middleware increases count', () {
      final initialCount = EventBus().signalMiddlewareCount;

      EventBus().addSignalMiddleware((name, data, next) {
        next(name, data);
      });

      expect(EventBus().signalMiddlewareCount, initialCount + 1);
    });
  });
}
