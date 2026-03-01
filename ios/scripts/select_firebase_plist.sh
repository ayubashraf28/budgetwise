#!/bin/sh
set -eu

PROJECT_DIR="${PROJECT_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
ENV_NAME="${APP_ENV:-prod}"

case "$ENV_NAME" in
  dev)
    SOURCE_FILE="$PROJECT_DIR/Runner/Firebase/GoogleService-Info-Dev.plist"
    ;;
  stg|stage|staging)
    SOURCE_FILE="$PROJECT_DIR/Runner/Firebase/GoogleService-Info-Stg.plist"
    ;;
  prod|production|*)
    SOURCE_FILE="$PROJECT_DIR/Runner/Firebase/GoogleService-Info-Prod.plist"
    ;;
esac

DEST_FILE="$PROJECT_DIR/Runner/GoogleService-Info.plist"

if [ ! -f "$SOURCE_FILE" ]; then
  echo "Missing Firebase plist for APP_ENV=$ENV_NAME at $SOURCE_FILE"
  exit 1
fi

cp "$SOURCE_FILE" "$DEST_FILE"
echo "Selected Firebase plist: $SOURCE_FILE -> $DEST_FILE"
