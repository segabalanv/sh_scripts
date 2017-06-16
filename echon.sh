#!/bin/bash
echon() {
  echo "$*" | awk '{ printf "%s", $0 }'
}

echon "Enter coordinates for satellite acquisition: "
read coordinates
