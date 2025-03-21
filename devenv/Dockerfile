# Local dev with the x86_64 architecture
FROM --platform=linux/amd64 ubuntu:22.04

# Install dependencies and Verilog tools
RUN apt update && apt install -y \
    iverilog \
    gtkwave \
    yosys \
    make \
    gcc \
    g++ \
    vim \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

COPY ../cpsc420-lab1/ ../cpsc420-lab2/ ../cpsc420-lab3/ /workspace/

# Build: `docker build -f ../devenv/Dockerfile -t mydevenv ..`
# Start the container: `docker run -it -v myhomedir:/home/nonroot mydevenv`
CMD ["/bin/bash"]
