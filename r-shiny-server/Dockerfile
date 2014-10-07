FROM eddelbuettel/ubuntu-r-base

MAINTAINER Winston Chang "winston@rstudio.com"

RUN update-locale

RUN apt-get install -y \
    gdebi-core \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev

# Download and install shiny server
RUN wget https://s3.amazonaws.com/rstudio-shiny-server-pro-build/ubuntu-12.04/x86_64/VERSION -O "version.txt" && \
    VERSION=$(cat version.txt)  && \
    wget "https://s3.amazonaws.com/rstudio-shiny-server-pro-build/ubuntu-12.04/x86_64/shiny-server-commercial-$VERSION-amd64.deb" -O ssp-latest.deb && \
    gdebi -n ssp-latest.deb && \
    rm -f version.txt ssp-latest.deb

RUN echo "password" | /opt/shiny-server/bin/sspasswd /etc/shiny-server/passwd "admin"

RUN R -e "install.packages(c('shiny', 'rmarkdown'), repos='http://cran.rstudio.com/')"

RUN cp -R /usr/local/lib/R/site-library/shiny/examples/* /srv/shiny-server/

EXPOSE 3838

CMD ["/usr/bin/shiny-server"]
