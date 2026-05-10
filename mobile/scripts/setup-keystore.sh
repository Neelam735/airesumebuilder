#!/usr/bin/env bash
# Generates a release keystore for Play Store uploads and writes
# android/key.properties with the credentials that android/app/build.gradle
# reads from disk at build time.
#
# Run once per developer machine. The resulting keystore is the SAME key
# you must use for every future release — losing it means you can never
# update the app on the same Play Console listing.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KEYSTORE_DIR="$ROOT/android/keystore"
KEYSTORE_FILE="$KEYSTORE_DIR/upload-keystore.jks"
PROPS_FILE="$ROOT/android/key.properties"

if [[ -f "$KEYSTORE_FILE" ]]; then
  echo "✗ Keystore already exists at $KEYSTORE_FILE"
  echo "  Refusing to overwrite. Move/delete it manually if you really want to recreate."
  exit 1
fi

if ! command -v keytool >/dev/null 2>&1; then
  echo "✗ keytool not found. Install a JDK (Temurin 17 recommended)."
  exit 1
fi

read -rp "Key alias [upload]: " ALIAS
ALIAS=${ALIAS:-upload}

read -rp "Distinguished name (CN=Your Name, O=Your Org, C=IN): " DN
DN=${DN:-CN=Resume Forge AI, O=Resume Forge AI, C=IN}

read -rsp "Keystore password: " STORE_PWD; echo
read -rsp "Confirm keystore password: " STORE_PWD2; echo
[[ "$STORE_PWD" == "$STORE_PWD2" ]] || { echo "Passwords don't match"; exit 1; }

read -rsp "Key password (Enter to reuse keystore password): " KEY_PWD; echo
KEY_PWD=${KEY_PWD:-$STORE_PWD}

mkdir -p "$KEYSTORE_DIR"

keytool -genkey -v \
  -keystore "$KEYSTORE_FILE" \
  -alias "$ALIAS" \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -dname "$DN" \
  -storepass "$STORE_PWD" \
  -keypass "$KEY_PWD"

cat > "$PROPS_FILE" <<EOF
storePassword=$STORE_PWD
keyPassword=$KEY_PWD
keyAlias=$ALIAS
storeFile=keystore/upload-keystore.jks
EOF

chmod 600 "$KEYSTORE_FILE" "$PROPS_FILE"

cat <<MSG

✓ Keystore created at $KEYSTORE_FILE
✓ Credentials written to $PROPS_FILE

Next:
  1. Verify android/app/build.gradle has the signingConfigs block from
     mobile/android/signing.gradle.example merged in.
  2. Build a release AAB:
       flutter build appbundle --release --dart-define=API_BASE=https://your-backend
  3. Upload build/app/outputs/bundle/release/app-release.aab to Play Console.

Important:
  - BACK UP $KEYSTORE_FILE somewhere offline. If you lose it you can never
    publish updates on the same Play Store listing.
  - Never commit it. /android/keystore is gitignored by mobile/.gitignore.
MSG
