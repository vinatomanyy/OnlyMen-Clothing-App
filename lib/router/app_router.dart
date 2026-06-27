import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home/home_screen.dart';
import '../features/detail/product_detail_screen.dart';
import '../features/category/category_screen.dart';
import '../features/lookbook/lookbook_screen.dart';
import '../features/favorites/favorites_screen.dart';
import '../features/map/map_screen.dart';
import '../features/nearby/nearby_screen.dart';
import '../features/promotions/promotions_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/cart/checkout_screen.dart';

import '../features/reviews/reviews_screen.dart';
import '../features/gallery/gallery_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/search/search_screen.dart';
import '../features/stylist/booking_screen.dart';
import '../widgets/main_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter({bool showOnboarding = false}) => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    // Splash
    GoRoute(
      path: '/splash',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const SplashScreen(),
    ),

    // Onboarding — outside shell
    GoRoute(
      path: '/onboarding',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const OnboardingScreen(),
    ),

    // Main shell with bottom nav
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: '/favorites',
          builder: (context, state) => const FavoritesScreen(),
        ),
        GoRoute(
          path: '/booking',
          builder: (context, state) => const BookingScreen(),
        ),
      ],
    ),

    // Full screen routes — outside shell
    GoRoute(
      path: '/product/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => ProductDetailScreen(
        productId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/category/:name',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => CategoryScreen(
        category: state.pathParameters['name']!,
      ),
    ),
    GoRoute(
      path: '/lookbook',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const LookbookScreen(),
    ),
    GoRoute(
      path: '/map',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const MapScreen(),
    ),
    GoRoute(
      path: '/nearby',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const NearbyScreen(),
    ),
    GoRoute(
      path: '/promotions',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const PromotionsScreen(),
    ),
    GoRoute(
      path: '/cart',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/checkout',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final total = double.tryParse(state.uri.queryParameters['total'] ?? '0') ?? 0;
        return CheckoutScreen(total: total);
      },
    ),
    GoRoute(
      path: '/chat',
      redirect: (_, __) => '/booking',
    ),
    GoRoute(
      path: '/stylist',
      redirect: (_, __) => '/booking',
    ),
    GoRoute(
      path: '/reviews/:productId',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => ReviewsScreen(
        productId: state.pathParameters['productId']!,
      ),
    ),
    GoRoute(
      path: '/gallery',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const GalleryScreen(),
    ),
  ],
);