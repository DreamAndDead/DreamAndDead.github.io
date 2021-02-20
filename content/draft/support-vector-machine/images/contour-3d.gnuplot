set multiplot
f(x, y) = -x**2 - y**2 + x*y

set isosamples 100
set hidden3d
unset colorbox

unset xtics
unset ytics
unset ztics
set border 15

splot [-3:3] [-3:3] f(x, y) with pm3d title ""

splot [x=-3:3] [y=-3:3] 'contour.table' using 1:2:(f($1, $2)) lt rgb "blue" with lines title ""

unset multiplot
