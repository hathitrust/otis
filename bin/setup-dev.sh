#!/usr/bin/env bash

BINPATH=`dirname $0`
cd $BINPATH/..
docker compose run --rm dev /bin/bash -c "bundle install && npm install && npm run build"

errVal=$?
if [ $errVal -ne 0 ]
then
  exit $errVal
fi

echo "otis build done"
