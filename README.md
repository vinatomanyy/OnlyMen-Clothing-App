# OnlyMen — Men's Clothing Shop

A modern minimalist e-commerce Flutter app for men's clothing. Black, white, navy, and gold accent color palette. Backed by Supabase for products, promotions, reviews, orders, and bookings.

## Features

- Product catalog with size & color variant selection
- Wishlist / Favorites (persisted locally)
- Store locator with interactive map
- Nearby stores with distance sorting
- Promotions & coupon codes
- Cart & mock checkout
- Personal styling appointment booking
- Chat with stylist
- Reviews with fit feedback
- Dark mode support
- Responsive (phone + tablet)

## Tech Stack

- **Framework:** Flutter 3.x / Dart 3.x / Material 3
- **State:** Riverpod
- **Navigation:** go_router
- **Backend:** Supabase (PostgreSQL + Storage)
- **Images:** CachedNetworkImage (WebP from Supabase Storage)
- **Local storage:** shared_preferences (favorites + cart)
- **Map:** flutter_map (static markers, OpenStreetMap tiles)

## Setup

### Prerequisites

- Flutter SDK 3.x
- Supabase project (URL and anon key in `lib/utils/supabase_config.dart`)

### Run

```bash
flutter pub get
flutter run
```

### Supabase

The app connects to a Supabase project at `hrjtpwgoaeqzkijanfki.supabase.co` using an anon key with RLS policies for public read/insert. Tables: `products`, `promotions`, `reviews`, `orders`, `bookings`. Storage bucket: `product-images` (public, WebP).
