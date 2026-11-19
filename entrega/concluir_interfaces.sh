#!/usr/bin/env bash
# Registra a persistência e a remoção dos volumes após a conferência no navegador.
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
OUT="$ROOT/entrega/evidencias"
n=${1:?Informe a prática 10 ou 14}
[[ "$n" == 10 || "$n" == 14 ]]
cd "$ROOT"/labs/"$n"-*
compose=(docker compose)
if [[ -f compose.desafio.yaml ]]; then
    compose+=(-f compose.yaml -f compose.desafio.yaml)
fi

if [[ "$n" == 14 ]]; then
    antes=$(grep -E '^[a-f0-9]{64}$' "$OUT/14-ids-antes.txt" | sort)
    depois=$("${compose[@]}" ps -q | sort)
    [[ -n "$antes" && "$antes" == "$depois" ]]
    consulta="SELECT id, ra FROM alunos WHERE ra = '2021004';"
    {
        printf 'IDs iguais antes e depois da exclusão pelo navegador:\n%s\n\n' "$depois"
        printf '$ consulta ao banco\n%s\n' "$consulta"
        "${compose[@]}" exec -T db psql -X -v ON_ERROR_STOP=1 -U unifeg -d lab_sistemas_distribuidos -c "$consulta"
    } | tee "$OUT/14-desafio-banco.txt"
    grep -q '(0 rows)' "$OUT/14-desafio-banco.txt"
fi

projeto=$(basename "$PWD")
if [[ "$n" == 10 ]]; then projeto=lab10-pgadmin-compose; else projeto=lab14-projeto-integrador; fi
{
    printf '$ docker compose down\n'
    "${compose[@]}" down
    printf '$ docker volume ls --filter label=com.docker.compose.project=%s\n' "$projeto"
    docker volume ls --filter "label=com.docker.compose.project=$projeto"
    [[ -n $(docker volume ls -q --filter "label=com.docker.compose.project=$projeto") ]]
    printf '$ docker compose down -v\n'
    "${compose[@]}" down -v
    printf '$ docker volume ls --filter label=com.docker.compose.project=%s\n' "$projeto"
    docker volume ls --filter "label=com.docker.compose.project=$projeto"
    [[ -z $(docker volume ls -q --filter "label=com.docker.compose.project=$projeto") ]]
} 2>&1 | tee "$OUT/$n-limpeza.txt"
