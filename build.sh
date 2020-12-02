#!/usr/bin/env bash
sed -i "s/%VERSION%/$(git describe --abbrev --always --dirty)/" book.md
pandoc --to=epub3 --toc --default-image-extension=png -o book.epub book.md
pandoc            --toc --default-image-extension=png -o book.pdf book.md
