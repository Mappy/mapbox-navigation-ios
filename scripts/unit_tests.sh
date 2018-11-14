#!/usr/bin/env bash

set -e

SIMULATOR_VERSION=12.1

xcodebuild test -scheme "MapboxDirections iOS" -destination "platform=iOS Simulator,name=iPhone 8,OS=${SIMULATOR_VERSION}" | xcpretty -r junit --output test-reports/TEST-MBDirections.xml && exit ${PIPESTATUS[0]}

