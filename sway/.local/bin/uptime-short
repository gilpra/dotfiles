#!/bin/sh

uptime -p |
  sed 's/up //' |
  sed 's/ hours\?/h/' |
  sed 's/ minutes\?/m/' |
  sed 's/ hour\?/h/' |
  sed 's/ minute\?/m/'
