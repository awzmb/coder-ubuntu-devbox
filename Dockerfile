FROM ubuntu:23.04

# install the docker apt repository
RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get upgrade --yes && \
    DEBIAN_FRONTEND="noninteractive" apt-get install --yes ca-certificates

# install baseline packages
RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install --yes \
      bash \
      zsh \
      build-essential \
      ca-certificates \
      curl \
      htop \
      locales \
      man \
      python3 \
      python3-pip \
      software-properties-common \
      sudo \
      systemd \
      systemd-sysv \
      unzip \
      vim \
      neovim \
      wget \
      rsync && \
    # install latest git using their official ppa
    add-apt-repository ppa:git-core/ppa && \
    DEBIAN_FRONTEND="noninteractive" apt-get install --yes git

# install docker packages
RUN sudo install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    sudo chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install --yes \
      containerd.io \
      docker-ce \
      docker-ce-cli \
      docker-buildx-plugin \
      docker-compose-plugin

# enables docker starting with systemd
RUN systemctl enable docker

# add docker-compose
RUN curl -L "https://github.com/docker/compose/releases/download/v2.17.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker-compose

# install additional shell tools
RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install --yes \
    vifm \
    calc \
    unrar \
    bat \
    jq \
    tree \
    ack \
    fd-find \
    fzf \
    tmux \
    ranger \
    gnupg2 \
    w3m \
    exa \
    w3m-img \
    python3-neovim \
    calcurse \
    newsboat \
    neofetch \
    xdg-utils \
    pass

# install openvpn, wireguard and additional networking tools
RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install --yes \
    netcat-openbsd \
    openvpn \
    wireguard

# install vim-plug for vim and neovim
RUN curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim && \
    sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# install kubectl
RUN curl -o /usr/local/bin/kubectl \
  -L "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# install gcloud
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - && apt-get update -y && apt-get install google-cloud-sdk -y

# kubernetes tools: kubectx, and kubens
RUN wget https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx -O /usr/local/bin/kubectx && chmod +x /usr/local/bin/kubectx
RUN wget https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens -O /usr/local/bin/kubens && chmod +x /usr/local/bin/kubens

# kubernetes tools: helm
RUN curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 && \
  bash get_helm.sh && \
  rm get_helm.sh

# kubernetes tools: krew
RUN OS="$(uname | tr '[:upper:]' '[:lower:]')" && \
    ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" && \
    KREW="krew-${OS}_${ARCH}" && \
    curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" && \
    tar zxvf ${KREW}.tar.gz && \
    "./$KREW" install krew && \
    cp $HOME/.krew/bin/kubectl-krew /usr/local/bin/

# install terraform
RUN TERRAFORM_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1') && \
    TERRAFORM_ZIP="terraform_${TERRAFORM_VERSION}_$(uname | tr '[:upper:]' '[:lower:]')_$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/').zip" && \
    wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${TERRAFORM_ZIP} && \
    unzip ${TERRAFORM_ZIP} && \
    mv terraform /usr/local/bin/terraform && \
    rm ${TERRAFORM_ZIP}

# install terraform-ls (usage in vim)
RUN TERRAFORM_LS_VERSION=$(curl -s https://releases.hashicorp.com/terraform-ls/ | grep terraform-ls/ | sed 's/<[^>]*>//g' | sed 's/terraform-ls_//g' | tr -s \\t " " | sort -r | head -n 1 | cut -c 2-) && \
    TERRAFORM_LS_ZIP="terraform-ls_${TERRAFORM_LS_VERSION}_$(uname | tr '[:upper:]' '[:lower:]')_$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/').zip" && \
    wget "https://releases.hashicorp.com/terraform-ls/${TERRAFORM_LS_VERSION}/${TERRAFORM_LS_ZIP}" && \
    unzip ${TERRAFORM_LS_ZIP} && \
    mv terraform-ls /usr/local/bin/terraform-ls && \
    rm "${TERRAFORM_LS_ZIP}"

# install cilium
RUN CILIUM_VERSION=$(curl -s https://api.github.com/repos/cilium/cilium-cli/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1') && \
    CILIUM_ARCHIVE="cilium-$(uname | tr '[:upper:]' '[:lower:]')-$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/').tar.gz" && \
    wget https://github.com/cilium/cilium-cli/releases/download/v${CILIUM_VERSION}/${CILIUM_ARCHIVE} && \
    tar xf ${CILIUM_ARCHIVE} && \
    rm ${CILIUM_ARCHIVE} && \
    chmod +x cilium && \
    mv cilium /usr/local/bin/cilium

# install nodejs and yarn (coc.nvim)
RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install --yes \
    nodejs \
    yarn

# install hcloud and aws cli
RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install --yes \
    hcloud-cli \
    awscli

# install fluxcd binary
RUN curl -s https://fluxcd.io/install.sh | bash

# install java development premise
RUN apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install --yes \
    openjdk-17-jdk \
    openjdk-11-jdk \
    maven \
    gradle \
    default-jdk

# install atlassian sdk and set ATLAS_HOME accordingly
RUN curl -o /tmp/atlassian-plugin-sdk.tar.gz -L "https://marketplace.atlassian.com/download/plugins/atlassian-plugin-sdk-tgz" && \
  mkdir -p /app/atlassian-sdk && \
  tar xf /tmp/atlassian-plugin-sdk.tar.gz -C \
    /app/atlassian-sdk --strip-components=1
RUN echo "export ATLAS_HOME=/app/atlassian-sdk" > /etc/profile.d/atlassian-sdk.sh

# make typing unicode characters in the terminal work.
ENV LANG en_US.UTF-8

# set default shell to zsh
RUN chsh -s /bin/zsh && \
    echo "export SHELL=/bin/zsh" > /etc/profile.d/40zshdefaultshell.sh

# add a user `coder` so that you're not developing as the `root` user
RUN useradd coder \
      --create-home \
      --shell=/bin/bash \
      --groups=docker \
      --uid=1001 \
      --user-group && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers.d/nopasswd

USER coder

# maven settings.xml for atlassian development
RUN mkdir -p ${HOME}/.m2
ADD ./maven-settings.xml ${HOME}/.m2/settings.xml

# get custom shell setup from github
RUN git clone https://github.com/awzmb/wmconfig $HOME/.cfg
RUN $HOME/.cfg/install || :
