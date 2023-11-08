# A dockerfile must always start by importing the base image.
# We use the keyword 'FROM' to do that.
# In our example, we want import the python image.
# So we write 'python' for the image name and 'latest' for the version.
FROM python:3.10-bookworm

RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
RUN python get-pip.py
RUN python -m pip install snakemake
RUN python -m pip install vpt[all]

# In order to launch our python code, we must import it into our image.
# We use the keyword 'COPY' to do that.
# The first parameter 'main.py' is the name of the file on the host.
# The second parameter '/' is the path where to put the file on the image.
# Here we put the file at the image root folder.
ADD main.py .
ADD ./workflow ./cell-segmentation/workflow
ADD ./config ./cell-segmentation/config
ADD ./utils ./cell-segmentation/utils

# We need to define the command to launch when we are going to run the image.
# We use the keyword 'CMD' to do that.
# The following command will execute "python ./main.py".
CMD [ "python", "./main.py" ]
# CMD [ "bash", "./workflow/test_run.sh" ]
# CMD ["supervisord", "-n"]