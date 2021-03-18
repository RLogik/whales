# Whales #

This repository is designed to be a template to ‘dockerise’ coding repositories.
When working collaboratively on a project, participants often have different operating systems and setups.
This can be a real nightmare, especially when testing if your code behaves as intended.
To bypass this, it is useful for all participants to be able to set up the same virtual environment with exactly the same settings,
within which the project can be compiled, run, and tested.
Docker presents itself as a universal, easily accessible solution, with a minimal setup effort.

## Hello World Example ##

```
 /¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯\       v ˇ
 | There be whales!
 \______  __________/
        \ |                      .
         \|                    ==
          \                 ===
     /''''**'''''''''''\___/ ===
~~~ {~~ ~~~~ ~~~ ~~~~ ~~ ~ / ====- ~~~~
####\|||||||| ^   U    __/######==#####
##### ¯¯¯¯¯¯¯¯\_______/###########.####
#######################################
#######################################
```

1. Clone this repository.
2. Ensure you have installed Docker and at least granted access to the folder in which the repository has been cloned.
3. Ensure you have bash or bash for Windows.
4. Navigate to the root path of the repository and execute the following commands in bash:

    ```bash
    chmod +x *.sh; # grant execution rights to the shell scripts
    ./hello.sh "Captain..."
    ./hello.sh "There be whales\!" # NOTE: Do not write "!"
    ```

    If performed correctly, first the docker image will be created.
    Then the docker image will be started in a container,
    and you will see two whales with messages `(blank)` and `Hello world!`.
    Then upon the second "hello" script execution, the docker image will be started in a container,
    and you will see two whales with messages `Hello world!` and `I am a whale`.
    One should also see a file `HELLO_WORLD` in the root of the project,
    which will be modified as one calls the above commands.
    If one modifies this file, then calls the script, the modifications
    should display.
5. If this works as described, then this means the scripts function correctly:
    Project users are able to start images with ease, execute methods within them
    (_e.g._ compilation of a code, execution of an algorithm, _etc._)
    and the results can be saved (optionally) for the next execution.

## Status and cleaning ##

Call `. whales_setup/docker.sh --status` to view the status of the containers and images.
For example after the above hello-world example, the status looks like this:

```
[INFO] Container states:
CONTAINER ID   NAMES            IMAGE          SIZE                 STATUS
3exxxxxxxxx2   whales_hello_1   whales:hello   0B (virtual 101MB)   Exited (0) 50 seconds ago

[INFO] Images:
IMAGE ID       REPOSITORY   TAG       SIZE      CREATED AT
efxxxxxxxxx2   whales       explore   101MB     2021-xxxxx:15:19
53xxxxxxxxx8   <none>       <none>    101MB     2021-xxxxx:15:02
d6xxxxxxxxx2   whales       hello     101MB     2021-xxxxx:14:57
```

Call `. whales_setup/docker.sh --clean` to clean all whale-containers and whale-images.

Call `. whales_setup/docker.sh --clean-all` to clean all containers and images.

## How to start a project with Whales ##

1. Clone this repository (and delete unnecessary subfolders like [/examples](examples)).
2. Modify
    [whales_setup/.env](whales_setup/.env),
    [whales_setup/docker-compose.yml](whales_setup/docker-compose.yml),
    and
    [whales_setup/Dockerfile](whales_setup/Dockerfile)
    to suit the needs of your application.
3. Within scripts for processes you intend to start in a docker service, add

    ```bash
    source whales_setup/.lib.whales.sh;
    source whales_setup/.lib.sh;
    ```

    to the start of your script.
    Prepend commands to be called within docker services with the `call_within_docker` command.
    See the existing scripts in this repository (`build.sh`, `test.sh`) for examples.
    Refer also to the section
        [_How to modify bash scripts_](#how-to-modify-bash-scripts-to-work-with-whales)
    below.

See also the subfolders in [/examples](examples) for further implementation examples of projects with Whales.

## How to add Whales to existing projects ##

1. Add the folder [/whales_setup](whales_setup) and a `.dockerignore` file (if one does not exist) to the root folder of your project.
    In `./.dockerignore` append the line

    ```.dockerignore
    !/whales_setup
    ```
2. Add services to [whales_setup/docker-compose.yml](whales_setup/docker-compose.yml).
    Take care to use the build context `..` (or `../path/to/subfolder`) instead of `.` (or `path/to/subfolder`).
    For mounted volumes, again take care to relativise to the `whales_setup` subfolder
    (_e.g._ `-./../src:$WD/src` and not `-src:$WD/src`).
3. In [whales_setup/Dockerfile](whales_setup/Dockerfile),
    provided the context in [whales_setup/docker-compose.yml](whales_setup/docker-compose.yml) has been set appropriately,
    there should be no need to worry about relativising paths.
4. Modify process scripts (see section [_How to modify bash scripts_](#how-to-modify-bash-scripts-to-work-with-whales)).

## How to modify bash scripts to work with Whales ##

The `call_within_docker` command in [whales_setup/.lib.whales.sh](whales_setup/.lib.whales.sh) acts as a quasi decorator.
When used, it

- interrupts a running script
- checks whether currently inside the docker environment (by consulting a file `whales_setup/DOCKER_DEPTH`),
- if already inside docker, it will return to the original script,
- otherwise it will launch the appropriate docker container (with an image:tag name assigned to it) in the appropriate mode,
and then call the original script within the container.

Modification of existing bash scripts, _e.g._ `build.sh`, `test.sh`, _etc._ in the root folder of your project
are can be modified quite simply as the following example demonstrate.

#### Example 1 ####

Original bash file, `build.sh`:

```bash
#/bin/bash

python3 -m pip install tensorflow;
python3 src/main.py
```

This becomes:

```bash
#/bin/bash

SCRIPTARGS="$@";
source whales_setup/.lib.whales.sh;
source whales_setup/.lib.sh;

# call_within_docker <base_tag> <tag>     <save> <it>  <expose_ports> <script>  <params>
call_within_docker   "prod"     "setup"   false  false true           "build.sh" $SCRIPTARGS;

python3 -m pip install tensorflow;
python3 src/main.py
```

**NOTE:** Replace `"prod"` by the appropriate service name in `whales_setup/docker-compose.yml`.

#### Example 2 ####

Original bash file, `test.sh`:

```bash
#/bin/bash

mode="$1";
if [ "$mode" == "interactive" ]; then
    swipl -lq src/main.pl;
else
    swipl -fq src/main.pl -t halt;
fi
```

This becomes:

```bash
#/bin/bash

SCRIPTARGS="$@";
FLAGS=( "$@" );

source whales_setup/.lib.whales.sh;
source whales_setup/.lib.sh;

mode="${FLAGS[0]}";
if [ "$mode" == "interactive" ]; then
    # call_within_docker <base_tag> <tag>     <save> <it>  <expose_ports> <script>  <params>
    call_within_docker   "test"     "explore" true   true  true           "test.sh" $SCRIPTARGS;
    swipl -lq src/main.pl;
else
    # call_within_docker <base_tag> <tag>     <save> <it>  <expose_ports> <script>  <params>
    call_within_docker   "test"     "explore" false  false true           "test.sh" $SCRIPTARGS;
    swipl -fq src/main.pl -t halt;
fi
```

**NOTE 1:** Replace `"test"` by the appropriate service name in `whales_setup/docker-compose.yml`.

**NOTE 2:** Set the `<save>` to true/false, depending upon whether you want to overwrite the state
of the image after carrying out the commands/interactions in the docker container.
