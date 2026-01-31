# Hamara Prayas - Blood Bank Locator & Emergency Services

A comprehensive iOS application for locating blood banks, managing blood requests, and providing emergency blood services.

## Features

### 🔐 Authentication System
- **User Login & Registration**: Secure authentication with email/password
- **Profile Management**: User profiles with blood type and donor information
- **Session Management**: Persistent login sessions with secure token storage

### 🗺️ Enhanced Blood Bank Locator
- **OpenStreetMap Integration**: Real-time blood bank discovery using OpenStreetMap API
- **Interactive Map View**: Visual representation of nearby blood banks with MapKit
- **Location Services**: GPS-based proximity search with customizable radius
- **Detailed Information**: Comprehensive blood bank details including ratings, hours, and inventory

### 🩸 Blood Request Management
- **Emergency Requests**: Quick submission of urgent blood requests
- **Request Tracking**: Monitor request status from pending to fulfilled
- **Blood Type Filtering**: Find compatible blood types and available units
- **Hospital Integration**: Link requests to specific medical facilities

### 🚨 Emergency Services
- **24/7 Support**: Round-the-clock emergency blood request handling
- **Priority System**: Urgency-based request prioritization
- **Direct Contact**: Emergency hotline integration and direct facility communication

### 📱 Modern iOS Interface
- **SwiftUI Design**: Beautiful, responsive interface following iOS design guidelines
- **Tabbed Navigation**: Intuitive navigation between different app sections
- **Dark Mode Support**: Automatic theme adaptation
- **Accessibility**: VoiceOver and accessibility features support

## Technical Architecture

### Frontend (iOS)
- **SwiftUI**: Modern declarative UI framework
- **MapKit**: Native iOS mapping and location services
- **Core Location**: GPS and location permission management
- **Combine**: Reactive programming for data binding

### Backend Services
- **RESTful API**: Standard HTTP-based communication
- **JWT Authentication**: Secure token-based authentication
- **OpenStreetMap API**: Real-time geographic data
- **Scalable Architecture**: Ready for cloud deployment

### Data Models
- **User Management**: Comprehensive user profiles and preferences
- **Blood Bank Data**: Detailed facility information and inventory
- **Request System**: Complete blood request lifecycle management

## Setup Instructions

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0+ deployment target
- macOS 14.0 or later
- Apple Developer Account (for device testing)

### Installation

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/HamaraPrayas_build.git
   cd HamaraPrayas_build
   ```

2. **Open in Xcode**
   ```bash
   open HamaraPrayas_build.xcodeproj
   ```

3. **Configure Location Services**
   - Add location usage descriptions in `Info.plist`:
     ```xml
     <key>NSLocationWhenInUseUsageDescription</key>
     <string>This app needs location access to find nearby blood banks.</string>
     <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
     <string>This app needs location access to find nearby blood banks.</string>
     ```

4. **Configure Network Security**
   - Add App Transport Security settings if needed:
     ```xml
     <key>NSAppTransportSecurity</key>
     <dict>
         <key>NSAllowsArbitraryLoads</key>
         <true/>
     </dict>
     ```

5. **Build and Run**
   - Select your target device or simulator
   - Press `Cmd + R` to build and run

### Backend Configuration

The app includes a complete backend service structure that can be easily connected to your server:

1. **Update Backend URL**
   - Edit `BackendService.swift` and update `BackendConfig.baseURL`
   - Configure your API endpoints

2. **Database Setup**
   - The backend service is designed to work with any database
   - Recommended: PostgreSQL, MySQL, or MongoDB
   - Implement the `BackendServiceProtocol` for your specific backend

3. **Authentication Server**
   - JWT token-based authentication
   - Secure password hashing (bcrypt recommended)
   - Refresh token support

## API Endpoints

### Authentication
- `POST /auth/login` - User login
- `POST /auth/register` - User registration
- `POST /auth/logout` - User logout
- `POST /auth/forgot-password` - Password reset request

### User Management
- `GET /user/profile` - Get user profile
- `PUT /user/profile/update` - Update user profile

### Blood Banks
- `GET /blood-banks` - Get nearby blood banks
- `GET /blood-banks/{id}` - Get specific blood bank details

### Blood Requests
- `GET /blood-requests` - Get user's blood requests
- `POST /blood-requests` - Submit new blood request
- `PUT /blood-requests/{id}` - Update request status

## OpenStreetMap Integration

The app uses OpenStreetMap's Overpass API for real-time blood bank discovery:

- **Search Radius**: Configurable search radius (default: 15km)
- **Facility Types**: Hospitals, clinics, and medical centers
- **Real-time Data**: Live facility information and status
- **Fallback System**: Sample data when network is unavailable

## Testing

### Unit Tests
- Run tests with `Cmd + U`
- Tests cover authentication, data models, and services

### UI Tests
- Automated UI testing for critical user flows
- Location permission testing
- Map interaction testing

## Deployment

### App Store
1. Configure app signing and capabilities
2. Set appropriate deployment target
3. Test on physical devices
4. Submit for App Store review

### Enterprise
1. Configure enterprise distribution
2. Set up device provisioning
3. Deploy via MDM or direct installation

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue in the GitHub repository
- Contact the development team
- Check the documentation wiki

## Roadmap

### Version 2.0
- [ ] Push notifications for emergency requests
- [ ] Blood donation scheduling
- [ ] Integration with hospital systems
- [ ] Multi-language support

### Version 3.0
- [ ] AI-powered blood matching
- [ ] Community features
- [ ] Advanced analytics dashboard
- [ ] Wearable device integration

---

**Made with ❤️ by Avighna Daruka**

*Saving lives, one drop at a time.*

