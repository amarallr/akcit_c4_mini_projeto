/* P08-MOD-005 | P08-FUN-013 | P08-RF-012/013/014: navegação estática e gráficos.
 * Cálculos estatísticos vêm de R; filtros exploratórios não executam P06.
 */
'use strict';
const $ = id => document.getElementById(id);
const esc = s => String(s ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const num = n => n == null || !Number.isFinite(+n) ? 'Indisponível' : (+n).toLocaleString('pt-BR',{maximumFractionDigits:2});
const percent = n => n == null ? 'Indisponível' : `${num(n*100)}%`;
const millions = n => n == null ? 'Indisponível' : `${num(n/1e6)} mi`;
const monthLabel = d => `${d.slice(5,7)}/${d.slice(0,4)}`;
const dateAxis = dates => {
  const step=Math.max(1,Math.ceil(dates.length/7));
  const ticks=dates.filter((_,i)=>i%step===0||i===dates.length-1);
  return {type:'date',tickvals:ticks,ticktext:ticks.map(monthLabel),gridcolor:'#edf1f3',zeroline:false};
};
// Valores continuam integrais no gráfico; apenas os rótulos usam milhões.
function moneyAxis(values){
  const valid=values.filter(v=>v!=null&&Number.isFinite(+v)).map(Number);
  if(!valid.length)return {title:{text:'Milhões da unidade da fonte'}};
  const low=Math.min(0,...valid),high=Math.max(0,...valid),span=high-low||Math.max(Math.abs(high),1);
  const raw=span/5,unit=10**Math.floor(Math.log10(raw));
  const step=([1,2,2.5,5,10].find(x=>x*unit>=raw)||10)*unit;
  const ticks=[];for(let x=Math.floor(low/step)*step;x<=Math.ceil(high/step)*step+step*.01;x+=step)ticks.push(x);
  return {title:{text:'Milhões da unidade da fonte'},tickvals:ticks,ticktext:ticks.map(v=>num(v/1e6)),gridcolor:'#e8eef0',zerolinecolor:'#9eafb8',zerolinewidth:1};
}
const sum = xs => xs.length && xs.some(x=>x!=null) ? xs.reduce((s,x)=>s+(x==null?0:+x),0) : null;
const array = x => Array.isArray(x) ? x : x == null ? [] : [x];
const unpack = x => x.formato==='colunas' ? array(x.valores[0]).map((_,j)=>Object.fromEntries(x.colunas.map((c,i)=>[c,array(x.valores[i])[j]]))) : array(x.linhas).map(row=>Object.fromEntries(x.colunas.map((c,i)=>[c,row[i]])));
const state = {view:'overview',entity:null,admin:'',universe:'',month:'',start:'',end:'',preset:'all',limit:100,zoom:1};
const cache = new Map(); let meta,overview,current,rows=[],recs=[],ticket=0,expandedPanel,placeholder,focusReturn;
const charts = new Set();
const boardPanels={};
function compactChart(id){return $(id)?.closest('.dashboard-grid')!=null;}
function assembleDashboard(){
  document.body.classList.add('single-screen');
  const top=document.createElement('section');top.className='dashboard-top';
  top.setAttribute('aria-label','Indicadores e cobertura');
  top.append($('kpis'),$('context-summary'));
  const grid=document.createElement('section');grid.className='dashboard-grid';grid.id='dashboard-grid';
  grid.setAttribute('aria-label','Painel integrado de análises');
  const cards=[['overview','timeline','Evolução do PL'],['admins','ranking-chart','Administradores'],
    ['portfolio','portfolio-chart','Composição do ativo'],['distribution','boxplot','Distribuição do PL'],
    ['stats','stats','Estatísticas completas'],['funds','fund-table','Fundos e classes']];
  for(const [view,id,label] of cards){
    const panel=$(id).closest('.panel');panel.classList.add('dashboard-card');panel.dataset.card=view;
    boardPanels[view]=panel;
    const hint=document.createElement('p');hint.className='card-hint';
    hint.textContent=view==='admins'?'Prévia dos 5 maiores · expandir para top 25':view==='distribution'?'Prévia de 3 administradores · expandir para comparar':label+' · conteúdo completo em Expandir';
    panel.append(hint);grid.append(panel);
  }
  const support=document.createElement('section');support.id='dashboard-support';support.className='panel';support.hidden=true;
  support.innerHTML='<h2>Detalhes, dados e metodologia</h2>';
  support.append(document.querySelector('.pre-filter'));
  for(const el of document.querySelectorAll('.view')){el.hidden=false;support.append(el);}
  const evolution=$('portfolio-evolution-panel');evolution.classList.remove('panel');evolution.hidden=false;
  boardPanels.portfolio.append(evolution);
  const tools=document.createElement('div');tools.className='dashboard-tools';
  tools.innerHTML='<span>Resumo integrado · expanda qualquer bloco para explorar</span><button id="more-analysis">Dados, cobertura e metodologia</button><a href="relatorio_analise_fidc.html">Relatório analítico ↗</a>';
  document.querySelector('main').append(top,grid,tools,support);
}
async function json(path) { if(!cache.has(path)) cache.set(path,fetch(path).then(r=>{if(!r.ok)throw Error(`Falha HTTP ${r.status}: ${path}`);return r.json();}).catch(e=>{cache.delete(path);throw e;}));return cache.get(path); }
function table(id,headers,records) {
  const numeric=headers.map(h=>/^(PL|Valor|Soma|Participação|Posição$|Resultado$|P25|P97|Percentil|Potenciais|Fundos|Meses|Cobertos|%)/.test(h));
  $(id).innerHTML = records.length ? `<div class="table-viewport" tabindex="0" role="region" aria-label="${esc(headers.join(', '))}"><table><thead><tr>${headers.map((h,i)=>`<th scope="col"${numeric[i]?' class="numeric"':''}>${esc(h)}</th>`).join('')}</tr></thead><tbody>${records.map(row=>`<tr>${row.map((v,i)=>`<td data-label="${esc(headers[i])}"${numeric[i]?' class="numeric"':''}>${v}</td>`).join('')}</tr>`).join('')}</tbody></table></div>` : '<p class="notice">Sem registros para este recorte.</p>';
}
function options(id,items,value) { $(id).innerHTML=items.map(([v,l])=>`<option value="${esc(v)}">${esc(l)}</option>`).join('');$(id).value=value; }
function selectedRows() { return rows.filter(d=>d.tipo===state.universe&&(!state.admin||d.cnpj_admin===state.admin)&&(!state.entity||identity(d)===state.entity)); }
function identity(d){return `${d.cnpj}|${d.tipo}`;}
function selectedRank(){return array(current.ranking).filter(d=>d.tipo===state.universe);}
function within(d){return d.data>=state.start&&d.data<=state.end&& (state.preset!=='q4'||(+d.data.slice(5,7)>=10&&+d.data.slice(0,4)<new Date().getFullYear()&&+d.data.slice(0,4)>=new Date().getFullYear()-5));}
function chart(id,traces,title,height=430,extra={}) {
  if(!window.Plotly){$(id).innerHTML='<p>Gráfico indisponível; consulte a tabela equivalente abaixo.</p>';return;}
  charts.add(id);
  if(compactChart(id)){
    height=Math.max(160,Number(getComputedStyle(document.documentElement).getPropertyValue('--board-card-height').replace('px',''))-82||210);
    extra={...extra,margin:{...extra.margin,l:id==='ranking-chart'||id==='portfolio-chart'?140:62,r:65,t:12,b:id==='boxplot'?62:45}};
    title='';
    if(traces.length===1&&traces[0].orientation==='h'){
      const labels=traces[0].y;extra.yaxis={...extra.yaxis,tickvals:labels,ticktext:labels.map(v=>String(v).length>18?String(v).slice(0,17)+'…':v)};
    }
  }
  $(id).style.height=`${height}px`;
  if($(id).getBoundingClientRect().width<500){
    const horizontal=traces.some(t=>t.type==='bar'&&t.orientation==='h');
    extra={...extra,margin:{...extra.margin,l:horizontal?112:62,r:horizontal?72:18,t:compactChart(id)?12:80,b:extra.margin?.b||80}};
    if(horizontal&&traces.length===1){const labels=traces[0].y;extra.yaxis={...extra.yaxis,tickvals:labels,ticktext:labels.map(v=>String(v).length>16?String(v).slice(0,15)+'…':v)};}
  }
  return Plotly.react($(id),traces,{title:{text:title,font:{size:15}},height,autosize:true,separators:',.',
    margin:{l:68,r:24,t:68,b:66},paper_bgcolor:'#fff',plot_bgcolor:'#fff',font:{family:'system-ui',color:'#182f3d'},
    showlegend:false,...extra,xaxis:{automargin:true,gridcolor:'#edf1f3',...extra.xaxis},yaxis:{title:{text:meta.unidade},automargin:true,gridcolor:'#edf1f3',...extra.yaxis}},
    {responsive:true,displaylogo:false,scrollZoom:false,toImageButtonOptions:{format:'svg',filename:`fidc-${id}-${state.month}`}});
}
function statForSelection(wins=false){
  if(state.entity){const d=selectedRows()[0],v=d?.[wins?'pl_wins':'pl'];return {n_valido:v==null?0:1,n_ausente:v==null?1:0,cobertura:v==null?0:1,minimo:v,p2_5:v,p25:v,mediana:v,p75:v,p97_5:v,media:v,maximo:v,desvio_padrao:null,iqr:v==null?null:0,total:v,negativos:v!=null&&v<0?1:0,zeros:v===0?1:0,outliers:0,wins_alterados:d&&d.pl!==d.pl_wins?1:0};}
  const source=state.admin ? current[wins?'estatisticas_admin_wins':'estatisticas_admin'] : overview[wins?'estatisticas_wins':'estatisticas'];
  return array(source).find(d=>d.tipo===state.universe&&d.data===state.month&&(!state.admin||d.cnpj_admin===state.admin))||{};
}
function renderScope(){
  const admin=selectedRank().find(d=>d.cnpj_admin===state.admin)?.administrador||state.admin;
  const ent=rows.find(d=>identity(d)===state.entity);
  $('scope').textContent=`${state.universe} · competência ${state.month} · série ${state.start} a ${state.end} · ${state.preset==='q4'?'Histórico Q4 · ':''}${state.admin?`administrador: ${admin}`:'todos os administradores'}${ent?` · entidade: ${ent.DENOM_SOCIAL} (${ent.cnpj})`:''} · ${meta.unidade}. ${state.month.startsWith('2026')?'2026 incompleto.':''}`;
  $('breadcrumb').textContent=`Visão geral${state.admin?` → ${admin}`:''}${ent?` → ${ent.DENOM_SOCIAL}`:''}`;
  $('back').hidden=!state.admin&&!state.entity;
  if(expandedPanel)$('expanded-scope').textContent=$('scope').textContent;
}
function statsTable(){
  const s=statForSelection();
  const fields=[['n válido','n_valido'],['n ausente','n_ausente'],['Cobertura','cobertura'],['Mínimo','minimo'],['Percentil 2,5 (P2,5)','p2_5'],['Percentil 25 (P25)','p25'],['Mediana','mediana'],['Percentil 75 (P75)','p75'],['Percentil 97,5 (P97,5)','p97_5'],['Média','media'],['Máximo','maximo'],['Desvio padrão amostral (n ≥ 2)','desvio_padrao'],['IQR (P75 − P25)','iqr'],['Total do PL original','total'],['PL negativos','negativos'],['PL zero','zeros'],['Potenciais outliers · 1,5 × IQR','outliers'],['Valores alterados pela winsorização','wins_alterados']];
  table('stats',['Indicador','Valor observado'],fields.map(([l,k])=>[esc(l),k==='cobertura'?percent(s[k]):num(s[k])]));
  const data=selectedRows(),r=selectedRank();
  $('kpis').innerHTML=[['PL original',millions(s.total),'Soma das posições no recorte'],['Fundos/classes',new Set(data.map(identity)).size,'Identidades CNPJ + tipo'],['CNPJs distintos',new Set(data.map(d=>d.cnpj)).size,'Identificadores sem repetição'],['Percentil 97,5 (P97,5)',millions(s.p97_5),'Corte superior da distribuição original']].map(([l,v,note])=>`<div class="kpi"><span>${esc(l)}</span><strong>${esc(v)}</strong><small>${l.includes('PL')||l.includes('Percentil')?'milhões da unidade da fonte':'na competência'}</small><small class="kpi-note">${esc(note)}</small></div>`).join('');
  const allStats=array(overview.estatisticas).filter(d=>d.tipo===state.universe).sort((a,b)=>a.data.localeCompare(b.data));
  const observed=allStats.find(d=>d.data===state.month),previous=allStats.filter(d=>d.data<state.month).at(-1);
  const count=observed?.fundos_classes,priorCount=previous?.fundos_classes;
  const reduced=count!=null&&priorCount>0&&count/priorCount<.8;
  $('context-summary').classList.toggle('reduced',reduced);
  $('context-summary').innerHTML=reduced?`<strong>Cobertura reduzida nesta competência</strong><span>${num(count)} posições em ${esc(state.month)}, frente a ${num(priorCount)} em ${esc(previous.data)} (${percent(count/priorCount)} da quantidade anterior). A diferença de PL total não descreve, por si, mudança do mercado ou rentabilidade.</span>`:`<strong>Leitura do patrimônio informado</strong><span>PL é patrimônio líquido; ativo total é a base da composição da carteira. Os universos são separados e a população varia entre competências. Valores extremos e concentração exigem contexto, sem indicar irregularidade.</span>`;
  if(state.entity||state.admin){$('concentration').innerHTML='<p>Indicadores de concentração referem-se ao universo completo. Limpe o administrador/entidade para consultá-los.</p>';return;}
  const c=array(overview.concentracao).find(d=>d.tipo===state.universe&&d.data===state.month)||{};
  const unknown=data.filter(d=>!d.cnpj_admin);const coverage=s.total ? sum(r.map(d=>d.valor))/s.total : null;
  table('concentration',['Indicador','Valor'],[['Top 5',percent(c.top5)],['Top 10',percent(c.top10)],['Top 25',percent(c.top25)],['Demais administradores',percent(c.demais)],['HHI · escala 0–10.000',num(c.hhi)],['Cobertura do PL por administrador identificado',percent(coverage)],['Posições sem administrador validado',num(unknown.length)],['PL sem administrador validado',num(sum(unknown.map(d=>d.pl)))]]);
}
async function temporal(){
  let series;
  if(state.entity){const cnpj=state.entity.split('|')[0];const hist=unpack(await json(`dados/historico_${cnpj.slice(12,14)}.json`));series=hist.filter(d=>identity(d)===state.entity&&within(d)).map(d=>({...d,total:d.pl}));}
  else series=array(state.admin?overview.series_admin:overview.estatisticas).filter(d=>d.tipo===state.universe&&within(d)&&(!state.admin||d.cnpj_admin===state.admin));
  series.sort((a,b)=>a.data.localeCompare(b.data));
  const all=meta.competencias.filter(data=>within({data}));const byDate=new Map(series.map(d=>[d.data,d]));
  const totals=all.map(d=>byDate.get(d)?.total??null);
  chart('timeline',[{type:'scatter',mode:'lines+markers',x:all,y:totals,connectgaps:false,line:{color:'#00685f',width:2.5},marker:{size:5},hovertemplate:'%{x|%d/%m/%Y}<br>PL original: %{y:,.2f}<extra></extra>'}],`PL original · ${state.universe} · ${monthLabel(state.start)} a ${monthLabel(state.end)}`,430,{xaxis:dateAxis(all),yaxis:moneyAxis(totals)});
  table('timeline-table',['Competência','PL original','n válido','P97,5 original'],series.map(d=>[esc(d.data),num(d.total),num(d.n_valido),num(d.p97_5)]));
}
function historyRanking(vinculos=[]){
  const grouped=new Map();
  array(overview.ranking_mensal_wins).filter(d=>d.tipo===state.universe&&within(d)).forEach(d=>{
    let r=grouped.get(d.cnpj_admin);if(!r){r={...d,valor:null,meses:0,fundos_classes:null};grouped.set(d.cnpj_admin,r);}r.valor=sum([r.valor,d.valor]);r.meses++;r.administrador=d.administrador;
  });
  const rs=[...grouped.values()].sort((a,b)=>(b.valor??-Infinity)-(a.valor??-Infinity)||a.cnpj_admin.localeCompare(b.cnpj_admin));
  rs.forEach(d=>{d.fundos_classes=vinculos.filter(v=>v.tipo===state.universe&&v.cnpj_admin===d.cnpj_admin&&array(v.competencias).some(i=>within({data:meta.competencias[i]}))).length;});
  const denominator=sum(rs.map(d=>d.valor));rs.forEach((d,i)=>{d.posicao=i+1;d.denominador=denominator;d.participacao=denominator?d.valor/denominator:null;});return rs;
}
async function rank(){
  const history=$('ranking-mode').value==='history',full=history?historyRanking(array(await json('dados/vinculos_admin.json'))):selectedRank(),top=full.slice(0,25);
  const title=history?'Ranking histórico por soma de posições mensais winsorizadas':`Top 25 por PL na competência ${state.month}`;
  $('ranking-title').textContent=title;
  $('ranking-note').textContent=`${state.universe} · ${history?`${state.start} a ${state.end}${state.preset==='q4'?' · preset Q4 aplicado':''}. Soma de posições mensais; não é PL atual ou fluxo. Cobertura desigual pode influenciar o ranking.`:'PL original na mesma data para todas as entidades.'} Denominador integral antes do top25. Clique na barra ou no nome para abrir o administrador. O filtro de administrador não altera o universo do ranking.`;
  const preview=compactChart('ranking-chart')?top.slice(0,5):top;
  const reversed=[...preview].reverse(),max=Math.max(...preview.map(d=>d.valor??0),0),min=Math.min(...preview.map(d=>d.valor??0),0);
  await chart('ranking-chart',[{type:'bar',orientation:'h',x:reversed.map(d=>d.valor),y:reversed.map(d=>`${d.posicao} · ${(d.administrador||d.cnpj_admin).slice(0,26)}`),customdata:reversed.map(d=>d.cnpj_admin),
    text:reversed.map(d=>millions(d.valor)),textposition:'outside',cliponaxis:false,marker:{color:reversed.map(d=>d.valor<0?'#9b6000':'#00685f')},hovertemplate:'%{y}<br>%{x:,.2f}<extra></extra>'}],`${history?'Soma winsorizada':'PL original'} · ${state.universe} · ${history?`${state.start} a ${state.end}`:state.month}`,
    Math.max(400,top.length*43+120),{margin:{l:180,r:90,t:65,b:65},xaxis:{...moneyAxis(top.map(d=>d.valor)),range:[min<0?min*1.15:0,max*1.25||1]},yaxis:{automargin:false,title:{text:''}}});
  $('ranking-chart').removeAllListeners?.('plotly_click');$('ranking-chart').on?.('plotly_click',e=>openAdmin(e.points[0].customdata));
  table('ranking-table',history?['Posição','Administrador · CNPJ','Soma mensal winsorizada','Participação','Meses · fundos/classes']:['Posição','Administrador · CNPJ','PL original','Participação','Fundos/classes'],top.map(d=>[num(d.posicao),`<button data-admin="${esc(d.cnpj_admin)}">${esc(d.administrador||'Nome indisponível')}</button><small>${esc(d.cnpj_admin)}</small>`,num(d.valor),percent(d.participacao),history?`${num(d.meses)} meses<small>${num(d.fundos_classes)} fundos/classes distintos${d.fundos_classes==null?' · disponível no CSV histórico integral':''}</small>`:num(d.fundos_classes)]));
  const rest=full.slice(25);$('ranking-rest').textContent=`${full.length} administradores identificados. Denominador: ${num(full[0]?.denominador)}. Demais administradores: ${num(sum(rest.map(d=>d.valor))??0)} (${percent(sum(rest.map(d=>d.participacao))??0)}).`;
  const detail=selectedRank().find(d=>d.cnpj_admin===state.admin);
  if(!state.admin){$('admin-detail').innerHTML='<p>Selecione um administrador no ranking ou filtro global.</p>';return;}
  $('admin-detail').innerHTML=detail?`<p><strong>${esc(detail.administrador)}</strong> · CNPJ ${esc(state.admin)} · ${state.month}</p><p>PL original ${num(detail.valor)} · participação ${percent(detail.participacao)} · ${num(detail.fundos_classes)} fundos/classes. Soma reconciliada da lista: ${num(sum(rows.filter(d=>d.tipo===state.universe&&d.cnpj_admin===state.admin).map(d=>d.pl)))}.</p><button id="admin-funds">Abrir todos os fundos/classes</button>`:'<p class="notice">Administrador sem posição nesta competência.</p>';
  $('admin-funds')?.addEventListener('click',()=>show('funds',true));
}
function funds(){
  const query=$('fund-search').value.trim().toLocaleLowerCase('pt-BR');const all=selectedRows();
  const data=all.filter(d=>`${d.DENOM_SOCIAL} ${d.cnpj}`.toLocaleLowerCase('pt-BR').includes(query));
  const mode=$('fund-sort').value;
  data.sort((a,b)=>mode==='name'?String(a.DENOM_SOCIAL).localeCompare(String(b.DENOM_SOCIAL),'pt-BR'):mode==='cnpj'?a.cnpj.localeCompare(b.cnpj):(b.pl??-Infinity)-(a.pl??-Infinity)||a.cnpj.localeCompare(b.cnpj));
  const denominator=sum(all.map(d=>d.pl));
  $('fund-count').textContent=`${data.length} de ${all.length} fundos/classes do recorte. Soma do PL da lista completa: ${num(denominator)}. Prévia ${Math.min(state.limit,data.length)} registros; busca consulta todos. ${state.admin?'Participação no PL do administrador.':'Participação no PL do universo selecionado.'}`;
  table('fund-table',['Fundo/classe · CNPJ','PL original','Participação','Administrador'],data.slice(0,state.limit).map(d=>[`<button data-entity="${esc(identity(d))}">${esc(d.DENOM_SOCIAL||'Nome indisponível')}</button><small>${esc(d.cnpj)} · ${esc(d.tipo)}</small>`,num(d.pl),percent(denominator?d.pl/denominator:null),esc(d.nome_admin||'Não identificado')]));
  $('more-funds').hidden=state.limit>=data.length;
}
async function entityDetail(){
  if(!state.entity){$('entity-title').textContent='Selecione uma entidade na lista.';$('entity-table').innerHTML='';if(charts.has('entity-chart'))Plotly.purge('entity-chart');return;}
  const ent=rows.find(d=>identity(d)===state.entity),cnpj=state.entity.split('|')[0];
  const hist=unpack(await json(`dados/historico_${cnpj.slice(12,14)}.json`)).filter(d=>identity(d)===state.entity&&within(d)).sort((a,b)=>a.data.localeCompare(b.data));
  $('entity-title').textContent=`${ent?.DENOM_SOCIAL||cnpj} · ${cnpj} · ${state.universe}. Histórico integral da entidade no período; administrador registrado em cada data. ${state.admin?`Período sob administrador ${state.admin} destacado na tabela.`:''}`;
  const all=meta.competencias.filter(data=>within({data})),byDate=new Map(hist.map(d=>[d.data,d]));
  const values=all.map(d=>byDate.get(d)?.pl??null);
  chart('entity-chart',[{type:'scatter',mode:'lines+markers',x:all,y:values,connectgaps:false,line:{color:'#00685f'},hovertemplate:'%{x|%d/%m/%Y}<br>PL original: %{y:,.2f}<extra></extra>'}],`PL original da entidade · ${monthLabel(state.start)} a ${monthLabel(state.end)}`,430,{xaxis:dateAxis(all),yaxis:moneyAxis(values)});
  table('entity-table',['Competência','PL original','Administrador histórico','Sob administrador selecionado'],hist.map(d=>[esc(d.data),num(d.pl),`${esc(d.nome_admin||'Não identificado')}<small>${esc(d.cnpj_admin)}</small>`,state.admin?(d.cnpj_admin===state.admin?'Sim':'Não'):'Todos']));
}
function portfolio(){
  const data=selectedRows(),level=$('portfolio-level').value,mode=$('portfolio-mode').value;
  const chosen=new Set(data.map(identity));const rr=recs.filter(d=>d.tipo===state.universe&&chosen.has(identity(d)));
  const valid=new Set(rr.filter(d=>d.empilhavel).map(identity));
  const basis=mode==='stack'?data.filter(d=>valid.has(identity(d))):data;
  const maps=array(overview.mapa).filter(m=>m.nivel===level);
  const values=maps.map(m=>{const ok=basis.filter(d=>d[m.campo]!=null&&d[m.pai]!=null&&d[m.pai]>0);const v=sum(ok.map(d=>d[m.campo])),b=sum(ok.map(d=>d[m.pai]));return {...m,valor:v,base:b,percentual:b?v/b:null,cobertos:ok.length,negativos:ok.filter(d=>d[m.campo]<0).length};});
  $('portfolio-note').textContent=`${state.universe} · ${state.month} · ${level}. Base: ${level==='Ativo'?'ativo total':'total da carteira'}. Razão de somas de posições com valor e base positiva presentes. ${mode==='stack'?`${basis.length} de ${data.length} posições completas, não negativas e reconciliadas no ativo; somente nível Ativo permite barra de 100%.`:'Cobertura pode variar entre categorias; os percentuais não são forçados a 100%.'} Valores negativos preservados.`;
  if(mode==='stack'&&level!=='Ativo'){$('portfolio-chart').innerHTML='<p class="notice">A reconciliação do detalhe da carteira não foi confirmada; escolha Componentes do ativo para barras de 100%.</p>';}
  else if(mode==='stack')chart('portfolio-chart',values.map((v,i)=>({type:'bar',orientation:'h',name:v.rotulo,y:['Ativo reconciliado'],x:[v.percentual==null?null:v.percentual*100],text:[percent(v.percentual)],textposition:'inside',marker:{color:['#00685f','#397ea2','#945e00','#754b94'][i]}})),`Composição do ativo reconciliado · ${state.month}`,400,{barmode:'stack',showlegend:true,legend:{orientation:'h',y:-.4},xaxis:{title:{text:'% do ativo comparável'},range:[0,100]},yaxis:{title:{text:''}},margin:{l:30,r:30,t:70,b:120}});
  else chart('portfolio-chart',[{type:'bar',orientation:'h',y:values.map(v=>v.rotulo),x:values.map(v=>mode==='percent'?v.percentual==null?null:v.percentual*100:v.valor),text:values.map(v=>mode==='percent'?percent(v.percentual):millions(v.valor)),textposition:'outside',cliponaxis:false,marker:{color:'#00685f'}}],`${level} · ${state.universe} · ${state.month}`,Math.max(400,values.length*50+120),{margin:{l:175,r:90,t:70,b:65},xaxis:{...(mode==='percent'?{title:{text:'% da base comparável'}}:moneyAxis(values.map(v=>v.valor))),rangemode:'tozero'},yaxis:{title:{text:''},automargin:false}});
  table('portfolio-table',['Categoria','Valor observado','% da base comparável','Cobertos/elegíveis'],values.map(v=>[esc(v.rotulo),num(v.valor),percent(v.percentual),`${v.cobertos}/${data.length}${v.negativos?` · ${v.negativos} negativos`:''}`]));
  table('reconciliation',['Indicador','Resultado'],[['Posições com dados completos',num(rr.filter(d=>d.diferenca!=null).length)],['Posições reconciliadas',num(rr.filter(d=>d.reconciliado).length)],['Posições sem reconciliação',num(rr.filter(d=>d.diferenca!=null&&!d.reconciliado).length)],['Sem dados completos',num(rr.filter(d=>d.diferenca==null).length)],['Diferença somada · mesmas posições completas',num(sum(rr.map(d=>d.diferenca)))],['Ativo das posições completas',num(sum(rr.filter(d=>d.diferenca!=null).map(d=>d.ativo)))],['Tolerância absoluta por posição','0,05 unidade da fonte · 5 arredondamentos de centavos']]);
  $('portfolio-download').href=`dados/carteira_${state.month}.csv`;
  if(expandedPanel&&expandedPanel.contains($('portfolio-evolution')))portfolioEvolution().catch(e=>{$('portfolio-evolution-table').textContent=`Série indisponível: ${e.message}`;});
}
async function portfolioEvolution(){
  const level=$('portfolio-level').value,percentMode=$('portfolio-mode').value==='percent';let series;
  if(state.entity){
    const cnpj=state.entity.split('|')[0],hist=unpack(await json(`dados/historico_${cnpj.slice(12,14)}.json`)).filter(d=>identity(d)===state.entity&&within(d));
    series=hist.flatMap(d=>array(overview.mapa).filter(m=>m.nivel===level).map(m=>({data:d.data,categoria:m.rotulo,valor:d[m.campo],percentual:d[m.pai]>0&&d[m.campo]!=null?d[m.campo]/d[m.pai]:null,cobertos:d[m.campo]!=null&&d[m.pai]>0?1:0,elegiveis:1})));
  }else{const s=await json(`dados/carteira_serie_${state.universe.replaceAll(' ','_')}.json`);series=array(state.admin?s.administradores:s.universo).filter(d=>d.nivel===level&&within(d)&&(!state.admin||d.cnpj_admin===state.admin));}
  const dates=meta.competencias.filter(data=>within({data}));const categories=[...new Set(series.map(d=>d.categoria))];
  const colors=['#00685f','#397ea2','#945e00','#754b94','#b64d46','#376f48','#746742','#716784','#126d83','#8f5265'];
  chart('portfolio-evolution',categories.map((category,i)=>{const byDate=new Map(series.filter(d=>d.categoria===category).map(d=>[d.data,d]));return {type:'scatter',mode:'lines+markers',name:category,x:dates,y:dates.map(d=>{const row=byDate.get(d);return percentMode?row?.percentual==null?null:row.percentual*100:row?.valor??null;}),connectgaps:false,line:{color:colors[i]}};}),`Composição · ${state.universe} · ${state.start} a ${state.end}`,450,{showlegend:true,legend:{orientation:'h',y:-.3},margin:{l:70,r:20,t:70,b:105},xaxis:dateAxis(dates),yaxis:percentMode?{title:{text:'% da base comparável'}}:moneyAxis(series.map(d=>d.valor))});
  table('portfolio-evolution-table',['Competência · categoria','Valor','% da base','Cobertos/elegíveis'],series.map(d=>[`${esc(d.data)} · ${esc(d.categoria)}`,num(d.valor),percent(d.percentual),`${d.cobertos}/${d.elegiveis}`]));
}
function distribution(){
  const wins=$('distribution-mode').value==='wins',log=$('distribution-scale').value==='log';
  let groups;
  if(state.entity)groups=[{...statForSelection(wins),cnpj_admin:state.admin,administrador:rows.find(d=>identity(d)===state.entity)?.DENOM_SOCIAL}];
  else groups=array(current[wins?'estatisticas_admin_wins':'estatisticas_admin']).filter(d=>d.tipo===state.universe&&(!state.admin||d.cnpj_admin===state.admin));
  const rankOrder=selectedRank().map(d=>d.cnpj_admin);groups.sort((a,b)=>rankOrder.indexOf(a.cnpj_admin)-rankOrder.indexOf(b.cnpj_admin));
  const excluded=groups.filter(d=>log&&!(d.minimo>0)).length;groups=groups.filter(d=>!log||d.minimo>0).slice(0,compactChart('boxplot')?3:8);
  const traces=[],colors=['#00685f','#397ea2','#945e00','#754b94'];
  groups.forEach((s,i)=>{
    const name=state.entity?s.administrador:selectedRank().find(d=>d.cnpj_admin===s.cnpj_admin)?.administrador||s.cnpj_admin;
    const label=`${String(name||'Não identificado').slice(0,19)} · n=${s.n_valido}`;
    const vals=selectedRows().filter(d=>state.entity||d.cnpj_admin===s.cnpj_admin).map(d=>d[wins?'pl_wins':'pl']).filter(v=>v!=null);
    if(s.n_valido<4)traces.push({type:'scatter',mode:'markers',x:vals.map(()=>label),y:vals,marker:{color:colors[i%4]},name:label});
    else {traces.push({type:'box',x:[label],q1:[s.p25],median:[s.mediana],q3:[s.p75],lowerfence:[s.bigode_inferior],upperfence:[s.bigode_superior],boxpoints:false,name:label,marker:{color:colors[i%4]}});
      const out=vals.filter(v=>v<s.bigode_inferior||v>s.bigode_superior);if(out.length)traces.push({type:'scatter',mode:'markers',x:out.map(()=>label),y:out,marker:{color:colors[i%4],size:5},name:'Potenciais outliers'});}
  });
  $('distribution-note').textContent=`${state.month} · ${state.universe} · ${wins?'PL winsorizado; limites globais por universo/competência, calculados antes do filtro de administrador':'PL original por padrão'}. Até 8 administradores por tamanho; selecione outro pelo filtro global. ${log?`${excluded} grupos com zeros/negativos excluídos do gráfico logarítmico.`:''} n<4 exibido em pontos. Outliers são extremos estatísticos, sem remoção. Pontos não são amostrados. P97,5 na tabela continua sendo o original, mesmo na visão winsorizada.`;
  chart('boxplot',traces,`Distribuição ${wins?'winsorizada':'original'} · ${state.month}`,500,{yaxis:log?{type:'log',title:{text:meta.unidade}}:{...moneyAxis(groups.flatMap(s=>[s.minimo,s.maximo])),type:'linear'},xaxis:{tickangle:-25,automargin:true},margin:{l:68,r:20,t:70,b:145}});
  table('distribution-table',['Administrador · n','P25 / mediana / P75','Percentil 97,5 (P97,5) original','Potenciais outliers'],groups.map(s=>{
    const original=state.entity?statForSelection():array(current.estatisticas_admin).find(d=>d.tipo===state.universe&&d.cnpj_admin===s.cnpj_admin)||{};
    const name=state.entity?s.administrador:selectedRank().find(d=>d.cnpj_admin===s.cnpj_admin)?.administrador||s.cnpj_admin;
    return [`${esc(name)}<small>n=${s.n_valido}${s.n_valido<4?' · poucas observações':''}</small>`,`${num(s.p25)} / ${num(s.mediana)} / ${num(s.p75)}`,num(original.p97_5),num(s.outliers)];}));
}
function dictionary(){
  const q=$('dictionary-search').value.toLocaleLowerCase('pt-BR');
  $('dictionary').innerHTML=array(overview.dicionario).filter(d=>`${d.campo} ${d.descricao}`.toLocaleLowerCase('pt-BR').includes(q)).map(d=>`<details class="dictionary-item"><summary>${esc(d.tabela)} · ${esc(d.campo)} — ${esc(d.descricao||'Descrição não confirmada')}</summary><dl>${[['Origem',d.origem],['Tipo',d.tipo],['Unidade/escala',d.unidade],['Granularidade',d.granularidade],['Disponibilidade',d.disponibilidade],['Cobertura de não nulos',percent(d.cobertura)],['Nulos',d.nulos],['Transformação / fórmula',d.transformacao],['Domínio',d.dominio],['Páginas',d.paginas],['Fonte',d.fonte],['Consulta',d.consulta]].map(([l,v])=>`<dt>${esc(l)}</dt><dd>${esc(v||'Não confirmado')}</dd>`).join('')}</dl></details>`).join('');
}
async function render(){
  renderScope();statsTable();funds();
  await Promise.all([temporal(),rank(),entityDetail()]);portfolio();distribution();
  if(expandedPanel?.id==='dashboard-support')dictionary();
  requestAnimationFrame(resizeCharts);
}
function renderViewHeading(){
  const headings={
    overview:['PANORAMA DO UNIVERSO','O patrimônio informado em perspectiva','Leia a posição mensal junto com sua cobertura. Compare a série, a distribuição e a composição do mesmo universo.'],
    admins:['ADMINISTRADORES','Quem reúne o patrimônio informado','Compare todos na mesma competência. Abra um administrador para reconciliar seu total com as posições dos fundos/classes.'],
    funds:['FUNDOS E CLASSES','Da posição mensal à história da entidade','Pesquise a lista completa do recorte e selecione uma entidade. A tabela histórica preserva o administrador informado em cada data.'],
    portfolio:['COMPOSIÇÃO CONTÁBIL','Onde estão os ativos informados','Explore componentes do ativo e detalhes da carteira em níveis separados. Leia os percentuais junto com a base comparável e a reconciliação.'],
    distribution:['DISTRIBUIÇÕES','Além da média: dispersão e extremos','Cada observação é o PL de um fundo/classe na competência. A caixa resume quartis e mediana; pontos extremos permanecem visíveis.'],
    method:['FONTE E MÉTODO','Entenda o dado antes de interpretar','Consulte definições, cobertura, fórmulas e arquivos integrais. O relatório registra um recorte fixo, independente dos filtros do painel.']
  };
  const [kicker,title,description]=headings[state.view];
  $('view-kicker').textContent=kicker;$('view-title').textContent=title;$('view-description').textContent=description;
  $('mobile-view').value=state.view;
}
function urlState(){const p=new URLSearchParams();for(const k of ['view','universe','month','start','end','preset','admin','entity'])if(state[k])p.set(k,state[k]);history.replaceState(null,'',`#${p}`);}
async function show(view,open=false){state.view=view;renderViewHeading();document.querySelectorAll('[data-view]').forEach(el=>el.setAttribute('aria-current',el.dataset.view===view?'page':'false'));urlState();await render();if(open){const panel=view==='method'?$('dashboard-support'):boardPanels[view];expand(panel,view==='method'?$('more-analysis'):panel.querySelector('.expand'));}}
async function openAdmin(id){closeExpansion();state.admin=id;state.entity=null;$('administrator').value=id;await show('admins');expand($('admin-detail').closest('.panel'),boardPanels.admins.querySelector('.expand'));}
async function openEntity(id){closeExpansion();state.entity=id;const ent=rows.find(d=>identity(d)===id);if(ent?.cnpj_admin){state.admin=ent.cnpj_admin;$('administrator').value=state.admin;}await show('funds');expand($('entity-chart').closest('.panel'),boardPanels.funds.querySelector('.expand'));}
async function loadMonth(){
  const t=++ticket;$('status').textContent='Carregando competência…';$('retry').hidden=true;
  try {const data=await json(`dados/${state.month}.json`);if(t!==ticket)return;current=data;rows=unpack(data.posicoes);recs=unpack(data.reconciliacao);
    const r=selectedRank();options('administrator',[['','Todos'],...r.map(d=>[d.cnpj_admin,`${d.administrador||d.cnpj_admin} · ${d.cnpj_admin}`])],state.admin);
    if(state.admin&&!r.some(d=>d.cnpj_admin===state.admin)){state.admin='';state.entity=null;$('administrator').value='';}
    if(state.entity&&!rows.some(d=>identity(d)===state.entity)){state.entity=null;}
    $('status').textContent='';await show(state.view);
  }catch(e){$('status').textContent=`Não foi possível carregar: ${e.message}`;$('retry').hidden=false;}
}
function fitDashboard(){
  const grid=$('dashboard-grid');if(!grid)return;
  const width=grid.getBoundingClientRect().width;
  let height=300;
  if(width>=1150&&state.zoom===1){
    const spare=window.innerHeight-grid.getBoundingClientRect().top-document.querySelector('.dashboard-tools').offsetHeight-document.querySelector('footer').offsetHeight-30;
    height=Math.min(330,Math.max(210,Math.floor((spare-12)/2)));
  }
  const value=height+'px';if(document.documentElement.style.getPropertyValue('--board-card-height')!==value)document.documentElement.style.setProperty('--board-card-height',value);
}
function resizeCharts(){fitDashboard();if(!window.Plotly)return;for(const id of charts){const el=$(id);if(el?.getBoundingClientRect().width>0&&el.data){if(compactChart(id)){const height=Math.max(160,parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--board-card-height'))-82);el.style.height=height+'px';if(el.layout?.height!==height)Plotly.relayout(el,{height});}Plotly.Plots.resize(el);}}}
function zoom(delta,reset=false){state.zoom=reset?1:Math.min(2,Math.max(.5,Math.round((state.zoom+delta)*10)/10));document.documentElement.style.zoom=state.zoom;$('zoom-level').textContent=`${Math.round(state.zoom*100)}%`;setTimeout(resizeCharts,100);}
function expand(panel,button){if(expandedPanel===panel)return;if(expandedPanel)closeExpansion();expandedPanel=panel;focusReturn=button;placeholder=document.createComment('panel');panel.before(placeholder);panel.hidden=false;$('expanded-title').textContent=panel.querySelector('h2').textContent;$('expanded-scope').textContent=$('scope').textContent;$('expanded-body').append(panel);$('expanded').showModal();$('close-expanded').focus();render().catch(e=>{$('status').textContent=e.message;});if(panel.contains($('portfolio-evolution')))portfolioEvolution().catch(e=>{$('portfolio-evolution-table').textContent=e.message;});setTimeout(resizeCharts,80);}
function closeExpansion(){if(!expandedPanel)return;const panel=expandedPanel;placeholder.replaceWith(panel);if(panel.id==='dashboard-support')panel.hidden=true;expandedPanel=null;$('expanded').close();focusReturn?.focus();render().catch(e=>{$('status').textContent=e.message;});setTimeout(resizeCharts,80);}
function setup(){
  assembleDashboard();
  $('more-analysis').onclick=()=>expand($('dashboard-support'),$('more-analysis'));
  $('mobile-view').onchange=()=>show($('mobile-view').value,true);
  $('filter-more').onclick=()=>{
    const open=document.querySelector('.filters').classList.toggle('advanced-open');
    $('filter-more').setAttribute('aria-expanded',String(open));
    $('filter-more').textContent=open?'Recolher filtros −':'Série e administrador +';
  };
  document.querySelectorAll('.panel').forEach(panel=>{const b=document.createElement('button');b.textContent='Expandir';b.className='expand';b.setAttribute('aria-label',`Expandir ${panel.querySelector('h2').textContent}`);b.addEventListener('click',()=>expand(panel,b));panel.prepend(b);});
  $('close-expanded').addEventListener('click',closeExpansion);$('expanded').addEventListener('cancel',e=>{e.preventDefault();closeExpansion();});
  $('zoom-in').onclick=()=>zoom(.1);$('zoom-out').onclick=()=>zoom(-.1);$('zoom-reset').onclick=()=>zoom(0,true);
  document.querySelectorAll('[data-view]').forEach(b=>b.onclick=()=>show(b.dataset.view,true));
  document.addEventListener('click',e=>{const a=e.target.closest('[data-admin]'),f=e.target.closest('[data-entity]');if(a)openAdmin(a.dataset.admin);if(f)openEntity(f.dataset.entity);});
  $('month').onchange=()=>{state.month=$('month').value;state.entity=null;loadMonth();};
  $('universe').onchange=()=>{state.universe=$('universe').value;state.admin='';state.entity=null;loadMonth();};
  $('administrator').onchange=()=>{state.admin=$('administrator').value;state.entity=null;show(state.view);};
  for(const id of ['start','end','preset'])$(id).onchange=()=>{state[id]=$(id).value;if(state.start>state.end){state.end=state.start;$('end').value=state.end;}show(state.view);};
  $('clear').onclick=()=>{closeExpansion();state.admin='';state.entity=null;state.preset='all';state.start=meta.competencias[0];state.end=meta.competencias.at(-1);state.month=state.end;state.limit=100;$('fund-search').value='';for(const id of ['start','end','preset'])$(id).value=state[id];$('month').value=state.month;loadMonth();};
  $('back').onclick=()=>{closeExpansion();if(state.entity){state.entity=null;show('funds');}else{state.admin='';$('administrator').value='';show('admins');}};
  $('retry').onclick=loadMonth;
  $('fund-search').oninput=()=>{state.limit=100;funds();};$('fund-sort').onchange=funds;$('more-funds').onclick=()=>{state.limit+=100;funds();};
  $('ranking-mode').onchange=rank;for(const id of ['portfolio-level','portfolio-mode'])$(id).onchange=portfolio;for(const id of ['distribution-mode','distribution-scale'])$(id).onchange=distribution;
  $('dictionary-search').oninput=dictionary;
  let timeout;new ResizeObserver(()=>{clearTimeout(timeout);timeout=setTimeout(resizeCharts,120);}).observe(document.querySelector('main'));
}
async function init(){
  const started=performance.now();
  try {meta=await json('manifesto_publico.json');overview=await json('visao_geral.json');
    const p=new URLSearchParams(location.hash.slice(1));state.universe=meta.universos.includes(p.get('universe'))?p.get('universe'):meta.universos.includes('Classe')?'Classe':meta.universos[0];
    state.month=meta.competencias.includes(p.get('month'))?p.get('month'):meta.competencias.at(-1);
    state.start=meta.competencias.includes(p.get('start'))?p.get('start'):meta.competencias[0];state.end=meta.competencias.includes(p.get('end'))?p.get('end'):meta.competencias.at(-1);
    state.preset=p.get('preset')==='q4'?'q4':'all';state.admin=p.get('admin')||'';state.entity=p.get('entity');state.view=['overview','admins','funds','portfolio','distribution','method'].includes(p.get('view'))?p.get('view'):'overview';
    options('universe',meta.universos.map(v=>[v,v]),state.universe);for(const id of ['month','start','end'])options(id,meta.competencias.map(v=>[v,monthLabel(v)]),state[id]);$('preset').value=state.preset;
    $('pre-filter').textContent=`${meta.expressao_filtros}. ${meta.pre_consolidacao}. ${meta.cotistas}`;
    $('generation').textContent=`Geração ${meta.gerado_em} · schema ${meta.schema} · assinatura ${meta.assinatura}. ${num(meta.bytes_publicados/1024**2)} MiB publicados; geração R ${num(meta.segundos_geracao)} segundos.`;
    $('version').textContent=`${meta.schema} · ${meta.assinatura.slice(0,12)}`;
    json('versao_publicacao.json').then(v=>{$('version').textContent+=` · commit ${v.sha.slice(0,12)}`;document.body.dataset.commit=v.sha;}).catch(()=>{});
    const files=[['estatisticas_por_competencia.csv','Estatísticas completas'],['estatisticas_por_administrador.csv','Estatísticas por administrador'],['ranking_por_competencia.csv','Ranking por competência'],['ranking_historico_completo.csv','Ranking histórico'],['posicoes_fundos_classes.csv','Posições de fundos/classes'],['dicionario_analitico.csv','Dicionário analítico'],['mapa_carteira.csv','Mapa da carteira'],['reconciliacao_carteira.csv','Reconciliação'],['carteira_por_administrador.csv','Carteira agregada'],['manifesto_publico.json','Manifesto e hashes'],['relatorio_analise_fidc.md','Relatório Markdown']];
    $('downloads').innerHTML=`<div class="download-row">${files.map(([f,n])=>`<a href="${f}" download>${esc(n)}</a>`).join('')}</div><p>Carteira longa completa: cada competência tem CSV próprio na página Carteira. Valores integrais sem arredondamento de apresentação. Identificadores devem ser importados como texto.</p>`;
    $('data-vintage').textContent='Série '+monthLabel(meta.competencias[0])+' a '+monthLabel(meta.competencias.at(-1))+' · '+meta.competencias.length+' competências';
    setup();await loadMonth();document.body.dataset.loadMs=Math.round(performance.now()-started);document.body.dataset.ready='true';
  }catch(e){$('status').textContent=`Falha ao iniciar: ${e.message}. Recarregue para tentar novamente.`;}
}
init();
