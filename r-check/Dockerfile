FROM rocker/r-devel

MAINTAINER Winston Chang "winston@rstudio.com"

RUN apt-get install -y \
    libcurl4-gnutls-dev

RUN Rscript -e "install.packages('devtools'); \
          update.packages(ask = FALSE)" && \
    Rscript -e "devtools::install_github('hadley/devtools')"

RUN echo "\nalias R='R --no-save --no-restore-data --quiet'" >> $HOME/.bashrc && \
    echo "R_LIBS_USER=~/R-lib/%v" > $HOME/.Renviron && \
    mkdir -p $HOME/R-lib/3.1 $HOME/R-lib/3.2

# Can't use $HOME with COPY for some reason
COPY check_all.R /root/check_all.R

# Temporary workaround for bug in rocker/R-devel:
# https://github.com/rocker-org/rocker/issues/53
RUN echo 'options("repos"="http://cran.rstudio.com")' >> /usr/local/lib/R/etc/Rprofile.site
