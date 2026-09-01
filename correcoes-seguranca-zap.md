# Correções de segurança — relatório ZAP (01/09/2026)

Resultado do relatório: **0 vulnerabilidades altas**, 6 médias, 5 baixas,
5 informativas. Boa base para um app desse porte — nada crítico. Abaixo,
o que foi corrigido, o que ainda precisa de um passo manual seu, e o que
só se resolve trocando de hospedagem.

---

## ✅ Corrigido agora (v4.7)

- **CSP (Content-Security-Policy)** — adicionada via `<meta>` no
  `<head>`. Restringe de onde o app pode carregar scripts (só o próprio
  site + cdnjs.cloudflare.com + cdn.jsdelivr.net), estilos, fontes e
  imagens. Mitiga XSS e injeção de conteúdo malicioso.
- **Proteção contra clickjacking (via JavaScript)** — se alguém tentar
  carregar o app dentro de um `<iframe>` em outro site, ele força sair do
  frame automaticamente.
- **`robots.txt` bloqueando indexação** — o app é uma ferramenta privada
  com login, não faz sentido aparecer no Google. Antes, o GitHub Pages
  gerava um `robots.txt`/`sitemap.xml` próprio (via Jekyll) com um
  comportamento estranho de CSP que o relatório pegou — isso some agora.
- **`.nojekyll`** — desativa o processamento automático do GitHub Pages
  (Jekyll), que não usamos e que estava gerando esses arquivos extras.

## ⚠️ Requer 1 passo manual seu (Sub Resource Integrity)

O relatório pediu pra adicionar um atributo `integrity` nos scripts
externos (jsPDF e Supabase), que trava o navegador pra só aceitar o
arquivo exato que a gente espera, e recusar automaticamente se o CDN for
comprometido e servir outra coisa no lugar.

**Por que não coloquei esse valor sozinho:** esse "hash de segurança"
precisa ser calculado byte a byte, exatamente igual ao arquivo real. Se
eu colocar um valor levemente errado (o que pode acontecer se eu calcular
a partir de uma cópia do texto, em vez do arquivo binário original), o
navegador **bloqueia completamente** o carregamento do script — e isso
quebraria a geração de PDF ou o próprio login em produção. Prefiro te
pedir esse passo, que leva 1 minuto, a arriscar isso.

**Como fazer:**
1. Acesse [srihash.org](https://www.srihash.org/)
2. Cole esta URL e gere o hash: `https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js`
3. Copie o trecho `integrity="sha384-..."` gerado
4. Repita para: `https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.js`
5. Me manda os dois valores (ou os dois `<script>` completos que o site
   gerar) que eu coloco no `index.html` pra você.

---

## 🚫 Não corrigível no GitHub Pages (exige trocar de hospedagem)

Estas exigem **cabeçalhos HTTP de verdade**, configurados pelo servidor —
e o GitHub Pages **não permite configurar cabeçalhos customizados** (não
tem um arquivo tipo `_headers` como Netlify/Cloudflare Pages têm). Não é
um problema do código, é uma limitação da hospedagem gratuita atual:

| Achado do relatório | O que seria a correção |
|---|---|
| CSP Header Not Set | Cabeçalho `Content-Security-Policy` real (o meta tag que adicionei cobre parte disso, mas não tudo — ex: `frame-ancestors` só funciona via header de verdade) |
| Missing Anti-clickjacking Header | Cabeçalho `X-Frame-Options` (mitiguei via JavaScript, mas não é tão robusto quanto o header) |
| Cross-Domain Misconfiguration (CORS) | Cabeçalho `Access-Control-Allow-Origin` mais restritivo nos arquivos estáticos — risco baixo aqui, já que são só ícone/manifest/robots.txt, nada sensível |
| Cross-Origin-Embedder-Policy Missing | Cabeçalho `Cross-Origin-Embedder-Policy` |
| Cross-Origin-Opener-Policy Missing | Cabeçalho `Cross-Origin-Opener-Policy` |
| Permissions Policy Header Not Set | Cabeçalho `Permissions-Policy` |
| X-Content-Type-Options Header Missing | Cabeçalho `X-Content-Type-Options: nosniff` |

**Se algum dia quiser fechar essas também:** migrar a hospedagem pra
**Cloudflare Pages** ou **Netlify** (ambos gratuitos) resolveria todas de
uma vez, porque os dois permitem configurar cabeçalhos customizados via
um arquivo simples (`_headers`). Isso não muda nada pro usuário final —
só o processo de publicar o site muda um pouco. Posso te ajudar com essa
migração se quiser, é um processo separado.

## ℹ️ Informativos (sem ação necessária)

- **Cross-Domain JavaScript Source File Inclusion** — inerente à
  arquitetura (carregamos jsPDF e o cliente do Supabase de CDNs, já que o
  GitHub Pages não hospeda pacotes npm). Mitigado pelo SRI (seção acima).
- **Cache-Control / Retrieved from Cache** — o HTML principal não carrega
  nenhum dado sensível embutido (os dados reais vêm do Supabase, depois
  do login, nunca ficam gravados no HTML estático), então o cache do
  GitHub Pages nesses arquivos não expõe informação de ninguém.
