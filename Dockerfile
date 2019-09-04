FROM postgres:11-alpine

ENV PGEVOLVE_INSTALL_PATH="/opt/pg-evolve/install" \
    PGEVOLVE_EVOLUTIONS_PATH="/opt/pg-evolve/evolutions"

COPY src/pg-evolve /usr/local/bin

RUN mkdir -p ${PGEVOLVE_EVOLUTIONS_PATH}

COPY src/install ${PGEVOLVE_INSTALL_PATH}

CMD ["pg-evolve"]
