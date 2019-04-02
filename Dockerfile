FROM nvidia/cuda:10.1-cudnn7-devel-ubuntu18.04

## Install basic packages and useful utilities
## ===========================================
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:neovim-ppa/stable && \
    apt-get update -y && \
    apt-get install -y \
        build-essential bzip2 ca-certificates locales fonts-liberation \
        man cmake sudo python3 python3-dev python3-pip python python-dev \
        python-pip sshfs wget curl rsync ssh nano vim emacs git tig tmux \
        zsh unzip htop tree silversearcher-ag ctags cscope libblas-dev \
        liblapack-dev gfortran libfreetype6-dev libpng-dev ffmpeg faac faad \
        x264 python-qt4 python3-pyqt5 imagemagick inkscape jed libsm6 \
        libxext-dev libxrender1 lmodern netcat pandoc texlive-fonts-extra \
        texlive-fonts-recommended texlive-generic-recommended neovim \
        texlive-latex-base texlive-latex-extra texlive-xetex \
        graphviz mc nfs-common && \
    pip install pynvim && \
    apt-get clean

    ## ToDo: increase memory limit to 10GB in: /etc/ImageMagick-6/policy.xml

## Set locale
## ==========
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

## VSCode
## ======
RUN cd /tmp && \
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg && \
    install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/ && \
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list && \
    apt-get install apt-transport-https && \
    apt-get update && \
    apt-get install -y code && \
    rm microsoft.gpg

## Install pycharm
## ===============
ARG PYCHARM_SOURCE="https://download.jetbrains.com/python/pycharm-community-2018.3.5.tar.gz"
RUN mkdir /opt/pycharm && \
    cd /opt/pycharm && \
    curl -L $PYCHARM_SOURCE -o installer.tgz && \
    tar --strip-components=1 -xzf installer.tgz && \
    rm installer.tgz && \
    /usr/bin/python2 /opt/pycharm/helpers/pydev/setup_cython.py build_ext --inplace && \
    /usr/bin/python3 /opt/pycharm/helpers/pydev/setup_cython.py build_ext --inplace
COPY ./resources/pycharm.bin /usr/local/bin/pycharm

## Setup app folder
## ================
RUN mkdir /app && \
    chmod 777 /app

## Setup python environment
## ========================
RUN sudo -H pip3 --no-cache-dir install -U virtualenv && \
    virtualenv /app/venv && \
    export PATH="/app/venv/bin:$PATH" && \
    pip3 --no-cache-dir install pip && \
    hash -r pip && \
    pip3 --no-cache-dir install -U \
        ipython numpy scipy matplotlib PyQt5 seaborn plotly \
        bokeh ggplot altair pandas pyyaml protobuf ipdb flake8 \
        cython sympy nose jupyter sphinx tqdm opencv-contrib-python \
        scikit-image scikit-learn imageio torchvision tensorflow-gpu \
        tensorboardX jupyter jupyterthemes jupyter_contrib_nbextensions \
        jupyterlab ipywidgets && \
    pip --no-cache-dir install --upgrade tensorflow-gpu
RUN chmod a=u -R /app/venv
ENV PATH="/app/venv/bin:$PATH"
ENV MPLBACKEND=Agg

## Import matplotlib the first time to build the font cache.
## ---------------------------------------------------------
RUN python -c "import matplotlib.pyplot" && \
    cp -r /root/.cache /etc/skel/

## Setup Jupyter
## -------------
RUN jupyter nbextension enable --py widgetsnbextension && \
    jupyter contrib nbextension install --system && \
    jupyter nbextensions_configurator enable && \
    jupyter serverextension enable --py jupyterlab --system && \
    cp -r /root/.jupyter /etc/skel/

## Install dumb-init
## =================
RUN wget https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64.deb
RUN dpkg -i dumb-init_*.deb

## Copy scripts
## ============
COPY /resources/entrypoint.sh /app/scripts/entrypoint.sh
COPY /resources/default_cmd.sh /app/scripts/default_cmd.sh
RUN chmod a=u -R /app/scripts && \
    echo "#!/bin/bash\nset -e\nexec /app/scripts/entrypoint.sh \"\$@\"" > /usr/local/bin/run && \
    chmod a+x /usr/local/bin/run && \
    echo "#!/bin/bash\nset -e\nif [[ -f \$HOME/visldock_default_cmd.sh ]]; then exec \$HOME/visldock_default_cmd.sh \"\$@\"; else exec /app/scripts/default_cmd.sh \"\$@\"; fi" > /usr/local/bin/default_cmd && \
    chmod a+x /usr/local/bin/default_cmd && \
    cp /app/scripts/default_cmd.sh /etc/skel/visldock_deafult_cmd.sh

## Create dockuser user
## ====================
ARG DOCKUSER_UID=4283
ARG DOCKUSER_GID=4283
RUN groupadd -g $DOCKUSER_GID dockuser && \
    useradd --system --create-home --home /home/dockuser --shell /bin/bash -G sudo -g dockuser -u $DOCKUSER_UID dockuser && \
    mkdir /tmp/runtime-dockuser && \
    chown dockuser:dockuser /tmp/runtime-dockuser && \
    echo "dockuser ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/dockuser

WORKDIR /root
ENTRYPOINT ["/usr/bin/dumb-init", "--", "run"]
