#!/usr/bin/env Rscript
f = file("stdin")
open(f)
state_data = read.delim(f, header=FALSE)
colnames(state_data) = c("State","City","Population")
summary(state_data)
