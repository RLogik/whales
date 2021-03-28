# Installation of Whales via Docker #

If you do not wish to install the requirements (beyond Docker + bash),
you can install Whales via a dockerhub image.

We will assume you have installed [Docker](https://www.docker.com/products/docker-desktop) for your system, and granted file permissions.
And we assume your system has a bash console (for Windows users install [git-for-windows](https://gitforwindows.org) which includes bash).

Navigate to your code project and run the following command
in a bash console

```bash
    tag=latest && dest=. \
    && docker pull rlogik/whales:${tag}                                \
    && id="$( docker run -d rlogik/whales:${tag} )"                    \
    && docker cp "${id}:/usr/app/whales/." "${dest}"                   \
    && docker stop "$id"  >> /dev/null && docker rm "$id" >> /dev/null \
    && docker rmi rlogik/whales:${tag};
```

In this command you can change the `tag=latest` tag to any other tag on
[dockerhub/rlogik/whales](https://hub.docker.com/r/rlogik/whales/tags).
You can also change the `dest=.` command to your desired installation path.

If you wish, you can copy the executables `.whales/jq` and `.whales/dos2unix`
to your local directory (_e.g._ `/usr/local/bin` on Linux/OSX),
so that you no longer need to install these.

## Automation ##

You can convert the above command to a bash script,
_e.g._ [importwhales](importwhales).
Grant this permissions via `chmod +x importwhales`.
Place it in a directory of binaries in your Systems `$PATH` variable,
(_e.g._ `/usr/local/bin` on Linux/OSX).
Within all code projects you can now call `importwhales .`
to setup whales in one single step.
