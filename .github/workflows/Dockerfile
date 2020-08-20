# set base image (host OS)
FROM google/cloud-sdk:latest

# set the working directory in the container
WORKDIR /code

# copy the dependencies file to the working directory
COPY provisioning/ .

# install dependencies
RUN pip3 install -r requirements.txt

# command to run on container start
CMD [ "python3", "provision_test.py" ]


