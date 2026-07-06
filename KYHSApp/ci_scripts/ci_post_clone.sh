#!/bin/sh
set -e

echo "Ruby: $(ruby --version)"
echo "CocoaPods: $(pod --version)"

pod install --repo-update
