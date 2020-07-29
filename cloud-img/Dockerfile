FROM gcr.io/cloudshell-images/cloudshell:latest

# install Terraform 0.12.29
RUN sudo apt-get install unzip && \
    wget -q https://releases.hashicorp.com/terraform/0.12.29/terraform_0.12.29_linux_amd64.zip -o ./terraform.zip && \
    unzip -o terraform.zip && \
    sudo install terraform /usr/local/bin

# Change "Open in Cloudshell" script to run ./install.sh
RUN sed -i '$ d' /google/devshell/bashrc.google.d/cloudshell_open.sh
RUN sed -i '$ d' /google/devshell/bashrc.google.d/cloudshell_open.sh
RUN echo './install.sh' >> /google/devshell/bashrc.google.d/cloudshell_open.sh
RUN echo '}' >> /google/devshell/bashrc.google.d/cloudshell_open.sh  
