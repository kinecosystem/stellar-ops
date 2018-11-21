FROM nginx:1.15.6-alpine
COPY ./ngx_http_statsd_module.so /etc/nginx/modules/
COPY ./nginx.conf.tmpl /etc/nginx/
EXPOSE 80 443
CMD envsubst '$STATSD_METRIC_PREFIX $STATSD_SAMPLE_RATE $HOST $PROXY_LISTEN_PORT $PROXY_READ_TIMEOUT $PROXY_PASS_URL' < /etc/nginx/nginx.conf.tmpl > /etc/nginx/nginx.conf && exec nginx
