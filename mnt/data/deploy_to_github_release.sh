#!/bin/bash
# FortressPi v22.0 GitHub Full Auto-Deploy Script

REPO_URL="https://github.com/Streep69/FlySkiPi.git"
BRANCH="release-v22"

echo "🔁 Cloning repository..."
git clone $REPO_URL fortresspi_release
cd fortresspi_release
git checkout -b $BRANCH

echo "📦 Copying files..."
cp -r ../FortressPi_Full_GitHub_Push/* .

echo "📂 Committing changes..."
git add .
git commit -m "Release v22.0 - Full FortressPi Bundle"
git push origin $BRANCH

echo "🚀 Creating release..."
gh release create v22.0 ./FortressPi_Deploy_Validated_Final.zip ./FortressPi_LogicAudit_Manifest.zip --title "FortressPi v22.0 Final Bundle" --notes-file RELEASE_NOTES.md
