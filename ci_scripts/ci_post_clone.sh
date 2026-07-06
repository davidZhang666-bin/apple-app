#!/bin/sh
set -e

echo "Ruby: $(ruby --version)"
echo "CocoaPods: $(pod --version)"

cd KYHSApp
pod install --repo-update
