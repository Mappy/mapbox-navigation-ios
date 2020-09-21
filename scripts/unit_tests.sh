#!/usr/bin/env bash

set -e

SIMULATOR_VERSION=13.7

xcodebuild test -scheme MapboxCoreNavigation -destination "platform=iOS Simulator,name=iPhone 8,OS=${SIMULATOR_VERSION}" -testLanguage fr -testRegion fr_FR | xcpretty -r junit --output test-reports/TEST-MBCoreNavigation.xml && exit ${PIPESTATUS[0]}
