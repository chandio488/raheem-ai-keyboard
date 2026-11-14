#!/usr/bin/env bash
# Raheem AI Keyboard v1 rebrand — applied at CI build time to the pinned
# upstream Indic Keyboard tree (Apache-2.0; all upstream license and
# copyright notices are kept untouched).
set -euo pipefail
SRC="${1:?usage: apply-raheem.sh <indic-keyboard-tree>}"
J="$SRC/java"

# 1) App / IME label -> Raheem AI Keyboard
sed -i \
  -e 's|<string name="english_ime_name">Indic Keyboard</string>|<string name="english_ime_name">Raheem AI Keyboard</string>|' \
  -e 's|<string name="spell_checker_service_name">Indic Keyboard Spell Checker</string>|<string name="spell_checker_service_name">Raheem AI Keyboard Spell Checker</string>|' \
  -e 's|<string name="english_ime_settings">Indic Keyboard Settings</string>|<string name="english_ime_settings">Raheem AI Keyboard Settings</string>|' \
  -e 's|<string name="android_spell_checker_settings">Indic Keyboard Spell Checker Settings</string>|<string name="android_spell_checker_settings">Raheem AI Keyboard Spell Checker Settings</string>|' \
  "$J/res/values/strings-appname.xml"

# 2) applicationId + version (v1)
sed -i \
  -e 's|applicationId = "org.smc.inputmethod.indic"|applicationId = "com.raheem.keyboard"|' \
  -e 's|versionCode = 220|versionCode = 1|' \
  -e 's|versionName = "4.0.1"|versionName = "1.0"|' \
  "$J/build.gradle"

# 3) Urdu subtype locales ur_IN -> ur_PK (Urdu Navees, Urdu NLA, Urdu Transliteration)
sed -i 's|android:imeSubtypeLocale="ur_IN"|android:imeSubtypeLocale="ur_PK"|g' "$J/res/xml/method.xml"

# Sanity checks — fail the build loudly if the rebrand did not land
grep -q 'Raheem AI Keyboard' "$J/res/values/strings-appname.xml"
grep -q 'com.raheem.keyboard' "$J/build.gradle"
test "$(grep -c 'ur_PK' "$J/res/xml/method.xml")" = "3"
echo "Raheem AI Keyboard v1 rebrand applied OK"
