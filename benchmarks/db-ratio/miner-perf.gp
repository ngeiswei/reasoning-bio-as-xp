set datafile separator ','
set xlabel "db-ratio"
set ylabel "max-error"
plot "miner-perf.csv" using 1:4 with lines
