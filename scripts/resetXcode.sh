#!/bin/bash
killall Xcode
xcrun -k
xcodebuild -alltargets clean
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Caches/com.apple.dt.Xcode/*
open /Applications/Xcode.app