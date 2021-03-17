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
