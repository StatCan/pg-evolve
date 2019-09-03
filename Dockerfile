FROM postgres:11-alpine

COPY src/pg-evolve /usr/local/bin

RUN mkdir -p /opt/pg-evolve/install

COPY src/install /opt/pg-evolve/install/

CMD ["pg-evolve"]
