import 'package:uniswap/models/swap.dart';

class SwapRepository {
  SwapRepository() : _swaps = List<Swap>.from(_seedSwaps());

  final List<Swap> _swaps;

  List<Swap> fetchSwaps() {
    return List<Swap>.from(_swaps)
      ..sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
  }

  Swap? getById(String id) {
    try {
      return _swaps.firstWhere((swap) => swap.id == id);
    } catch (_) {
      return null;
    }
  }

  void updateStatus(String id, SwapStatus status) {
    final index = _swaps.indexWhere((swap) => swap.id == id);
    if (index == -1) return;
    _swaps[index] = _swaps[index].copyWith(
      status: status,
      lastUpdated: DateTime.now(),
    );
  }

  void updateMeetupLocation(String id, String location) {
    final index = _swaps.indexWhere((swap) => swap.id == id);
    if (index == -1) return;
    _swaps[index] = _swaps[index].copyWith(
      meetupLocation: location,
      lastUpdated: DateTime.now(),
    );
  }

  Swap createSwap({
    required String title,
    required String imageUrl,
    required String otherUserName,
    required String otherUserContact,
    SwapRole role = SwapRole.buying,
  }) {
    final swap = Swap(
      id: 'swap_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      imageUrl: imageUrl,
      otherUserName: otherUserName,
      otherUserAvatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
      otherUserContact: otherUserContact,
      role: role,
      status: SwapStatus.proposalSent,
      meetupLocation: null,
      lastUpdated: DateTime.now(),
    );
    _swaps.insert(0, swap);
    return swap;
  }

  static List<Swap> _seedSwaps() {
    return [
      Swap(
        id: 'swap_1',
        title: 'Calculus Textbook',
        imageUrl: 'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f',
        otherUserName: 'utm_trader',
        otherUserAvatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
        otherUserContact: 'utm_trader@utm.my',
        role: SwapRole.buying,
        status: SwapStatus.proposalSent,
        meetupLocation: null,
        lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Swap(
        id: 'swap_2',
        title: 'Sony WH-1000XM5',
        imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e',
        otherUserName: 'utm_seller',
        otherUserAvatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
        otherUserContact: 'utm_seller@utm.my',
        role: SwapRole.buying,
        status: SwapStatus.accepted,
        meetupLocation: null,
        lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Swap(
        id: 'swap_3',
        title: 'Vintage Denim Jacket',
        imageUrl: 'https://images.unsplash.com/photo-1512436991641-6745cdb1723f',
        otherUserName: 'utm_buyer',
        otherUserAvatarUrl: 'https://images.unsplash.com/photo-1544723795-3fb6469f5b39',
        otherUserContact: 'utm_buyer@utm.my',
        role: SwapRole.selling,
        status: SwapStatus.meetupArranged,
        meetupLocation: 'UTM Library Lobby',
        lastUpdated: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Swap(
        id: 'swap_4',
        title: 'Desk Lamp',
        imageUrl: 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c',
        otherUserName: 'utm_swapper',
        otherUserAvatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
        otherUserContact: 'utm_swapper@utm.my',
        role: SwapRole.selling,
        status: SwapStatus.completed,
        meetupLocation: 'Faculty Lounge',
        lastUpdated: DateTime.now().subtract(const Duration(days: 6)),
      ),
    ];
  }
}
