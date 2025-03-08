FROM ubuntu:24.04 AS build
RUN apt-get update -y
RUN apt-get install -y git bash wget xz-utils

RUN useradd -ms /bin/bash user
WORKDIR /home/user

RUN wget 'https://github.com/riscv-collab/riscv-gnu-toolchain/releases/download/2025.01.20/riscv64-elf-ubuntu-24.04-gcc-nightly-2025.01.20-nightly.tar.xz' -O riscv.tar.xz \
 && tar -xf riscv.tar.xz \
 && rm riscv.tar.xz

USER user
RUN	echo 'export RISCV="/home/user/riscv"' >> ~/.bashrc \
 && echo 'export PATH=$PATH:$RISCV/bin' >> ~/.bashrc

ENV RISCV=/home/user/riscv

USER root
RUN apt-get install -y autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev libusb-1.0-0-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev device-tree-compiler pkg-config libexpat-dev

USER user
RUN git clone 'https://github.com/riscv-software-src/riscv-isa-sim/' \
 && cd riscv-isa-sim \
 && mkdir build \
 && cd build \
 && ../configure --prefix=$RISCV \
 && make \
 && make install

RUN git clone --recursive 'https://github.com/riscv-collab/riscv-openocd/' \
 && cd riscv-openocd \
 && ./bootstrap \
 && ./configure --enable-internal-jimtcl --prefix=$RISCV \
 && make \
 && make install

ENV PATH=$PATH:$RISCV/bin

RUN git clone 'https://github.com/riscv-software-src/riscv-pk/' \
 && cd riscv-pk \
 && mkdir build \
 && cd build \
 && ../configure --prefix=$RISCV --host=riscv64-unknown-elf \
 && make \
 && make install

RUN git clone 'https://github.com/riscv/riscv-tests/' \
 && cd riscv-tests \
 && git submodule update --init --recursive \
 && autoconf \
 && ./configure --prefix=$RISCV/target \
 && make \
 && make install

################## 2nd stage ####################

FROM ubuntu:24.04
RUN apt-get update -y \
 && apt-get install -y tmux vim bash wget

RUN apt-get install -y verilator gtkwave

RUN useradd -ms /bin/bash user
WORKDIR /home/user

USER user
RUN	echo 'export RISCV="/home/user/riscv"' >> ~/.bashrc \
 && echo 'export PATH=$PATH:$RISCV/bin' >> ~/.bashrc

COPY --from=build /home/user/riscv /home/user/riscv

RUN wget 'https://github.com/mortbopet/Ripes/releases/download/v2.2.6/Ripes-v2.2.6-linux-x86_64.AppImage' -O Ripes.AppImage \
 && chmod a+x Ripes.AppImage

USER root
RUN apt-get install -y libfuse2 fuse libgl1 libglx-mesa0 libmpc3 make device-tree-compiler default-jre g++ gcc

RUN wget 'https://github.com/TheThirdOne/rars/releases/download/v1.6/rars1_6.jar' -O rars1_6.jar \
 && chmod a+x rars1_6.jar

USER user
CMD ["/bin/bash", "-l"]
