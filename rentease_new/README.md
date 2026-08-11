# RentEase

RentEase is a property management and student accommodation platform built with Flutter and Supabase. It is designed to digitize rent collection, maintenance tracking, and communication between landlords and tenants.

## Key Features

- Dual-User Experience: Dedicated dashboards for Landlords and Tenants.
- Real-Time Dashboards: Landlords can view occupancy rates and revenue statistics.
- Maintenance Management: Tenants can submit requests and track resolution status.
- Secure Payment Tracking: Integrated history for rent payments and record-keeping.
- Instant Communication: Built-in chat system for direct interaction.
- Property Management: Tools for adding properties, managing rooms, and assigning tenants.

## Tech Stack

- Frontend: Flutter (Dart)
- Backend and Database: Supabase (PostgreSQL, Auth, Storage)
- State Management: Provider
- Local Storage: Shared Preferences

## Project Structure

- lib/models/: Data structures for Users, Properties, and Payments.
- lib/services/: Logic for Supabase integration, Auth, and Database operations.
- lib/screens/: UI implementation for Landlord and Tenant views.
- lib/utils/: Theme constants and global styling.

## Setup and Installation

1. Clone the repository:
   git clone https://github.com/Blutiger21/RentEase_App.git

2. Install dependencies:
   flutter pub get

3. Configure Supabase:
   Update lib/main.dart with your unique supabaseUrl and supabaseAnonKey.

4. Android Setup:
   Ensure a key.properties file exists in the android/ directory for app signing.
   Verify internet permissions in AndroidManifest.xml.

5. Run the application:
   flutter run

## Author

Fidelis Belle
IT Student at Central University of Technology
South Africa
