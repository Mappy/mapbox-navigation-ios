#!/bin/bash

# sync_mappy_fork - A script to sync Mappy fork of Directions with Mapbox repository

git remote -v | grep 'upstream' &> /dev/null || git remote add upstream https://github.com/mapbox/MapboxDirections.swift.git
git remote update
git checkout master
git pull origin master
git merge upstream/master
git push origin master
git checkout -
