#!/usr/bin/env bash

set -e

carthage bootstrap --platform ios
xcodebuild -scheme MapboxCoreNavigationUniversal -configuration Release -UseModernBuildSystem=NO
