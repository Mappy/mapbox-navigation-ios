#!/usr/bin/env bash

set -e

SIMULATOR_VERSION=11.4

xcodebuild test -scheme MapboxCoreNavigation -destination "platform=iOS Simulator,name=iPhone 8,OS=${SIMULATOR_VERSION}" | xcpretty -r junit --output test-reports/TEST-MBCoreNavigation.xml && exit ${PIPESTATUS[0]}

