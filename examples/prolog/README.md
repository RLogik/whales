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

# A Prolog project with Whales #

1. Ensure that
    - Docker has been installed and at least granted access to the folder in which the repository has been cloned;
    - bash is on your system (or git/bash-for-Windows has been installed);
    - dos2unix has been installed (and is an accessible command in the bash terminal—call `dos2unix --version` to see if it exists).
2. Start the Docker application.
3. Clone this repository and navigate in a bash terminal to this folder.
    Then Carry out the following commands:

    ```bash
    chmod +x *.sh; # grant execution rights to the shell scripts
    ./build.sh --mode run;
    ./build.sh --mode unit;
    ./build.sh --mode explore;
    ```

To see the status of the docker containers and images, call `./.whales/docker.sh --status;`.

To clean the images and containers created by the above commands, call `./clean.sh --mode docker`.
