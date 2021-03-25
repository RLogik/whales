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

1. Ensure you have installed Docker and at least granted access to the folder in which the repository has been cloned.
2. Ensure you have bash or bash for Windows.
3. Start the Docker application.
4. Navigate to this folder and carry out the following commands

    ```bash
    chmod +x *.sh; # grant execution rights to the shell scripts
    ./test.sh --mode run;
    ./test.sh --mode unit;
    ./test.sh --mode explore;
    ```

5. To see the status of the docker containers and images,
    call `./whales_setup/docker.sh --status;`.
6. To clean the images and containers created by the above commands,
    call `./clean.sh --mode docker`.
