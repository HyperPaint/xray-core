#!/bin/bash

repository="hyperpaint"
name="xray-core"
version="1.0.0"
xray_core_version="25.9.11"

docker build -t "$repository/$name:$version-$xray_core_version" .
