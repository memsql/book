#!/usr/bin/env bash
sed -i.bak "s/%VERSION%/Version $(git describe --abbrev --always --dirty) -- $(date '+%B %d, %Y')/" book.md
pandoc --to=epub3 --toc --default-image-extension=png -o book.epub book.md
pandoc            --toc --default-image-extension=png -o book.pdf book.md
mv book.md.bak book.md
