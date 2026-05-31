import 'package:uniswap/models/listing.dart';

class ListingRepository {
  Future<List<Listing>> fetchFeatured() async {
    return _seedListings();
  }

  Future<List<Listing>> fetchNearby() async {
    return _seedListings();
  }

  Future<List<Listing>> search({String query = ''}) async {
    return _seedListings();
  }

  List<Listing> _seedListings() {
    return const [
      Listing(
        id: '1',
        title: 'Calculus Textbook',
        price: 'RM 45',
        condition: 'Good',
        imageUrl: 'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f',
        sellerName: 'Siti Aisyah',
      ),
      Listing(
        id: '2',
        title: 'Sony WH-1000XM5',
        price: 'RM 320',
        condition: 'Like New',
        imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e',
        sellerName: 'Ahmad Razif',
      ),
      Listing(
        id: '3',
        title: 'Vintage Denim Jacket',
        price: 'RM 55',
        condition: 'Good',
        imageUrl: 'https://images.unsplash.com/photo-1512436991641-6745cdb1723f',
        sellerName: 'Siti Aisyah',
      ),
      Listing(
        id: '4',
        title: 'Dell XPS 13',
        price: 'RM 1500',
        condition: 'Like New',
        imageUrl: 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8',
        sellerName: 'Ahmad Rafli',
      ),
    ];
  }
}
