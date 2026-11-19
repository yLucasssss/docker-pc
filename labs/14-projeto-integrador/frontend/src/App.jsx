import { useEffect, useState } from "react";

export default function App() {
  const [alunos, setAlunos] = useState(null);
  const [erro, setErro] = useState(null);
  const [excluindo, setExcluindo] = useState(null);

  useEffect(() => {
    fetch("/api/alunos")
      .then((r) => r.json())
      .then(setAlunos)
      .catch((e) => setErro(String(e)));
  }, []);

  async function excluirAluno(aluno) {
    if (!window.confirm(`Excluir o registro de ${aluno.nome}?`)) return;
    setExcluindo(aluno.id);
    setErro(null);
    try {
      const resposta = await fetch(`/api/alunos/${aluno.id}`, { method: "DELETE" });
      if (!resposta.ok) throw new Error(`Falha na exclusão (${resposta.status})`);
      setAlunos((atuais) => atuais.filter(({ id }) => id !== aluno.id));
    } catch (falha) {
      setErro(String(falha));
    } finally {
      setExcluindo(null);
    }
  }

  return (
    <main className="container">
      <h1>Projeto Integrador — Unifeg</h1>
      <p>React (Nginx) → API (Node/Express-like) → PostgreSQL, tudo em containers.</p>

      {erro && <p style={{ color: "salmon" }}>Erro ao consultar a API: {erro}</p>}
      {!erro && !alunos && <p>Carregando alunos...</p>}

      {alunos && (
        <table>
          <thead>
            <tr><th>RA</th><th>Nome</th><th>Período</th><th>Ações</th></tr>
          </thead>
          <tbody>
            {alunos.map((a) => (
              <tr key={a.id}>
                <td>{a.ra}</td>
                <td>{a.nome}</td>
                <td>{a.periodo}</td>
                <td><button type="button" disabled={excluindo !== null} onClick={() => excluirAluno(a)}>Excluir</button></td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </main>
  );
}
