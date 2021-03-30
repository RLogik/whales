# Installation of Whales via artefacts #

The [importwhales](importwhales) script allows users to automate importing whales into their projects.
Grant this script permissions (`chmod +x importwhales`).
Place it in a directory of binaries in your system's `$PATH` variable (_e.g._ `/usr/local/bin` on Linux/OSX).
Within all code projects users simply call `importwhales {TAG-NAME}` to import Whales in one step.
See the [releases page](https://github.com/RLogik/whales/releases) for valid tag names.
The script simply downloads the versioned Github artefact to a temporary folder,
unpacks it and copies in the relevant parts, namely the following
```
    . (project root)
    |
    | ...
    |
    |____ /.whales
    |____ /.whales.templates
    |__ .whales.env                # <- not overwritten if already exists
    |__ .whales.Dockerfile         # "
    |__ .whales.docker-compose.yml # "
    |
    | ...
    |
```
to your current path. If you already have old Whales files in your directory,
the script will only overwrite the subfolders `./.whales` and `./.whales.templates`,
but **does not overwrite** the three user config files.

The script also contains a variant which downloads artefacts from Dockerhub
(see [dockerhub/rlogik/whales](https://hub.docker.com/r/rlogik/whales/tags)).
Simply switch which lines are commented out in the script at this position:
```bash
...
get_artefact_from_repo "${TAG}";
# get_artefact_via_docker "${TAG}";
...
```
We will likely in future publish to another Docker registry,
and will then update this script.
