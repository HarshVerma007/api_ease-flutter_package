import 'package:api_ease/api_ease.dart';
import 'package:flutter/material.dart';

import 'app_config.dart';
import 'examples/custom_dialog_example.dart';
import 'examples/declarative_widget_example.dart';
import 'examples/pagination_example.dart';
import 'examples/result_pattern_example.dart';
import 'examples/retry_example.dart';
import 'examples/simple_call_example.dart';

void main() {
  // One-time setup. Everything is optional: ApiEase works without init().
  ApiEase.init(config: kExampleConfig);
  runApp(const ApiEaseExampleApp());
}

class ApiEaseExampleApp extends StatelessWidget {
  const ApiEaseExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'api_ease example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3F51B5)),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F51B5),
          brightness: Brightness.dark,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  static const _titles = [
    'Simple Call',
    'Result Pattern',
    'Declarative Widget',
    'Retry Demo',
    'Custom Dialog',
  ];

  Widget _body() {
    switch (_index) {
      case 0:
        return const SimpleCallExample();
      case 1:
        return const ResultPatternExample();
      case 2:
        return const DeclarativeWidgetExample();
      case 3:
        return const RetryExample();
      default:
        return const CustomDialogExample();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Pagination example',
            icon: const Icon(Icons.view_list_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const PaginationExample(),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(child: _body()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bolt_outlined),
            selectedIcon: Icon(Icons.bolt),
            label: 'Call',
          ),
          NavigationDestination(
            icon: Icon(Icons.rule_outlined),
            selectedIcon: Icon(Icons.rule),
            label: 'Result',
          ),
          NavigationDestination(
            icon: Icon(Icons.widgets_outlined),
            selectedIcon: Icon(Icons.widgets),
            label: 'Widget',
          ),
          NavigationDestination(
            icon: Icon(Icons.replay_outlined),
            selectedIcon: Icon(Icons.replay),
            label: 'Retry',
          ),
          NavigationDestination(
            icon: Icon(Icons.wifi_off_outlined),
            selectedIcon: Icon(Icons.wifi_off),
            label: 'Dialog',
          ),
        ],
      ),
    );
  }
}
