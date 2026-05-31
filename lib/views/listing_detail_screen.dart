import 'package:flutter/material.dart';

class ListingDetailScreen extends StatelessWidget {
  const ListingDetailScreen({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f',
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Text('Calculus Textbook', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text('RM 45', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: const [
              Chip(label: Text('Good')),
              Chip(label: Text('Textbook')),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1500648767791-00dcc994a43e'),
            ),
            title: const Text('Siti Aisyah'),
            subtitle: const Text('UTM Johor'),
            trailing: ElevatedButton(
              onPressed: () {},
              child: const Text('Chat'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Includes notes and highlights. Pickup at UTM library or COD nearby campus.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Start swap'),
          ),
        ],
      ),
    );
  }
}
