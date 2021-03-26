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

This repository is designed to provide a easy to deploy template to ‘dockerise’ your code.

_For those not familiar with Docker..._
When working collaboratively on a project, participants often have different operating systems and setups.
This can present a real nightmare, especially when it comes to testing.
To bypass all these issues, it is useful for all participants to be able to set up
exactly the same virtual environment with exactly the same settings,
within which the project can be compiled, run, and tested.
Docker presents itself as a universal, easily accessible solution.

This tool provides simple scripting commands to augment processes,
so that these processes get called within a docker container,
and allowing stages of your code (e.g. installation, compilation, testing)
to be saved as docker images.
The tool manages the dependencies between these stages using labels,
so that you can more readily move between images without the hassle of
having to look up ids of docker images/containers or having to remount volumes, _etc._

## Requirements ##

By design this tool has very minimal dependencies (you just need Docker + bash),
so that it is as widely accessible as possible.
This project has been developed with

- **Docker** version **20.10.5**;
- **docker-compose** version **1.28.5**;
- the **Docker app** version **3.2.2**.
- the **dos2unix** tool for bash.

This may work with previous versions, and _should_ work with future versions,
but we cannot at the moment guarantee this.

For **Windows users**:

- **bash** is required, see _e.g._ <https://gitforwindows.org>.
- it may be necessary to install [**WSL2**](https://docs.microsoft.com/de-de/windows/wsl/wsl2-kernel#download-the-linux-kernel-update-package).
- optionally, instead of the usual Docker app, [**Docker Edge**](https://docs.docker.com/docker-for-windows/edge-release-notes/) is recommended,
as it is apparently faster.

Open bash and call `dos2unix --version` to see if `dos2unix` is installed.
If not, see <https://command-not-found.com/dos2unix>, <https://chocolatey.org/packages/dos2unix>, etc.

## Hello World Example ##

Follow the instructions in [examples/hello-world](examples/hello-world).

## How to add Whales to existing projects ##

1. Clone this repository and copy the following into your project:
    ```
        [project root]
        |
        |____ /.whales
        |    |____ ... ( do not modify contents )
        |
        |____ .whales.env
        |____ .whales.Dockerfile
        |____ .whales.docker-compose.yml
    ```
    Add a `./.dockerignore` file, if one does not exist, and append the lines
    ```.dockerignore
    !/.whales
    !/.whales.env
    ```
2. Modify the [.whales.env](.whales.env) file in the project root.
    In particular, set the name of your project here:
    ```.env
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
4. Modify process scripts (see section [_How to modify bash scripts_](#how-to-modify-bash-scripts-to-work-with-whales)).

See also the notes aboving [_Moving the Whales folder_](#moving-whales-files/folder-within-a-project).
And see the subfolders in [./examples](examples) for further implementation examples of Whales projects.

## Status and cleaning ##

Calling
```bash
source .whales/docker.sh --service <name-of-service> --status;
```
displays the status of containers + images associated with a named service.
If the `--service` option not given or left blank,
then all services within the local project will be displayed.
The same logic applies to the command
```bash
source .whales/docker.sh --service <name-of-service> --clean;
```
this time with the action of deleting containers/images.

Optionally, one may additionally use the `--project <name-of-project>` flag,
to specify by which project name to filter.
Otherwise the local `.whales.env` file is consulted.

Call `./.whales/docker.sh --clean-all` to clean all containers and images.

## Moving Whales folder within a project ##

If [./.whales](.whales) is moved or renamed,
simply change the corresponding variable in [.env-file](.env)
and adjust the exclusion/inclusion rules in
    [.gitignore](.gitignore) + [.dockerignore](.dockerignore)
appropriately.
By default these are as follows:
```.env
# in .env
WHALES_SETUP_PATH=.whales
```
```.gitignore
# in .gitignore + .dockerignore
!/.whales
```

## How to modify bash scripts to work with Whales ##

The `whale_call` command in [.whales/.lib.sh](.whales/.lib.sh) acts as a quasi decorator.
When used, it

- interrupts a running script
- checks whether currently inside the docker environment (by consulting a file `.whales/DOCKER_DEPTH`),
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

source .whales/.lib.sh;

# whale_call <service> <tag-sequence> <save, it, ports> <type, command>
whale_call   "$SERVICE" "prod,setup"  true false false  SCRIPT $ME $SCRIPTARGS;

python3 -m pip install tensorflow;
python3 src/main.py "${SCRIPTARGS[0]}";
```

**NOTE:** Replace `"prod-service"` by the appropriate service name in [.whales.docker-compose.yml](.whales.docker-compose.yml).

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

source .whales/.lib.sh;

mode="${FLAGS[0]}";
if [ "$mode" == "interactive" ]; then
    # whale_call <service>  <tag-sequence>   <save, it, ports> <type, command>
    whale_call   "$SERVICE" "test,(explore)" true true true    SCRIPT $ME $SCRIPTARGS;
    swipl -lq src/main.pl;
else
    # whale_call <service>  <tag-sequence>   <save, it, ports> <type, command>
    whale_call   "$SERVICE" "test,explore"   false false true  SCRIPT $ME $SCRIPTARGS;
    swipl -fq src/main.pl -t halt;
fi
```

**NOTE 1:** Replace `"test-service"` by the appropriate service name in [.whales.docker-compose.yml](.whales.docker-compose.yml).

**NOTE 2:** Set the `<save>` argument to true/false, depending upon whether you want to save.
If `save=true`, then when complete, the exited container will be committed to an image named `whales:<tag>`.

### Sequence of images ###

The `<tag-sequence>` argument is a comma separated list of ‘tag’-names,
representing a route from the initial image created by the service to the desired tag name of the save image (if saving is set).
For example, suppose we have service called `boats-service` defined in [.whales.docker-compose.yml](.whales.docker-compose.yml)
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

Then in our scripts the `<tag-sequence>` in the `whale_call` would be given as follows:

| Process             | Command: `whale_call`<br/>Arguments: `<service> <tag-sequence> <save> <it>` |
| :------------------ | :---------------------------------------------------------------------------------- |
| pre-compilation     | `"boats-service" ".,precompile"                 true  false` |
| compilation:        | `"boats-service" "precompile,compile"           true  false` |
| unit-testing        | `"boats-service" "compile,unit"                 true  false` |
| e2e-testing         | `"boats-service" "unit,e2e"                     true  false` |
| artefact-creation   | `"boats-service" "e2e,zip"                      false false` |
| explorative testing | `"boats-service" "precompile,compile,(explore)" true  true ` |

Note for the initial build one uses `.` instead of the docker tag name.
The command does not really work with docker tag names,
but with values saved as docker labels.
See section [_Docker ‘tags’ vs. docker labels_](#docker-tags-vs-docker-labels) for more.

#### Docker ‘tags’ vs. docker labels ####

For stability purposes the Whales project only loosely applies tag names, but does not rely on them,
as tag names can always be inadvertently overwritten.
Instead each image and container built by Whales scripts, are assigned **docker labels** according to the following scheme:

- `org.whales.project` = the project name
- `org.whales.service` = the name of the service associated to the initial image
- `org.whales.tag` = the ‘tag’ name of the image (this _cannot_ be overwritten).
    For the initial image, this key is given no value.
- `org.whales.initial` = true/false, indicating whether the image is the initial image built by the service.

#### Syntax of tag-sequence argument ####

The examples above and in this repository should make clear, who to use this argument.
Nonetheless for completeness, we provide here a thorough explanation.
The `<tag-sequence>` argument must contain no spaces and be a comma-separated list. The final entry in a list of length `n`≥2 can be contained in parentheses. The script pre-transforms arguments as follows

- `"tag_1,tag_2,...,(tag_n)"` ⟶ `"tag_1,tag_2,...,tag_n,tag_n"`;
- `"tag_1"` ⟶ `"tag_1,tag_1"`

Then the `<tag-sequence>`-argument is valid, exactly in case
the resulting pre-transformed argument is of the form
`"tag_1,tag_2,...,tag_n"`
where `n`≥2 and each `tag_i` contains no spaces (or commas).
#### Interpretation ####

Here `<image>` denotes the image name (without tag) of the service
in [.whales.docker-compose.yml](.whales.docker-compose.yml).

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
