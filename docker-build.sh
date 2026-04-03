#!/bin/bash

repository="hyperpaint"
name="xray-core"
version="1.0.0"
xray_core_version="26.2.2"

docker build --build-arg XRAY_CORE_VERSION="v${xray_core_version}" --tag "$repository/$name:$version-$xray_core_version" .
