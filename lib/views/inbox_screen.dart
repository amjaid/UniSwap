import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uniswap/models/conversation_thread.dart';
import 'package:uniswap/viewmodels/inbox_viewmodel.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inboxViewModelProvider);
    final viewModel = ref.read(inboxViewModelProvider.notifier);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inbox'),
          bottom: TabBar(
            onTap: (index) {
              switch (index) {
                case 0:
                  viewModel.setFilter(ThreadCategory.all);
                  break;
                case 1:
                  viewModel.setFilter(ThreadCategory.buying);
                  break;
                case 2:
                  viewModel.setFilter(ThreadCategory.selling);
                  break;
              }
            },
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Buying'),
              Tab(text: 'Selling'),
            ],
          ),
        ),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.errorMessage != null
                ? Center(child: Text(state.errorMessage!))
                : _InboxList(
                    threads: viewModel.filteredThreads(),
                    onTap: (thread) => context.go('/chat/${thread.id}'),
                  ),
      ),
    );
  }
}

class _InboxList extends StatelessWidget {
  const _InboxList({required this.threads, required this.onTap});

  final List<ConversationThread> threads;
  final ValueChanged<ConversationThread> onTap;

  @override
  Widget build(BuildContext context) {
    if (threads.isEmpty) {
      return const Center(child: Text('No conversations yet.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: threads.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final thread = threads[index];
        return _ThreadTile(thread: thread, onTap: () => onTap(thread));
      },
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.thread, required this.onTap});

  final ConversationThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      leading: CircleAvatar(backgroundImage: NetworkImage(thread.contactAvatarUrl)),
      title: Row(
        children: [
          Expanded(child: Text(thread.contactName)),
          if (thread.isVerified) const Icon(Icons.verified, size: 16, color: Colors.blue),
        ],
      ),
      subtitle: Text(thread.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_formatTime(thread.lastTimestamp), style: Theme.of(context).textTheme.bodySmall),
          if (thread.unreadCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                thread.unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _formatTime(DateTime timestamp) {
  final now = DateTime.now();
  if (now.difference(timestamp).inDays >= 1) {
    return '${timestamp.month}/${timestamp.day}';
  }
  final hour = timestamp.hour.toString().padLeft(2, '0');
  final minute = timestamp.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
