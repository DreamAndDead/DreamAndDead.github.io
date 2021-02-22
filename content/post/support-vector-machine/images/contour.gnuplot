set multiplot
f(x, y) = -x**2-y**2 + x*y

set view map

unset xtics
unset ytics

unset surface
set contour
set isosamples 100
set cntrlabel onecolor
set cntrparam levels discrete -5, -4, -3, -2, -1.5, -0.75, -0.5, -0.1875, -0.046875, 0
splot [-3:3] [-3:3] f(x, y) linetype rgb "black" with lines title ""
unset contour

set surface
splot [x=-3:3] [y=-3:3] 'contour.table' using 1:2:(f($1, $2)) lt rgb "blue" with lines title ""

unset multiplot
