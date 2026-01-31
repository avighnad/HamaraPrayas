#!/bin/bash

# Firebase Configuration Backup Script
# Run this script to backup your Firebase configuration files

echo "🔥 Firebase Configuration Backup Script"
echo "========================================"

# Create backup directory
BACKUP_DIR="./firebase_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "📁 Creating backup directory: $BACKUP_DIR"

# Backup iOS configuration
if [ -f "./HamaraPrayas_build/GoogleService-Info.plist" ]; then
    cp "./HamaraPrayas_build/GoogleService-Info.plist" "$BACKUP_DIR/"
    echo "✅ Backed up iOS GoogleService-Info.plist"
else
    echo "❌ iOS GoogleService-Info.plist not found"
fi

# Backup Android configuration (if exists)
if [ -f "../AndroidStudioProjects/HamaraPrayas/app/google-services.json" ]; then
    cp "../AndroidStudioProjects/HamaraPrayas/app/google-services.json" "$BACKUP_DIR/"
    echo "✅ Backed up Android google-services.json"
else
    echo "❌ Android google-services.json not found"
fi

# Create project info file
cat > "$BACKUP_DIR/project_info.txt" << EOF
Firebase Project Backup
=======================
Date: $(date)
Project ID: hamara-prayas-9247e (ORIGINAL - DELETED)
Bundle ID: hamara-prayas.HamaraPrayas-build
Web Client ID: 700643113411-oa74fro4grfr6sq9jousno8ucg2qo0hd.apps.googleusercontent.com

IMPORTANT: This project was deleted and cannot be recovered.
Use this information to set up a new Firebase project.

Next Steps:
1. Create new Firebase project
2. Add iOS app with bundle ID: hamara-prayas.HamaraPrayas-build
3. Enable Authentication, Firestore, Storage
4. Download new GoogleService-Info.plist
5. Update Android app with new Web Client ID
EOF

echo "📝 Created project info file"

# Create Firestore export script (for future use)
cat > "$BACKUP_DIR/export_firestore.sh" << 'EOF'
#!/bin/bash
# Firestore Export Script
# Run this periodically to backup your Firestore data

echo "📤 Exporting Firestore data..."

# You'll need to install Firebase CLI first:
# npm install -g firebase-tools

# Login to Firebase
# firebase login

# Export Firestore data
# firebase firestore:export ./firestore_backup_$(date +%Y%m%d_%H%M%S)

echo "✅ Firestore export completed"
EOF

chmod +x "$BACKUP_DIR/export_firestore.sh"

echo "📋 Created Firestore export script"

echo ""
echo "🎉 Backup completed!"
echo "📁 Backup location: $BACKUP_DIR"
echo ""
echo "⚠️  IMPORTANT REMINDERS:"
echo "1. Never delete Firebase projects without backing up data first"
echo "2. Use Firestore export to backup your database regularly"
echo "3. Keep configuration files in version control"
echo "4. Document your Firebase project settings"
echo ""
echo "📚 For data recovery, see: firebase_setup_guide.md"











