# Firebase Project Recovery Guide

## Your Original Project Details
- **Project ID**: `hamara-prayas-9247e` (DELETED - cannot be recovered)
- **Bundle ID**: `hamara-prayas.HamaraPrayas-build`
- **Web Client ID**: `700643113411-oa74fro4grfr6sq9jousno8ucg2qo0hd.apps.googleusercontent.com`

## Step-by-Step Recovery Process

### 1. Create New Firebase Project
1. Go to https://console.firebase.google.com/
2. Click "Create a project"
3. Project name: `hamara-prayas-new` (or similar)
4. Enable Google Analytics (optional)
5. Create project

### 2. Add iOS App
1. Click "Add app" → iOS
2. iOS bundle ID: `hamara-prayas.HamaraPrayas-build`
3. App nickname: `Hamara Prayas iOS`
4. Download the new `GoogleService-Info.plist`
5. Replace the existing file in your Xcode project

### 3. Enable Services
Enable these services in your new Firebase project:
- **Authentication** → Sign-in method → Google
- **Firestore Database** → Create database (test mode)
- **Storage** (if needed)
- **Cloud Messaging** (if using push notifications)

### 4. Configure Google Sign-In
1. In Authentication → Sign-in method → Google
2. Add iOS bundle ID: `hamara-prayas.HamaraPrayas-build`
3. **IMPORTANT**: Note the new Web Client ID for Android app

### 5. Set Up Firestore Collections
Create these collections in Firestore:
- `blood_requests`
- `help_requests` 
- `users`
- `community_posts`

### 6. Update Android App
Once you have the new Web Client ID:
1. Update `google-services.json` in Android project
2. Update Web Client ID in `LoginScreen.kt`
3. Update Firestore rules

## Data Recovery
Unfortunately, **Firestore data cannot be recovered** once a project is deleted. You'll need to:
1. Recreate your data structure
2. Add sample data for testing
3. Have users re-register and create new content

## Security Rules
Use these Firestore rules for development:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

## Next Steps
1. Create the new Firebase project
2. Download new configuration files
3. Update both iOS and Android apps
4. Test authentication and database operations
5. Recreate your data structure

## Important Notes
- The old project ID `hamara-prayas-9247e` is permanently deleted
- All Firestore data is lost and cannot be recovered
- You'll need new API keys and configuration files
- Users will need to sign in again with the new project











