FROM gcr.io/cloudshell-images/cloudshell:latest

WORKDIR /

RUN git clone https://github.com/GoogleCloudPlatform/stackdriver-sandbox.git

WORKDIR /stackdriver-sandbox/terraform/

ENTRYPOINT ["./install.sh"]
