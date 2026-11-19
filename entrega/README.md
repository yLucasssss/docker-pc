# Avaliação P2 — Docker e Docker Compose

**Lucas Araujo · Ciência da Computação · Centro Universitário Unifeg**

O [roteiro preenchido](../docs/Roteiro_Docker_Aluno_Preenchido.docx) reúne 45 respostas relacionadas às 14 práticas. Os quadros apontam para saídas de comandos Docker, Compose, `curl`, PostgreSQL e verificações no navegador. Os registros completos estão em [evidencias/](evidencias/).

A cópia identificada para entrega acadêmica está na pasta local `entrega-local/`. O RA está nessa cópia.

O projeto partiu do commit `e86296957db798c46334e53100b0a3d812628719` do [repositório do roteiro](https://github.com/pccdias/roteiro_docker_unifeg_2026b). Cada pasta em `labs/` preserva o código e as configurações da sua prática. Os arquivos produzidos para os desafios acompanham as práticas correspondentes.

## Ambiente e reprodução

Os comandos da coluna Linux foram executados no Ubuntu 24.04, em uma VM local QEMU no Windows. O laboratório usou Docker Engine e os plugins Compose e Buildx do repositório oficial da Docker. Os horários nos logs da VM estão em UTC. No Ubuntu, um usuário com acesso ao daemon pode executar as etapas na ordem do roteiro.

```bash
bash entrega/executar.sh 01
```

O script aceita o número da prática ou `all` para a sequência completa. Ele foi usado em um ambiente de laboratório dedicado e cria containers, imagens, redes e volumes com os nomes do roteiro. As práticas 10 e 14 mantêm as interfaces abertas para a conferência no navegador. Em seguida, `bash entrega/concluir_interfaces.sh 10` ou `bash entrega/concluir_interfaces.sh 14` verifica as condições e encerra a respectiva stack.

O script `entrega/navegador.py` usa Playwright e o Chrome para registrar as telas do Vite, do integrador e do pgAdmin. Ele lê credenciais de teste pela entrada padrão. Os arquivos `.env` são gerados nas práticas que exigem senhas. Cada segredo real fica no ambiente local do laboratório.

O Codex auxiliou na execução, na coleta de evidências, na elaboração das respostas e na implementação dos desafios. Os resultados foram registrados durante a execução local.
