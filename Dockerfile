# garyfeng
FROM continuumio/miniconda3:latest

# Install Python 3.9 and Jupyter Lab
RUN conda install python=3.10 -y && \
    conda install jupyterlab -y && \
    conda clean -a -y

# Copy the requirements.txt file into the container
COPY requirements.txt /tmp/requirements.txt

# Install the Python packages listed in requirements.txt
RUN pip install -r /tmp/requirements.txt

# Set up Jupyter Lab to listen on all interfaces and not require a token
RUN jupyter lab --generate-config && \
    echo "c.NotebookApp.ip = '0.0.0.0'" >> ~/.jupyter/jupyter_lab_config.py && \
    echo "c.NotebookApp.open_browser = False" >> ~/.jupyter/jupyter_lab_config.py && \
    echo "c.NotebookApp.token = ''" >> ~/.jupyter/jupyter_lab_config.py

# Install the Python packages not listed in requirements.txt
# RUN pip install datasets tiktoken
# RUN pip install --upgrade pymilvus
# RUN pip install "pymilvus[model]"

# Set the working directory
WORKDIR /home/jovyan/work

# Install necessary build tools
RUN apt-get update && apt-get install -y build-essential cmake git unzip wget

# Add Debian testing repositories for newer versions of GCC and G++
RUN echo "deb http://deb.debian.org/debian testing main" > /etc/apt/sources.list.d/testing.list && \
    apt-get update && \
    apt-get install -y -t testing gcc g++

# # Ensure the exact version of GCC and G++ is used
# RUN GCC_VERSION=$(ls /usr/bin/gcc-* | grep -oP '(?<=/usr/bin/gcc-)\d+' | sort -nr | head -n1) && \
#     GXX_VERSION=$(ls /usr/bin/g++-* | grep -oP '(?<=/usr/bin/g++-)\d+' | sort -nr | head -n1) && \
#     update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-$GCC_VERSION 60 && \
#     update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-$GXX_VERSION 60

# Set environment variable to use C++17 standard
ENV CXXFLAGS="-std=c++17"

# Install Abseil from source
RUN wget https://github.com/abseil/abseil-cpp/archive/refs/tags/20230125.2.zip && \
    unzip 20230125.2.zip && \
    cd abseil-cpp-20230125.2 && \
    mkdir build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DCMAKE_CXX_STANDARD=17 .. && \
    make -j$(nproc) && \
    make install

# Set CMAKE_PREFIX_PATH to the installation location of absl
ENV CMAKE_PREFIX_PATH=/usr/local

# Clone and build re2 from a stable version as a shared library
RUN git clone https://github.com/google/re2.git && \
    cd re2 && git checkout 2023-06-01 && \
    mkdir build && cd build && \
    cmake -DBUILD_SHARED_LIBS=ON -DCMAKE_PREFIX_PATH=/usr/local -DCMAKE_CXX_STANDARD=17 .. && \
    make -j$(nproc) && \
    make install && \
    cd ../.. && rm -rf re2

# Force reinstall the re2 Python package
# RUN pip install --force-reinstall re2

# # COPY current directory
# we will instead use directory mapping during dev
# COPY . /home/jovyan/work

# install ttsfrd
RUN wget https://www.modelscope.cn/models/speech_tts/speech_kantts_ttsfrd/resolve/master/ttsfrd-0.3.9-cp310-cp310-linux_x86_64.whl
RUN pip install ttsfrd-0.3.9-cp310-cp310-linux_x86_64.whl

# Cosyvoice uses Inflect, which requires Pydantic 1.x
RUN pip uninstall -y pydantic && pip install pydantic==1.9.1

# Expose the Jupyter Lab port
EXPOSE 8888

# Start Jupyter Lab
CMD ["jupyter", "lab", "--no-browser", "--allow-root"]
