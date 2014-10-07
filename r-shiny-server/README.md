Docker for Shiny Server
=======================

This is a Dockerfile for Shiny Server on Ubuntu 14.04.


## Usage:

To run a temporary container with Shiny Server:

```sh
docker run --rm -p 3838:3838 wch1/r-shiny-server
```


To expose a directory on the host to the container use `-v <host_dir>:<container_dir>`:

```sh
docker run --rm -p 3838:3838 -v /home/username/shinyapps/:/srv/shiny-server/ wch1/r-shiny-server
```

If you have an app in /home/username/shinyapps/appdir, you can run the app by visiting http://localhost:3838/appdir/. (If using boot2docker, visit http://192.168.59.103:3838/appdir/


To run in the background, listening on port 80:

```sh
docker run -d -p 80:3838 -v /home/username/shinyapps/:/srv/shiny-server/ wch1/r-shiny-server
```
