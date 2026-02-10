# Module Template

```dart
import 'package:air_framework/air_framework.dart';
import 'ui/views/{{snake_name}}_view.dart';
import 'ui/state/state.dart';

class {{PascalName}}Module extends AppModule {
  @override
  String get id => '{{snake_name}}';

  @override
  String get name => '{{PascalName}}';

  @override
  List<AirRoute> get routes => [
    AirRoute(
      path: '/{{snake_name}}',
      builder: (context, state) => const {{PascalName}}View(),
    ),
  ];

  @override
  void onBind(AirDI di) {
    di.registerLazySingleton<{{PascalName}}State>(() => {{PascalName}}State());
  }
}
```

# Screen Template (AirView)

```dart
import 'package:flutter/material.dart';
import 'package:air_framework/air_framework.dart';
import '../state/state.air.g.dart'; // Import generated flows/pulses

class {{PascalName}}View extends StatelessWidget {
  const {{PascalName}}View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{{PascalName}}')),
      body: Center(
        child: AirView((context) {
          // Reactive UI
          return Text('Count: ${{{PascalName}}Flows.count.value}');
        }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => {{PascalName}}Pulses.increment.pulse(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

# State Template

```dart
import 'package:air_framework/air_framework.dart';

part 'state.air.g.dart';

@GenerateState('{{snake_name}}')
class {{PascalName}}State extends _{{PascalName}}State {
  // Flows (State)
  int _count = 0;

  // Pulses (Actions)
  @override
  void increment() {
    count++;
  }
}
```
