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

## Requirements ##

This project has been developed with

- **Docker** version **20.10.5**;
- **docker-compose** version **1.28.5**;
- the **Docker app** version **3.2.2**.

This may work with previous versions, and _should_ work with future versions,
but we cannot at the moment guarantee this.

For **Windows users**:

- **bash** is required, see _e.g._ <https://gitforwindows.org>.
- it may be necessary to install [**WSL2**](https://docs.microsoft.com/de-de/windows/wsl/wsl2-kernel#download-the-linux-kernel-update-package).
- optionally, instead of the usual Docker app, [**Docker Edge**](https://docs.docker.com/docker-for-windows/edge-release-notes/) is recommended,
as it is apparently faster.

## Hello World Example ##

1. Clone this repository to some path.
2. Ensure the Docker app has been granted access to the path (or a directory containing it).
3. Start the Docker application.
4. Navigate to the root path of the repository and execute the following commands in bash:

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

In [whales_setup/docker-compose.yml](whales_setup/docker-compose.yml)
one can optionally uncomment the volume mounting and repeat step 4 above.
One should now a file `HELLO_WORLD` in the root of the project,
which will be modified as one calls the above commands.
If one modifies this file, then calls the script, the modifications
should display.

If this works as described, then this means the scripts function correctly:
Project users are able to start images with ease, execute methods within them
(_e.g._ compilation of a code, execution of an algorithm, _etc._)
and the results can be saved (optionally) for the next execution.

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

## Status and cleaning ##

Call `./whales_setup/docker.sh --status` to view the status of the containers and images. For example after the above hello-world example, the status looks like this:

```
CONTAINERS:
CONTAINER ID   NAMES                    IMAGE                SIZE                 STATUS                      CREATED AT
ecxxxxxxxxxd   whales_hello-service_0   whales-hello:build   0B (virtual 102MB)   Exited (0) 39 seconds ago   2021-xxxxxxxx:23:44

IMAGES:
IMAGE ID       REPOSITORY:TAG         SIZE      CREATED AT

d0xxxxxxxxx7   whales-hello:explore   102MB     2021-xxxxxxxx:24:13
     labels:   {"org.whales.initial":"false","org.whales.project":"whales","org.whales.service":"hello-service","org.whales.tag":"explore"}

4cxxxxxxxxx7   <none>:<none>          102MB     2021-xxxxxxxx:24:08
     labels:   {"org.whales.initial":"false","org.whales.project":"whales","org.whales.service":"hello-service","org.whales.tag":"explore"}

6dxxxxxxxxx0   <none>:<none>          102MB     2021-xxxxxxxx:23:49
     labels:   {"org.whales.initial":"false","org.whales.project":"whales","org.whales.service":"hello-service","org.whales.tag":"explore"}

d9xxxxxxxxxd   whales-hello:build     102MB     2021-xxxxxxxx:23:44
     labels:   {"org.whales.initial":"true","org.whales.project":"whales","org.whales.service":"hello-service"}
```

Calling `./whales_setup/docker.sh --service <name-of-service> --status` limits this output to images
associated to a desired service.
Optionally one may use the `--project <name-of-project>` flag, to specify by which project name to filter.
Otherwise the local `.env` file (in the setup folder) is consulted.

Call `./whales_setup/docker.sh --service <name-of-service> --clean`
to clean all containers + images associated with a service.
If the `--service` option not given or left blank,
then all services within the local project will be deleted.

Call `./whales_setup/docker.sh --clean-all` to clean all containers and images.

## Moving Whales folder within a project ##

If [./whales_setup](whales_setup) is moved or renamed,
simply change the corresponding variable in [.env-file](.env)
and adjust the exclusion/inclusion rules in
    [.gitignore](.gitignore) + [.dockerignore](.dockerignore)
appropriately.
By default these are as follows:
```.env
# in .env
WHALES_SETUP_PATH=whales_setup
```
```.gitignore
# in .gitignore + .dockerignore
!/whales_setup
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

The `<tag-sequence>` argument is a comma separated list of ‘tag’-names,
representing a route from the initial image created by the service to the desired tag name of the save image (if saving is set).
For example, suppose we have service called `boats-service` defined in [whales_setup/docker-compose.yml](whales_setup/docker-compose.yml)
to build an image with the designation `whales-boats:build`.
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
    whales-boats:build ____> *:precompile ____> *:compile ____> *:unit ____> *:e2e ____> *:zip
                                 \                   \___________> *:explore
                                  \_________> *:explore
```

Then in our scripts the `<tag-sequence>` in the `call_within_docker` would be given as follows:

| Process             | Command: `call_within_docker`<br/>Arguments: `<service> <tag-sequence> <save> <it>` |
| :------------------ | :---------------------------------------------------------------------------------- |
| pre-compilation     | `"boats-service" ".,precompile"                 true  false` |
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

#### ‘Tags’ ####

For stability purposes the Whales project only loosely applies tag names, but does not rely on them,
as tag names can always be inadvertently overwritten.
Instead each image and container built by Whales scripts, are assigned **docker labels** according to the following scheme:

- `org.whales.project` = the project name
- `org.whales.service` = the name of the service associated to the initial image
- `org.whales.tag` = the ‘tag’ name of the image (this _cannot_ be overwritten).
    For the initial image, this key is given no value.
- `org.whales.initial` = true/false, indicating whether the image is the initial image built by the service.

#### Interpretation ####

Here `<image>` denotes the image name (without tag) of the service
in [whales_setup/docker-compose.yml](whales_setup/docker-compose.yml).

- The tag value `.` is reserve to denote the initial image built via for the docker-compose service.
    _E.g._ if the `<tag-sequence>` argument is pre-transformed to `".,tag_2,...,tag_n"`,
    then the scripts will search for the initial image created for the service.
- If the `<tag-sequence>` argument is pre-transformed to `"tag_1,tag_2,...,tag_n"`,
    then the entry point will be taken to be the latest tag, `tag_i`, where `i` ∈ {1,2,...,`n`-1},
    for which an image exists satisfying the following conditions:

    - it has label `org.whales.project=<project name>`;
    - it has label `org.whales.project=<service name>`;
    - it has label `org.whales.tag=<tag>`, where `<tag>` is the value of `tag_i`;

    or if `tag_i==.` holds, then the following condition is used instead of the final one:

    - it has label `org.whales.initial=true`.

    That is, we allow up to the penultimate element in the list to be used as the starting point.
    The saved image (if the `--save` flag is used) will be assigned the following attributes:

    - the label `org.whales.project=<project name>`;
    - the label  `org.whales.project=<service name>`;
    - the label `org.whales.tag=<tag>`, where `<tag>` is the value of `tag_n`;
    - the image:tag designation `<image>:tag_n`,
        where `<image>` is the name of the image of the image initially built by the service.
        (If this is blank then `<image>` is replaced by a default value given by `<image>:=<project>_<service>`.)

- Observe that if the `<tag-sequence>` argument was originally of the form `"tag_1,tag_2,...,(tag_n)"`,
    then the penultimate element in the pre-transformed list coincide with the final element.
    So effectively, we allow up and including the finale element in the list to be used as the starting point.
    If the starting point and saving point are the same, then saving simply means overwriting the image.
- If the `<tag-sequence>` argument was originally of the form `"tag_1"`,
    then since the pre-transformed list becomes `"tag_1,tag_1"`,
    the instruction is simply: start and end points are the same image.
- Finally, if no valid starting point is found, an error is thrown.
