set samples 1000
log2(x) = log(x) / log(2)
f(x) = - x * log2(x) - (1 - x) * log2(1 - x)

plot [0:1] f(x)