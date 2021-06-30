#!/bin/bash

echo Building NYPLAxis
cd Axis-iOS
git fetch && git checkout develop
./buildFramework.sh
cd ..



