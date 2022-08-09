FROM cruizba/ubuntu-dind as actions-runner

ARG GITHUB_RUNNER_VERSION="2.294.0"

ENV DEBIAN_FRONTEND "noninteractive"

# Personal Access Token with rights to register the runner
ENV GITHUB_PAT "{{ github_pat }}"
ENV GITHUB_OWNER "dxos"
ENV RUNNER_WORKDIR "_work"

RUN apt-get update \
    && apt-get install -y \
        curl \
        sudo \
        git \
        jq \
        gnupg \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m github \
    && groupadd docker \
    && usermod -aG sudo github \
    && usermod -aG docker github \
    && echo "%sudo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# install tzdata package
RUN sudo apt-get update
RUN apt-get install -y tzdata
# set your timezone
RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime
RUN dpkg-reconfigure --frontend noninteractive tzdata

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y keyboard-configuration

RUN sudo apt-get install -y\
    libgtk-3-0\
    libx11-xcb1\
    libxcomposite1\
    libxcursor1\
    libxdamage1\
    libxfixes3\
    libxi6\
    libxrender1\
    libfreetype6\
    libfontconfig1\
    libdbus-glib-1-2\
    libdbus-1-3\
    libglib2.0-0\
    libpangocairo-1.0-0\
    libpango-1.0-0\
    libharfbuzz0b\
    libatk1.0-0\
    libcairo-gobject2\
    libcairo2\
    libgdk-pixbuf2.0-0\
    libxcb-shm0\
    libpangoft2-1.0-0\
    libxt6\
    libdrm2\
    libnspr4\
    libgbm1\
    libgtk2.0-0\
    libgtk-3-0\
    libnotify-dev\
    libgconf-2-4\
    libnss3\
    libxss1\
    libasound2\
    libxtst6\
    cmake

# Install playwright deps
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
RUN sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
RUN sudo apt-get update
RUN sudo apt-get install -y\
    xauth\
    xvfb\
    libgbm-dev\
    google-chrome-stable\
    fonts-ipafont-gothic\
    fonts-wqy-zenhei\
    fonts-thai-tlwg\
    fonts-kacst\
    fonts-freefont-ttf

USER github
WORKDIR /home/github

RUN curl -Ls https://github.com/actions/runner/releases/download/v${GITHUB_RUNNER_VERSION}/actions-runner-linux-x64-${GITHUB_RUNNER_VERSION}.tar.gz | tar xz && sudo -E ./bin/installdependencies.sh

COPY --chown=github:github entrypoint.sh ./entrypoint.sh
RUN sudo chmod u+x ./entrypoint.sh

ENTRYPOINT ["/home/github/entrypoint.sh"]

RUN git clone https://github.com/pcarrier/baba && cd baba && cmake . && make && make install && cd .. && rm -fr baba

FROM actions-runner as dxos-actions-runner

RUN sudo apt-get update
RUN sudo apt-get install -y autoconf automake make cmake g++ libtool libxtst-dev libpng-dev libx11-dev jq gstreamer1.0-plugins-bad libenchant1c2a gstreamer1.0-libav lsof

ENV NVM_DIR /home/github/.nvm

RUN mkdir -p "$NVM_DIR" && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash

RUN . $NVM_DIR/nvm.sh \
    && nvm install 16.14.2 \
    && nvm use 16.14.2 \
    # Rush and pnpm version match the versions in rush.json:
    && npm install -g @microsoft/rush@5.58.0 pnpm@6.24.2 yarn@1.22.17 \
    && npx playwright@1.11.0 install-deps

RUN echo ". $NVM_DIR/nvm.sh && nvm use 16.14.2" >> /home/github/.bashrc
RUN echo 'export PATH="$(yarn global bin):$PATH"' >> /home/github/.bashrc
