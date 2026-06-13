import 'package:flutter/material.dart';
class ReviewsScreen extends StatelessWidget {
  final String productId;
  const ReviewsScreen({super.key, required this.productId});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Reviews: $productId')));
}