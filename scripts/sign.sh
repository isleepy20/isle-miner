#!/usr/bin/env bash
# Align + sign the release APK with v1, v2, v3 and v4, then verify.
# Run from the project root after:  gradle assembleRelease
set -euo pipefail

SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:?set ANDROID_HOME}}"
BT="$SDK/build-tools/${BUILD_TOOLS_VERSION:-35.0.0}"
IN="app/build/outputs/apk/release/app-release-unsigned.apk"
OUT="build/signed"
KS="${KEYSTORE_PATH:-build/release.jks}"
ALIAS="${KEY_ALIAS:-isleminer}"
PASS="${KEYSTORE_PASSWORD:-isleminer123}"   # only protects the auto-generated key; use real secrets for releases

mkdir -p "$OUT" "$(dirname "$KS")"

if [[ -n "${KEYSTORE_BASE64:-}" ]]; then
  echo "$KEYSTORE_BASE64" | base64 -d > "$KS"
elif [[ ! -f "$KS" ]]; then
  keytool -genkeypair -keystore "$KS" -alias "$ALIAS" -keyalg RSA -keysize 2048 \
    -validity 10000 -storepass "$PASS" -keypass "$PASS" -dname "CN=Isle Miner"
fi

rm -f "$OUT"/*

# 1) zipalign BEFORE signing
"$BT/zipalign" -f -p 4 "$IN" "$OUT/aligned.apk"
"$BT/zipalign" -c -p 4 "$OUT/aligned.apk"

# 2) sign with v1 + v2 + v3 + v4 (v4 writes IsleMiner.apk.idsig next to the APK)
"$BT/apksigner" sign \
  --ks "$KS" --ks-key-alias "$ALIAS" --ks-pass "pass:$PASS" --key-pass "pass:$PASS" \
  --min-sdk-version 26 \
  --v1-signing-enabled true --v2-signing-enabled true \
  --v3-signing-enabled true --v4-signing-enabled true \
  --out "$OUT/IsleMiner.apk" "$OUT/aligned.apk"
rm -f "$OUT/aligned.apk"

# 3) verify
"$BT/apksigner" verify --verbose --print-certs --min-sdk-version 26 "$OUT/IsleMiner.apk"
"$BT/apksigner" verify --verbose --min-sdk-version 26 \
  --v4-signature-file "$OUT/IsleMiner.apk.idsig" "$OUT/IsleMiner.apk"
ls -l "$OUT"
