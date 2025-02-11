import 'package:flutter/material.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filters
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: 10, // TODO: Replace with actual data
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Image.network(
                  'https://picsum.photos/seed/$index/400/200',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                ListTile(
                  title: Text('Event ${index + 1}'),
                  subtitle: const Text('Date • Time • Location'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement booking
                    },
                    child: const Text('Book'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Create new event
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
