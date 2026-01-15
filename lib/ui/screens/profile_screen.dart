import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quote_vault/data/repositories/auth_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.read(authRepositoryProvider).currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          CircleAvatar(
            radius: 40,
            child: Text(
              user?.email?.substring(0, 1).toUpperCase() ?? 'U',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.userMetadata?['name'] ?? 'User',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            user?.email ?? '',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.red),
            title: const Text('My Favorites'),
            onTap: () {
              context.push('/favorites');
            },
          ),
          ListTile(
            leading: const Icon(Icons.style), // or collections icon
            title: const Text('My Collections'),
            onTap: () => context.push('/collections'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => context.push('/settings'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFBA1A1A)),
            title: const Text(
              'Logout',
              style: TextStyle(color: Color(0xFFBA1A1A)),
            ),
            onTap: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) {
                // GoRouter redirect should handle this, but explicit help doesn't hurt
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}
