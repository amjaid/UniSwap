import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uniswap/config/theme.dart';
import 'package:uniswap/models/swap.dart';
import 'package:uniswap/viewmodels/swap_detail_viewmodel.dart';

class SwapDetailScreen extends ConsumerStatefulWidget {
  const SwapDetailScreen({super.key, required this.swapId});

  final String swapId;

  @override
  ConsumerState<SwapDetailScreen> createState() => _SwapDetailScreenState();
}

class _SwapDetailScreenState extends ConsumerState<SwapDetailScreen> {
  final _meetupController = TextEditingController();

  @override
  void dispose() {
    _meetupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(swapDetailViewModelProvider(widget.swapId));
    final viewModel = ref.read(swapDetailViewModelProvider(widget.swapId).notifier);
    final swap = state.swap;

    if (swap != null && _meetupController.text.isEmpty && swap.meetupLocation != null) {
      _meetupController.text = swap.meetupLocation!;
    }

    ref.listen<SwapDetailState>(swapDetailViewModelProvider(widget.swapId), (previous, next) {
      final error = next.errorMessage;
      if (error != null && error != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        viewModel.clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Swap Detail')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : swap == null
              ? const Center(child: Text('Swap not found.'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            swap.imageUrl,
                            width: 84,
                            height: 84,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(swap.title, style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 6),
                              _StatusChip(label: swap.status.label),
                              const SizedBox(height: 6),
                              Text('Role: ${swap.role.label}', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Timeline', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _SwapStepper(status: swap.status),
                    const SizedBox(height: 16),
                    if (swap.status != SwapStatus.cancelled && swap.status != SwapStatus.completed) ...[
                      Text('Meetup location', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _meetupController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. UTM Library Lobby',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: swap.status == SwapStatus.accepted
                            ? () => viewModel.arrangeMeetup(_meetupController.text)
                            : null,
                        child: const Text('Set meetup location'),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (swap.status == SwapStatus.accepted || swap.status == SwapStatus.meetupArranged) ...[
                      Text('Contact after acceptance', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(swap.otherUserAvatarUrl),
                        ),
                        title: Text(swap.otherUserName),
                        subtitle: Text(swap.otherUserContact),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (swap.status == SwapStatus.proposalSent) ...[
                      _ActionRow(
                        primaryLabel: 'Accept',
                        onPrimary: viewModel.acceptSwap,
                        secondaryLabel: 'Cancel',
                        onSecondary: viewModel.cancelSwap,
                      ),
                    ] else if (swap.status == SwapStatus.meetupArranged) ...[
                      _ActionRow(
                        primaryLabel: 'Mark completed',
                        onPrimary: viewModel.markCompleted,
                        secondaryLabel: 'Cancel',
                        onSecondary: viewModel.cancelSwap,
                      ),
                    ] else if (swap.status == SwapStatus.accepted) ...[
                      _ActionRow(
                        primaryLabel: 'Cancel',
                        onPrimary: viewModel.cancelSwap,
                        secondaryLabel: null,
                        onSecondary: null,
                      ),
                    ] else if (swap.status == SwapStatus.completed) ...[
                      const Center(child: Text('This swap is completed.')),
                    ] else if (swap.status == SwapStatus.cancelled) ...[
                      const Center(child: Text('This swap was cancelled.')),
                    ],
                  ],
                ),
    );
  }
}

class _SwapStepper extends StatelessWidget {
  const _SwapStepper({required this.status});

  final SwapStatus status;

  @override
  Widget build(BuildContext context) {
    final steps = [
      const Step(title: Text('Proposal Sent'), content: SizedBox.shrink(), isActive: true),
      const Step(title: Text('Accepted'), content: SizedBox.shrink(), isActive: true),
      const Step(title: Text('Meetup Arranged'), content: SizedBox.shrink(), isActive: true),
      const Step(title: Text('Completed'), content: SizedBox.shrink(), isActive: true),
    ];

    return Stepper(
      currentStep: status.stepIndex.clamp(0, steps.length - 1),
      controlsBuilder: (_, __) => const SizedBox.shrink(),
      steps: steps,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: onPrimary,
            child: Text(primaryLabel),
          ),
        ),
        if (secondaryLabel != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: onSecondary,
              child: Text(secondaryLabel!),
            ),
          ),
        ],
      ],
    );
  }
}
