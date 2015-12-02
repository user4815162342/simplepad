#!/bin/sh
ln -s executable/simplepad /usr/local/bin/simplepad
xdg-mime install ftm-mimetype.xml
cp simplepad.desktop /usr/local/share/applications/simplepad.desktop
xdg-mime default simplepad.desktop text/x-ftm

