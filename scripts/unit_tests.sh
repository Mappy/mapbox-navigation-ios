#!/usr/bin/env bash

set -e

SIMULATOR_VERSION=12.2

xcodebuild test -scheme MapboxCoreNavigation -destination "platform=iOS Simulator,name=iPhone 8,OS=${SIMULATOR_VERSION}" | xcpretty -r junit --output test-reports/TEST-MBCoreNavigation.xml && exit ${PIPESTATUS[0]}

