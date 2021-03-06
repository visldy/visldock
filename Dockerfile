FROM nvidia/cuda:10.1-cudnn7-devel-ubuntu18.04

## Install basic packages and useful utilities
## ===========================================
ENV DEBIAN_FRONTEND noninteractive
ENV MPLBACKEND=Agg
ARG PYCHARM_SOURCE="https://download.jetbrains.com/python/pycharm-community-2018.3.5.tar.gz"
ARG DOCKUSER_UID=4283
ARG DOCKUSER_GID=4283


RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:neovim-ppa/stable && \
    apt-get update -y && \
    apt-get install -y \
        build-essential bzip2 ca-certificates locales fonts-liberation \
        man cmake sudo openssh-server python3 python3-dev python3-pip \
        python python-dev python-pip sshfs wget curl rsync ssh bc nano vim \
        emacs git tig tmux zsh unzip htop tree silversearcher-ag ctags cscope \
        libblas-dev liblapack-dev gfortran libfreetype6-dev libpng-dev ffmpeg \
        faac faad x264 python-qt4 python3-pyqt5 imagemagick inkscape jed libsm6 \
        libxext-dev libxrender1 lmodern netcat pandoc texlive-fonts-extra \
        texlive-fonts-recommended texlive-generic-recommended neovim \
        texlive-latex-base texlive-latex-extra texlive-xetex tzdata udev \
        graphviz mc nfs-common apt-utils desktop-file-utils usbutils \
        libusb.1.0-0-dev mercurial subversion libglib2.0-0 webcam guvcview \
        systemd systemd-sysv mesa-utils v4l-utils qv4l2 v4l2ucp python-opencv \
        python3-opencv python3-tk nautilus firefox p7zip-full p7zip-rar && \
    pip install pynvim && \
## Setup openvc version
    python2 -c "import cv2 as cv" && \
    python3 -c "import cv2 as cv" && \

## ToDo: increase memory limit to 10GB in: /etc/ImageMagick-6/policy.xml

## Set locale and update prompt
## ============================
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen && \
    echo 'export PS1="Docker-"$PS1' >> /etc/skel/.bashrc && \

## SSH server
## ==========
    mkdir /var/run/sshd && \
    sed 's/^#\?PasswordAuthentication .*$/PasswordAuthentication yes/g' -i /etc/ssh/sshd_config && \
    sed 's/^Port .*$/Port 9022/g' -i /etc/ssh/sshd_config && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \

## VSCode
## ======
    cd /tmp && \
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg && \
    install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/ && \
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list && \
    apt-get install apt-transport-https && \
    apt-get update && \
    apt-get install -y code && \
    apt-get clean && \
    rm microsoft.gpg && \
    rm -rf /var/lib/apt/lists/* && \

## Install Spark
## ===============
#RUN cd /tmp && \
#    wget -q http://mirrors.ukfast.co.uk/sites/ftp.apache.org/spark/spark-${APACHE_SPARK_VERSION}/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
#    echo "E8B7F9E1DEC868282CADCAD81599038A22F48FB597D44AF1B13FCC76B7DACD2A1CAF431F95E394E1227066087E3CE6C2137C4ABAF60C60076B78F959074FF2AD *spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" | sha512sum -c - && \
#    tar xzf spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -C /usr/local --owner root --group root --no-same-owner && \
#    rm spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
#    cd /usr/local && ln -s spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} spark

## Install pycharm
## ===============
    mkdir /opt/pycharm && \
    cd /opt/pycharm && \
    curl -L $PYCHARM_SOURCE -o installer.tgz && \
    tar --strip-components=1 -xzf installer.tgz && \
    rm installer.tgz && \
    /usr/bin/python2 /opt/pycharm/helpers/pydev/setup_cython.py build_ext --inplace && \
    /usr/bin/python3 /opt/pycharm/helpers/pydev/setup_cython.py build_ext --inplace && \

## Setup app folder
## ================
    mkdir /app && \
    chmod 777 /app && \

## Setup python environment
## ========================
    pip3 install pip && \
    hash -r pip && \
    pip3 --no-cache-dir install -U \
        virtualenv ipython numpy scipy matplotlib PyQt5 seaborn plotly \
        bokeh ggplot altair pandas pyyaml protobuf ipdb flake8 cython \
        sympy nose sphinx tqdm opencv-contrib-python scikit-image \
        scikit-learn imageio torchvision tensorflow-gpu tensorboardX \
        jupyter jupyterthemes jupyter_contrib_nbextensions jupyterlab \
        jupyterhub ipywidgets keras pillow toposort tensorflow && \
        rm -r /root/.cache/pip && \

## Import matplotlib the first time to build the font cache.
## =========================================================
    python3 -c "import matplotlib.pyplot" && \
    cp -r /root/.cache /etc/skel/ && \

## Setup Jupyter
## =============
    pip install six && \
    jupyter nbextension enable --py widgetsnbextension && \
    jupyter contrib nbextension install --system && \
    jupyter nbextensions_configurator enable && \
    jupyter serverextension enable --py jupyterlab --system && \
    pip install RISE && \
    jupyter-nbextension install rise --py --sys-prefix --system && \
    cp -r /root/.jupyter /etc/skel/ && \

## Create virtual environment
## ==========================
    cd /app/ && \
    virtualenv --system-site-packages dockvenv && \
    virtualenv --relocatable dockvenv && \
    grep -rlnw --null /usr/local/bin/ -e '#!/usr/bin/python3' | xargs -0r cp -t /app/dockvenv/bin/ && \
    sed -i "s/#"'!'"\/usr\/bin\/python3/#"'!'"\/usr\/bin\/env python/g" /app/dockvenv/bin/* && \
    mv /app/dockvenv /root/ && \
    ln -sfT /root/dockvenv /app/dockvenv && \
    cp -rp /root/dockvenv /etc/skel/ && \
    sed -i "s/^\(PATH=\"\)\(.*\)$/\1\/app\/dockvenv\/bin\/:\2/g" /etc/environment && \

## Node.js
## =======
    curl -sL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g grunt-cli && \

## Install dumb-init
## =================
    cd /tmp && \
    wget -O dumb-init.deb https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64.deb && \
    dpkg -i dumb-init.deb && \
    rm dumb-init.deb && \

## Install anaconda3
## =================
    wget https://repo.anaconda.com/archive/Anaconda3-2019.03-Linux-x86_64.sh -O ~/anaconda.sh && \
    /bin/bash ~/anaconda.sh -b -p /opt/conda && \
    rm ~/anaconda.sh && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    PATH="$PATH:/opt/conda/bin" && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> /etc/skel/.bashrc && \
#    echo "conda activate base" >> /etc/skel/.bashrc && \
    conda update conda -y && \
#    conda install -c menpo opencv3 && \
    conda install -c menpo \
      tensorflow-gpu keras PyTorch matplotlib && \
    conda update --all -y && \
    anaconda-navigator --reset && \
    conda clean -a -y && \

## Create dockuser user
## ====================
    groupadd -g $DOCKUSER_GID dockuser && \
    useradd --system --create-home --home /home/dockuser --shell /bin/bash -G sudo -g dockuser -u $DOCKUSER_UID dockuser && \
    mkdir /tmp/runtime-dockuser && \
    chown dockuser:dockuser /tmp/runtime-dockuser && \
    echo "dockuser ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/dockuser && \

## Copy scripts
## ============
    mkdir /app/bin && \
    chmod a=u -R /app/bin && \
    sed -i "s/^\(PATH=\"\)\(.*\)$/\1\/app\/bin\/:\2/g" /etc/environment && \
    touch /etc/skel/.sudo_as_admin_successful && \
## Cleanup
## ============
    rm -rf /var/lib/apt/lists/*

ENV PATH="/app/bin:/opt/conda/bin:/app/dockvenv/bin:${PATH}"
COPY ./resources/pycharm.bin /usr/local/bin/pycharm
COPY /resources/entrypoint.sh /app/bin/run
COPY /resources/default_notebook.sh /app/bin/default_notebook
COPY /resources/default_jupyterlab.sh /app/bin/default_jupyterlab
COPY /resources/run_server.sh /app/bin/run_server
COPY /phidgets/99-libphidget22.rules /etc/udev/rules.d/99-libphidget22.rules
COPY /phidgets/libphidget22.so* /usr/lib/
COPY /matlab/matl.tar /usr/local/bin/
RUN cd /usr/local/bin && \
    tar -xf matl.tar && \
    rm matl.tar
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8  

WORKDIR /root
ENTRYPOINT ["/usr/bin/dumb-init", "--", "run"]
## nvidia-container-runtime
## ===========================================
ENV NVIDIA_VISIBLE_DEVICES \
    ${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES \
    ${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics
ENV PATH="/usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}"
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64
RUN echo "export PATH=$PATH" > /etc/environment
