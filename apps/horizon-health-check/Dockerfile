FROM python:3.7.2-alpine3.9

COPY main.py Pipfile Pipfile.lock /opt/horizon-health-check/
WORKDIR /opt/horizon-health-check

# Install dependencies
RUN pip install pipenv \
    && apk add -qU --no-cache -t .build-deps gcc musl-dev git \
    && pipenv sync --bare --clear \
    && apk del -q .build-deps

EXPOSE 8000
