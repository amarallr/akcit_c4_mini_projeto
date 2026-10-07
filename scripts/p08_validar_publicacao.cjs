// P08-MOD-006 | P08-FUN-014 | P08-TST-004: build estático íntegro antes de publicar.
const fs=require('fs'),path=require('path'),crypto=require('crypto'),assert=require('assert');
const root=path.resolve(process.argv[2]||'site');
const read=n=>fs.readFileSync(path.join(root,n),'utf8');
const meta=JSON.parse(read('manifesto_publico.json'));
assert.equal(meta.schema,'p08-v2026-10-07');
assert(meta.competencias.length>0&&meta.assinatura.length===64);
for(const f of meta.arquivos){const p=path.resolve(root,f.arquivo);assert(p.startsWith(root+path.sep));const bytes=fs.readFileSync(p);assert.equal(bytes.length,f.bytes,f.arquivo);assert.equal(crypto.createHash('sha256').update(bytes).digest('hex'),f.sha256.toLowerCase(),f.arquivo);}
for(const page of ['index.html','relatorio_analise_fidc.html']){
 const html=read(page);assert(html.includes('lang="pt-BR"'));assert(html.includes('P97,5')||html.includes('Percentil 97,5'));
 for(const match of html.matchAll(/(?:href|src)="([^"]+)"/g)){
  const target=match[1];if(/^(https?:|#|data:)/.test(target))continue;
  assert(!target.startsWith('/'),`Path absoluto fora do subdiretório: ${target}`);
  assert(fs.existsSync(path.join(root,target.split('#')[0])),`${page}: link ausente ${target}`);
 }
}
const all=JSON.parse(read('visao_geral.json'));
function csvRecords(text){let rows=[],row=[],cell='',quoted=false;for(let i=0;i<text.length;i++){const c=text[i];if(c==='"'){if(quoted&&text[i+1]==='"'){cell+='"';i++;}else quoted=!quoted;}else if(c===','&&!quoted){row.push(cell);cell='';}else if((c==='\n'||c==='\r')&&!quoted){if(c==='\r'&&text[i+1]==='\n')i++;row.push(cell);cell='';if(row.some(Boolean))rows.push(row);row=[];}else cell+=c;}if(cell||row.length){row.push(cell);rows.push(row);}const headers=rows.shift();return rows.map(r=>Object.fromEntries(headers.map((h,i)=>[h,r[i]])));}
const stats=csvRecords(read('estatisticas_por_competencia.csv'));
for(const s of all.estatisticas){const c=stats.find(d=>d.tipo===s.tipo&&d.data===s.data);assert(c);for(const field of ['n_valido','n_ausente','total','p97_5','mediana','media','p25','p75']){if(s[field]==null)assert.equal(c[field],'');else assert(Math.abs(Number(c[field])-s[field])<=Math.max(1,Math.abs(s[field]))*1e-12,`${field}: CSV/JSON divergentes`);}}
const ranking=csvRecords(read('top25_administradores.csv'));assert(ranking.every(d=>'pl_soma_periodo' in d&&'percentual_pl_total' in d&&'quantidade_fundos' in d));
const report=read('relatorio_analise_fidc.md');for(const type of meta.universos){const s=all.estatisticas.filter(d=>d.tipo===type).at(-1);assert(report.includes(Number(s.p97_5).toLocaleString('pt-BR',{minimumFractionDigits:2,maximumFractionDigits:2})),`P97,5 do relatório: ${type}`);}
assert(all.estatisticas.every(d=>'p97_5' in d));
assert(all.series_admin.every(d=>'p97_5' in d));
for(const month of meta.competencias){const d=JSON.parse(read(`dados/${month}.json`));assert(d.posicoes.colunas.includes('pl'));const values=d.posicoes.valores[d.posicoes.colunas.indexOf('data')];assert((Array.isArray(values)?values:[values]).every(data=>data===month));}
for(const month of meta.competencias){
 const d=JSON.parse(read(`dados/cotistas_${month}.json`));
 for(const name of ['series','perfil']){
  const t=d[name],index=t.colunas.indexOf('data');assert(index>=0);
  assert(t.valores[index].every(v=>v===month));
  for(let i=0;i<t.colunas.length;i++)if(t.colunas[i].startsWith('TAB_X_NR_COTST'))assert(t.valores[i].every(v=>v===null||(Number.isInteger(v)&&v>=0)));
 }
 assert(d.series.colunas.includes('TAB_X_NR_COTST'));
 assert.equal(d.perfil.colunas.filter(c=>c.startsWith('TAB_X_NR_COTST_')).length,32);
}
for(const file of ['cotistas_tab_x_1.csv','cotistas_tab_x_1_1.csv'])assert(fs.existsSync(path.join(root,file)));
console.log(`Build válido: ${meta.arquivos.length} hashes, ${meta.competencias.length} partições mensais, HTML/links, P97,5 e paths relativos.`);
