FROM google/cloud-sdk:latest
COPY entrypoint.bash /entrypoint.bash
ENTRYPOINT ["bash", "/entrypoint.bash"]