#!/usr/bin/env bash
pandoc --to=epub3 --toc --default-image-extension=png -o book.epub book.md
pandoc            --toc --default-image-extension=png -o book.pdf book.md
