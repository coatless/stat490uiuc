# Install rmr2 dependencies
install.packages(c('RJSONIO', 'itertools', 'digest', 'Rcpp', 'functional', 'httr', 'plyr', 'stringr', 'reshape2', 'caTools', 'rJava'), repos="http://cran.us.r-project.org", INSTALL_opts=c('--byte-compile') )

# Install plyrmr dependencies
install.packages(c('dplyr', 'R.methodsS3', 'Hmisc'), repos="http://cran.us.r-project.org", INSTALL_opts=c('--byte-compile')

# Installs some wonderful HPC Packages
install.packages(c("bigmemory","foreach","iterators","doMC","doSNOW","itertools"), repos="http://cran.us.r-project.org", INSTALL_opts=c('--byte-compile') )
