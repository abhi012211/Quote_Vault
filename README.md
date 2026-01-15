# QuoteVault

QuoteVault is a modern, feature-rich quote discovery and collection application built with Flutter & Supabase.

## Features

- **Authentication**: Secure Sign Up, Login, and QuoteVault implementation using Supabase Auth.
- **Browse & Discovery**: Infinite scroll feed of quotes, searchable by category.
- **Favorites & Collections**: Save your favorite quotes and organize them into custom collections.
- **Daily Quote**: Get a fresh quote every day, delivered via local notifications.
- **Sharing**: Share quote text or beautiful images directly to social media.
- **Widgets**: Home screen widget (Android) to display the daily quote.
- **Personalization**: Dark/Light mode support and settings.

## Getting Started

### Prerequisites

- Flutter SDK
- Supabase Account

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/quote_vault.git
   cd quote_vault
   ```

2. **Supabase Configuration**
   - Create a new Supabase project.
   - Run the SQL script found in `db_setup.sql` in your Supabase SQL Editor to set up tables and RLS policies.
   - Update `lib/core/constants/app_constants.dart` with your Supabase URL and Anon Key.

3. **Run the App**
   ```bash
   flutter pub get
   flutter run
   ```

## Architecture

The project follows a simplified Clean Architecture with Riverpod for state management:

- `lib/core`: App-wide constants, themes, and utilities.
- `lib/data`: Repositories, Data Models, and Services (Supabase, Notification, Share, Widget).
- `lib/ui`: Screens and Widgets (MVVM pattern with ConsumerWidgets).

## Key Libraries

- `flutter_riverpod`: State management.
- `supabase_flutter`: Backend and Auth.
- `go_router`: Navigation.
- `flutter_local_notifications`: Daily reminders.
- `home_widget`: Android Home Screen Widget.
- `share_plus`: Sharing capabilities.

## License

MIT
