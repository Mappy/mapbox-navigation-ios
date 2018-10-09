#!/usr/bin/env bash

set -e

xcodebuild -scheme MapboxCoreNavigationUniversal -configuration Release -UseModernBuildSystem=NO
