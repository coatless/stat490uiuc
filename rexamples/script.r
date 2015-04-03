#!/usr/bin/env Rscript
f = file("stdin") ## read the contents of standard input (stdin)
open(f) ## open the handle on stdin
my_data = read.delim(f, header=FALSE, stringsAsFactors=FALSE) ## read stdin as a table
my_data_count = table(my_data[,1]) ## count the number of occurance of column 1
write.table(my_data_count,quote = FALSE,row.names = FALSE,col.names = FALSE,sep = "\t") ## format the output so we see column1<tab>count
