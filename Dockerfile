# https://github.com/baxpr/fsl-base
# This base container has FSL and ImageMagick installed
FROM baxterprogers/fsl-base:v6.0.5.2

# Install Freesurfer bits. We just need mri_convert
RUN wget -nv https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.2.0/freesurfer-linux-centos7_x86_64-7.2.0.tar.gz \
    -O /opt/freesurfer.tgz && \
    tar -zxf /opt/freesurfer.tgz -C /usr/local freesurfer/bin/mri_convert && \
    tar -zxf /opt/freesurfer.tgz -C /usr/local freesurfer/build-stamp.txt && \
    tar -zxf /opt/freesurfer.tgz -C /usr/local freesurfer/SetUpFreeSurfer.sh && \
    tar -zxf /opt/freesurfer.tgz -C /usr/local freesurfer/FreeSurferEnv.sh && \
    rm /opt/freesurfer.tgz

# Freesurfer env
ENV PATH=/usr/local/freesurfer/bin:${PATH}
ENV FREESURFER_HOME=/usr/local/freesurfer
ENV FSF_OUTPUT_FORMAT=nii.gz
ENV XDG_RUNTIME_DIR=/tmp

# Pipeline code
COPY README.md /opt/hipp-pf/README.md
COPY src /opt/hipp-pf/src

# Entrypoint
ENTRYPOINT ["xwrapper.sh","pipeline.sh"]
