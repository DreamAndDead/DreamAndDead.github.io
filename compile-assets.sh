#!/usr/bin/env bash

set -ex

# compile all tex files and convert to pngs

# need:
# - install texlive
# - install image magick
# - install gnuplot

dir=./assets

if [[ -d $1 ]]
then
    dir=$1
fi

export TEXINPUTS=$(pwd)/assets/img/texmf//:${TEXINPUTS}

# compile gnuplot
# gnuplot -e "cmd1; cmd2;" filename
find $dir -name *.gnuplot | sed -e 's/.gnuplot$//' | while read f; do cd $(dirname $f); gnuplot -e "set term pngcairo size 800,600; set output \"$(basename $f).png\"" $(basename $f).gnuplot; cd -; done

# compile tex
find $dir -name *.tex | sed -e 's/.tex$//' | while read f; do cd $(dirname $f); pdflatex -shell-escape -enable-write18 $(basename $f).tex; magick convert -density 200 -quality 100 -flatten $(basename $f).pdf $(basename $f).png; cd -; done
