#!/usr/bin/env bash

set -e

carthage update --platform iOS
xcodebuild -scheme MapboxCoreNavigationUniversal -configuration Release -UseModernBuildSystem=NO
