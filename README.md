```
 /¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯\       v ˇ
 | Thar be whales!
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

# Whales #

This repository is designed to be a template to ‘dockerise’ coding repositories.
When working collaboratively on a project, participants often have different operating systems and setups.
This can be a real nightmare, especially when testing if your code behaves as intended.
To bypass this, it is useful for all participants to be able to set up the same virtual environment with exactly the same settings,
within which the project can be compiled, run, and tested.
Docker presents itself as a universal, easily accessible solution, with a minimal setup effort.

## Hello World Example ##

1. Clone this repository.
2. Ensure you have installed Docker and at least granted access to the folder in which the repository has been cloned.
3. Ensure you have bash or bash for Windows.
4. Start the Docker application.
5. Navigate to the root path of the repository and execute the following commands in bash:

    ```bash
    chmod +x *.sh; # grant execution rights to the shell scripts
    ./hello.sh "Captain, ...";
    ./hello.sh "Thar be whales\!"; # NOTE: Do not write "!"
    ./hello.sh "I am a humpback whale.";
    ```

    If performed correctly, first the docker image will be created.
    Then the docker image will be started in a container,
    and you will see two whales with messages `(blank)` and `Hello world!`.
    Then upon the second "hello" script execution, the docker image will be started in a container,
    and you will see two whales with messages `Hello world!` and `I am a whale`.
6. In [whales_setup/docker-compose.yml](whales_setup/docker-compose.yml)
    one can optionally uncomment the volume mounting and repeat steps 4–5 above.
    One should now a file `HELLO_WORLD` in the root of the project,
    which will be modified as one calls the above commands.
    If one modifies this file, then calls the script, the modifications
    should display.
7. If this works as described, then this means the scripts function correctly:
    Project users are able to start images with ease, execute methods within them
    (_e.g._ compilation of a code, execution of an algorithm, _etc._)
    and the results can be saved (optionally) for the next execution.

## Status and cleaning ##

Call `./whales_setup/docker.sh --status` to view the status of the containers and images.
For example after the above hello-world example, the status looks like this:

```
SERVICES:
            Name                          Command               State    Ports
------------------------------------------------------------------------------
whales_setup_hello-service_1   bash -c echo -e "Service \ ...   Exit 0

         Container              Repository     Tag      Image Id       Size
-----------------------------------------------------------------------------
whales_setup_hello-service_1   whales-hello   build   35xxxxxxxxx6   101.3 MB

CONTAINERS:
CONTAINER ID   NAMES                          IMAGE                SIZE                 STATUS                     CREATED AT ago
e8xxxxxxxxx4   whales_setup_hello-service_1   whales-hello:build   0B (virtual 101MB)   Exited (0) 4 minutes ago   2021-xxxxxxxx:29:05 ago

IMAGES:
IMAGE ID       REPOSITORY     TAG       SIZE      CREATED AT
18xxxxxxxxx4   whales-hello   explore   101MB     2021-xxxxxxxx:31:54
e5xxxxxxxxx0   <none>         <none>    101MB     2021-xxxxxxxx:29:12
35xxxxxxxxx6   whales-hello   build     101MB     2021-xxxxxxxx:29:04
```

Call `./whales_setup/docker.sh --clean` to clean all whale-containers and whale-images.

Call `./whales_setup/docker.sh --clean-all` to clean all containers and images.

## How to start a new project with Whales ##

1. Clone this repository (and delete unnecessary subfolders like [./examples](examples)).
2. Modify the [.env](.env) file in the project root.
    Even if you wish to leave most values as is, definitely consider changing the value of the following key:
    ```.env
    WHALES_COMPOSE_PROJECT_NAME=whales
    ```
    Setting this argument to be different for different projects prevents
    Docker from confusing your images and containers with those of other projects.
3. Modify
    [whales_setup/docker.env](whales_setup/docker.env)
    +
    [whales_setup/docker-compose.yml](whales_setup/docker-compose.yml)
    +
    [whales_setup/Dockerfile](whales_setup/Dockerfile)
    to suit the needs of your application.
    </br>
    **Note:**
        [.env](.env)
        +
        [whales_setup/docker.env](whales_setup/docker.env)
    are used to dynamically create
        `whales_setup/.env`,
    which is used in [whales_setup/docker-compose.yml](whales_setup/docker-compose.yml).
4. Modify process scripts (see section [_How to modify bash scripts_](#how-to-modify-bash-scripts-to-work-with-whales)).

See also the notes aboving [_Moving the Whales folder_](#moving-whales-files/folder-within-a-project).
See also the subfolders in [./examples](examples) for further implementation examples of projects with Whales.

## How to add Whales to existing projects ##

1. Add the folder [./whales_setup](whales_setup) and a `.dockerignore` file (if one does not exist) to the root folder of your project.
    In `./.dockerignore` append the line
    ```.dockerignore
    !/whales_setup
    ```
2. Add the file [.env](.env) to the root folder, if one does not exist.
    Otherwise append the values to the end of your existing `.env` file (ensure there are no naming conflicts).
    Even if you wish to leave most values as is, definitely consider changing the value of the following key:
    ```.env
    WHALES_COMPOSE_PROJECT_NAME=whales
    ```
    Setting this argument to be different for different projects prevents
    Docker from confusing your images and containers with those of other projects.
3. Add services to [whales_setup/docker-compose.yml](whales_setup/docker-compose.yml).
    Take care to use the build context `..` (or `../path/to/subfolder`) instead of `.` (or `path/to/subfolder`).
    For mounted volumes, again take care to relativise to the `whales_setup` subfolder
    (_e.g._ `-./../src:$WD/src` and not `-src:$WD/src`).
    </br>
    **Note:**
        [.env](.env)
        +
        [whales_setup/docker.env](whales_setup/docker.env)
    are used to dynamically create
        `whales_setup/.env`,
    which is used in [whales_setup/docker-compose.yml](whales_setup/docker-compose.yml).
4. In [whales_setup/Dockerfile](whales_setup/Dockerfile),
    provided the context in [whales_setup/docker-compose.yml](whales_setup/docker-compose.yml) has been set appropriately,
    there should be no need to worry about relativising paths.
5. Modify process scripts (see section [_How to modify bash scripts_](#how-to-modify-bash-scripts-to-work-with-whales)).

See also the notes aboving [_Moving the Whales folder_](#moving-whales-files/folder-within-a-project).

## Moving Whales files/folder within a project ##

If you wish to move or rename the [./whales_setup](whales_setup) folder
or wish to move the Docker files contain in this folder (`docker-compose.yml` + `Dockerfile`),
then ensure that the corresponding variables in [.env-file](.env) are adjusted.
By default these are as follows:
```.env
# in .env
WHALES_SETUP_PATH=whales_setup
WHALES_DOCKER_COMPOSE_CONFIG_FILE=whales_setup/docker-compose.yml
```

Also adjust the exclusion/inclusion rules in
    [.gitignore](.gitignore)
    + [.dockerignore](.dockerignore)
    + [whales_setup/.gitignore](whales_setup/.gitignore)
appropriately.
By default these are as follows:
```
# in .gitignore + .dockerignore
!/whales_setup

# in whales_setup/.gitignore
# (NOTE: not in whales_setup/.dockerignore as docker files not needed inside container)
!/docker-compose.yml
!/Dockerfile
```

## How to modify bash scripts to work with Whales ##

The `call_within_docker` command in [whales_setup/.lib.sh](whales_setup/.lib.sh) acts as a quasi decorator.
When used, it

- interrupts a running script
- checks whether currently inside the docker environment (by consulting a file `whales_setup/DOCKER_DEPTH`),
- if already inside docker, it will return to the original script,
- otherwise it will launch the appropriate docker container (with an image:tag name assigned to it) in the appropriate mode,
and then call the original script within the container.

Modification of existing bash scripts, _e.g._ `build.sh`, `test.sh`, _etc._ in the root folder of your project
can be modified quite simply as the following examples demonstrate.

### Example 1 ###

Original bash file, `build.sh`:

```bash
#!/usr/bin/env bash

python3 -m pip install tensorflow;
python3 src/main.py $1;
```

This becomes:

```bash
#!/usr/bin/env bash

SCRIPTARGS="$@";
ME="build.sh";
SERVICE="prod-service";

source whales_setup/.lib.sh;

# call_within_docker <service>  <tag-sequence> <save> <it>  <expose> <script> <params>
call_within_docker   "$SERVICE" "prod,setup"   true   false false    "$ME"    $SCRIPTARGS;

python3 -m pip install tensorflow;
python3 src/main.py "${SCRIPTARGS[0]}";
```

**NOTE:** Replace `"prod-service"` by the appropriate service name in [whales_setup/docker-compose.yml](whales_setup/docker-compose.yml).

### Example 2 ###

Original bash file, `test.sh`:

```bash
#!/usr/bin/env bash

mode="$1";
if [ "$mode" == "interactive" ]; then
    swipl -lq src/main.pl;
else
    swipl -fq src/main.pl -t halt;
fi
```

This becomes:

```bash
#!/usr/bin/env bash

SCRIPTARGS="$@";
FLAGS=( "$@" );
ME="test.sh";
SERVICE="test-service";

source whales_setup/.lib.sh;

mode="${FLAGS[0]}";
if [ "$mode" == "interactive" ]; then
    # call_within_docker <service>  <tag-sequence>   <save> <it> <expose> <script> <params>
    call_within_docker   "$SERVICE" "test,(explore)" true   true true     "$ME"    $SCRIPTARGS;
    swipl -lq src/main.pl;
else
    # call_within_docker <service>  <tag-sequence> <save> <it>  <expose> <script> <params>
    call_within_docker   "$SERVICE" "test,explore" false  false true     "$ME"    $SCRIPTARGS;
    swipl -fq src/main.pl -t halt;
fi
```

**NOTE 1:** Replace `"test-service"` by the appropriate service name in [whales_setup/docker-compose.yml](whales_setup/docker-compose.yml).

**NOTE 2:** Set the `<save>` argument to true/false, depending upon whether you want to save.
If `save=true`, then when complete, the exited container will be committed to an image named `whales:<tag>`.

### Sequence of images ###

The `<tag-sequence>` argument is a comma separated list of tag-names,
representing a route from the service image to the desired tag name of the save image (if at all desired).
For example, suppose we have service called `boats-service` defined in [whales_setup/docker-compose.yml](whales_setup/docker-compose.yml)
to build an image with the designation `whales:boats`.
And suppose we have some testing processes,

- pre-compilation
- compilation
- unit-testing
- e2e-testing
- artefact-creation
- explorative testing

for which we wish to build images with the following dependencies:

```
    ( service )
    whales:boats ____> whales:precompile ____> whales:compile ____> whales:unit ____> whales:e2e ____> whales:zip
                              \                       \___________> whales:explore
                               \_________> whales:explore
```

Then in our scripts the `<tag-sequence>` in the `call_within_docker` would be given as follows:

| Process             | Command: `call_within_docker`<br/>Arguments: `<service> <tag-sequence> <save> <it>` |
| :------------------ | :---------------------------------------------------------------------------------- |
| pre-compilation     | `"boats-service" "boats,precompile"             true  false` |
| compilation:        | `"boats-service" "precompile,compile"           true  false` |
| unit-testing        | `"boats-service" "compile,unit"                 true  false` |
| e2e-testing         | `"boats-service" "unit,e2e"                     true  false` |
| artefact-creation   | `"boats-service" "e2e,zip"                      false false` |
| explorative testing | `"boats-service" "precompile,compile,(explore)" true  true ` |


#### Syntax ####

The `<tag-sequence>` argument must contain no spaces and be a comma-separated list.
The final entry in a list of length `n`≥2 can be contained in parentheses.
The script pre-transforms arguments as follows

- `"tag_1,tag_2,...,(tag_n)"` ⟶ `"tag_1,tag_2,...,tag_n,tag_n"`;
- `"tag_1"` ⟶ `"tag_1,tag_1"`

Then the `<tag-sequence>`-argument is valid, exactly in case
the resulting pre-transformed argument is of the form
`"tag_1,tag_2,...,tag_n"`
where `n`≥2 and each `tag_i` contains no spaces (or commas).

#### Interpretation ####

Here `<image>` denotes the image name (without tag) of the service
in [whales_setup/docker-compose.yml](whales_setup/docker-compose.yml).

- If the `<tag-sequence>` argument is pre-transformed to `"tag_1,tag_2,...,tag_n"`,
    then the entry point will be taken to be the latest tag, `tag_i`, where `i` ∈ {1,2,...,`n`-1},
    for which an image `<image>:tag_i` exists.
    And the image name for saving will be `<image>:tag_n`.
    That is, we allow up to the penultimate element in the list to be used as the starting point.
- Observe that if the `<tag-sequence>` argument was originally of the form `"tag_1,tag_2,...,(tag_n)"`,
    then the penultimate element in the pre-transformed list coincide with the final element.
    So effectively, we allow up and including the finale element in the list to be used as the starting point.
    If the starting point and saving point are the same, then saving simply means overwriting the image.
- If the `<tag-sequence>` argument was originally of the form `"tag_1"`,
    then since the pre-transformed list becomes `"tag_1,tag_1"`,
    the instruction is simply: start and end points are the same image.
- Finally, if no valid starting point is found, an error is thrown.
