set isosamples 1000
log2(x) = log(x) / log(2)
f(x, y) = - x * log2(x) - y * log2(y) - (1 - x - y) * log2(1 - x - y)

splot [0:1] [0:1] f(x, y) linetype rgb "black" with pm3d