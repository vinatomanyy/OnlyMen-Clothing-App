import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/product.dart';
import '../models/branch.dart';
import '../models/review.dart';
import '../models/promotion.dart';
import '../models/lookbook.dart';

class MockRepository {
  // Flutter web prepends 'assets/' automatically — avoid the double prefix.
  static Future<String> _load(String path) {
    final key = kIsWeb ? path.replaceFirst('assets/', '') : path;
    return rootBundle.loadString(key);
  }

  static Future<List<Product>> getProducts() async {
    final data = await _load('assets/mock/products.json');
    final list = jsonDecode(data) as List;
    return list.map((e) => Product.fromJson(e)).toList();
  }

  static Future<List<Branch>> getBranches() async {
    final data = await _load('assets/mock/branches.json');
    final list = jsonDecode(data) as List;
    return list.map((e) => Branch.fromJson(e)).toList();
  }

  static Future<List<Review>> getReviews({String? productId}) async {
    final data = await _load('assets/mock/reviews.json');
    final list = jsonDecode(data) as List;
    final reviews = list.map((e) => Review.fromJson(e)).toList();
    if (productId != null) {
      return reviews.where((r) => r.productId == productId).toList();
    }
    return reviews;
  }

  static Future<List<Promotion>> getPromotions() async {
    final data = await _load('assets/mock/promotions.json');
    final list = jsonDecode(data) as List;
    return list.map((e) => Promotion.fromJson(e)).toList();
  }

  static Future<List<Lookbook>> getLookbooks() async {
    final data = await _load('assets/mock/lookbooks.json');
    final list = jsonDecode(data) as List;
    return list.map((e) => Lookbook.fromJson(e)).toList();
  }
}