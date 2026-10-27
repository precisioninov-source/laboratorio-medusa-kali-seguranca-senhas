# Laboratório de Segurança de Senhas: Kali Linux, Medusa e Metasploitable 2

> Projeto educacional para um laboratório local e isolado. Os testes descritos aqui são autorizados somente contra VMs que você controla. Não use os comandos contra endereços públicos, redes corporativas, contas reais ou sistemas sem autorização formal.

**Trilha:** fundamentos de autenticação, ataques a senhas e defesa  
**Ferramentas principais:** Kali Linux, Medusa, VirtualBox e Metasploitable 2  
**Complementos estudados:** Hydra, Ncrack, John the Ripper, WPScan, Patator, SMBclient e DVWA  
**Status:** roteiro preparado; preencha a seção de resultados depois de executar o laboratório.

## Apresentação

Este repositório documenta um laboratório controlado para entender como senhas fracas, reutilizadas ou previsíveis podem comprometer serviços de rede. A prática relaciona autenticação, ataques de dicionário, força bruta, combinações híbridas, regras de transformação (mangling), password spraying e credential stuffing com controles de prevenção e detecção.

O objetivo não é apenas encontrar uma combinação válida. É registrar hipótese, escopo, evidências, limitações e recomendações para reduzir o risco. As credenciais do laboratório são fictícias e as listas são pequenas de propósito.

## Objetivos de aprendizagem

- Explicar autenticação e diferença entre fator de autenticação, credencial e sessão.
- Diferenciar dicionário, força bruta pura, ataque híbrido, password spraying e credential stuffing.
- Reconhecer que enumeração de usuários amplia a superfície de ataque.
- Executar uma simulação limitada com Medusa contra FTP e SMB em VM vulnerável.
- Observar o comportamento de um formulário web de DVWA e entender a diferença entre autenticação HTTP e formulário web.
- Relacionar resultados com controles preventivos, monitoramento e resposta.
- Comparar ferramentas sem tratar nenhuma delas como substituta de autorização ou de metodologia.

## Escopo e regras do laboratório

| Item | Definição |
|---|---|
| Ativos autorizados | Kali Linux e Metasploitable 2 criadas por você no VirtualBox; DVWA local, se usado |
| Rede | Host-only ou rede interna dedicada, sem adaptador em bridge |
| Dados | Usuários e senhas fictícios, sem reutilizar credenciais pessoais ou corporativas |
| Intensidade | Uma VM por vez, wordlists minúsculas, baixa concorrência e janela curta |
| Parada | Interrompa ao observar instabilidade, bloqueios inesperados ou tráfego fora do escopo |
| Evidências | Anote data, IP privado, versão, comando redigido sem segredo e resultado; oculte credenciais |

**Antes de começar:** desligue as VMs e confirme que ambas usam a mesma rede Host-only (ou Internal Network) no VirtualBox. Não use Bridge. Se a VM Kali tiver outra interface com acesso à internet, confirme que o alvo é o IP Host-only da VM vulnerável, não o gateway nem o IP público. Tire snapshots para poder voltar ao estado inicial.

## Arquitetura

```text
[Kali Linux: ferramentas e anotações]
              │ rede isolada Host-only
              ▼
[Metasploitable 2: FTP / SMB vulneráveis]
              │
              └── [DVWA local: formulário web, opcional]
```

## Preparação do ambiente

1. Instale o VirtualBox e obtenha as imagens de Kali Linux e Metasploitable 2 de suas fontes oficiais.
2. Crie duas VMs e configure as placas de rede na mesma rede Host-only ou Internal Network. Mantenha ambas sem bridge.
3. Inicie primeiro a VM vulnerável e depois a Kali. Descubra o IP privado em cada VM com `ip addr`.
4. Confirme conectividade apenas entre as VMs: `ping -c 2 <IP_DA_VM_VULNERAVEL>`.
5. Na Kali, verifique que o Medusa existe e consulte módulos instalados:

```bash
medusa -V
medusa -d
medusa -M ftp -q
medusa -M smbnt -q
medusa -M web-form -q
```

Os módulos disponíveis podem variar conforme a versão e os pacotes instalados. Use o help local para conferir sintaxe antes de executar. Nunca cole uma lista grande de senhas em um alvo.

### Checagem de rede

Registre os endereços privados em `docs/registro-de-testes.md`. Se não conseguir identificar com certeza o IP da VM vulnerável, não execute os testes. Refaça a configuração do VirtualBox e valide o endereçamento.

## Conceitos estudados

| Técnica | Como funciona | Risco/observação |
|---|---|---|
| Ataque de dicionário | Compara uma lista pequena de senhas prováveis | Senhas comuns ou previsíveis podem ser descobertas |
| Força bruta pura | Tenta combinações de um alfabeto definido | O espaço cresce rapidamente com o tamanho e a variedade de caracteres |
| Híbrido / mangling | Aplica variações a palavras-base, como sufixos | Padrões previsíveis continuam vulneráveis |
| Password spraying | Testa poucas senhas comuns em vários usuários, espaçando tentativas | Pode contornar limiares simples por conta; deve ser detectado por correlação |
| Credential stuffing | Testa pares usuário/senha vazados de outros serviços | Reutilização de senha transforma vazamentos externos em risco interno |
| Enumeração de usuários | Tenta identificar contas existentes por respostas, shares ou mensagens | Respostas diferentes podem revelar nomes válidos |

**Cuidado conceitual:** password spraying e credential stuffing não são sinônimos. No spraying, uma ou poucas senhas são testadas em várias contas. No credential stuffing, pares de credenciais já expostos são reutilizados. Este laboratório usa apenas valores fictícios e não reproduz listas vazadas.

## Prática 1 — FTP com Medusa

Crie ou revise uma conta de teste controlada na VM. Não presuma usuário/senha padrão: confirme as configurações da VM e documente o estado inicial. Use a lista curta fornecida em `wordlists/senhas-lab.txt`.

```bash
# Troque pelo IP Host-only confirmado da sua VM vulnerável.
TARGET="<IP_HOST_ONLY_METASPLOITABLE>"
medusa -h "$TARGET" -u labuser -P wordlists/senhas-lab.txt -M ftp -t 1
```

O comando deve ser executado somente após verificar que `$TARGET` é a VM de laboratório. `-u` define um usuário único, `-P` aponta para uma lista de senhas e `-M ftp` seleciona o módulo FTP. `-t 1` limita a concorrência. Uma tentativa aceita é evidência de senha fraca no estado testado; não salve nem publique o valor da senha.

**Validação:** verifique o log da VM e o resultado do cliente FTP local. Registre apenas “autenticou/não autenticou”, horário e evidência sanitizada. Não deixe uma sessão aberta nem leia arquivos pessoais.

## Prática 2 — SMB, enumeração e spraying controlado

Primeiro identifique serviços e compartilhamentos apenas no alvo autorizado. A enumeração é observação de exposição, não autorização para acessar dados.

```bash
# Lista serviços/compartilhamentos anunciados pelo alvo de laboratório.
smbclient -L "//$TARGET" -N
```

Se precisar listar contas para a atividade, use somente contas sintéticas previamente preparadas na VM e ferramentas locais da trilha. Registre a fonte e o motivo. Não enumere usuários de rede real. Para a simulação de spraying, escolha uma única senha fictícia e poucas contas de teste, sem combinações de credenciais reais:

```bash
# Exemplo didático: poucas contas fictícias e uma senha fictícia.
medusa -h "$TARGET" -U wordlists/usuarios-lab.txt -p 'TreinoLab!2026' -M smbnt -t 1
```

A compatibilidade do módulo SMBNT depende da versão e dos recursos compilados no Medusa. Consulte `medusa -M smbnt -q`. Se a VM não oferecer SMB compatível, registre a limitação; não aumente a intensidade para “forçar” resultado.

**Evidência:** registre quantas contas de laboratório foram testadas, resultado agregado, serviço/porta e alertas observados. Não inclua senha válida, hash, nomes pessoais ou dados retornados por shares.

## Prática 3 — Formulário web DVWA

O DVWA deve estar instalado localmente e acessível somente pela rede do laboratório. Defina o nível de segurança de forma consciente e documente-o. O módulo `http` do Medusa cobre autenticação HTTP como Basic/NTLM/Digest; o `web-form` é o módulo voltado a formulários GET/POST. Um formulário pode usar token CSRF, cookies ou lógica específica, então o resultado depende de examinar a requisição e o módulo disponível.

```bash
# Consulte primeiro a sintaxe da versão instalada. Não adivinhe parâmetros.
medusa -M web-form -q
```

Para esta etapa, capture a requisição de login do DVWA local com as ferramentas do navegador/proxy ensinadas na aula, identifique campos e resposta de sucesso/erro e faça um teste manual de poucas tentativas com contas fictícias. Se o módulo `web-form` instalado suportar os parâmetros necessários, adapte o comando seguindo o help local e a documentação do projeto Medusa. Não publique cookies, tokens CSRF, credenciais, IP público ou valores de sessão.

**Critério de conclusão:** demonstrar como distinguir falha de autenticação de um erro de token/sessão e explicar por que automação mal configurada pode gerar falso positivo. O repositório não afirma que o formulário foi testado até você preencher as evidências.

## Wordlists didáticas

Os arquivos em `wordlists/` são deliberadamente curtos, sintéticos e inadequados para qualquer uso fora deste laboratório. Não acrescente senhas vazadas, pessoais ou de terceiros. A lista curta reduz o impacto e torna o teste reproduzível.

## Comparação das ferramentas vistas nas aulas

| Ferramenta | Papel discutido na trilha | Registro/reflexão sugerida |
|---|---|---|
| Medusa | Auditoria de autenticação de serviços por módulos | Módulos disponíveis, concorrência e limitações observadas |
| Hydra | Alternativa para testar autenticação em serviços suportados | Compare sintaxe e saída apenas em VM própria |
| Ncrack | Auditoria de autenticação em serviços de rede | Compare foco, suporte e controle de taxa |
| John the Ripper | Auditoria de hashes obtidos legalmente em laboratório | Diferencie tentativa online de auditoria offline de hash |
| Patator | Framework modular para testes de autenticação | Compare flexibilidade e complexidade de configuração |
| WPScan | Avaliação de segurança de WordPress autorizado | Use somente WordPress local ou escopo autorizado; não é substituto de Medusa |
| SMBclient | Cliente para validar exposição e acesso SMB | Não abra nem copie arquivos de terceiros |

A atividade principal não precisa rodar todas as ferramentas. Uma comparação conceitual, baseada nas aulas, já demonstra compreensão; se fizer testes adicionais, mantenha-os no laboratório e documente o escopo.

## Análise e recomendações de mitigação

### Controles técnicos

- Exigir senhas longas e únicas; usar gerenciador de senhas e MFA, especialmente para acesso remoto e contas privilegiadas.
- Bloquear ou limitar tentativas de autenticação com política proporcional, janela de tempo e tratamento cuidadoso para evitar negação de serviço por bloqueio abusivo.
- Aplicar atrasos progressivos e detecção de spraying por origem, por janela de tempo e por conjunto de contas, não apenas por conta individual.
- Eliminar contas padrão, desativar serviços não utilizados e restringir FTP/SMB a redes e hosts necessários. Preferir protocolos seguros e criptografados.
- Para aplicações web: proteção CSRF, mensagens de erro que não revelem se usuário existe, controles de taxa no servidor, MFA, monitoramento de sessão e alertas.
- Monitorar falhas e sucessos de login, origem, horário, serviço e volume; preservar logs e criar alertas para padrões distribuídos.
- Usar hashes de senha com algoritmo moderno de derivação e salt exclusivo, como Argon2id, scrypt, bcrypt ou PBKDF2 conforme plataforma/política; nunca armazenar senha em texto claro.

### Detecção e resposta

1. Correlacione falhas repetidas e sucessos após falhas em um mesmo usuário, origem ou grupo de contas.
2. Revise logs do serviço e do sistema para confirmar horário, protocolo e conta afetada.
3. Se for ambiente real, acione o processo formal de resposta a incidentes; preserve evidências e evite testes adicionais sem autorização.
4. Em caso de credencial exposta, redefina a senha, encerre sessões, revise MFA e procure reutilização em outros serviços.
5. Registre a causa raiz, o controle preventivo e como a correção será validada.

## Resultados — preencher após executar

Não invente resultados. Atualize `docs/registro-de-testes.md` com data, versões, escopo, observações e capturas anonimizadas. Exemplo de resumo:

> No cenário [FTP/SMB/DVWA], com [quantidade] tentativas controladas em VM isolada, observei [resultado agregado]. A evidência foi [log/captura sanitizada]. O teste não representa sistemas de produção. Recomendo [controle específico].

## Organização do repositório

```text
.
├── README.md
├── docs/
│   ├── perfil-dio.md
│   └── registro-de-testes.md
├── images/
│   └── README.md
├── scripts/
│   └── gerar-wordlists.sh
└── wordlists/
    ├── senhas-lab.txt
    └── usuarios-lab.txt
```

## Publicação no GitHub e entrega na DIO

1. Crie um repositório público com nome objetivo, por exemplo `laboratorio-medusa-kali-seguranca-senhas`.
2. Revise o README e substitua os campos de exemplo pelos seus resultados reais.
3. Adicione capturas próprias em `images/`, sem credenciais, cookies, tokens, dados pessoais ou IP público.
4. Faça o primeiro commit com uma mensagem clara, como `docs: documenta laboratório controlado de auditoria de senhas`.
5. Confira o repositório em uma janela anônima: README renderizado, links válidos e nenhum segredo publicado.
6. Na DIO, entregue o link do repositório e a breve descrição sugerida em `docs/perfil-dio.md`.

## Referências

- Medusa — documentação do projeto: https://jmk-foofus.github.io/medusa/medusa.html
- Medusa — módulo FTP: https://jmk-foofus.github.io/medusa/medusa-ftp.html
- Medusa — módulo SMBNT: https://jmk-foofus.github.io/medusa/medusa-smbnt.html
- Medusa — módulo HTTP: https://jmk-foofus.github.io/medusa/medusa-http.html
- Medusa — módulo Web Form: https://jmk-foofus.github.io/medusa/medusa-web-form.html
- OWASP — Authentication Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- OWASP — Credential Stuffing Prevention Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/Credential_Stuffing_Prevention_Cheat_Sheet.html
- DVWA — projeto: https://github.com/digininja/DVWA
- Kali Linux — documentação: https://www.kali.org/docs/
- VirtualBox — documentação de rede: https://www.virtualbox.org/manual/ch06.html

## Licença

Conteúdo documental sob licença MIT. Ferramentas e imagens de terceiros mantêm suas próprias licenças. Consulte `LICENSE`.
