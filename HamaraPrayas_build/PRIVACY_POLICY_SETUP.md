# Privacy Policy and Terms of Service Setup

## Overview
Your Hamara Prayas app now includes privacy policy and terms of service URLs for Google Sign-In authentication. These URLs will be displayed during the Google OAuth flow to comply with App Store requirements.

## Configuration

### 1. URLs Already Configured ✅

Your privacy policy and terms of service URLs are already configured in `HamaraPrayas_build/Services/AuthenticationService.swift`:

```swift
struct PrivacyPolicyConfig {
    static let privacyPolicyURL = "https://www.hamaraprayas.in/our-vision/hamara-prayas-app/privacy-policy"
    static let termsOfServiceURL = "https://www.hamaraprayas.in/our-vision/hamara-prayas-app/tos"
}
```

**Your actual URLs are:**
- **Privacy Policy**: [https://www.hamaraprayas.in/our-vision/hamara-prayas-app/privacy-policy](https://www.hamaraprayas.in/our-vision/hamara-prayas-app/privacy-policy)
- **Terms of Service**: [https://www.hamaraprayas.in/our-vision/hamara-prayas-app/tos](https://www.hamaraprayas.in/our-vision/hamara-prayas-app/tos)

### 2. Privacy Policy and Terms of Service Already Created ✅

Your privacy policy and terms of service pages are already live and accessible on your website. The content includes:

**Privacy Policy covers:**
- Data collection (email, name, location, blood type, device info)
- Location services usage
- Third-party services (Google Analytics, Firebase)
- Data retention and user rights
- Contact information (avighnadaruka@gmail.com)

**Terms of Service covers:**
- App usage rules and restrictions
- User responsibilities
- Liability limitations
- Data usage policies
- Contact information (avighnadaruka@gmail.com)

### 3. Testing

Your privacy policy and terms of service are now integrated:
1. Build and run your app
2. Try Google Sign-In
3. Check the console logs for the configured URLs
4. Verify the URLs are accessible in a browser
5. Users will see the privacy policy notice during Google Sign-In

## App Store Compliance

This setup helps meet App Store requirements for:
- Privacy policy disclosure
- Terms of service agreement
- Data collection transparency
- User consent for data usage

## Notes

- The URLs are configured in the `configureGoogleSignInWithPrivacyPolicy()` method
- Google Sign-In will automatically display these during the OAuth flow
- Users will see a notice in the app about agreeing to these terms
- The configuration is logged to the console for debugging

## Support

If you need help creating the actual privacy policy and terms of service content, consider using:
- Privacy policy generators
- Legal templates
- Professional legal services
