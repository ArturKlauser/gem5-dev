# Development environment for [gem5](http://gem5.org) ARM.
The Dockerfile in this repository creates the gem5-dev docker image that
includes the build environment necessary to compile and run the gem5 ARM
full system simulator. The image is structured in such a way that it assumes
the user mounts a gem5 working directory residing on the host machine into
the container running the gem5-dev image. The docker image hosts the full
build environment, whereas the gem5 working directory holds the gem5 source
code, compile artifacts, and the image files for full system simulation if
desired.

The gem5-dev docker image is structured to run as a binary supporting several
commands:
  * **install-source**: installs the gem5 sources from git in the working
     directory
  * **update-source**: updates the gem5 sources
  * **install-system**: installs the gem5 ARM system image by downloading and
    uplacking the corresponding tar file
  * **build**: builds the gem5 ARM binary
  * **run-se**: runs a sample binary in Syscall Emulation mode
  * **run-fs**: starts a sample run in Full System mode
  * **shell**: enters into an interactive shell in the container running the
    gem5-dev image in which the developer can work within the build
    environment; above commands are also available within this shell as
    commands to the gem5-dev tool

## How to build the docker image
Build the gem5-dev image like this:
```
docker build -t gem5-dev docker
```
This creates the docker image called gem5-dev. 
Docker hub also holds a pre-built image under [arturklauser/gem5-dev](https://hub.docker.com/r/arturklauser/gem5-dev/). To use this image simply use `docker pull arturklauser/gem5-dev` or use it in your own Dockerfile:
```
FROM arturklauser/gem5-dev
...
```

## How to use the docker image
### Setting up the gem5 working directory
Create a directory on the host system which you'd like to use as gem5
working directory. It will contain the sources, build artifacts (e.g. .o and
binary files), and the ARM system image files. You'll need several GBs of
space for this (currently about 12 GB, but it depends on your builds). 
Let's call that directory $GEM5_WORKDIR.

### Installing, building, and running gem5
Now you can run the gem5-dev docker image and use it to get the gem5 source,
compile gem5, and run it:
```
docker run --rm -v $GEM5_WORKDIR:/gem5 -it gem5-dev install-source
docker run --rm -v $GEM5_WORKDIR:/gem5 -it gem5-dev build
docker run --rm -v $GEM5_WORKDIR:/gem5 -it gem5-dev run-se
```
Note that the gem5 sources will be installed into a directory called
'source' inside $GEM5_WORKDIR.

### Installing and running full system images
If you also want to use full system mode, you have to install the
corresponding system files as well:
```
docker run --rm -v $GEM5_WORKDIR:/gem5 -it gem5-dev install-system
docker run --rm -v $GEM5_WORKDIR:/gem5 -it gem5-dev run-fs
```
Note that the gem5 ARM system files will be installed into a directory called
'system' inside $GEM5_WORKDIR.

If you want to build your own full system images, see Pau's
[gem5_arm_fullsystem_files_generator](https://github.com/metempsy/gem5_arm_fullsystem_files_generator).

### Starting your own runs
The runs that were started with the 'run' commands above are just sample
commands that allow you to verify that the build has worked properly. In
order to actually do something useful with gem5, you'll have to issue your
own run commands. To do that, get into a shell in the build environment and
issue the run commands you need:
```
# on the host
docker run --rm -v $GEM5_WORKDIR:/gem5 -it gem5-dev shell
# now in the docker container
cd source
build/ARM/gem5.opt configs/example/se.py -c tests/test-progs/hello/bin/arm/linux/hello
```

### Modifying source code
The gem5-dev build environment doesn't contain any editor, so it's not a
convenient place to modify the gem5 sources. The method of development with
the gem5-dev docker image is that you edit the gem5 source files on your
host machine on which it is assumed you have already set up whatever source
code editing environment you prefer. Since all the source code lives in the
gem5 working directory on the host, your host editing environment has full
native access to the source files. Once you're done with a modification and
want to test it, simply run the compile step inside the gem5-dev container.
Here is a sample development cycle:
```
# on the host
vim $GEM5_WORKDIR/source/src/arch/arm/some_file.cc
# edit that file, then compile it
docker run --rm -v $GEM5_WORKDIR:/gem5 -it gem5-dev build
```

Alternatively, you could also use a second terminal in which you keep a
shell open in the gem5-dev container and perform your compiles there:

*Terminal 1:*
```
# on the host
docker run --rm -v $GEM5_WORKDIR:/gem5 -it gem5-dev shell
# now in the docker container
cd source
```
*Terminal 2:*
```
# on the host
edit $GEM5_WORKDIR/source/src/arch/arm/some_file.cc
# editing that file ...
```
*Terminal 1:*
```
# still in the docker container
scons -j $(nproc) build/ARM/gem5.opt
# if it compiles, run it, otherwise back to editing on the host
build/ARM/gem5.opt configs/example/se.py -c tests/test-progs/hello/bin/arm/linux/hello
```
