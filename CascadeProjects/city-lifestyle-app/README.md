# City Lifestyle App

A modern cross-platform application for exploring and experiencing city life, built with Flutter and Node.js.

## Features

- Cross-platform support (Web, iOS, Android)
- Real-time city events and activities
- Local business discovery
- User reviews and ratings
- Interactive city maps
- Personalized recommendations
- Social features and community engagement
- Responsive admin dashboard with accessibility features

## Tech Stack

### Frontend
- Flutter (Web + Mobile)
- Material Design 3
- Google Maps SDK
- Provider for state management
- Accessibility features (WCAG compliant)

### Backend
- Node.js with Express
- MongoDB for database
- Docker for containerization
- JWT for authentication
- Google Cloud Platform for hosting

## Getting Started

### Prerequisites
- Docker and Docker Compose
- Flutter SDK
- Node.js 18+
- MongoDB

### Installation

1. Clone the repository
2. Navigate to the backend directory and run:
   ```bash
   docker-compose up --build
   ```
3. Navigate to the frontend directory and run:
   ```bash
   flutter pub get
   flutter run
   ```

## Project Structure

```
city-lifestyle-app/
├── frontend/              # Flutter application
│   ├── lib/
│   │   ├── screens/      # Application screens
│   │   ├── widgets/      # Reusable widgets
│   │   ├── utils/        # Utility functions
│   │   ├── providers/    # State management
│   │   └── theme/        # App theming
├── backend/              # Node.js API
└── docker/              # Docker configuration
```

## Keyboard Shortcuts

### Dashboard Navigation
- Alt + 1: Overview tab
- Alt + 2: Performance tab
- Alt + 3: A/B Tests tab
- Alt + 4: Settings tab

### Actions
- Ctrl + R: Refresh data
- Ctrl + E: Export data
- Alt + K: Show keyboard shortcuts
- Esc: Close dialogs/panels

### Accessibility Features
- Full keyboard navigation support
- Screen reader compatibility
- High contrast mode
- Adjustable text scaling
- Reduced motion option

## Environment Variables

Create a `.env` file in the backend directory with the following variables:
```
MONGODB_URI=mongodb://localhost:27017/city_lifestyle
JWT_SECRET=your_jwt_secret
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
```

## License

MIT License
