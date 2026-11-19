"""Preenche a cópia do roteiro com respostas e evidências da execução."""

import argparse
import json
import re
from pathlib import Path

from docx import Document
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Pt, RGBColor
from docx.text.paragraph import Paragraph


ROOT = Path(__file__).resolve().parents[1]
EVIDENCIAS = ROOT / "entrega" / "evidencias"
ORIGINAL = ROOT / "docs" / "Roteiro_Docker_Aluno.docx"
RESPOSTAS = ROOT / "entrega" / "respostas.json"
DATA = "18/11/2026"
ESCAPES = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]|\x1b\][^\x07]*\x07|[\x00-\x08\x0b\x0c\x0e-\x1f]")
MAPA = {
    247: ("01-hello",), 277: ("01-ps",), 347: ("02-os-release",),
    468: ("03-build",), 484: ("03-json",), 507: ("03-history",),
    580: ("04-bind-3",), 597: ("04-volume",), 611: ("04-tmpfs-1", "04-tmpfs-2"),
    652: ("05-html",), 673: ("05-portas",), 808: ("06-http",), 822: ("06-logs",),
    947: ("07-json",), 1027: ("08-ps",), 1121: ("09-logs",), 1133: ("09-select",),
    1257: ("10-ps",), 1267: ("10-pgadmin",), 1360: ("11-tamanhos",),
    1467: ("12-hmr",), 1479: ("12-modulos",), 1585: ("13-ps",), 1604: ("13-stats",),
    1626: ("13-registry",), 1819: ("14-ps",), 1833: ("14-antes",),
    1851: ("14-depois",), 1859: ("14-frontend",),
}
DESAFIOS = {
    "01": ("01-desafio", "O filtro por prefixo listou os três containers em execução."),
    "02": ("02-banner", "O figlet foi executado no Ubuntu e a saída foi gravada pelo shell do host."),
    "03": ("03-desafio", "O Dockerfile adicional declarou um healthcheck HTTP e o container foi verificado em execução."),
    "04": ("04-desafio", "O Docker recriou o volume ao solicitá-lo por nome e o contador retomou em 1."),
    "05": ("05-desafio", "O mesmo container ficou conectado às duas redes nomeadas."),
    "06": ("06-indexes", "A página sobre.html foi lida via bind mount. Com Options -Indexes, um diretório sem index retornou 403."),
    "07": ("07-desafio", "A rota /saude/ envia a URI fixa /status. Em /api/, a URI / substitui o prefixo e preserva o sufixo. Sem URI em proxy_pass, o caminho do cliente é repassado."),
    "08": ("08-desafio-ps", "O arquivo de sobreposição incluiu NGINX_HOST e a sondagem HTTP do backend."),
    "09": ("09-desafio", "O índice adicional apareceu no esquema de alunos após inicializar um volume novo."),
    "10": ("10-desafio", "Um serviço de demonstração aguardou a saúde do pgAdmin. A pilha original não tem consumidores internos dependentes da inicialização do painel."),
    "11": ("11-desafio", "O estágio de verificação foi construído separadamente. Ele não foi copiado para o runtime e as duas imagens de produção mantiveram o mesmo tamanho."),
    "12": ("12-tamanhos", "As imagens de desenvolvimento e produção foram construídas e tiveram seus tamanhos registrados."),
    "13": ("13-desafio", "O processo recebeu SIGKILL no teste. O estado e os logs foram inspecionados para diagnosticar a interrupção."),
    "14": ("14-desafio", "A exclusão pela interface retornou HTTP 204, sumiu da consulta e preservou os IDs dos containers durante o teste."),
}


def nova_linha(apos):
    elemento = OxmlElement("w:p")
    apos._p.addnext(elemento)
    return Paragraph(elemento, apos._parent)


def inserir_texto(apos, texto, codigo=False):
    p = nova_linha(apos)
    p.paragraph_format.space_after = Pt(4)
    r = p.add_run(texto)
    r.font.name = "Consolas" if codigo else "Calibri"
    r.font.size = Pt(8 if codigo else 10)
    r.font.color.rgb = RGBColor.from_string("185650" if codigo else "244C41")
    return p


def evidencia(nomes):
    blocos = []
    for nome in nomes:
        arquivo = EVIDENCIAS / f"{nome}.txt"
        if not arquivo.is_file():
            return None
        texto = ESCAPES.sub("", arquivo.read_text(encoding="utf-8", errors="replace")).strip()
        if not texto:
            return None
        blocos.append(texto)
    return "\n\n".join(blocos)


def determinado(n, saida):
    if n == 10:
        return bool(evidencia(("10-pgadmin", "10-persistencia", "10-limpeza")))
    if n == 14:
        return bool(evidencia(("14-frontend", "14-pgadmin", "14-limpeza")))
    return saida


def gerar(destino, ra, turma):
    doc = Document(ORIGINAL)
    doc.core_properties.author = "Lucas Araujo"
    ps = [Paragraph(e, doc) for e in doc._element.iter(qn("w:p"))]
    assert ps[8].text == "Nome do aluno" and ps[1888].text == "Rubrica de avaliação"
    for i, valor in {9: "Lucas Araujo", 11: ra or "Na cópia identificada", 13: turma, 15: DATA}.items():
        ps[i].add_run(valor)
    inserir_texto(ps[144], "Execução no Ubuntu 24.04 em VM QEMU no Windows. Docker Engine e Compose do repositório oficial da Docker. O Codex auxiliou na execução, na coleta e na redação. As saídas anexadas foram obtidas durante os testes.")
    respostas = json.loads(RESPOSTAS.read_text(encoding="utf-8"))
    exercicios = [i for i, p in enumerate(ps) if 229 <= i < 1888 and re.fullmatch(r"Prática [0-9]{2} — .+", p.text)]
    assert len(exercicios) == 14

    status_path = EVIDENCIAS / "status.tsv"
    status = {}
    if status_path.exists():
        for linha in status_path.read_text(encoding="utf-8").splitlines():
            numero, estado = linha.split("\t")
            status[numero] = estado == "0"

    faltando = []
    for i, nomes in MAPA.items():
        texto = evidencia(nomes)
        if texto is None:
            faltando.extend(nomes)
            inserir_texto(ps[i], "Resultado ainda sem evidência anexada.")
            continue
        anterior = ps[i]
        for linha in texto.splitlines():
            anterior = inserir_texto(anterior, linha, codigo=True)
            anterior.paragraph_format.space_after = Pt(0)
        for j in range(i + 1, min(i + 7, len(ps))):
            if ps[j]._p.getparent() is ps[i]._p.getparent() and not ps[j].text.strip():
                ps[j]._p.getparent().remove(ps[j]._p)
            else:
                break

    pgadmin_integrador = evidencia(("14-pgadmin",))
    if pgadmin_integrador:
        inserir_texto(ps[1866], pgadmin_integrador, codigo=True)
        inserir_texto(ps[1866], "Captura da consulta em entrega/evidencias/14-pgadmin.png.")

    total = 0
    for n, (inicio, fim) in enumerate(zip(exercicios, [*exercicios[1:], 1888]), 1):
        numero = f"{n:02}"
        perguntas = next(i for i in range(inicio, fim) if ps[i].text == "Perguntas de verificação")
        desafio = next(i for i in range(perguntas + 1, fim) if ps[i].text == "Desafio")
        checklist = next(i for i in range(desafio + 1, fim) if ps[i].text == "Checklist de conclusão")
        indices = [i for i in range(perguntas + 1, desafio) if re.match(r"^\d+\. ", ps[i].text)]
        assert len(indices) == len(respostas[numero]), numero
        for i, resposta in zip(indices, respostas[numero]):
            inserir_texto(ps[i], resposta)
        total += len(indices)
        nome_evidencia, explicacao = DESAFIOS[numero]
        desafio_observado = evidencia((nome_evidencia,))
        if desafio_observado is None:
            inserir_texto(ps[desafio + 1], "Desafio sem evidência consolidada.")
        else:
            inserir_texto(ps[desafio + 1], f"{explicacao} Evidência: entrega/evidencias/{nome_evidencia}.txt.")
        completa = status.get(numero, False) and determinado(n, True)
        completa = completa and all(evidencia(nomes) for i, nomes in MAPA.items() if inicio <= i < fim)
        if completa:
            inserir_texto(ps[checklist], "Verificado na execução. Saídas reais anexadas nos quadros e nos arquivos da prática.")
            for item in ps[checklist + 1:fim]:
                if not item.text.strip():
                    break
                frase = item.text
                item.style = doc.styles["Normal"]
                propriedades = item._p.pPr
                if propriedades is not None and propriedades.numPr is not None:
                    propriedades.remove(propriedades.numPr)
                item.text = "☑ " + frase
            ps[1911 + 4 * (n - 1)].add_run(DATA)
        else:
            inserir_texto(ps[checklist], "O registro ainda tem etapas sem comprovação suficiente.")
    destino.parent.mkdir(parents=True, exist_ok=True)
    doc.save(destino)
    print(f"{total} respostas, {len(MAPA)} quadros de evidência. Documento: {destino}")
    if faltando:
        print("Quadros pendentes:", ", ".join(faltando))


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("destino", type=Path)
    ap.add_argument("--ra", default="")
    ap.add_argument("--turma", default="Ciência da Computação")
    args = ap.parse_args()
    gerar(args.destino, args.ra, args.turma)
