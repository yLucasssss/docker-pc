#!/usr/bin/env bash
# Executa o roteiro numa VM de laboratório isolada e guarda saídas reais.
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
OUT="$ROOT/entrega/evidencias"
mkdir -p "$OUT"

run() { printf '\n$'; printf ' %q' "$@"; printf '\n'; "$@"; }
evidence() {
    local nome=$1; shift
    run "$@" 2>&1 | tee "$OUT/$nome.txt"
}
http() { curl --fail --silent --show-error "$@"; }
wait_url() {
    local url=$1 tentativas=${2:-150}
    for _ in $(seq 1 "$tentativas"); do
        if curl -fsS --max-time 2 -o /dev/null "$url" 2>/dev/null; then return 0; fi
        sleep 2
    done
    printf 'URL indisponível: %s\n' "$url" >&2
    docker ps -a
    return 1
}
wait_health() {
    local id=$1 tentativas=${2:-100}
    for _ in $(seq 1 "$tentativas"); do
        if [[ $(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "$id") == healthy ]]; then return 0; fi
        sleep 2
    done
    docker logs "$id"; return 1
}
secrets() {
    local senha="Lab$(cat /proc/sys/kernel/random/uuid | tr -d '-')!"
    awk -v senha="$senha" '/^(POSTGRES_PASSWORD|PGADMIN_DEFAULT_PASSWORD)=/{sub(/=.*/,"=" senha)} {print}' \
        .env.example > .env
    chmod 600 .env
}
compose_config() {
    docker compose config --quiet
    docker compose config --services
}
psql09() { docker exec "$1" psql -X -v ON_ERROR_STOP=1 -U unifeg -d "$2" -c "$3"; }
wait_pg() {
    for _ in $(seq 1 100); do
        if docker exec "$1" pg_isready -h 127.0.0.1 -U unifeg -d lab_sistemas_distribuidos >/dev/null 2>&1; then return 0; fi
        sleep 2
    done
    docker logs "$1"; return 1
}
start_pg09() {
    run docker run -d --name lab-postgres --env-file .env -v pgdata-lab09:/var/lib/postgresql/data \
        -v "$PWD/init:/docker-entrypoint-initdb.d:ro" -p 5432:5432 postgres:16-alpine
    wait_pg lab-postgres
}

if [[ ${1:-} == all ]]; then
    : > "$OUT/status.tsv"
    for n in {01..14}; do
        set +e
        bash "$0" "$n" 2>&1 | tee "$OUT/$n-log.txt"
        estado=${PIPESTATUS[0]}
        set -e
        printf '%s\t%s\n' "$n" "$estado" | tee -a "$OUT/status.tsv"
    done
    ! grep -q $'\t[1-9]' "$OUT/status.tsv"
    exit
fi

n=${1:?Informe o número da prática ou all}
cd "$ROOT"/labs/"$n"-*
printf 'Prática %s — %s — %s\n' "$n" "$(basename "$PWD")" "$(date -Iseconds)"

case "$n" in
01)
    { run docker version; run docker compose version; run docker info; run id; } | tee "$OUT/00-ambiente.txt"
    evidence 01-hello docker run hello-world
    run docker run --rm alpine echo 'Ola, Unifeg'
    printf 'hostname\nexit\n' | run script -q -e -c 'docker run -it --name meu-alpine alpine sh' /dev/null
    run docker ps
    evidence 01-ps docker ps -a --filter name=meu-alpine
    run docker logs meu-alpine
    run docker rm meu-alpine
    for i in 1 2 3; do run docker run -d --name "lucas-p2-$i" alpine sleep 300; done
    evidence 01-desafio docker ps --filter 'name=^/lucas-p2-'
    run docker rm -f lucas-p2-1 lucas-p2-2 lucas-p2-3
    ;;
02)
    run docker run -dit --name lab-ubuntu -v "$PWD/scripts:/scripts:ro" ubuntu:24.04 bash
    run docker exec lab-ubuntu bash -c 'apt-get update && apt-get install -y curl procps'
    evidence 02-os-release docker exec lab-ubuntu cat /etc/os-release
    run docker exec lab-ubuntu sh /scripts/explorar.sh
    run docker stop lab-ubuntu
    run docker ps -a --filter name=lab-ubuntu
    run docker start lab-ubuntu
    run docker exec lab-ubuntu bash -c 'command -v curl && curl --version'
    run docker commit lab-ubuntu exploracao-lucas:com-curl
    run docker run --rm exploracao-lucas:com-curl curl --version
    run docker rm -f lab-ubuntu
    run docker run --rm ubuntu:24.04 bash -lc 'if command -v curl; then exit 1; else echo "curl ausente no Ubuntu limpo"; fi'
    run docker run --rm ubuntu:24.04 bash -lc \
        'apt-get update -qq >&2 && apt-get install -y -qq figlet >&2 && figlet "Lucas Araujo"' > "$OUT/02-banner.txt"
    cat "$OUT/02-banner.txt"
    ;;
03)
    evidence 03-build docker build --progress=plain -t app-fundamentos:1.0 .
    run docker run --rm -d --name app-lab03 -p 3000:3000 app-fundamentos:1.0
    wait_url http://localhost:3000
    evidence 03-json http http://localhost:3000
    run docker stop app-lab03
    evidence 03-cache docker build --progress=plain -t app-fundamentos:1.0 .
    printf '\n// Revisao do laboratorio P2 de Lucas Araujo\n' >> app/server.js
    evidence 03-edit docker build --progress=plain -t app-fundamentos:1.0 .
    evidence 03-history docker image history app-fundamentos:1.0
    run docker image ls app-fundamentos
    printf '\nHEALTHCHECK --interval=2s --timeout=2s CMD node -e "fetch(\x27http://127.0.0.1:3000/\x27).then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"\n' > "$OUT/03-healthcheck-linha.txt"
    cat Dockerfile "$OUT/03-healthcheck-linha.txt" > Dockerfile.health
    run docker build -f Dockerfile.health -t app-fundamentos:health .
    run docker run --rm -d --name lab03-saude app-fundamentos:health
    wait_health lab03-saude
    evidence 03-desafio docker ps --filter name=lab03-saude
    run docker stop lab03-saude
    ;;
04)
    mkdir -p dados
    for i in 1 2 3; do
        evidence "04-bind-$i" docker run --rm -v "$PWD/scripts:/scripts:ro" -v "$PWD/dados:/dados" alpine sh /scripts/contador.sh
    done
    run cat dados/contador.txt dados/log.txt
    run docker volume create dados-contador
    for i in 1 2; do run docker run --rm -v "$PWD/scripts:/scripts:ro" -v dados-contador:/dados alpine sh /scripts/contador.sh; done
    evidence 04-volume docker volume inspect dados-contador
    for i in 1 2; do
        evidence "04-tmpfs-$i" docker run --rm -v "$PWD/scripts:/scripts:ro" --tmpfs /dados alpine sh /scripts/contador.sh
    done
    run docker volume ls --filter name=dados-contador
    run docker volume rm dados-contador
    evidence 04-desafio docker run --rm -v "$PWD/scripts:/scripts:ro" -v dados-contador:/dados alpine sh /scripts/contador.sh
    ;;
05)
    run docker network create rede-lab05
    run docker run -d --name servidor --network rede-lab05 nginx:alpine
    for _ in $(seq 1 15); do
        if docker run --rm --network rede-lab05 busybox wget -qO /dev/null http://servidor; then break; fi
        sleep 2
    done
    evidence 05-html docker run --rm --network rede-lab05 busybox wget -qO- http://servidor
    run docker run -d --name servidor-exposto --network rede-lab05 -p 8080:80 nginx:alpine
    wait_url http://localhost:8080
    run http http://localhost:8080
    run docker network inspect rede-lab05
    evidence 05-portas docker port servidor-exposto
    run docker run -d --name servidor-default nginx:alpine
    if run docker run --rm busybox wget -T 5 -qO- http://servidor-default; then exit 1; fi
    run docker network create rede-lab05-b
    run docker network connect rede-lab05-b servidor
    evidence 05-desafio docker inspect --format '{{json .NetworkSettings.Networks}}' servidor
    run docker rm -f servidor servidor-exposto servidor-default
    run docker network rm rede-lab05 rede-lab05-b
    ;;
06)
    run docker run -d --name lab-apache -p 8080:80 -v "$PWD/site:/usr/local/apache2/htdocs" \
        -v "$PWD/conf/httpd.conf:/usr/local/apache2/conf/httpd.conf:ro" httpd:2.4
    wait_url http://localhost:8080
    evidence 06-http http -i http://localhost:8080
    grep -qi 'X-Servido-Por: Apache-Unifeg-Lab06' "$OUT/06-http.txt"
    run docker exec lab-apache httpd -t
    evidence 06-logs docker logs lab-apache
    printf '\n<!-- P2 - Lucas Araujo -->\n' >> site/index.html
    run bash -c 'curl -fsS http://localhost:8080 | grep -F "P2 - Lucas Araujo"'
    printf '<h1>Sobre o laboratório de Lucas Araujo</h1>\n' > site/sobre.html
    evidence 06-desafio http -i http://localhost:8080/sobre.html
    sed -i 's/Options Indexes FollowSymLinks/Options -Indexes +FollowSymLinks/' conf/httpd.conf
    run docker rm -f lab-apache
    run docker run -d --name lab-apache -p 8080:80 -v "$PWD/site:/usr/local/apache2/htdocs" \
        -v "$PWD/conf/httpd.conf:/usr/local/apache2/conf/httpd.conf:ro" httpd:2.4
    wait_url http://localhost:8080/sobre.html
    mkdir -p site/listagem-lab
    printf 'verificacao\n' > site/listagem-lab/dado.txt
    evidence 06-indexes curl -s -o /dev/null -w '%{http_code}\n' http://localhost:8080/listagem-lab/
    grep -q '^403$' "$OUT/06-indexes.txt"
    run docker rm -f lab-apache
    ;;
07)
    run docker network create rede-lab07
    run docker build -t backend-lab07:1.0 ./backend
    run docker run -d --name backend --network rede-lab07 backend-lab07:1.0
    run docker run -d --name lab-nginx --network rede-lab07 -p 8081:80 \
        -v "$PWD/site:/usr/share/nginx/html:ro" -v "$PWD/conf/nginx.conf:/etc/nginx/nginx.conf:ro" nginx:alpine
    wait_url http://localhost:8081/api/status
    run http -i http://localhost:8081
    evidence 07-json http http://localhost:8081/api/status
    run docker exec lab-nginx nginx -t
    if ! grep -q 'location /saude/' conf/nginx.conf; then
        awk '/location \/api\// {print "        location /saude/ { proxy_pass http://backend:4000/status; }"} {print}' \
            conf/nginx.conf > nginx.desafio.tmp
        cat nginx.desafio.tmp > conf/nginx.conf
        rm nginx.desafio.tmp
    fi
    run docker exec lab-nginx nginx -t
    run docker exec lab-nginx nginx -s reload
    wait_url http://localhost:8081/saude/
    evidence 07-desafio http http://localhost:8081/saude/
    run docker rm -f lab-nginx backend
    run docker network rm rede-lab07
    ;;
08)
    run docker compose config
    run docker compose up -d --build
    wait_url http://localhost:8081/api/status
    evidence 08-ps docker compose ps
    run http http://localhost:8080
    run http http://localhost:8081
    run http http://localhost:8081/api/status
    run docker compose logs nginx
    run docker compose exec -T nginx nginx -t
    run docker compose down
    cat > compose.override.yaml <<'EOF'
services:
  nginx:
    environment:
      NGINX_HOST: unifeg-lucas.local
  backend:
    healthcheck:
      test: ["CMD", "node", "-e", "fetch('http://127.0.0.1:4000/status').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"]
      interval: 3s
      timeout: 3s
      retries: 10
EOF
    evidence 08-desafio docker compose config
    run docker compose up -d --wait --wait-timeout 180
    evidence 08-desafio-ps docker compose ps
    run docker compose down
    ;;
09)
    secrets
    run docker volume create pgdata-lab09
    start_pg09
    evidence 09-logs docker logs lab-postgres
    evidence 09-select psql09 lab-postgres lab_sistemas_distribuidos 'SELECT * FROM alunos ORDER BY id;'
    docker exec lab-postgres pg_dump -U unifeg lab_sistemas_distribuidos > "$OUT/09-backup.sql"
    run docker exec lab-postgres createdb -U unifeg lab09_restauro
    run docker exec -i lab-postgres psql -X -v ON_ERROR_STOP=1 -U unifeg -d lab09_restauro < "$OUT/09-backup.sql"
    evidence 09-restauro psql09 lab-postgres lab09_restauro 'SELECT * FROM alunos ORDER BY id;'
    run docker rm -f lab-postgres
    start_pg09
    evidence 09-persistencia psql09 lab-postgres lab_sistemas_distribuidos 'SELECT * FROM alunos ORDER BY id;'
    run docker rm -f lab-postgres
    run docker volume rm pgdata-lab09
    printf '%s\n' 'CREATE INDEX IF NOT EXISTS idx_alunos_ra_lab09 ON alunos (ra);' > init/03-indice.sql
    start_pg09
    evidence 09-desafio psql09 lab-postgres lab_sistemas_distribuidos '\d alunos'
    run docker rm -f lab-postgres
    ;;
10)
    [[ -f .env ]] || secrets
    run compose_config
    run docker compose up -d --wait --wait-timeout 240
    wait_url http://localhost:8082/login 400
    evidence 10-ps docker compose ps
    run docker compose logs db
    run docker compose exec -T db psql -X -U unifeg -d lab_sistemas_distribuidos -c 'SELECT * FROM alunos ORDER BY id;'
    run docker compose down
    cat > compose.desafio.yaml <<'EOF'
services:
  pgadmin:
    healthcheck:
      test: ["CMD", "/venv/bin/python3", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1/', timeout=4).close()"]
      interval: 5s
      timeout: 5s
      start_period: 420s
      retries: 30
  verificador:
    image: alpine
    command: ["echo", "pgAdmin pronto para o serviço dependente"]
    depends_on:
      pgadmin:
        condition: service_healthy
EOF
    desafio=(docker compose -f compose.yaml -f compose.desafio.yaml)
    run "${desafio[@]}" up -d
    wait_health "$("${desafio[@]}" ps -q db)"
    evidence 10-persistencia "${desafio[@]}" exec -T db psql -X -U unifeg -d lab_sistemas_distribuidos -c 'SELECT count(*) FROM alunos;'
    wait_health "$("${desafio[@]}" ps -q pgadmin)" 420
    evidence 10-desafio "${desafio[@]}" ps -a
    evidence 10-desafio-logs "${desafio[@]}" logs verificador
    ;;
11)
    cd app-node
    run docker build --progress=plain -f Dockerfile.single-stage -t app-multistage:single .
    run docker build --progress=plain -f Dockerfile -t app-multistage:multi .
    evidence 11-tamanhos docker image ls app-multistage
    run docker image inspect --format '{{.RepoTags}} {{.Size}} bytes' app-multistage:single app-multistage:multi
    run docker image history app-multistage:single
    run docker image history app-multistage:multi
    run docker run --rm -d --name app-single -p 5000:5000 app-multistage:single
    run docker run --rm -d --name app-multi -p 5001:5000 app-multistage:multi
    for p in 5000 5001; do wait_url "http://localhost:$p"; evidence "11-http-$p" http "http://localhost:$p"; done
    run docker stop app-single app-multi
    awk '/^FROM node:20-alpine/ {print "FROM builder AS teste\nRUN node --check dist/index.js\n"} {print}' Dockerfile > Dockerfile.teste
    run docker build -f Dockerfile.teste --target teste -t app-multistage:teste .
    run docker build -f Dockerfile.teste -t app-multistage:multi-teste .
    evidence 11-desafio docker image inspect --format '{{.RepoTags}} {{.Size}}' app-multistage:multi app-multistage:multi-teste
    test "$(docker image inspect -f '{{.Size}}' app-multistage:multi)" = "$(docker image inspect -f '{{.Size}}' app-multistage:multi-teste)"
    ;;
12)
    run docker compose config
    run docker compose up -d --build
    wait_url http://localhost:5173
    http http://localhost:5173/src/App.jsx > "$OUT/12-antes.jsx"
    sleep 10
    sed -i 's/React dentro de um container/React dentro de um container — P2 Lucas Araujo/' app-react/src/App.jsx
    sleep 4
    http http://localhost:5173/src/App.jsx > "$OUT/12-depois.jsx"
    grep -F 'P2 Lucas Araujo' "$OUT/12-depois.jsx"
    evidence 12-hmr docker compose logs react-dev
    evidence 12-modulos docker compose exec -T react-dev sh -c 'ls -1 node_modules | wc -l'
    run docker compose down
    run docker build -t app-react-lab12:prod .
    run docker build -t app-react-lab12:dev -f Dockerfile.dev .
    evidence 12-tamanhos docker image ls app-react-lab12
    run docker run --rm -d --name react-prod -p 8090:80 app-react-lab12:prod
    wait_url http://localhost:8090
    evidence 12-prod http -I http://localhost:8090
    run docker stop react-prod
    ;;
13)
    run docker compose up -d --build --wait --wait-timeout 240
    evidence 13-ps docker compose ps
    wait_url http://localhost:6000/saude
    run http http://localhost:6000
    evidence 13-saude http http://localhost:6000/saude
    id=$(docker compose ps -q app)
    evidence 13-stats docker stats --no-stream "$id"
    evidence 13-usuario docker compose exec -T app whoami
    run docker compose exec -T app sh -c 'test -s /run/secrets/db_password && echo "Arquivo de segredo montado e legível"'
    run docker inspect --format '{{json .State.Health}} CPU={{.HostConfig.NanoCpus}} MEM={{.HostConfig.Memory}}' "$id"
    run docker build -t app-lab13:1.0 ./app
    run docker tag app-lab13:1.0 localhost:5000/app-lab13:1.0
    wait_url http://localhost:5000/v2/
    run docker push localhost:5000/app-lab13:1.0
    run docker rmi app-lab13:1.0 localhost:5000/app-lab13:1.0
    run docker pull localhost:5000/app-lab13:1.0
    evidence 13-registry http http://localhost:5000/v2/_catalog
    run docker compose logs app
    run docker compose exec -T app sh -c 'printf "DB_PASSWORD_FILE=%s\n" "$DB_PASSWORD_FILE"'
    if run timeout 5 docker compose events --since 5m; then :; else [[ $? == 124 || $? == 143 ]]; fi
    run docker compose kill -s SIGKILL app
    for _ in $(seq 1 30); do
        [[ $(docker inspect -f '{{.State.Running}}' "$id") == false ]] && break
        sleep 1
    done
    [[ $(docker inspect -f '{{.State.Running}}' "$id") == false ]]
    evidence 13-desafio docker compose ps -a app
    run docker inspect --format '{{json .State}}' "$id"
    run docker compose logs app
    run docker compose down -v
    ;;
14)
    [[ -f .env ]] || secrets
    run compose_config
    run docker compose up -d --build --wait --wait-timeout 420
    wait_url http://localhost:8084/api/status
    evidence 14-ps docker compose ps
    evidence 14-status http http://localhost:8084/api/status
    evidence 14-antes http http://localhost:8084/api/alunos
    run http -X POST http://localhost:8084/api/alunos -H 'Content-Type: application/json' \
        -d '{"nome":"Lucas Araujo — teste P2","ra":"2021004","periodo":8}'
    evidence 14-depois http http://localhost:8084/api/alunos
    grep -q 'Lucas Araujo' "$OUT/14-depois.txt"
    run docker compose logs backend
    evidence 14-ids-antes docker compose ps -q
    wait_url http://localhost:8083/login 400
    ;;
*) printf 'Prática inválida: %s\n' "$n" >&2; exit 2 ;;
esac
