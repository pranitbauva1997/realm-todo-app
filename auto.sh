export PROJDIR=${PROJDIR:-$(git rev-parse --show-toplevel)}
export IN_NIX_SHELL=${IN_NIX_SHELL:-nopes}
export PYTHONPATH=${PROJDIR}/dj

export PATH=${PROJDIR}/venv/bin:${PROJDIR}/.cargo/bin:$PATH

export DATABASE_URL_PY=sqlite:///${PROJDIR}/hello.db
export DATABASE_URL=hello.db
export CARGO_HOME="${PROJDIR}/.cargo";

setup() {
    pushd2 /

    test -f venv/bin/python || python3 -m venv venv
    test -f venv/bin/doit || pip install -r requirements.txt
    test -f .git/hooks/pre-commit || pre-commit install
    test -f realm/README.md || gsub update

    mkdir -p .cargo
    test -f .cargo/bin/diesel || cargo install diesel_cli --no-default-features --features sqlite

    doit
    popd2
}

pushd2() {
    PUSHED=$(pwd)
    cd "${PROJDIR}""$1" >> /dev/null || return
}

popd2() {
    cd "${PUSHED:-$PROJDIR}" >> /dev/null || return
    unset PUSHED
}

o() {
    cd "${PROJDIR}" || return
}

manage() {
    pushd2 /dj
    DATABASE_URL=${DATABASE_URL_PY} python manage.py "$@"
    r=$?
    popd2
    return ${r}
}

migrate() {
    pushd2 /dj
    DATABASE_URL=${DATABASE_URL_PY} python manage.py migrate "$@"
    r=$?
    popd2
    return ${r}
}

dodo() {
    pushd2 /
    doit "$@"
    r=$?
    popd2
    return ${r}
}

recreatedb_pg() {
    pushd2 /
    psql -U postgres -c "CREATE USER root;"
    psql -U postgres -c "ALTER USER root WITH SUPERUSER;"
    psql -c "DROP DATABASE IF EXISTS amitu_heroku;" template1
    psql -c "CREATE DATABASE amitu_heroku" template1
    psql -c "CREATE EXTENSION IF NOT EXISTS citext;" amitu_heroku

    echo "    -> running django migration"
    # shellcheck disable=SC2119
    migrate

    psql -c "ALTER SCHEMA public RENAME TO the_public_schema;" amitu_heroku

    pg_dump amitu_heroku --schema='the_public_schema' --schema-only -f schema.sql
    psql -c "ALTER SCHEMA the_public_schema RENAME TO public;" amitu_heroku

    sed -i -e 's/the_public_schema/test/g' schema.sql
    sed -i -e 's/test.citext/public.citext/g' schema.sql
    psql -d amitu_heroku -f schema.sql  # create initial test schema

    echo "    -> copying amitu_heroku db into fifthtry_local"

    echo "    -> updating schema.rs"
    rust_schema fifthtry

    echo "    -> all done"
    popd2
}

rust_schema() {
    pushd2 /"$1"_db
    python ../scripts/create_diesel_toml.py "$@"
    diesel print-schema > src/schema_pg.rs
    sed -i -e 's/Citext/realm::base::sql_types::Citext/g' src/schema_pg.rs
    popd2
}

recreatedb_sqlite() {
    pushd2 /
    echo "    -> deleting existing db"
    rm -f "hello.db"

    echo "    -> running django migration"
    # shellcheck disable=SC2119
    DATABASE_URL=${DATABASE_URL_PY} migrate

    echo "    -> creating pristine.db"
    cp "hello.db" "pristine.db"

    echo "    -> generating diesel.toml"
    python scripts/create_diesel_toml_sqlite.py hello hello.db

    echo "    -> updating schema.rs"

    diesel print-schema --database-url=${DATABASE_URL} > src/schema.rs

    echo "    -> all done"
    popd2
}

check() {
    pushd2 /
    sh scripts/clippy.sh
    sh scripts/django-check.sh
    flake8 --ignore=E501,W503 --max-line-length=88
    black --check dj
    popd2
}

djshell() {
    manage shell_plus --ipython
}

dbshell() {
    manage dbshell
}


alias open=/usr/bin/open
alias gst="git status"
alias gd="git diff"
alias gp="git push"
alias less=bat
alias cat=bat
alias lc="tokei -s lines | bat"
alias cc="cargo fmt && cargo check"
alias serve="cargo run -- --test"

setup
