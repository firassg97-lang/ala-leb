#!/usr/bin/env bash
#
# fix_privacy_manifests.sh
# ------------------------------------------------------------------
# Scans every *.xcprivacy privacy manifest under ios/Pods and repairs
# the ITMS-91064 condition:
#
#   "NSPrivacyTracking must be true if NSPrivacyTrackingDomains isn't empty."
#
# For any manifest where NSPrivacyTrackingDomains is NON-empty but
# NSPrivacyTracking is missing or set to false, it forces
# NSPrivacyTracking = true. It never edits app logic and never touches
# files that are already consistent.
#
# Safe to run repeatedly (idempotent). Intended to run in CI right
# after `pod install`. Requires macOS (uses /usr/libexec/PlistBuddy).
# ------------------------------------------------------------------
set -euo pipefail

PLIST_BUDDY="/usr/libexec/PlistBuddy"
PODS_DIR="${1:-ios/Pods}"

if [ ! -d "$PODS_DIR" ]; then
  echo "⚠️  Pods directory not found at '$PODS_DIR' — skipping privacy manifest fix."
  exit 0
fi

if [ ! -x "$PLIST_BUDDY" ]; then
  echo "⚠️  PlistBuddy not available (not macOS?) — skipping privacy manifest fix."
  exit 0
fi

echo "🔍 Scanning '$PODS_DIR' for .xcprivacy manifests…"

fixed_count=0
scanned_count=0

# -print0 / read -d '' to survive paths with spaces
while IFS= read -r -d '' manifest; do
  scanned_count=$((scanned_count + 1))

  # Count non-empty entries inside NSPrivacyTrackingDomains.
  # PlistBuddy prints an array as:
  #   Array {
  #       some.domain.com
  #   }
  # We strip the first ("Array {") and last ("}") lines and count the rest.
  domain_count=$(
    "$PLIST_BUDDY" -c "Print :NSPrivacyTrackingDomains" "$manifest" 2>/dev/null \
      | sed -e '1d' -e '$d' \
      | grep -c '[^[:space:]]' || true
  )

  # Nothing to do if there are no tracking domains.
  if [ "${domain_count:-0}" -eq 0 ]; then
    continue
  fi

  # Read the current NSPrivacyTracking value ("true", "false", or empty).
  tracking_value=$("$PLIST_BUDDY" -c "Print :NSPrivacyTracking" "$manifest" 2>/dev/null || true)

  if [ "$tracking_value" = "true" ]; then
    # Already consistent — leave it untouched.
    continue
  fi

  echo "⚙️  Fixing: $manifest"
  echo "     NSPrivacyTrackingDomains has $domain_count entr(y/ies) but NSPrivacyTracking='${tracking_value:-<missing>}'"

  if [ -z "$tracking_value" ]; then
    # Key is missing → add it as a boolean true.
    "$PLIST_BUDDY" -c "Add :NSPrivacyTracking bool true" "$manifest"
  else
    # Key exists (false) → set it to true.
    "$PLIST_BUDDY" -c "Set :NSPrivacyTracking true" "$manifest"
  fi

  echo "     ✅ NSPrivacyTracking set to true"
  fixed_count=$((fixed_count + 1))
done < <(find "$PODS_DIR" -name "*.xcprivacy" -type f -print0)

echo "🏁 Done. Scanned $scanned_count manifest(s), fixed $fixed_count."
