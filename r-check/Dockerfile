FROM rocker/r-devel

MAINTAINER Winston Chang "winston@rstudio.com"

RUN apt-get install -y \
    libcurl4-gnutls-dev \
    libpq-dev \
    libmysqlclient-dev \
    pandoc \
    pandoc-citeproc

# Temporary workaround for bug in rocker/R-devel:
# https://github.com/rocker-org/rocker/issues/53
RUN echo 'options("repos"="http://cran.rstudio.com")' >> /usr/local/lib/R/etc/Rprofile.site

# Temporary workaround related to shared libpath problem:
# https://github.com/rocker-org/rocker/issues/54
RUN mkdir /usr/local/lib/R/site-library-devel && \
    echo "R_LIBS_SITE=\${R_LIBS_SITE-'/usr/local/lib/R/site-library-devel:/usr/local/lib/R/library:/usr/lib/R/library'}" \ > /usr/local/lib/R/etc/Renviron.site

RUN Rscript -e "install.packages('devtools'); update.packages(ask = FALSE)" && \
    Rscript -e "devtools::install_github('hadley/devtools')"

RUN Rscriptdevel -e "install.packages(c('devtools', 'rmarkdown'))" && \
    Rscriptdevel -e "devtools::install_github('hadley/devtools')"

RUN echo "\nalias R='R --no-save --no-restore-data --quiet'" >> $HOME/.bashrc && \
    echo "\nalias Rdevel='Rdevel --no-save --no-restore-data --quiet'" >> $HOME/.bashrc && \
    echo "R_LIBS_USER=~/R-lib/%v" > $HOME/.Renviron && \
    mkdir -p $HOME/R-lib/3.1 $HOME/R-lib/3.2

# Can't use $HOME with COPY for some reason
COPY check_all.R /root/check_all.R

