FROM osrf/ros:humble-desktop-full

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV ROS_DISTRO=humble
ENV RMW_IMPLEMENTATION=rmw_fastrtps_cpp

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Keep this image Ubuntu/ROS-native. Do not install Conda here; it is a common
# source of protobuf / Python package shadowing problems for ROS and Gazebo.
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales \
    sudo \
    git \
    curl \
    wget \
    rsync \
    tree \
    vim \
    nano \
    ca-certificates \
    build-essential \
    cmake \
    pkg-config \
    python3-pip \
    python3-catkin-pkg \
    python3-colcon-common-extensions \
    python3-rosdep \
    python3-vcstool \
    libboost-all-dev \
    libtbb-dev \
    liburdfdom-dev \
    liborocos-kdl-dev \
    libpcl-dev \
    libeigen3-dev \
    libopencv-dev \
    libmatio-dev \
    gazebo \
    libgazebo-dev \
    mesa-utils \
    x11-apps \
    libgl1 \
    libegl1 \
    libglfw3 \
    libglew2.2 \
    libxinerama1 \
    libxcursor1 \
    libxrandr2 \
    libxi6 \
    ros-humble-urdf \
    ros-humble-urdfdom \
    ros-humble-urdfdom-headers \
    ros-humble-kdl-parser \
    ros-humble-hardware-interface \
    ros-humble-controller-manager \
    ros-humble-controller-interface \
    ros-humble-controller-manager-msgs \
    ros-humble-control-msgs \
    ros-humble-gazebo-ros-pkgs \
    ros-humble-gazebo-plugins \
    ros-humble-gazebo-ros2-control \
    ros-humble-control-toolbox \
    ros-humble-ros2-control \
    ros-humble-ros2-controllers \
    ros-humble-rqt-gui \
    ros-humble-rqt-robot-steering \
    ros-humble-rviz2 \
    ros-dev-tools \
    && locale-gen en_US en_US.UTF-8 \
    && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Optional packages can differ between apt snapshots / ROS package sets.
RUN apt-get update \
    && optional=( \
      ros-humble-plotjuggler \
      ros-humble-plotjuggler-ros \
      ros-humble-robot-controllers \
      ros-humble-robot-controllers-interface \
      ros-humble-robot-controllers-msgs \
    ) \
    && for pkg in "${optional[@]}"; do \
         if apt-cache show "$pkg" >/dev/null 2>&1; then \
           apt-get install -y --no-install-recommends "$pkg"; \
         else \
           echo "[WARN] optional apt package not available, skipping: $pkg"; \
         fi; \
       done \
    && rm -rf /var/lib/apt/lists/*

RUN rosdep init || true

ARG USERNAME=ros
ARG USER_UID=1000
ARG USER_GID=1000

RUN if ! getent group "${USER_GID}" >/dev/null; then \
      groupadd --gid "${USER_GID}" "${USERNAME}"; \
    fi \
    && if ! id -u "${USERNAME}" >/dev/null 2>&1; then \
      useradd --uid "${USER_UID}" --gid "${USER_GID}" -m "${USERNAME}" -s /bin/bash; \
    fi \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}" \
    && chmod 0440 "/etc/sudoers.d/${USERNAME}" \
    && for group in video render dialout; do \
         if getent group "$group" >/dev/null; then usermod -aG "$group" "${USERNAME}"; fi; \
       done

USER ${USERNAME}
WORKDIR /home/${USERNAME}/limx_ws

RUN mkdir -p /home/${USERNAME}/limx_ws/src /home/${USERNAME}/mujoco \
    && echo 'source /opt/ros/humble/setup.bash' >> /home/${USERNAME}/.bashrc \
    && echo 'if [ -f /usr/share/gazebo/setup.bash ]; then source /usr/share/gazebo/setup.bash; fi' >> /home/${USERNAME}/.bashrc \
    && echo 'if [ -f "$HOME/limx_ws/install/setup.bash" ]; then source "$HOME/limx_ws/install/setup.bash"; fi' >> /home/${USERNAME}/.bashrc \
    && echo 'export LIMX_WS=${LIMX_WS:-$HOME/limx_ws}' >> /home/${USERNAME}/.bashrc
