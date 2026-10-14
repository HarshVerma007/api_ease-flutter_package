#!/usr/bin/env bash
# Usage: ./release.sh 1.0.0
# Run from the api_ease package root, after `git remote add origin ...`.
set -euo pipefail

VERSION="${1:-1.0.0}"
TAG="v${VERSION}"

# 1. Detect your GitHub username from the origin remote.
REMOTE_URL="$(git remote get-url origin)"
OWNER="$(echo "$REMOTE_URL" | sed -E 's#^(git@github.com:|https://github.com/)([^/]+)/.*#\2#')"
echo "GitHub user: $OWNER"

# 2. Fill in your username (works on macOS and Linux).
perl -pi -e "s#github\.com/OWNER/#github.com/$OWNER/#g" README.md
perl -pi -e "s#github\.com/user/#github.com/$OWNER/#g" pubspec.yaml

# 3. Make sure pubspec and tag agree.
if ! grep -q "^version: ${VERSION}\$" pubspec.yaml; then
  echo "pubspec.yaml version is not ${VERSION}. Fix it first." >&2
  exit 1
fi

# 4. Verify, commit, push.
flutter pub get
flutter analyze
flutter test

git add -A
git commit -m "Prepare release ${TAG}" || echo "Nothing to commit"
git push origin HEAD

# 5. Tag and push the tag.
git tag -a "$TAG" -m "api_ease ${VERSION}"
git push origin "$TAG"

echo "Done. Create the release at: https://github.com/$OWNER/api_ease/releases/new?tag=$TAG"
