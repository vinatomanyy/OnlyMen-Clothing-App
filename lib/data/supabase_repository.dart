import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/branch.dart';
import '../models/review.dart';
import '../models/promotion.dart';
import '../models/lookbook.dart';
import '../models/booking.dart';
import '../models/order.dart';
import 'mock_repository.dart';

class SupabaseRepository {
  static final _client = Supabase.instance.client;

  // ── Products ──────────────────────────────────────────────
  static Future<List<Product>> getProducts() async {
    try {
      final res = await _client
          .from('products')
          .select()
          .order('id', ascending: true);
      final list = (res as List).map((e) => Product.fromJson(e)).toList();
      if (list.isEmpty) return MockRepository.getProducts();
      return list;
    } catch (_) {
      return MockRepository.getProducts();
    }
  }

  static Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final res = await _client
          .from('products')
          .select()
          .eq('category', category)
          .order('id', ascending: true);
      final list = (res as List).map((e) => Product.fromJson(e)).toList();
      if (list.isEmpty) {
        final all = await MockRepository.getProducts();
        return all.where((p) => p.category == category).toList();
      }
      return list;
    } catch (_) {
      final all = await MockRepository.getProducts();
      return all.where((p) => p.category == category).toList();
    }
  }

  static Future<List<Product>> getBestsellers() async {
    try {
      final res = await _client
          .from('products')
          .select()
          .eq('is_bestseller', true)
          .order('id', ascending: true);
      final list = (res as List).map((e) => Product.fromJson(e)).toList();
      if (list.isEmpty) {
        final all = await MockRepository.getProducts();
        return all.where((p) => p.isBestseller).toList();
      }
      return list;
    } catch (_) {
      final all = await MockRepository.getProducts();
      return all.where((p) => p.isBestseller).toList();
    }
  }

  static Future<List<Product>> getNewArrivals() async {
    try {
      final res = await _client
          .from('products')
          .select()
          .eq('is_new', true)
          .order('id', ascending: true);
      final list = (res as List).map((e) => Product.fromJson(e)).toList();
      if (list.isEmpty) {
        final all = await MockRepository.getProducts();
        return all.where((p) => p.isNew).toList();
      }
      return list;
    } catch (_) {
      final all = await MockRepository.getProducts();
      return all.where((p) => p.isNew).toList();
    }
  }

  static Future<Product?> getProductById(String id) async {
    try {
      final res = await _client
          .from('products')
          .select()
          .eq('id', id)
          .single();
      return Product.fromJson(res);
    } catch (_) {
      final all = await MockRepository.getProducts();
      try {
        return all.firstWhere((p) => p.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  static Future<List<Product>> searchProducts(String query) async {
    try {
      final res = await _client
          .from('products')
          .select()
          .ilike('name', '%$query%')
          .order('id', ascending: true);
      return (res as List).map((e) => Product.fromJson(e)).toList();
    } catch (_) {
      final all = await MockRepository.getProducts();
      return all
          .where((p) =>
              p.name.toLowerCase().contains(query.toLowerCase()) ||
              p.brand.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  // ── Branches ──────────────────────────────────────────────
  static Future<List<Branch>> getBranches() async {
    try {
      final res = await _client
          .from('branches')
          .select()
          .order('distance_km', ascending: true);
      return (res as List).map((e) => Branch.fromJson(e)).toList();
    } catch (_) {
      return MockRepository.getBranches();
    }
  }

  // ── Reviews ───────────────────────────────────────────────
  static Future<List<Review>> getReviews({String? productId}) async {
    try {
      var query = _client.from('reviews').select();
      if (productId != null) {
        query = query.eq('product_id', productId);
      }
      final res = await query.order('created_at', ascending: false);
      return (res as List).map((e) => Review.fromJson(e)).toList();
    } catch (_) {
      return MockRepository.getReviews(productId: productId);
    }
  }

  // ── Promotions ────────────────────────────────────────────
  static Future<List<Promotion>> getPromotions() async {
    try {
      final res = await _client.from('promotions').select();
      return (res as List).map((e) => Promotion.fromJson(e)).toList();
    } catch (_) {
      return MockRepository.getPromotions();
    }
  }

  // ── Lookbooks ─────────────────────────────────────────────
  static Future<List<Lookbook>> getLookbooks() async {
    try {
      final res = await _client.from('lookbooks').select();
      return (res as List).map((e) => Lookbook.fromJson(e)).toList();
    } catch (_) {
      return MockRepository.getLookbooks();
    }
  }

  // ── Bookings ──────────────────────────────────────────────
  static Future<bool> createBooking(Booking booking) async {
    try {
      await _client.from('bookings').insert(booking.toJson());
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Orders ────────────────────────────────────────────────
  static Future<bool> createOrder(Order order) async {
    try {
      await _client.from('orders').insert(order.toJson());
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Create Review ─────────────────────────────────────────
  static Future<bool> createReview(Review review) async {
    try {
      await _client.from('reviews').insert(review.toJson());
      return true;
    } catch (_) {
      return false;
    }
  }
}