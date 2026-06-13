import 'package:flutter/material.dart';
class CategoryScreen extends StatelessWidget {
  final String category;
  const CategoryScreen({super.key, required this.category});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Category: $category')));
}