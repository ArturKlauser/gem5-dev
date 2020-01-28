#!/bin/bash
#
# This script is the front-end execution script for using the gem5-dev
# docker image. To use it, you would run a command like this:
#   docker run -v $GEM5_HOST_WORKDIR:/gem5 -it gem5-dev [<cmd>]
#
# Author: Artur Klauser

#MOUNTDIR#  # substituted during docker build
mountdir=${mountdir:-'/gem5'}
readonly sourcedir="${mountdir}/source"
readonly systemdir="${mountdir}/system"

print_usage() {
  cat << EOF
Usage: gem5-dev <cmd>
Where <cmd> is one of:
  help ............. prints this help message
  install-source ... installs the gem5 git source repository into ${sourcedir}
  update-source .... updates the gem5 git source repository in ${sourcedir}
  install-system ... installs the gem5 ARM system images in ${systemdir}
  build ............ builds gem5 ARM binary
  run-se ........... runs gem5 ARM in Syscall Emulation mode
  run-fs ........... runs gem5 ARM in Full System mode
  shell | bash ..... enters into an interactive shell
EOF
}

check_hostdir_mounted() {
  # The docker image contains a watermark file in ${mountdir} which will
  # only be visible when no volume is mounted.
  if [[ -e "${mountdir}/.in-docker-container" ]]; then
    cat << EOF
No host volume mounted to container's ${mountdir} directory.
Run:
  docker run -v \$GEM5_HOST_WORKDIR:${mountdir} -it gem5-dev [<cmd>]
EOF
    exit 1
  fi
}

# Clone gem5 source repository into ${sourcedir} if it isn't already there.
install_source() {
  check_hostdir_mounted
  if [ ! -e "${sourcedir}/.git" ]; then
    echo "installing gem5 source respository into ${sourcedir} ..."
    git clone https://gem5.googlesource.com/public/gem5 ${sourcedir}
  else
    echo "gem5 source respository is already installed."
  fi
}

# Pull updates from gem5 source repository.
update_source() {
  check_hostdir_mounted
  if [[ -e "${sourcedir}/.git" ]]; then
    echo "updatig gem5 source respository at ${sourcedir} ..."
    cd ${sourcedir}
    git pull
  else
    echo "gem5 source respository not found at ${sourcedir}."
  fi
}

# Download full system image if it isn't aleady there.
install_system() {
  check_hostdir_mounted
  if [[ ! -e "${systemdir}" ]]; then
    echo "installing ARM full-system image into ${systemdir} ..."
    mkdir "${systemdir}"
    cd "${systemdir}"
    local image='aarch-system-20180409.tar.xz'
    echo "installing ARM full-system image $image"
    wget -O - "http://www.gem5.org/dist/current/arm/${image}" | tar xJvf -
    image='aarch-system-201901106.tar.bz2'
    echo "installing ARM full-system image $image"
    wget -O - "http://www.gem5.org/dist/current/arm/${image}" | tar xzvf -
  else
    echo "ARM full-system image is already installed."
  fi
}

# Builds the gem5 ARM binary.
build() {
  check_hostdir_mounted
  if [[ ! -e "${sourcedir}" ]]; then
    echo "gem5 source respository not found at ${sourcedir}."
    exit 1
  fi

  echo "building gem5 ARM binary ..."
  cd ${sourcedir}
  # Building inst-constrs-3.cc is a memory hog and can easily run the
  # container out of resources if done in parallel with other compiles. So
  # we first build it alone and then build the rest.
  local cmd="scons build/ARM/arch/arm/generated/inst-constrs-3.o"
  echo "${cmd}"
  ${cmd}
  # Now build the rest in parallel.
  local cmd="scons -j $(nproc) build/ARM/gem5.opt"
  echo "${cmd}"
  ${cmd}
}

# Runs the gem5 ARM binary in Syscall Emulation mode.
run_se() {
  check_hostdir_mounted
  if [[ ! -e "${sourcedir}" ]]; then
    echo "gem5 source respository not found at ${sourcedir}."
    exit 1
  fi

  echo "running gem5 ARM binary in Syscall Emulation mode ..."
  cd ${sourcedir}
  local simulator='build/ARM/gem5.opt'
  local script='configs/example/se.py'
  local binary='tests/test-progs/hello/bin/arm/linux/hello'
  if [[ ! -e "${simulator}" ]]; then
    echo "gem5 simulator binary ${simulator} not found."
    exit 1
  fi
  cmd="${simulator} ${script} -c ${binary}"
  echo "${cmd}"
  ${cmd}
}

# Runs the gem5 ARM binary in Full System mode.
run_fs() {
  check_hostdir_mounted
  if [[ ! -e "${sourcedir}" ]]; then
    echo "gem5 source respository not found at ${sourcedir}."
    exit 1
  fi
  if [[ ! -e "${systemdir}" ]]; then
    echo "gem5 ARM full system image not found at ${systemdir}."
    exit 1
  fi

  echo "running gem5 ARM binary in Full System mode ..."
  cd ${sourcedir}
  local simulator='build/ARM/gem5.opt'
  local script='configs/example/fs.py'

  if [[ ! -e "${simulator}" ]]; then
    echo "gem5 simulator binary ${simulator} not found."
    exit 1
  fi
  cmd="${simulator} ${script} \
    --machine-type=VExpress_GEM5_V1 \
    --dtb=armv8_gem5_v1_1cpu.dtb \
    --kernel=vmlinux.vexpress_gem5_v1_64 \
    --script=tests/halt.sh"
  echo "${cmd}"
  ${cmd}
}

# Starts an interactive shell.
run_shell() {
  check_hostdir_mounted
  echo "To build gem5, run: "
  echo "  cd ${sourcedir}; scons -j \$(nproc) build/ARM/gem5.opt"
  cd "${mountdir}"
  exec /bin/bash -l
}

main() {
  local cmd="$1"
  shift
  case "${cmd}" in
    'help') print_usage ;;
    'install-source') install_source ;;
    'update-source') update_source ;;
    'install-system') install_system ;;
    'build') build ;;
    'run-se') run_se ;;
    'run-fs') run_fs ;;
    'shell' | 'bash') run_shell ;;
    *)
      echo "unkown command '${cmd}'"
      echo
      print_usage
      exit 1
  esac
}

main "$@"
