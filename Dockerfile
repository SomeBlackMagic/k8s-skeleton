FROM fedora:33

RUN dnf install -y \
    git \ 
    python3 \
    python3-pip

ARG KS_VERSION

RUN git clone -b release-$KS_VERSION https://github.com/kubernetes-sigs/kubespray.git app

WORKDIR app

RUN pip3 install -r requirements.txt
