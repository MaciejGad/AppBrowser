#!/bin/bash
mkdir -p colors_tests
icon=`grep icon_name  config.json | tr "\"" " " | awk '{print $3}'`
for x in `cat color_variants.txt`; do  swift icon_gen.swift $icon $x colors_tests/$x.png; done