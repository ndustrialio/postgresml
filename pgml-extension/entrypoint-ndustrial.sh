#!/bin/bash

POSTGRES_USER=${POSTGRES_USER:-"user"}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-"pass"}
POSTGRES_DB=${POSTGRES_DB:-"db"}

# Exit on error, real CI
echo "Starting Postgres..."
service postgresql start
echo "Connecting to Postgres..."
while ! psql -c 'SELECT 1' -U postgres -h 127.0.0.1 > /dev/null; do
	sleep 1
done
echo "Creating user and database..."
(createdb -U postgres -h 127.0.0.1 "$POSTGRES_DB" 2> /dev/null) || true
(createuser -U postgres -h 127.0.0.1 -s -i -d -r -l -w "$POSTGRES_USER")
psql -c "ALTER ROLE \"$POSTGRES_USER\" WITH PASSWORD '$POSTGRES_PASSWORD'" -U postgres -h 127.0.0.1
echo "Installing pgml extension..."
psql -U postgres -h 127.0.0.1 "$POSTGRES_DB" -c 'CREATE EXTENSION IF NOT EXISTS pgml'
if [ -d "/docker-entrypoint-initdb.d" ]; then
echo "Running custom scripts..."
for f in /docker-entrypoint-initdb.d/*.sql; do
	echo "Running custom script ${f}"
	psql -U postgres -h 127.0.0.1 "$POSTGRES_DB" -f "${f}"
done
fi
echo "Installing pgvector.. "
psql -U postgres -h 127.0.0.1 "$POSTGRES_DB" -c 'CREATE EXTENSION IF NOT EXISTS vector'
echo "Ready!"
if [[ ! -z $@ ]]; then
	echo
	echo "To connect to the database: "
	echo "  psql postgres://$POSTGRES_USER:$POSTGRES_PASSWORD@127.0.0.1:5432/$POSTGRES_DB"
	echo
	$@
fi