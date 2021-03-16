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
 | New message:
 | Hello world!
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
    ./build.sh --mode setup;
    # wait for this to complete
    ./hello.sh --base prod "Hello world\!" # Do not write "!"
    ./hello.sh --base prod "I am a whale"
    ```

    If performed correctly, first the docker image will be created.
    Then upon the first "hello" script execution, the docker image will be started in a container,
    and you will see two whales with messages `(blank)` and `Hello world!`.
    Then upon the second "hello" script execution, the docker image will be started in a container,
    and you will see two whales with messages `Hello world!` and `I am a whale`.
5. If this works as described, then this means the scripts function correctly:
    Project users are able to start images with ease, execute methods within them
    (_e.g._ compilation of a code, execution of an algorithm, _etc._)
    and the results can be saved (optionally) for the next execution.

In the above example, `--base prod` was used as an argument because we started the service `prod`,
(which has image:tag=`whales:prod`).
Cf. `docker-compose.yml`.
If the services are renamed, then the argument has to be appropriately renamed.

## Status and cleaning ##

Call `. .docker.sh --status` to view the status of the containers and images.
For example after the above hello-world example, the status looks like this:

```
[INFO] Container states:
CONTAINER ID   NAMES           IMAGE          SIZE                 STATUS
6bxxxxxxxxx4   whales_prod_1   edxxxxxxxxx3   0B (virtual 101MB)   Exited (0) 2 minutes ago
[INFO] Images:
IMAGE ID       REPOSITORY   TAG       SIZE      CREATED AT
45xxxxxxxxx9   whales       prod      101MB     ...
71xxxxxxxxx3   <none>       <none>    101MB     ...
edxxxxxxxxx3   <none>       <none>    101MB     ...
```

Call `. .docker.sh --clean` to clean all whale-containers and whale-images.

Call `. .docker.sh --clean-all` to clean all containers and images.
