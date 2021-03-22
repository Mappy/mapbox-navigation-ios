#!/bin/bash

# sync_mappy_fork - A script to sync Mappy fork of Navigation with Mapbox repository

git remote -v | grep 'upstream' &> /dev/null || git remote add upstream https://github.com/mapbox/mapbox-navigation-ios.git
git remote update
git checkout master
git pull origin master
git pull --rebase upstream master
git push origin master
git checkout -
