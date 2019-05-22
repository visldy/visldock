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

For a complete list of packages take a look at the Dockerfile

The goal of this project is to try and create a development environment which enjoys the benefits of developing
on top of Docker such as portability, reproducibility, versioning, confinement etc. while trying to make
working inside a Docker container seamless as possible.

*visldock* comes with a CLI tool (the *visldock.sh* file) for simplifying the work with the Docker image as a development
working environment. The CLI offers some short and simple commands for running commands in either a disposable or a 
consistent Docker container. 

The following features are enabled by default (and can be disabled using the appropriate flags):
- Allowing GUI based applications to run inside the container (mapping the host's X-Server into the container).
- Using the same user inside the Docker container as the user on the host machine (along with it's uid and gid).
- Mapping the local user home and data folders inside the container (at */data* & */user*).
- Sharing all network ports between the container and the host machine (using the *host* network driver)
- Using a consistent home folder (given a path to a folder on the host machine as an input).

**!!! An important security note**: For enabling the X-Server mapping the CLI uses the following command:
"*xhost +local:root*" which creates a potential security venerability (For more details see:
http://wiki.ros.org/docker/Tutorials/GUI). To disable the X-server mapping and avoid this security issue 
using the -x flag when running commands.

For a more detailed documentation then this readme see the docs folder.

## Dependencies
- [Docker](https://www.docker.com/)
- NVIDIA drivers of version 418 or higher
- [NVIDIA-Docker](https://github.com/NVIDIA/nvidia-docker)

For setting these dependencies see the "*Installing dependencies*" section in documentation.

## Setup
A part from the above dependencies, the only necessary tool for using the *visldock* CLI is the *visldock.sh* file.
(The docker image itself is pulled from DockerHub on first usage). To download the file from github (along with
the rest of the repository) use:
``` bash
git clone https://github.com/visldy/visldock.git {target_folder}
```

Then move into the repository's folder (the folder containing the *visldock.sh* file) and run the following command 
to define the *visldock* command shortcut:
```bash
./visldock.sh setup
```
You will be ask to enter your user password.
(This command simply create a link to the *visldock.sh* file at */usr/bin/visldock*).

Note: you can also copy the file to the */usr/bin* folder (instead of creating a link) using the *-c* flag: *./visldock.sh setup -c*.

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

---

In most cases you would probably want to keep our home folder consistent between runs. This is done using the
*-f {folder to use as home folder}* flag. If a non existing or empty folder is given, then it is initialized with
some initial home folder content. 

For example, to run a container using the folder *~/docker_home* as a permanent home folder run:
```bash
visldock run -f ~/docker_home
```
You can even use your regular home folder for the home folder inside the container.

---

You can run any command directly with going through bash by adding it to the run command. For example, to 
run PyCharm inside a container run:
```bash
visldock run -f ~/docker_home pycharm
```

---

To open run the default Jupyter Notebook server using the preconfigured command (see below), run:
```bash
visldock run -f ~/docker_home default_notebook
```

---

You can run a container it in the background by using the detach flag *-d*.
```bash
visldock run -d -f ~/docker_home
```

And to stop a detach container run:
```bash
visldock stop
```

---

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

- To run more containers or in case, when another user use a Docker at same machine,
You can use flag *-c {container name} to run it, for example:

```bash
visldock run -c my_container -f ~/docker_home {Your command}
```


## Preconfigured commands
For convenient the docker image comes with a few preconfigured scripts (which are place in the */app/bin* folder):
- *default-notebook*: Opens Jupyter Notebook at the root directory using port 9900 (without a password nor token)
- *default-jupyterlab*: Opens Jupyter Lab at the root directory using port 9901 (without a password nor token)
- *run_server*: Starts Jupyter Notebook and Lab using a tmux session.

Enjoy ;)
