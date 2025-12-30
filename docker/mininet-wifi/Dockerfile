# docker/mininet-wifi/Dockerfile
FROM python:3.7-slim

# metadata pins
ENV DEBIAN_FRONTEND=noninteractive \
    OVS_VERSION=2.15.3 \
    PYTHON_VERSION=3.7.18 \
    MNWIFI_TAG=v2.4.3

# install system deps required for building OVS and Mininet-WiFi
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential ca-certificates curl git wget gnupg lsb-release \
    iproute2 iputils-ping net-tools ethtool tcpdump ssh sudo \
    libssl-dev libffi-dev pkg-config libnl-3-dev libnl-route-3-dev \
    libcap-ng-dev automake autoconf libtool python3-dev python3-venv \
    apt-transport-https && rm -rf /var/lib/apt/lists/*

# Install Open vSwitch pinned version (compile from source)
WORKDIR /tmp
RUN wget https://www.openvswitch.org/releases/openvswitch-${OVS_VERSION}.tar.gz \
    && tar xzf openvswitch-${OVS_VERSION}.tar.gz \
    && cd openvswitch-${OVS_VERSION} \
    && ./configure \
    && make -j"$(nproc)" && make install \
    && cd .. && rm -rf openvswitch-${OVS_VERSION}*

# Install Mininet-WiFi pinned tag (uses system python 3.7)
WORKDIR /opt
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3-pip python3-six wireless-tools rfkill python3-numpy libnl-genl-3-dev libevent-dev libdbus-1-dev \
        cgroup-tools \
    && git clone --depth 1 --branch ${MNWIFI_TAG} https://github.com/intrig-unicamp/mininet-wifi.git \
    && cd mininet-wifi \
    # Ensure submodules fetch is robust (try to update, fallback to https for problematic remotes)
    && git submodule update --init --recursive || (sed -i 's|http://w1.fi/hostap.git|https://w1.fi/hostap.git|g' .gitmodules && git submodule sync && git submodule update --init --recursive) \
    && apt-get update \
    && sed -i 's/pep8/pycodestyle/g; s/\bpyflakes\b/python3-pyflakes/g; s/cgroup-bin/cgroup-tools/g' util/install.sh \
    && python3 -m pip install --no-cache-dir six numpy matplotlib \
    && ./util/install.sh -Wlnfv  # installs mininet, ovs, wi-fi dependencies \
    && python3 -m pip install -e . \
    && rm -rf /var/lib/apt/lists/*

# Create a Python 3.7 virtualenv for extra tools and pin exact deps
RUN python3 -m venv /opt/py37 \
    && /opt/py37/bin/pip install --no-cache-dir \
      "ryu==4.34" \
      "eventlet==0.25.1" \
      "dnspython==1.16.0" \
      "setuptools==25.4.0"
ENV PATH="/opt/py37/bin:/opt/mininet-wifi:/opt/mininet-wifi/bin:${PATH}"

# cleanup
RUN apt-get purge -y --auto-remove build-essential wget \
    && rm -rf /var/lib/apt/lists/* /tmp/*

# add mnwifi helper scripts
WORKDIR /root
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["bash"]