#!/usr/bin/env bash
# RAHEEM AI ULTRA — v1 REPACK rebrand + THE SINGLE FEATURE UPDATE (v2 recipe),
# applied at CI build time to the pinned upstream Indic Keyboard tree
# (Apache-2.0; all upstream license and copyright notices are kept untouched).
#
# Why a repack (same version 1.0, NOT the feature update): the first v1 APK
# (package com.raheem.keyboard, CI debug-signed) would not install on the
# owner's phone — an older app already holds that package with a different
# signature ("package conflicts with an existing package"). This repack gives
# v1 a fresh unique package id (com.raheem.aiultra) so it installs alongside
# the old app, plus the owner's chosen name RAHEEM AI ULTRA and his brand
# icon. The owner's existing apps/keyboard are not touched.
#
# Steps 1–6 below are the v1 repack (unchanged). Steps 7–10 add the owner's
# ONE allowed feature update (design: UPDATE-FEATURE-DESIGN-2026-11-14.md):
#   7) Urdu suggestion dictionary (main_ur.dict, MD5-checked)
#   8) Full 10-mark اعراب coverage in both Urdu layouts
#   9) New sources: Quick Islamic Phrases panel + settings, offline-Urdu
#      voice scaffolding (model download/verify, capture, dictation panel)
#  10) Patched upstream sources: phrases key codes + panel wiring, mic-key
#      interception, RECORD_AUDIO, strings, proguard keep for sherpa-onnx
# Voice linking (step 11 below): Farhan's Phase-0 gate PASSED on 2026-11-14
# (the owner's own voice, per-sentence decode, sherpa-onnx 2.0.1 + Shruti
# pack: numbers and mixed English exact), so this update LINKS the offline
# Urdu recognizer: the pinned official sherpa-onnx 2.0.1 AAR is downloaded
# from the k2-fsa GitHub release, SHA-256 verified, and vendored into
# java/libs/; UrduAsrEngine.NATIVE_LINKED = true and SherpaOnnxRecognizer
# implements the bridge. The model itself is NOT in the APK — it downloads
# on first use with SHA-256 verification (OfflineVoiceManager).
#
# CI WORKFLOW (release signing) — the workflow file
# (.github/workflows/build.yml) must run, around the gradle build:
#   1. - name: Restore release keystore
#        env:
#          RELEASE_KEYSTORE_B64: ${{ secrets.RELEASE_KEYSTORE_B64 }}
#        run: |
#          echo "$RELEASE_KEYSTORE_B64" | base64 -d \
#            > "$RUNNER_TEMP/raheem-ultra-release.jks"
#          {
#            echo "INDIC_KEYSTORE=$RUNNER_TEMP/raheem-ultra-release.jks"
#            echo "INDIC_KEYSTORE_PASSWORD=${{ secrets.RELEASE_STORE_PASSWORD }}"
#            echo "INDIC_KEY_ALIAS=raheem-ultra"
#            echo "INDIC_KEY_PASSWORD=${{ secrets.RELEASE_KEY_PASSWORD }}"
#          } >> "$GITHUB_ENV"
#      (Upstream java/build.gradle already wires signingConfigs.release from
#      the INDIC_* env vars — no gradle signing edit is needed or wanted.
#      Secrets are referenced BY NAME ONLY; no password ever appears here.)
#   2. Build the release variant:
#        ./gradlew assembleOnlineRelease        (run inside src/java)
#      Output: src/java/build/outputs/apk/online/release/
#   3. Verify the signature before any upload:
#        apksigner verify --print-certs <apk>
#      The signer SHA-256 must equal the permanent release keystore's
#      fingerprint (see SIGNING-NOTE.md); a mismatch fails the job.
#   4. Cleanup, always:
#        - name: Remove keystore
#          if: always()
#          run: rm -f "$RUNNER_TEMP/raheem-ultra-release.jks"
#   5. Upload/release steps point at the release output dir from step 2.
# Required GitHub secrets (one-time human setup): RELEASE_KEYSTORE_B64,
# RELEASE_STORE_PASSWORD, RELEASE_KEY_PASSWORD.
# NOTE: because the update is release-signed while v1 was debug-signed, the
# owner must uninstall v1 ONCE before installing the update; every later
# build with this keystore installs cleanly over the previous one.
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

# Update assets (v2): same shipping pattern — assets-update.zip at the repo
# root extracts back into an assets-update/ folder next to this script.
UPDATE_ASSETS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/assets-update"
if [ ! -f "$UPDATE_ASSETS/main_ur.dict" ] && [ -f "$(dirname "$UPDATE_ASSETS")/assets-update.zip" ]; then
  python3 -m zipfile -e "$(dirname "$UPDATE_ASSETS")/assets-update.zip" "$(dirname "$UPDATE_ASSETS")/"
fi

# 1) App / IME labels -> RAHEEM AI ULTRA
sed -i \
  -e 's|<string name="english_ime_name">Indic Keyboard</string>|<string name="english_ime_name">RAHEEM AI ULTRA</string>|' \
  -e 's|<string name="spell_checker_service_name">Indic Keyboard Spell Checker</string>|<string name="spell_checker_service_name">RAHEEM AI ULTRA Spell Checker</string>|' \
  -e 's|<string name="english_ime_settings">Indic Keyboard Settings</string>|<string name="english_ime_settings">RAHEEM AI ULTRA Settings</string>|' \
  -e 's|<string name="android_spell_checker_settings">Indic Keyboard Spell Checker Settings</string>|<string name="android_spell_checker_settings">RAHEEM AI ULTRA Spell Checker Settings</string>|' \
  "$J/res/values/strings-appname.xml"

# 2) applicationId (fresh, unique) + version. History: v1 shipped base
#    versionCode 1 -> arm64 output 2, armeabi output 1 (upstream ABI-split
#    offsets); the v1.1 update used base 3 -> arm64 output 4, armeabi 3.
#    v1.2 (Direct Voice Typing build, owner order 2026-11-14) uses base 5
#    -> arm64 output 6, armeabi output 5, strictly higher than v1.1.
#    v1.3 (Hybrid Voice Routing, owner order + Farhan ruling 2026-11-14)
#    uses base 6 -> arm64 output 7, armeabi output 6, higher than v1.2.
#    v1.4 (visible Aerab, Farhan reply 23) uses base 7 -> arm64 output 8,
#    armeabi output 7, higher than v1.3.
sed -i \
  -e 's|applicationId = "org.smc.inputmethod.indic"|applicationId = "com.raheem.aiultra"|' \
  -e 's|versionCode = 220|versionCode = 7|' \
  -e 's|versionName = "4.0.1"|versionName = "1.4"|' \
  "$J/build.gradle"

# 3) Urdu locales ur_IN -> ur_PK — BOTH files that key Urdu by region:
#      a) res/xml/method.xml — the 3 declared IME subtypes (imeSubtypeLocale):
#         Urdu Navees, Urdu Windows (NLA), Urdu Transliteration.
#      b) res/xml/keyboard_languages.xml — the language-picker catalogue:
#         <language locale="ur_IN" englishName="Urdu"> carries the same 3
#         layout sets (urdu, urdu_nla, qwerty + ur-transliteration). The
#         first repack missed this file, so «Urdu» never appeared in the
#         keyboard's Languages lists on the owner's phone (proven by his
#         screenshots 2026-11-14 11:40 PKT).
#    Whole-tree sweep 2026-11-14 (URDU-LOCALE-FIX-2026-11-14.md): these are
#    the ONLY ur_IN occurrences in the pinned tree incl. submodules; bare
#    language-code "ur" references (spellchecker subtypeLocale, keyboard
#    texts table, script map, the translit scheme name) are region-free
#    and stay untouched.
sed -i 's|android:imeSubtypeLocale="ur_IN"|android:imeSubtypeLocale="ur_PK"|g' "$J/res/xml/method.xml"
sed -i 's|locale="ur_IN"|locale="ur_PK"|g' "$J/res/xml/keyboard_languages.xml"

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

# ---------------------------------------------------------------------------
# THE SINGLE FEATURE UPDATE (steps 7–11)
# ---------------------------------------------------------------------------

# 7) Urdu suggestion dictionary -> java/res/raw/main_ur.dict. The engine
#    resolves dictionaries by name (subtype ur_PK -> main_ur_pk -> main_ur),
#    so NO XML registration exists or is needed. Provenance + build record:
#    URDU-DICTIONARY-PREP-2026-11-14.md (the tree's own dictionaries-indic
#    Urdu wordfreq, 221,601 words + 71,777 bigrams, dicttool-validated).
cp "$UPDATE_ASSETS/main_ur.dict" "$J/res/raw/main_ur.dict"

# 8) اعراب coverage: replace the Urdu letter-row files with the completed
#    versions (AERAB-COVERAGE-PREP-2026-11-14.md; v1.4 design = Farhan
#    reply 23 after the owner's «اعراب پورے نہیں» verdict on v1.3).
#    v1.4: BOTH layouts get (a) the full Aerab row in the SHIFTED case of
#    row 1 — NLA's shifted row 1 is now identical to Navees', and its 9 old
#    letters (ظ ض ذ ڈ ث ۃ ـ چ خ) are preserved in long-press homes, never
#    deleted; and (b) an always-visible Aerab anchor key in the DEFAULT
#    case of row 2 (the row had 9 keys; the anchor is the 10th, no letter
#    displaced) whose long-press panel holds all 10 marks + tatweel.
cp "$UPDATE_ASSETS/aerab/rowkeys_urdu1.xml" "$J/res/xml/rowkeys_urdu1.xml"
cp "$UPDATE_ASSETS/aerab/rowkeys_urdu2.xml" "$J/res/xml/rowkeys_urdu2.xml"
cp "$UPDATE_ASSETS/aerab/rowkeys_urdu_nla1.xml" "$J/res/xml/rowkeys_urdu_nla1.xml"
cp "$UPDATE_ASSETS/aerab/rowkeys_urdu_nla2.xml" "$J/res/xml/rowkeys_urdu_nla2.xml"

# 9) New files (phrases panel + store + settings, voice manager/engine/panel,
#    seed JSON, model manifest, drawables, layouts) — paths inside newfiles/
#    mirror the tree, so a plain overlay copy lands each file in place.
cp -r "$UPDATE_ASSETS/newfiles/." "$SRC/"

# 10) Patched upstream files (full-file replacements produced from the pinned
#     tree; every edit anchor was asserted when the patches were generated):
#     Constants/CodesSet (CODE_PHRASES=-23, CODE_ALPHA_FROM_PHRASES=-24),
#     KeyboardState/KeyboardSwitcher/InputView (phrases + dictation panels),
#     SuggestionStripView + suggestions_strip.xml (toolbox phrases button),
#     LatinIME (mic interception, permission callback, phrase/dictation
#     listeners), InputLogic (no-op cases), AndroidManifest (RECORD_AUDIO),
#     prefs.xml (phrases settings entry), strings.xml (phrases + dictation
#     strings), proguard-rules.txt (sherpa-onnx keep rule).
#     NOTE: build.gradle is NOT in the overlay set — step 2 already edits it
#     (applicationId/version), so its sherpa-onnx note is inserted in place
#     below instead of shipping a full-file replacement.
cp -r "$UPDATE_ASSETS/patched/." "$SRC/"
python3 - "$J/build.gradle" <<'PYEOF'
import sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
anchor = "    implementation project(':ime')\n"
dep = anchor + """    // RAHEEM AI ULTRA update — offline Urdu voice: pinned official
    // sherpa-onnx 2.0.1 Android AAR, vendored into java/libs/ by recipe
    // step 11 (downloaded from the k2-fsa GitHub release, SHA-256 pinned).
    implementation(name: 'sherpa-onnx-2.0.1', ext: 'aar')
"""
if "sherpa-onnx-2.0.1" not in text:
    assert text.count(anchor) == 1, "build.gradle anchor drifted"
    text = text.replace(anchor, dep)
    if "flatDir" not in text:
        text += """
// RAHEEM AI ULTRA update — local AARs (sherpa-onnx) live in java/libs/.
repositories {
    flatDir {
        dirs 'libs'
    }
}
"""
    open(path, "w", encoding="utf-8").write(text)
print("build.gradle sherpa-onnx dependency OK")
PYEOF

# 11) Offline-voice native library: download the pinned official sherpa-onnx
#     2.0.1 Android AAR (the same version whose Python decoder passed the
#     owner's real-voice test) from the k2-fsa GitHub release and vendor it
#     into java/libs/. SHA-256 is pinned — a mismatch fails the build loudly.
SHERPA_AAR="$J/libs/sherpa-onnx-2.0.1.aar"
SHERPA_SHA256="a8d09d1d32f3eb8520482c6d3d43fae674681c5b050385967c70a3c2c9bf0ee7"
mkdir -p "$J/libs"
if [ ! -f "$SHERPA_AAR" ]; then
  curl -fsSL -o "$SHERPA_AAR" \
    "https://github.com/k2-fsa/sherpa-onnx/releases/download/v2.0.1/sherpa-onnx-2.0.1.aar"
fi
test "$(sha256sum "$SHERPA_AAR" | cut -d' ' -f1)" = "$SHERPA_SHA256"
echo "sherpa-onnx-2.0.1.aar vendored + SHA-256 verified"

# Sanity checks — fail the build loudly if the repack did not land
grep -q 'RAHEEM AI ULTRA' "$J/res/values/strings-appname.xml"
grep -q 'com.raheem.aiultra' "$J/build.gradle"
test "$(grep -c 'ur_PK' "$J/res/xml/method.xml")" = "3"
# Urdu locale fix: no ur_IN may remain in either locale-keyed file, and the
# catalogue's Urdu entry must now be ur_PK with all 3 layout sets intact.
! grep -q 'ur_IN' "$J/res/xml/method.xml"
! grep -q 'ur_IN' "$J/res/xml/keyboard_languages.xml"
grep -q '<language locale="ur_PK" englishName="Urdu"' "$J/res/xml/keyboard_languages.xml"
grep -q 'layoutSet="urdu"' "$J/res/xml/keyboard_languages.xml"
grep -q 'layoutSet="urdu_nla"' "$J/res/xml/keyboard_languages.xml"
grep -q 'translit="ur-transliteration"' "$J/res/xml/keyboard_languages.xml"
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

# --- Update (v2) sanity checks ---------------------------------------------
# Dictionary asset in place and byte-exact (MD5 from the prep record).
test "$(md5sum "$J/res/raw/main_ur.dict" | cut -d' ' -f1)" = "af770e6926c9718ae65fd05e7caf6a0f"
# اعراب: all 10 combining marks present in BOTH Urdu letter-row files
# (زبر U+064E، زیر U+0650، پیش U+064F، تشدید U+0651، جزم U+0652،
#  دو زبر U+064B، دو زیر U+064D، دو پیش U+064C، کھڑی زبر U+0670، مدّہ U+0653).
python3 - "$J/res/xml/rowkeys_urdu1.xml" "$J/res/xml/rowkeys_urdu2.xml" "$J/res/xml/rowkeys_urdu_nla1.xml" "$J/res/xml/rowkeys_urdu_nla2.xml" <<'PYEOF'
import sys
import xml.etree.ElementTree as ET
NS = "{http://schemas.android.com/apk/res-auto}"
MARKS = ["\u064e", "\u0650", "\u064f", "\u0651", "\u0652",
         "\u064b", "\u064d", "\u064c", "\u0670", "\u0653"]
def cases(path):
    out = {}
    for sw in ET.parse(path).getroot().iter("switch"):
        for case in sw:
            name = "shifted" if case.tag == "case" else "default"
            keys = []
            for k in case.iter("Key"):
                keys.append((k.get(NS + "keySpec") or "",
                             (k.get(NS + "moreKeys") or "")
                             + (k.get(NS + "additionalMoreKeys") or "")))
            out[name] = keys
    return out
def specs(keys):
    return [s for s, _ in keys]
def allvals(keys):
    return "|".join(s + "|" + m for s, m in keys)
u1, u2, n1, n2 = (cases(p) for p in sys.argv[1:5])
# 1) Shifted row 1 of BOTH layouts carries all 10 marks (7 direct keys,
#    3 grouped long-press partners — identical in Navees and NLA).
for name, c in [("urdu1", u1), ("nla1", n1)]:
    vals = allvals(c["shifted"])
    missing = [hex(ord(m)) for m in MARKS if m not in vals]
    if missing:
        sys.exit(f"AERAB FAIL {name} shifted row: missing {missing}")
    direct = [m for m in MARKS if m in specs(c["shifted"])]
    if len(direct) < 7:
        sys.exit(f"AERAB FAIL {name} shifted row: only {len(direct)} direct marks")
# 2) Default row 2 of BOTH layouts has the always-visible anchor: a shadda
#    key whose long-press panel holds the other 9 marks.
for name, c in [("urdu2", u2), ("nla2", n2)]:
    anchors = [(s, m) for s, m in c["default"] if s == "\u0651"]
    if not anchors:
        sys.exit(f"AERAB FAIL {name} default row 2: no anchor key")
    panel = anchors[0][1]
    missing = [hex(ord(m)) for m in MARKS if m != "\u0651" and m not in panel]
    if missing:
        sys.exit(f"AERAB FAIL {name} anchor panel: missing {missing}")
# 3) NLA's 9 old shifted letters are all still reachable in nla1+nla2.
vals = (allvals(n1["shifted"]) + allvals(n1["default"])
        + allvals(n2["shifted"]) + allvals(n2["default"]))
for ch in ["\u0638", "\u0636", "\u0630", "\u0688", "\u062b",
           "\u06c3", "\u0640", "\u0686", "\u062e"]:
    if ch not in vals:
        sys.exit(f"AERAB FAIL NLA letter lost: {hex(ord(ch))}")
print("aerab v1.4: full shifted row + default anchor panel in both layouts; NLA letters preserved")
PYEOF
# Phrases key codes registered end-to-end (a missing InputLogic case would
# throw at runtime; a missing CodesSet entry misaligns the code table).
grep -q 'CODE_PHRASES = -23' "$J/../common/src/com/android/inputmethod/latin/common/Constants.java"
grep -q 'CODE_ALPHA_FROM_PHRASES = -24' "$J/../common/src/com/android/inputmethod/latin/common/Constants.java"
grep -q 'Constants.CODE_PHRASES' "$J/src/com/android/inputmethod/keyboard/internal/KeyboardCodesSet.java"
grep -q 'case Constants.CODE_PHRASES' "$J/src/org/smc/inputmethod/indic/inputlogic/InputLogic.java"
grep -q 'setPhrasesKeyboard' "$J/src/com/android/inputmethod/keyboard/internal/KeyboardState.java"
grep -q 'setPhrasesKeyboard' "$J/src/com/android/inputmethod/keyboard/KeyboardSwitcher.java"
grep -q 'CODE_PHRASES' "$J/src/org/smc/inputmethod/indic/LatinIME.java"
grep -q 'toolbox_phrases_key' "$J/res/layout/suggestions_strip.xml"
grep -q 'android.permission.RECORD_AUDIO' "$J/AndroidManifest.xml"
grep -q 'android.permission.ACCESS_NETWORK_STATE' "$J/AndroidManifest.xml"
grep -q 'com.k2fsa.sherpa.onnx' "$J/proguard-rules.txt"
grep -q 'sherpa-onnx' "$J/build.gradle"
# New files at their in-tree paths.
test -f "$J/src/com/android/inputmethod/keyboard/phrases/PhrasesView.java"
test -f "$J/src/com/android/inputmethod/keyboard/voice/DictationView.java"
test -f "$J/src/org/smc/inputmethod/indic/phrases/PhraseStore.java"
test -f "$J/src/org/smc/inputmethod/indic/voice/OfflineVoiceManager.java"
test -f "$J/src/org/smc/inputmethod/indic/voice/UrduAsrEngine.java"
# Voice linked: bridge class present, engine flag on, AAR vendored + pinned.
test -f "$J/src/org/smc/inputmethod/indic/voice/SherpaOnnxRecognizer.kt"
grep -q 'NATIVE_LINKED = true' "$J/src/org/smc/inputmethod/indic/voice/UrduAsrEngine.java"
grep -q 'return new SherpaOnnxRecognizer()' "$J/src/org/smc/inputmethod/indic/voice/UrduRecognizer.java"
test "$(sha256sum "$J/libs/sherpa-onnx-2.0.1.aar" | cut -d' ' -f1)" = "a8d09d1d32f3eb8520482c6d3d43fae674681c5b050385967c70a3c2c9bf0ee7"
grep -q 'versionCode = 7' "$J/build.gradle"
grep -q 'versionName = "1.4"' "$J/build.gradle"
# Hybrid Voice Routing (v1.3): router probes network + voice IME presence.
test -f "$J/src/org/smc/inputmethod/indic/voice/OfflineVoiceRouter.java"
grep -q 'hasVoiceInputMethod' "$J/src/org/smc/inputmethod/indic/voice/OfflineVoiceRouter.java"
grep -q 'NET_CAPABILITY_INTERNET' "$J/src/org/smc/inputmethod/indic/voice/OfflineVoiceRouter.java"
# Name Correction Layer (Farhan reply 12): rules file + corrector + panel wiring.
test -f "$J/res/raw/name_corrections.json"
test -f "$J/src/org/smc/inputmethod/indic/voice/NameCorrector.java"
grep -q 'NameCorrector.correct' "$J/src/com/android/inputmethod/keyboard/voice/DictationView.java"
python3 - "$J/res/raw/name_corrections.json" <<'PYEOF'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
rules = data["rules"]
assert len(rules) >= 4, rules
pairs = {(r["wrong"], r["right"]) for r in rules}
assert ("فرانک", "فرحان") in pairs and ("منھنا", "میوز") in pairs
assert ("فرانس", "فرحان") in pairs and ("منع", "میوز") in pairs
print("name_corrections.json OK (4 rules)")
PYEOF
test -f "$J/res/xml/prefs_screen_phrases.xml"
test -f "$J/res/raw/quick_phrases.json"
test -f "$J/res/raw/voice_model_manifest.json"
# Seed + manifest are valid JSON with the designed shape (6 categories,
# 16 phrases; 5 pinned model files).
python3 - "$J/res/raw/quick_phrases.json" "$J/res/raw/voice_model_manifest.json" <<'PYEOF'
import json, sys
seed = json.load(open(sys.argv[1], encoding="utf-8"))
assert len(seed["categories"]) == 6, seed["categories"]
assert len(seed["phrases"]) == 16, seed["phrases"]
manifest = json.load(open(sys.argv[2], encoding="utf-8"))
assert len(manifest["files"]) == 5, manifest["files"]
assert all(len(f["sha256"]) == 64 for f in manifest["files"])
print("quick_phrases.json (6 categories, 16 phrases) + voice manifest (5 files) OK")
PYEOF
echo "RAHEEM AI ULTRA v1 repack + single feature update (v2 recipe) applied OK"
