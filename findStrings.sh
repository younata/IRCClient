#!/usr/bin/env bash

find . -name '*.m' | xargs genstrings -o en.lproj
