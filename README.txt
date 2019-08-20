# VISL-Dock

A fully featured computer vision / machine learning development environment inside a Docker image.

The image contains:
- The basic Ubnutu development packages: build-essentianl, cmake, etc.
- Common management tools: git, curl, rsync, etc.
- Terminal based develop tools: vim, tmux, zsh, tig, etc.
- GUI based IDE / editors: PyCharm: and VSCode.
- Basic scientific Python packages: NumPy, SciPy, Pandas, etc.
- Python plotting packages: Matplotlib, Plotly, Seaboarn, etc.
- Computer vision and machine learning packages: OpenCV, SciKit-Image, SciKit-learn, etc.
- Deep learning frameworks: Tensorflow (CPU support only for now) and Torch (+ TorchVision)
- Jupyter notebook and JupyterLab
- Anaconda3

The following features are enabled by default (and can be disabled using the appropriate flags):
- Allowing GUI based applications to run inside the container (mapping the host's X-Server into the container).
- Using the same user inside the Docker container as the user on the host machine (along with it's uid and gid).
- Mapping the local user home and data folders inside the container (at */data* & */user*).
- Sharing all network ports between the container and the host machine (using the *host* network driver)
- Using a consistent home folder (given a path to a folder on the host machine as an input).


## Usage
From the output of *visldock -h*:
```
A CLI tool for working with the visldock docker

usage: visldock  <command> [<options>]
   or: visldock -h         to print this help message.

Commands
    create_link             Create a link to the visldock.sh script in the /usr/bin folder (requiers sudo).
    build                   Build the image.
    run                     Run a command inside a new container.
    exec                    Execute a command inside an existing container.
    stop                    Stop a running container.
Use visldock <command> -h for specific help on each command.
```

## Examples
To simply start a disposable container running a simple bash shell, run:
```bash
visldock run
```

In most cases you would probably want to keep our home folder consistent between runs. This is done using the
*-f {folder to use as home folder}* flag. If a non existing or empty folder is given, then it is initialized with
some initial home folder content. 

For example, to run a container using the folder *~/docker_home* as a permanent home folder run:
```bash
visldock run -f ~/docker_home
```
You can even use your regular home folder for the home folder inside the container.

You can use network storage to have access to same home folder from any lab computer:
```bash
visldock run -f /home1/$USER/docker_home
```

You can run any command directly with going through bash by adding it to the run command. For example, to 
run PyCharm inside a container run:
```bash
visldock run -f ~/docker_home pycharm
```

To open run the default Jupyter Notebook server using the preconfigured command (see below), run:
```bash
visldock run -f ~/docker_home default_notebook
```

You can run a container it in the background by using the detach flag *-d*.
```bash
visldock run -d -f ~/docker_home
```

And to stop a detach container run:
```bash
visldock stop
```

You can also run a command on an existing container using the *exec* command.  For example, to open VSCode 
in an existing container, run:
```bash
visldock exec code
```

## Some notes
- By default, when starting a new container the current user on the host machine is recreated inside the container.
Commands are then executed using this user. You can use the *-u* flag to use a default *dockuser* user instead, or 
the *-s* to use *root* user.

- By default, the CLI maps the */user* folder inside the container to the user home folder (*/home/{username}*)
& */data* folder inside the container to the user data folder (*/data/{username}*) of the host
machine so that you could easily share file between the container and the host machine. To disable this mapping
use the *-r* flag.

- You can set a default run command (instead of opening bash) by placing a script file named *deafult_cmd.sh*
in your home folder (the one used be the container).

- To run more containers at same machine, You can use flag *-c* {container name} 
to run it, for example:
```bash
visldock run -c my_container -f ~/docker_home {Your command}
```

To use visldock with different image version, You can use flag -v:
```bash
visldock run -v v1.7 -f ~/docker_home
```

The default version now is "v1.7",
In case, the project was started early, You can use "v1.4" or "v1.6".

## Preconfigured commands
For convenient the docker image comes with a few preconfigured scripts (which are place in the */app/bin* folder):
- *default-notebook*: Opens Jupyter Notebook at the root directory using port 9900 (without a password nor token)
- *default-jupyterlab*: Opens Jupyter Lab at the root directory using port 9901 (without a password nor token)
- *run_server*: Starts Jupyter Notebook and Lab using a tmux session.

Enjoy ;)
