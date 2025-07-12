services:
  postgres:
    image: postgres:${postgres_version}
    container_name: postgres-server
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${database_name}
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${postgres_root_password}
      POSTGRES_INITDB_ARGS: "--auth-host=md5"
    ports:
      - "${postgres_port}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-scripts:/docker-entrypoint-initdb.d
      - ./config/postgresql.conf:/etc/postgresql/postgresql.conf
    command: >
      postgres 
      -c config_file=/etc/postgresql/postgresql.conf
      -c log_statement=all
      -c log_destination=stderr
      -c log_min_duration_statement=1000
      -c max_connections=200
      -c shared_buffers=256MB
      -c effective_cache_size=1GB
      -c work_mem=4MB
      -c maintenance_work_mem=64MB
    networks:
      - postgres_network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d ${database_name}"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

volumes:
  postgres_data:
    driver: local

networks:
  postgres_network:
    driver: bridge
