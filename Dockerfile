# syntax=docker/dockerfile:1

FROM ubuntu
RUN apt-get update && apt-get install -y curl
WORKDIR /app
COPY ./app .
CMD ["bash", "./app.sh"]
