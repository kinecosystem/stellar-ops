FROM python:3.7-alpine3.9
RUN pip install prometheus-client requests
EXPOSE 9473
COPY ./stellar-core-prometheus-exporter.py /usr/local/bin/stellar-core-prometheus-exporter.py
CMD [ "python", "/usr/local/bin/stellar-core-prometheus-exporter.py" ]
