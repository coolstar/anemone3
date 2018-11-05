#!/bin/bash
cp common/watermarktemplate.h common/watermark.h
sed -i .bak "s/placeHolderFunction/$1/g" common/watermark.h

if [ -f common/watermark.h.bak ]; then
	rm common/watermark.h.bak
fi