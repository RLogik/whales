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

# A Hello-World example with Whales #

1. Ensure that
    - Docker has been installed and at least granted access to the folder in which the repository has been cloned;
    - bash is on your system (or git/bash-for-Windows has been installed);
    - dos2unix has been installed (and is an accessible command in the bash terminal—call `dos2unix --version` to see if it exists).
2. Start the Docker application.
3. Clone this repository and navigate in a bash terminal to this folder.
    Then Carry out the following commands:

    ```bash
    chmod +x *.sh; # grant execution rights to the shell scripts
    ./hello.sh "Captain, ...";
    ./hello.sh "Thar be whales\!"; # NOTE: Do not write "!"
    ./hello.sh "I am a humpback whale.";
    ```

If performed correctly, first the docker image will be created.
Then the docker image will be started in a container,
and you will see two whales with messages `(blank)` and `Captain, ...`.
Then upon the second "hello" script execution, the docker image will be started in a container,
and you will see two whales with messages `Captain, ...` and `Thar be whales!`.

In [.whales.docker-compose.yml](.whales.docker-compose.yml)
one can optionally uncomment the volume mounting and repeat **step 3** above.
One should now a file `HELLO_WORLD` in the root of the project,
which will be modified as one calls the above commands.
If one modifies that text file, then calls the script,
the modifications should display.

If this works as described, then this means the scripts function correctly:
Project users are able to start images with ease, execute methods within them
(_e.g._ compilation of a code, execution of an algorithm, _etc._)
and the results can be saved (optionally) for the next execution.

## Status and cleaning ##

Call `./.whales/docker.sh --status` to view the status of the containers and images.
For example after the above example, the status looks like this:

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

Call `./.whales/docker.sh --clean;` to clean the images and containers created within this project.
