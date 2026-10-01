#!/usr/bin/env bash

# Your Bot Token & Target Channel
BOT_TOKEN="8721916407:AAGxW72Li0r0WK36IzUM8bOCosh35F9_AE0"
CHAT_ID="-1003480158558"
PIXELDRAIN_KEY="5e3542a1-e24f-4eb0-bcc2-9aced837931c"

# Host Choice: "pixeldrain", "gofile", or "both"
PREFERRED_HOST="both"

# Device Configuration
DEVICE_NAME="Redmi Turbo 3 / POCO F6"
DEVICE_CODENAME="peridot"
MAINTAINER="BLU/Ryznstk"

# Target Links
DONATE_URL="https://sociabuzz.com/blu_stk/donate"
CHANNEL_URL="https://t.me/blu_stk"

# Auto-detect built ZIP file from 'out/target/product/peridot/'
ZIP_PATH=$(ls -t out/target/product/${DEVICE_CODENAME}/*.zip 2>/dev/null | head -n 1)

if [ -z "$ZIP_PATH" ] && [ -n "$1" ]; then
    ZIP_PATH="$1"
fi

if [ -z "$ZIP_PATH" ] || [ ! -f "$ZIP_PATH" ]; then
    echo "❌ Error: No ROM ZIP file found!"
    exit 1
fi

ZIP_NAME=$(basename "$ZIP_PATH")
FILE_SIZE=$(du -h "$ZIP_PATH" | cut -f1)
BUILD_DATE=$(date +"%B %d, %Y")
DETECTED_ROM=$(echo "$ZIP_NAME" | cut -d'-' -f1)

ROM_NAME="${ROM_NAME:-$DETECTED_ROM}"
ROM_VERSION="${ROM_VERSION:-official}"

# Upload Functions
upload_pixeldrain() {
    echo "🚀 Uploading to PixelDrain..." >&2
    if [ -n "$PIXELDRAIN_KEY" ]; then
        # Authenticated Upload
        RES=$(curl -s -u ":$PIXELDRAIN_KEY" -F "file=@$ZIP_PATH" "https://pixeldrain.com/api/file")
    else
        # Anonymous Fallback
        RES=$(curl -s -F "file=@$ZIP_PATH" "https://pixeldrain.com/api/file")
    fi
    
    ID=$(echo "$RES" | jq -r '.id 2>/dev/null')
    if [ -n "$ID" ] && [ "$ID" != "null" ]; then
        echo "https://pixeldrain.com/u/$ID"
    fi
}

upload_gofile() {
    echo "🚀 Uploading to GoFile..." >&2
    SERVER=$(curl -s "https://api.gofile.io/servers" | jq -r '.data.servers[0].name 2>/dev/null')
    SERVER="${SERVER:-store1}"
    RES=$(curl -s -F "file=@$ZIP_PATH" "https://${SERVER}.gofile.io/contents/uploadfile")
    echo "$RES" | jq -r '.data.downloadPage 2>/dev/null'
}

# Process Uploads
if [ "$PREFERRED_HOST" == "pixeldrain" ]; then
    DOWNLOAD_URL=$(upload_pixeldrain)
elif [ "$PREFERRED_HOST" == "gofile" ]; then
    DOWNLOAD_URL=$(upload_gofile)
fi

# Construct Caption
CAPTION="<b>${ROM_NAME} is now available for ${DEVICE_NAME}</b>

<b>version :</b> ${ROM_VERSION}
<b>Maintainer :</b> ${MAINTAINER}
<b>File Size :</b> ${FILE_SIZE}
<b>Build Date :</b> ${BUILD_DATE}"

# Construct 2x2 Inline Keyboard
KEYBOARD=$(cat <<EOF
{
  "inline_keyboard": [
    [
      {"text": "Download ↗", "url": "${DOWNLOAD_URL}"},
      {"text": "Changelogs ↗", "url": "${CHANGELOG_URL}"}
    ],
    [
      {"text": "Donate ↗", "url": "${DONATE_URL}"},
      {"text": "Channel ↗", "url": "${CHANNEL_URL}"}
    ]
  ]
}
EOF
)

# Publish to Channel
echo "📢 Sending post to BLU personal build..."
curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendPhoto" \
     -F "chat_id=${CHAT_ID}" \
     -F "photo=@${BANNER_PATH}" \
     -F "caption=${CAPTION}" \
     -F "parse_mode=HTML" \
     -F "reply_markup=${KEYBOARD}" > /dev/null

echo "🎉 Done! Check @blu_stk"
