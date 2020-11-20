#!/usr/bin/env bash
pandoc --to=epub3 --mathml --toc --default-image-extension=png -o book.epub book.md
pandoc --pdf-engine=xelatex --mathml --toc --default-image-extension=png -o book.pdf book.md
