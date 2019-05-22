#!/bin/bash
set -e

## Main CLI function
## =================
app_name=visldock

repository="visldy/"
image_name="visldock"
version_name="v1.4"

container_name="visldock"

main_cli() {
    ## Parse args
    ## ==========
    usage() {
        echo "A CLI tool for working with the $app_name docker"
        echo ""
        echo "usage: $app_name  <command> [<options>]"
        echo "   or: $app_name -h         to print this help message."
        echo ""
        echo "Commands"
        echo "    setup                   Create a link or a copy of the $app_name.sh script in the /usr/bin folder (requiers sudo)."
        echo "    build                   Build the image."
        echo "    run                     Run a command inside a new container."
        echo "    exec                    Execute a command inside an existing container."
        echo "    stop                    Stop a running container."
        echo "Use $app_name <command> -h for specific help on each command."
    }
    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    while getopts ":h" opt; do
        case $opt in
            h )
                usage
                exit 0
                ;;
            \? )
                echo "Error: Invalid Option: -$OPTARG" 1>&2
                usage
                exit 1
                ;;
        esac
    done
    shift $((OPTIND -1))

    if [ "$#" -lt 1 ]; then
        echo "Error: Was expecting a command" 1>&2
        usage
        exit 1
    fi

    subcommand=$1; shift

    ref_dir="$( cd $( dirname "$(readlink -f ${BASH_SOURCE[0]})" ) && pwd )"

    case "$subcommand" in
        setup)
            setup_cli "$@"
            ;;
        build)
            build_cli "$@"
            ;;
        run)
            run_cli "$@"
            ;;
        exec)
            exec_cli "$@"
            ;;
        stop)
            stop_cli "$@"
            ;;
        *)
            echo "Error: unknown command $subcommand" 1>&2
            usage
            exit 1
    esac
}

setup_cli() {
    copy_script_file=false
    usage () {
        echo "Create a link or a copy of the $app_name.sh script in the /usr/bin folder (requiers sudo)."
        echo ""
        echo "usage: $app_name $subcommand"
        echo "   or: $app_name $subcommand -h    to print this help message."
        echo "Options:"
        echo "    -c                      Copy the script file to /usr/bin. By default a link is created to the current file."
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    while getopts "c" opt; do
        case $opt in
            c)
                copy_script_file=true
                ;;
            :)
                echo "Error: -$OPTARG requires an argument" 1>&2
                usage
                exit 1
                ;;
            \?)
                echo "Error: unknown option -$OPTARG" 1>&2
                usage
                exit 1
                ;;
        esac
    done
    shift $((OPTIND -1))

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi

    run_setup
}

build_cli() {
    tag_as_latest=true
    usage () {
        echo "Build the image"
        echo ""
        echo "usage: $app_name $subcommand [<options>]"
        echo "   or: $app_name $subcommand -h    to print this help message."
        echo "Options:"
        echo "    -v version_name         The version name to use for the build image. Default: \"$version_name\""
        echo "    -l                      Don't tag built image as latest"
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    while getopts "v:l" opt; do
        case $opt in
            v)
                version_name=$OPTARG
                ;;
            l)
                tag_as_latest=false
                ;;
            :)
                echo "Error: -$OPTARG requires an argument" 1>&2
                usage
                exit 1
                ;;
            \?)
                echo "Error: unknown option -$OPTARG" 1>&2
                usage
                exit 1
                ;;
        esac
    done
    shift $((OPTIND -1))

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi

    check_docker_for_sudo
    build_image
}

run_cli() {
    if xhost >& /dev/null ; then
        ## Display exist
        connect_to_x_server=true
    else
        ## No display
        connect_to_x_server=false
    fi
    if [[ "$(whoami)" == "root" ]]; then
        userstring="dockuser:4283:dockuser:4283"
    else
        userstring="$(whoami):$(id -u):$(id -gn):$(id -g)"
    fi
    map_data=true
    detach_container=false
    home_folder=""
    command_to_run=""
    extra_args=""
    if nvidia-smi >& /dev/null ; then 
        use_nvidia_runtime=true
    else
        use_nvidia_runtime=false
    fi
    usage () {
        echo "Run a command inside a new container"
        echo ""
        echo "usage: $app_name $subcommand [<options>] [command]"
        echo "   or: $app_name $subcommand -h    to print this help message."
        echo "Options:"
        echo "    -v version_name         The version name to use for the build image. Default: \"$version_name\""
        echo "    -c container_name       The name to for the created container. Default: \"$container_name\""
        echo "    -f home_folder          A folder to map as the dockuser's home folder."
        echo "    -s                      Run the command as root."
        echo "    -u                      Run the command as dockuser user."
        echo "    -i username             Run the command as *username*."
        echo "    -x                      Don't connect X-server"
        echo "    -r                      Don't map the user data & home folders on the host machine to /user & /data inside the container."
        echo "    -d                      Detach the container."
        echo "    -e extra_args           Extra arguments to pass to the docker run command."
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    while getopts "v:c:f:sui:xrde:" opt; do
        case $opt in
            v)
                version_name=$OPTARG
                ;;
            c)
                container_name=$OPTARG
                ;;
            f)
                home_folder=$OPTARG
                ;;
            s)
                userstring=""
                ;;
            u)
                userstring="dockuser:4283:dockuser:4283"
                ;;
            i)
                username=$OPTARG
                userstring="$username:$(id -u $username):$(id -gn $username):$(id -g $username)"
                ;;
            x)
                connect_to_x_server=false
                ;;
            r)
                map_data=false
                ;;
            d)
                detach_container=true
                ;;
            e)
                extra_args=$OPTARG
                ;;
            :)
                echo "Error: -$OPTARG requires an argument" 1>&2
                usage
                exit 1
                ;;
            \?)
                echo "Error: unknown option -$OPTARG" 1>&2
                usage
                exit 1
                ;;
        esac
    done
    shift $((OPTIND -1))

    userstring="${userstring// /-}"

    if [ "$#" -gt 0 ]; then
        command_to_run=( "$@" )
    fi

    check_docker_for_sudo
    run_command
}

exec_cli() {
    extra_args=""
    command_to_run="bash"
    usage () {
        echo "Execute a command inside an existing container"
        echo ""
        echo "usage: $app_name $subcommand [<options>] [command_to_run]"
        echo "   or: $app_name $subcommand -h    to print this help message."
        echo "Options:"
        echo "    -c container_name       The name to for the created container. default: \"$container_name\""
        echo "    -e extra_args           Extra arguments to pass to the docker exec command."
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    while getopts "c:u:e:" opt; do
        case $opt in
            c)
                container_name=$OPTARG
                ;;
            e)
                extra_args=$OPTARG
                ;;
            :)
                echo "Error: -$OPTARG requires an argument" 1>&2
                usage
                exit 1
                ;;
            \?)
                echo "Error: unknown option -$OPTARG" 1>&2
                usage
                exit 1
                ;;
        esac
    done
    shift $((OPTIND -1))

    if [ "$#" -gt 0 ]; then
        command_to_run=( "$@" )
    fi

    check_docker_for_sudo
    exec_command
}

stop_cli() {
    usage () {
        echo "Stop a running container."
        echo ""
        echo "usage: $app_name $subcommand"
        echo "   or: $app_name $subcommand -h    to print this help message."
        echo "Options:"
        echo "    -c container_name       The name to for the created container. default: \"$container_name\""
    }

    if [ "$#" -eq 1 ] && [ "$1" ==  "-h" ]; then
        usage
        exit 0
    fi

    while getopts "c:u:e:" opt; do
        case $opt in
            c)
                container_name=$OPTARG
                ;;
            :)
                echo "Error: -$OPTARG requires an argument" 1>&2
                usage
                exit 1
                ;;
            \?)
                echo "Error: unknown option -$OPTARG" 1>&2
                usage
                exit 1
                ;;
        esac
    done
    shift $((OPTIND -1))

    if [ "$#" -gt 0 ]; then
        echo "Error: Unexpected arguments: $@" 1>&2
        usage
        exit 1
    fi

    check_docker_for_sudo
    stop_container
}

check_docker_for_sudo() {
    if ! docker ps >& /dev/null; then
        if sudo docker ps >& /dev/null; then
            docker_sudo_prefix="sudo "
        else
            echo "!! Error: was not able to run \"docker ps\""
            exit
        fi
    else
        docker_sudo_prefix=""
    fi
}

run_setup() {
    if [ "$copy_script_file" = true ]; then 
        echo "-> Creating a copy of $ref_dir/$app_name.sh at /usr/bin/$app_name"
        sudo cp --remove-destination $ref_dir/$app_name.sh /usr/bin/$app_name
    else
        echo "-> Creating a symbolic link to $ref_dir$app_name.sh at /usr/bin/$app_name"
        sudo ln -sfT $ref_dir/$app_name.sh /usr/bin/$app_name
    fi
}

build_image() {
    echo "-> Building image from $ref_dir"

    ${docker_sudo_prefix}docker build -t $repository$image_name:$version_name $ref_dir

    if [ "$tag_as_latest" = true ]; then
        ${docker_sudo_prefix}docker tag $repository$image_name:$version_name $repository$image_name:latest
    fi
}

run_command() {
    # # if [ "user_host_user" = true ]; then
    # if [ true = true ]; then
    #     extra_args="-v /etc/passwd:/etc/passwd -u $(id -u ${USER}):$(id -g ${USER})"
    # fi

    if [[ ! -z $userstring ]]; then
        userstringsplit=(${userstring//:/ })
        new_username=${userstringsplit[0]}

        extra_args="$extra_args -e \"USERSTRING=$userstring\" --label new_username=$new_username"

        if [[ ! -z $home_folder ]]; then
            if [[ "$new_username" == "root" ]]; then
                extra_args="$extra_args -v $(readlink -f $home_folder):/root/"
            else
                extra_args="$extra_args -v $(readlink -f $home_folder):/home/$new_username/"
            fi
        fi
    fi

    if [ "$connect_to_x_server" = true ]; then
        xhost +local:root > /dev/null
        extra_args="$extra_args -e DISPLAY=${DISPLAY} -e MPLBACKEND=Qt5Agg -e QT_X11_NO_MITSHM=1 -v /tmp/.X11-unix:/tmp/.X11-unix"
        if [ -f /home/$new_username/.Xauthority ]; then
            if [[ -z "$(ls -A $home_folder)" ]]; then
                extra_args="$extra_args -v /home/$new_username/.Xauthority:/etc/skel/.Xauthority"
            else
                extra_args="$extra_args -v /home/$new_username/.Xauthority:/home/$new_username/.Xauthority"
            fi
        fi
    fi

    if [ "$map_data" = true ]; then
        extra_args="$extra_args -v /media:/media/"
        if [ -d /home/$new_username ]; then
            extra_args="$extra_args -v /home/$new_username:/user/"
        fi
        if [ -d /data/$new_username ]; then
            extra_args="$extra_args -v /data/$new_username:/data/$new_username/"
        fi
    fi

    if [ "$detach_container" = true ]; then
        extra_args="$extra_args -d"
    else
        extra_args="$extra_args -it"
    fi

    if [ "$use_nvidia_runtime" = true ]; then
        extra_args="$extra_args --runtime=nvidia"
    fi

    if [[ ! -z "$command_to_run" ]]; then
        eval "${docker_sudo_prefix}docker run" \
            "--rm" \
            "--network host" \
            "--name $container_name" \
            "$extra_args" \
            "$repository$image_name:$version_name \"\${command_to_run[@]}\""
    else
        eval "${docker_sudo_prefix}docker run" \
            "--rm" \
            "--network host" \
            "--name $container_name" \
            "$extra_args" \
            "$repository$image_name:$version_name"
    fi
}

exec_command() {
    # new_username=$(${docker_sudo_prefix}docker inspect $container_name | jq -r '.[0]["Config"]["Labels"]["new_username"]')
    # if [[ "$new_username" != "null" ]]; then
    new_username=$(${docker_sudo_prefix}docker inspect $container_name | sed -n 's/^[[:space:]]*"new_username":[[:space:]]*"\(.*\)"$/\1/p')
    if [[ ! -z "$new_username" ]]; then
        extra_args="$extra_args -u $new_username -w /home/$new_username"
    fi

    ${docker_sudo_prefix}docker exec -it $extra_args $container_name "${command_to_run[@]}"
}


stop_container() {
    echo "-> Stopping the container"
    ${docker_sudo_prefix}docker stop $container_name
}

main_cli "$@"
