"""Registra verificação de interface no Chrome usando Playwright."""

import argparse
import json
import re
import sys
import tempfile
from pathlib import Path

from playwright.sync_api import sync_playwright


SAIDA = Path(__file__).resolve().parent / "evidencias"
CHROME = Path(r"C:\Program Files\Google\Chrome\Application\chrome.exe")


def gravar(nome, texto):
    (SAIDA / nome).write_text(texto + "\n", encoding="utf-8")


def integrador(page, url):
    page.goto(url, wait_until="networkidle")
    tabela = page.locator("table")
    tabela.wait_for()
    registro = tabela.get_by_role("row").filter(has_text="Lucas Araujo — teste P2")
    registro.wait_for()
    desc = ("A página React carregou a tabela com RA, nome, período e ações após a chamada GET /api/alunos.\n"
            + tabela.inner_text())
    gravar("14-frontend.txt", desc)
    page.screenshot(path=str(SAIDA / "14-frontend.png"), full_page=True)
    page.once("dialog", lambda dialog: dialog.accept())
    with page.expect_response(lambda r: r.request.method == "DELETE" and "/api/alunos/" in r.url) as resposta:
        registro.get_by_role("button", name="Excluir").click()
    status = resposta.value.status
    assert status == 204, status
    registro.wait_for(state="detached")
    page.reload(wait_until="networkidle")
    page.locator("table").wait_for()
    assert not registro.count()
    page.screenshot(path=str(SAIDA / "14-depois-excluir.png"), full_page=True)
    gravar("14-exclusao-browser.txt", f"DELETE pela interface: HTTP {status}.\nTabela após recarregar:\n{tabela.inner_text()}")


def vite(page, url):
    mensagens = []
    page.on("console", lambda mensagem: mensagens.append(mensagem.text))
    page.goto(url, wait_until="domcontentloaded")
    page.locator("#root h1").wait_for(timeout=20000)
    page.screenshot(path=str(SAIDA / "12-vite-antes.png"))
    for _ in range(75):
        page.wait_for_timeout(500)
        if any("hot updated" in mensagem or "hmr update" in mensagem for mensagem in mensagens):
            break
    alteracoes = [m for m in mensagens if "hot updated" in m or "hmr update" in m or "connected" in m]
    assert any("/src/App.jsx" in m for m in alteracoes), alteracoes
    page.get_by_role("heading", name="Unifeg — React dentro de um container — P2 Lucas Araujo").wait_for()
    gravar("12-hmr-browser.txt", "\n".join(alteracoes) + "\n" + page.locator("#root h1").inner_text())
    page.screenshot(path=str(SAIDA / "12-vite-depois.png"))


def desbloquear_servidor(page, senha):
    aviso = page.get_by_text(re.compile(r"Please enter the password for the user", re.I)).first
    if not aviso.is_visible():
        return False
    campo = page.locator("input[type=password]:visible").last
    if campo.is_visible():
        campo.fill(senha)
    else:
        # Posição do campo do diálogo de conexão no viewport de 1420 × 960.
        page.mouse.click(522, 189)
        page.keyboard.insert_text(senha)
    confirmar = page.get_by_role("button", name=re.compile(r"\bOK\b", re.I)).last
    if confirmar.is_visible():
        confirmar.click()
    else:
        page.mouse.click(973, 281)
    page.wait_for_timeout(1400)
    return True


def pgadmin(page, url, numero, dados):
    page.goto(url + "/login", wait_until="domcontentloaded")
    page.locator("input[name=email]").fill(dados["PGADMIN_DEFAULT_EMAIL"])
    page.locator("input[name=password]").fill(dados["PGADMIN_DEFAULT_PASSWORD"])
    page.locator("button[type=submit],input[type=submit]").first.click()
    servidor = "Lab 10 - Postgres via Compose" if numero == "10" else "Lab 14 - Projeto Integrador"
    grupo = page.get_by_text("Unifeg", exact=True).first
    grupo.wait_for(timeout=45000)
    no_servidor = page.get_by_text(servidor, exact=True).first
    if not no_servidor.is_visible():
        page.mouse.click(15, 100)
    no_servidor.wait_for(timeout=30000)
    page.mouse.click(31, 123)
    banco = page.get_by_text(dados["POSTGRES_DB"], exact=True).first
    databases = page.get_by_text(re.compile(r"^Databases(?:\s|$)")).first
    for _ in range(45):
        if desbloquear_servidor(page, dados["POSTGRES_PASSWORD"]):
            continue
        if databases.is_visible() or banco.is_visible():
            break
        page.wait_for_timeout(500)
    if not banco.is_visible():
        databases.wait_for(timeout=35000)
        page.mouse.click(46, 146)
    banco.wait_for(timeout=25000)
    banco.click(button="right")
    page.get_by_text("Query Tool", exact=True).last.click(timeout=15000)

    print("Query Tool aberto", flush=True)
    sql = "SELECT id, nome, ra, periodo FROM public.alunos ORDER BY id;"
    editor = None
    editor_scope = None
    for _ in range(250):
        if desbloquear_servidor(page, dados["POSTGRES_PASSWORD"]):
            continue
        for frame in page.frames:
            item = frame.locator(".cm-content[contenteditable=true], .CodeMirror textarea").first
            if item.is_visible():
                editor, editor_scope = item, frame
                break
        if editor:
            break
        page.wait_for_timeout(500)
    if not editor:
        raise RuntimeError("Editor SQL não apareceu na interface do pgAdmin.")
    editor.click()
    page.keyboard.press("Control+a")
    page.keyboard.insert_text(sql)
    page.mouse.click(654, 112)
    for i in range(60):
        grade = editor_scope.locator("[role=row], .rdg-row, .slick-row")
        linhas = [" ".join(linha.split()) for linha in grade.all_inner_texts() if "2021" in linha]
        if linhas:
            break
        if i == 8 and editor_scope.get_by_text(re.compile(r"No data output")).first.is_visible():
            # O pgAdmin 8.14 expõe o ícone de execução por tooltip. A página
            # usa viewport fixa e o editor já está aberto nesta etapa.
            page.mouse.click(654, 112)
        page.wait_for_timeout(500)
    else:
        raise RuntimeError("A consulta foi enviada, mas a grade de resultados não apareceu.")
    page.mouse.move(90, 420)
    page.screenshot(path=str(SAIDA / f"{numero}-pgadmin.png"), full_page=True)
    gravar(f"{numero}-pgadmin.txt", f"pgAdmin · servidor {servidor} · banco {dados['POSTGRES_DB']}\n{sql}\n" + "\n".join(linhas))


def main():
    p = argparse.ArgumentParser()
    p.add_argument("modo", choices=("vite", "integrador", "pgadmin"))
    p.add_argument("url")
    p.add_argument("--pratica", choices=("10", "14"))
    args = p.parse_args()
    SAIDA.mkdir(exist_ok=True)
    with sync_playwright() as pw:
        browser = pw.chromium.launch(executable_path=str(CHROME), headless=True)
        page = browser.new_page(viewport={"width": 1420, "height": 960}, locale="en-US")
        if args.modo == "pgadmin":
            try:
                pgadmin(page, args.url, args.pratica, json.load(sys.stdin))
            except Exception:
                print("Página do pgAdmin no momento da falha:", page.title(), page.url, flush=True)
                if "/browser" in page.url:
                    diagnostico = Path(tempfile.gettempdir()) / f"p2-pgadmin-{args.pratica}-diagnostico.png"
                    page.screenshot(path=str(diagnostico), full_page=True)
                    print(diagnostico, flush=True)
                raise
        elif args.modo == "vite":
            vite(page, args.url)
        else:
            integrador(page, args.url)
        browser.close()


if __name__ == "__main__":
    main()
