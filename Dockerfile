# syntax=docker/dockerfile:1

FROM ubuntu
RUN apt update && apt install -y curl gpg
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg;
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null;
RUN apt update && apt install -y gh;

WORKDIR /app

# clone https://github.com/reichlab/container-utils. ADD is a hack ala https://stackoverflow.com/questions/35134713/disable-cache-for-specific-run-commands
ADD "https://api.github.com/repos/reichlab/container-utils/commits?per_page=1" latest_commit
RUN git clone https://github.com/reichlab/container-utils.git

COPY ./app .
CMD ["bash", "./app.sh"]
