import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Music Base')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Music library',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'The Windows foundation is ready for library and playback services.',
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Library source'),
              subtitle: const Text('No music source configured yet.'),
              trailing: FilledButton(
                onPressed: null,
                child: const Text('Configure later'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
