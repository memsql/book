#!/usr/bin/env bash
dot non-distributed-architecture.dot -Tpng -o non-distributed-architecture.png
dot non-distributed-architecture.dot -Tpdf -o non-distributed-architecture.pdf
dot distributed-architecture.dot -Tpng -o distributed-architecture.png
dot distributed-architecture.dot -Tpdf -o distributed-architecture.pdf
pandoc --to=epub3 --mathml --top-level-division=chapter --toc --default-image-extension=png -o book.epub book.md
pandoc --pdf-engine=xelatex --mathml --top-level-division=chapter --toc --default-image-extension=pdf -o book.pdf book.md
