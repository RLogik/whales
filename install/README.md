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
    |____ /.whales # (renamed from src)
   *|____ /.whales.templates # included if --templates flag used
   *|____ /.whales.examples  # included if --examples  flag used
    |
    |__ .whales.env                # <- only overwritten if --force used
    |__ .whales.Dockerfile         # "
    |__ .whales.docker-compose.yml # "
    |
    | ...
    |
```
to your current path.
<br>
Use the `--local` flag, to clone a locally saved distribution.
<br>
Use the `--force` flag, to force overwrite the 3 user config files.
<br>
Use the `--templates` flag to copy in the template folder.
<br>
Use the `--exmples` flag to copy in the examples folder.
<br>
The folder `./.whales` will be overwritten by force.

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

## Configuration ##

1. After adding Whales to your code project
    add a `./.dockerignore` file, if one does not exist,
    and append the lines
    ```.gitignore
    # in .dockerignore
    !/.whales
    !/.whales.env
    ```
2. Modify the [.whales.env](.whales.env) file in the project root.
    In particular, set the name of your project here:
    ```.env
    # in .whales.env
    WHALES_COMPOSE_PROJECT_NAME=<your project name>
    ```
    Setting this argument to be different for different projects prevents
    Docker from confusing your images and containers with those of other projects.
3. Modify
    [.whales.docker-compose.yml](.whales.docker-compose.yml)
    +
    [.whales.Dockerfile](.whales.Dockerfile)
    to suit the needs of your application.
    If in the docker-compose file you use your own Dockerfiles,
    ensure the block of instructions
    in [.whales.Dockerfile](.whales.Dockerfile) is included.
