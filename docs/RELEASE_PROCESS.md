# Release Process - SoDak Weather App

This document explains how to create new releases of the SoDak Weather app and how the automated build process works.

## Overview

The app uses GitHub Actions to automatically build and release APK files when you create a new version tag. This ensures consistent builds and makes it easy for users to download the latest version.

## How It Works

1. **Create a Version Tag**: When you push a tag like `v1.0.0`, GitHub Actions automatically triggers
2. **Build Process**: The workflow builds the Flutter app for Android
3. **Create Release**: A new GitHub release is created with the APK attached
4. **User Download**: Users can download the APK directly from the releases page

## Creating a New Release

### Option 1: Using the Release Script (Recommended)

1. **Make sure your changes are committed and pushed**:
   ```bash
   git add .
   git commit -m "Your commit message"
   git push origin main
   ```

2. **Run the release script**:
   ```bash
   ./scripts/create_release.sh 1.0.0
   ```

   This script will:
   - Clean and rebuild the project
   - Build the APK
   - Create a git tag
   - Push the tag to trigger the GitHub Action

### Option 2: Manual Process

1. **Build the APK locally**:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

2. **Create and push a tag**:
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```

## Version Numbering

Use semantic versioning (MAJOR.MINOR.PATCH):

- **MAJOR**: Breaking changes, major new features
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, minor improvements

Examples:
- `v1.0.0` - Initial release
- `v1.1.0` - New features added
- `v1.1.1` - Bug fixes
- `v2.0.0` - Major update with breaking changes

## GitHub Actions Workflow

The workflow (`.github/workflows/release.yml`) does the following:

1. **Triggers**: On push of tags matching `v*`
2. **Environment**: Ubuntu with Java 17 and Flutter 3.24.0
3. **Build Steps**:
   - Checkout code
   - Setup Java and Flutter
   - Install dependencies
   - Build APK
   - Create GitHub release
   - Upload APK as release asset

## Release Notes

The workflow automatically generates release notes including:

- Version number
- Installation instructions
- Feature list
- System requirements
- Support information

You can customize the release notes by editing the workflow file.

## Monitoring the Build

1. **Check GitHub Actions**: Go to your repository → Actions tab
2. **Build Progress**: Watch the workflow run in real-time
3. **Release Creation**: Once complete, the release will appear in the Releases tab

## Troubleshooting

### Build Failures

If the GitHub Action fails:

1. **Check the logs**: Look at the Actions tab for error details
2. **Common issues**:
   - Missing dependencies
   - API key issues
   - Flutter version conflicts
   - Android build configuration problems

### Local Build Issues

If the release script fails:

1. **Check Flutter installation**: `flutter doctor`
2. **Clean and rebuild**: `flutter clean && flutter pub get`
3. **Check Android setup**: Ensure Android SDK is properly configured

### Tag Issues

If you need to delete a tag:

```bash
# Delete local tag
git tag -d v1.0.0

# Delete remote tag
git push origin --delete v1.0.0
```

## User Experience

### For Users

Users can easily install the app by:

1. Going to the [Releases page](https://github.com/hawkstwelve/sodak_weather/releases)
2. Downloading the latest APK
3. Enabling "Install from Unknown Sources"
4. Installing the APK

### Benefits

- **Easy Distribution**: No need for app stores during development
- **Automatic Updates**: Users can check for new versions
- **Transparent Process**: Build logs are publicly available
- **Consistent Builds**: Same environment every time

## Future Enhancements

Consider adding:

- **Release Notes**: Custom release notes for each version
- **Multiple Architectures**: ARM64 and x86_64 builds
- **Beta Releases**: Pre-release versions for testing
- **Auto-updates**: In-app update checking
- **Code Signing**: Proper app signing for production

## Security Considerations

- **APK Verification**: Users should verify the APK source
- **Code Signing**: Consider signing APKs for production
- **API Keys**: Ensure API keys are not exposed in builds
- **Dependencies**: Keep dependencies updated for security

## Support

If you encounter issues with the release process:

1. Check the GitHub Actions logs
2. Review this documentation
3. Check Flutter and Android SDK setup
4. Create an issue in the repository 