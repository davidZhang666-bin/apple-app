#!/bin/sh
set -e

echo "Ruby: $(ruby --version)"
echo "CocoaPods: $(pod --version)"

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$script_dir/../KYHSApp"
echo "Installing CocoaPods dependencies in $(pwd)"
pod install --deployment --verbose
