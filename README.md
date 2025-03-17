# Green Pay

A modern mobile payment application built with Flutter that provides secure and convenient payment solutions.

## Features

- **Secure Authentication**
  - Phone number verification with OTP
  - Biometric authentication (Face ID/Fingerprint)
  - Secure token management

- **Wallet Management**
  - Add money to wallet
  - View transaction history
  - Check wallet balance and statistics

- **Bill Payments**
  - Pay utility bills
  - Generate and share payment receipts as PDF

- **Money Transfer**
  - Send money to contacts
  - UPI integration

- **Security**
  - Encrypted data storage
  - Key rotation mechanism
  - Biometric verification for sensitive operations

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio / VS Code
- Android SDK / Xcode (for iOS development)

## Architecture

The app follows a service-based architecture:

- **Services**: Handle business logic and API communication
  - `AuthService`: Manages authentication and user data
  - `WalletService`: Handles wallet operations
  - `APIService`: Manages API requests and responses
  - `BiometricAuthService`: Handles biometric authentication

- **Models**: Data structures for the application
  - `User`: User profile information
  - `Transaction`: Transaction details
  - `Bill`: Bill payment information

- **Screens**: UI components for different app features
  - Profile management
  - Wallet and transactions
  - Bill payments
  - Settings

## Security

Green Pay implements several security measures:

- Secure storage for sensitive data
- Biometric authentication for secure access
- Token-based authentication with refresh mechanism
- Encrypted data storage with key rotation


## License

This project is licensed under the MIT License - see the LICENSE file for details.
