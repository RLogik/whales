# Templates #

This folder contains a few extra templates of primarily bash files
that can be used in projects.

## Template for **.gitignore** and **.dockerignore** ##

```
*
!/.gitignore     # <- do not need these lines in .dockerignore
!/.dockerignore  # <-

# Need these for Whales project:
!/.whales
!/.whales.env
!/.whales.Dockerfile         # <- do not need these lines in .dockerignore
!/.whales.docker-compose.yml # <-

################################################################
# MAIN FOLDER
################################################################
!/.env
!/README.md
!/ISSUES.md
!/LICENSE

!/.lib.sh
!/build.sh
!/clean.sh
!/test.sh

################################################################
# PROJECT FILES
################################################################
# !/src
# !/test
# !/dist
# !/dist/VERSION

################################################################
# AUXLIARY
################################################################
/logs

################################################################
# ARTEFACTS
################################################################
#

################################################################
# Git Keep
################################################################
!/**/.gitkeep
```
