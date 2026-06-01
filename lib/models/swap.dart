enum SwapStatus {
  proposalSent,
  accepted,
  meetupArranged,
  completed,
  cancelled,
}

enum SwapRole {
  buying,
  selling,
}

class Swap {
  const Swap({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.otherUserName,
    required this.otherUserAvatarUrl,
    required this.otherUserContact,
    required this.role,
    required this.status,
    required this.meetupLocation,
    required this.lastUpdated,
  });

  final String id;
  final String title;
  final String imageUrl;
  final String otherUserName;
  final String otherUserAvatarUrl;
  final String otherUserContact;
  final SwapRole role;
  final SwapStatus status;
  final String? meetupLocation;
  final DateTime lastUpdated;

  Swap copyWith({
    SwapStatus? status,
    String? meetupLocation,
    DateTime? lastUpdated,
  }) {
    return Swap(
      id: id,
      title: title,
      imageUrl: imageUrl,
      otherUserName: otherUserName,
      otherUserAvatarUrl: otherUserAvatarUrl,
      otherUserContact: otherUserContact,
      role: role,
      status: status ?? this.status,
      meetupLocation: meetupLocation ?? this.meetupLocation,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

extension SwapStatusX on SwapStatus {
  String get label {
    switch (this) {
      case SwapStatus.proposalSent:
        return 'Proposal Sent';
      case SwapStatus.accepted:
        return 'Accepted';
      case SwapStatus.meetupArranged:
        return 'Meetup Arranged';
      case SwapStatus.completed:
        return 'Completed';
      case SwapStatus.cancelled:
        return 'Cancelled';
    }
  }

  int get stepIndex {
    switch (this) {
      case SwapStatus.proposalSent:
        return 0;
      case SwapStatus.accepted:
        return 1;
      case SwapStatus.meetupArranged:
        return 2;
      case SwapStatus.completed:
        return 3;
      case SwapStatus.cancelled:
        return 0;
    }
  }

  bool get isTerminal => this == SwapStatus.completed || this == SwapStatus.cancelled;
}

extension SwapRoleX on SwapRole {
  String get label {
    switch (this) {
      case SwapRole.buying:
        return 'Buying';
      case SwapRole.selling:
        return 'Selling';
    }
  }
}
