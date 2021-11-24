#!/bin/sh
APP_TAG=$3
docker tag $1 $2:${APP_TAG}
