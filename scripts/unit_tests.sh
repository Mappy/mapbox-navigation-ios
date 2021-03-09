#!/usr/bin/env bash

set -e

xcodebuild test -scheme "MapboxCoreNavigation" -destination "platform=iOS Simulator,name=iPhone 8" -testLanguage fr -testRegion fr_FR | xcpretty -r junit --output test-reports/TEST-MapboxCoreNavigation.xml && exit ${PIPESTATUS[0]}
