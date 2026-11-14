#!/usr/bin/env bash
# RAHEEM AI ULTRA — v1 REPACK rebrand, applied at CI build time to the pinned
# upstream Indic Keyboard tree (Apache-2.0; all upstream license and
# copyright notices are kept untouched).
#
# Why a repack (same version 1.0, NOT the feature update): the first v1 APK
# (package com.raheem.keyboard, CI debug-signed) would not install on the
# owner's phone — an older app already holds that package with a different
# signature ("package conflicts with an existing package"). This repack gives
# v1 a fresh unique package id (com.raheem.aiultra) so it installs alongside
# the old app, plus the owner's chosen name RAHEEM AI ULTRA and his brand
# icon. The owner's existing apps/keyboard are not touched.
set -euo pipefail
SRC="${1:?usage: apply-raheem-ultra.sh <indic-keyboard-tree>}"
J="$SRC/java"
ASSETS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/assets"

# Assets may arrive as a single zip at the repo root (GitHub web uploads
# flatten folder paths, so the icon set is shipped as assets-ultra.zip,
# which contains the assets/ tree and is extracted back into place here).
if [ ! -d "$ASSETS/icons" ] && [ -f "$(dirname "$ASSETS")/assets-ultra.zip" ]; then
  python3 -m zipfile -e "$(dirname "$ASSETS")/assets-ultra.zip" "$(dirname "$ASSETS")/"
fi

# 1) App / IME labels -> RAHEEM AI ULTRA
sed -i \
  -e 's|<string name="english_ime_name">Indic Keyboard</string>|<string name="english_ime_name">RAHEEM AI ULTRA</string>|' \
  -e 's|<string name="spell_checker_service_name">Indic Keyboard Spell Checker</string>|<string name="spell_checker_service_name">RAHEEM AI ULTRA Spell Checker</string>|' \
  -e 's|<string name="english_ime_settings">Indic Keyboard Settings</string>|<string name="english_ime_settings">RAHEEM AI ULTRA Settings</string>|' \
  -e 's|<string name="android_spell_checker_settings">Indic Keyboard Spell Checker Settings</string>|<string name="android_spell_checker_settings">RAHEEM AI ULTRA Spell Checker Settings</string>|' \
  "$J/res/values/strings-appname.xml"

# 2) applicationId (fresh, unique) + version (same v1: versionName 1.0)
sed -i \
  -e 's|applicationId = "org.smc.inputmethod.indic"|applicationId = "com.raheem.aiultra"|' \
  -e 's|versionCode = 220|versionCode = 1|' \
  -e 's|versionName = "4.0.1"|versionName = "1.0"|' \
  "$J/build.gradle"

# 3) Urdu subtype locales ur_IN -> ur_PK (Urdu Navees, Urdu NLA, Urdu Transliteration)
sed -i 's|android:imeSubtypeLocale="ur_IN"|android:imeSubtypeLocale="ur_PK"|g' "$J/res/xml/method.xml"

# 4) Launcher icon — pre-generated PNGs (owner's brand mark) copied over the
#    upstream files. Upstream structure (pinned commit e5bee019):
#      legacy:   res/mipmap-<density>/ic_launcher.png + ic_launcher_round.png
#      adaptive: res/mipmap-<density>/ic_launcher_foreground.png, referenced by
#                res/mipmap-anydpi-v26/ic_launcher{,_round}.xml — upstream points
#                those at a VECTOR (res/drawable/ic_launcher_foreground.xml), so
#                the anydpi XMLs are rewritten below to use the raster
#                foreground; the now-unused vector file is left untouched.
#    Foreground PNGs carry the artwork centred in the 66dp safe zone of the
#    108dp adaptive canvas (transparent surround), so launcher masks cannot
#    clip the R mark or the ULTRA word.
for d in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  for f in ic_launcher.png ic_launcher_round.png ic_launcher_foreground.png; do
    cp "$ASSETS/icons/mipmap-$d/$f" "$J/res/mipmap-$d/$f"
  done
done

# 5) Adaptive-icon definitions -> raster foreground + brand background colour
for x in ic_launcher.xml ic_launcher_round.xml; do
  cat > "$J/res/mipmap-anydpi-v26/$x" <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
    <monochrome android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
EOF
done
sed -i 's|<color name="ic_launcher_background">#2A3854</color>|<color name="ic_launcher_background">#192C89</color>|' \
  "$J/res/values/ic_launcher_background.xml"

# 6) DictionaryProvider authority -> package-unique value. Full source audit
#    (SOURCE-AUDIT-2026-11-14.md, pinned tree, all 12 of Farhan's categories):
#    the FIXED literal org.smc.inputmethod.dictionarypack.aosp occurs in
#    exactly two places, and both function as the provider authority, so both
#    must change together:
#      a) res/values/dictionary-pack.xml — <string name="authority">, used by
#         the manifest (@string/authority) and DictionarySettingsFragment.
#      b) DictionaryPackConstants.AUTHORITY — code constant the provider
#         builds its content URIs / UriMatcher from, the dictionary file
#         dumper queries with, and the install receiver matches against.
#    NOT touched: DICTIONARY_DOMAIN (com.android.inputmethod.dictionarypack.
#    aosp) and the manifest's UNKNOWN_CLIENT action — those are broadcast
#    intent actions, not authorities, and are a different literal anyway.
sed -i 's|org\.smc\.inputmethod\.dictionarypack\.aosp|com.raheem.aiultra.dictionarypack.aosp|g' \
  "$J/res/values/dictionary-pack.xml" \
  "$J/src/com/android/inputmethod/dictionarypack/DictionaryPackConstants.java"

# Sanity checks — fail the build loudly if the repack did not land
grep -q 'RAHEEM AI ULTRA' "$J/res/values/strings-appname.xml"
grep -q 'com.raheem.aiultra' "$J/build.gradle"
test "$(grep -c 'ur_PK' "$J/res/xml/method.xml")" = "3"
grep -q '@mipmap/ic_launcher_foreground' "$J/res/mipmap-anydpi-v26/ic_launcher.xml"
grep -q '@mipmap/ic_launcher_foreground' "$J/res/mipmap-anydpi-v26/ic_launcher_round.xml"
grep -q '#192C89' "$J/res/values/ic_launcher_background.xml"
# Authority fix: the old FIXED authority literal must be gone from the whole
# java/ tree (res + src + AndroidManifest.xml — the audit proved every
# functional occurrence lives under java/; the broadcast-action literal
# com.android.inputmethod.dictionarypack.aosp is a different string and is
# not matched), and the new package-unique value must be present in both
# authority sites (resource definition + Java constant).
! grep -rq 'org\.smc\.inputmethod\.dictionarypack\.aosp' "$J"
grep -q 'com.raheem.aiultra.dictionarypack.aosp' "$J/res/values/dictionary-pack.xml"
grep -q 'com.raheem.aiultra.dictionarypack.aosp' "$J/src/com/android/inputmethod/dictionarypack/DictionaryPackConstants.java"
for d in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  for f in ic_launcher.png ic_launcher_round.png ic_launcher_foreground.png; do
    test -s "$J/res/mipmap-$d/$f"
  done
done
echo "RAHEEM AI ULTRA v1 repack applied OK"
