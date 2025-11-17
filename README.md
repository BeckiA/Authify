# 🔐 Authify

**Authify** is a comprehensive, all-in-one authentication Flutter application that provides a complete authentication solution with email login, social media logins, password reset functionality, and user profile management.

## ✨ Features

### 🔑 Authentication Methods
- **Email & Password Login**: Secure email-based authentication with password validation
- **User Registration**: Complete signup flow with first name, last name, email, and password
- **Social Media Logins**: Support for OAuth providers (Google, Facebook, Apple, etc.) via Supabase
- **Email Verification**: Secure email verification flow with resend functionality
- **Password Reset**: Forgot password functionality with secure reset links
- **Deep Link Handling**: Automatic handling of authentication callbacks via deep links

### 👤 User Management
- **Profile Screen**: View and manage user profile information
- **Session Management**: Automatic session handling and persistence
- **Secure Logout**: Safe user logout with session cleanup

### 🎨 User Experience
- **Modern UI**: Clean, intuitive interface with Material Design
- **Form Validation**: Real-time input validation with helpful error messages
- **Loading States**: Visual feedback during authentication operations
- **Error Handling**: Comprehensive error handling with user-friendly messages
- **Navigation**: Smooth navigation flow using GetX routing

## 🛠️ Tech Stack

- **Framework**: Flutter 3.7.2+
- **State Management**: GetX
- **Backend**: Supabase (Authentication & Database)
- **Deep Links**: app_links package
- **Environment Variables**: flutter_dotenv
- **Icons**: Lucide Icons

## 📋 Prerequisites

Before you begin, ensure you have the following installed:
- Flutter SDK (3.7.2 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- A Supabase account and project

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/authify.git
cd authify
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Environment Setup

Create a `.env` file in the root directory with your Supabase credentials:

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

**Note**: Make sure to add `.env` to your `.gitignore` file to keep your credentials secure.

### 4. Configure Supabase

1. Create a project on [Supabase](https://supabase.com)
2. Enable the authentication providers you want to use (Email, Google, Facebook, Apple, etc.)
3. Configure redirect URLs in your Supabase dashboard:
   - For mobile: `authify://auth`
   - For web: Your web app URL

### 5. Run the App

```bash
# For Android
flutter run

# For iOS
flutter run

# For Web
flutter run -d chrome
```

## 📱 App Structure

```
lib/
├── bindings/          # GetX bindings for dependency injection
├── constants/         # App constants (colors, Supabase credentials)
├── controllers/       # Business logic and state management
├── models/           # Data models
├── screens/          # UI screens
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── forgot_password_screen.dart
│   ├── reset_password_screen.dart
│   ├── verify_email_screen.dart
│   ├── home_screen.dart
│   └── profile_screen.dart
├── services/         # Service layer (Supabase service)
├── utils/            # Utility functions
└── widgets/          # Reusable widgets
```

## 🔐 Authentication Flow

1. **Sign Up**: User creates an account with email and password
2. **Email Verification**: User receives verification email and clicks the link
3. **Login**: User logs in with verified email and password
4. **Password Reset** (if needed): User requests password reset, receives email, and sets new password
5. **Profile Access**: Authenticated users can access their profile

## 🌐 Deep Link Configuration

The app uses deep links (`authify://auth`) to handle authentication callbacks. Make sure to configure these in:

- **Android**: `android/app/src/main/AndroidManifest.xml`
- **iOS**: `ios/Runner/Info.plist`

## 📦 Dependencies

Key dependencies used in this project:

- `get: ^4.7.2` - State management and routing
- `supabase_flutter: ^2.10.3` - Supabase client
- `flutter_dotenv: ^5.1.0` - Environment variable management
- `app_links: ^6.4.1` - Deep link handling
- `lucide_icons: ^0.257.0` - Icon library

## 🔒 Security Features

- Secure password storage (handled by Supabase)
- Email verification requirement
- Secure password reset flow
- Session management
- Environment variable protection for API keys

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.

## 👤 Author

Created with ❤️ for secure authentication

## 🙏 Acknowledgments

- [Supabase](https://supabase.com) for the amazing backend infrastructure
- [Flutter](https://flutter.dev) for the cross-platform framework
- [GetX](https://pub.dev/packages/get) for state management

---

**Note**: Remember to keep your `.env` file secure and never commit it to version control. Use environment variables or secure storage for production deployments.
