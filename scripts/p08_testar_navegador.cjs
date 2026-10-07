// P08-MOD-006 | P08-FUN-015 | P08-TST-004/005: Chromium real, sem dependências npm.
// CDP por WebSocket local RFC6455. Servidor apenas para teste; Pages é estático.
const http=require('http'),fs=require('fs'),path=require('path'),crypto=require('crypto'),{spawn}=require('child_process'),assert=require('assert');
const root=path.resolve('site'),evidence=path.resolve('evidencias/p08');fs.mkdirSync(evidence,{recursive:true});
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
class CDP{
 constructor(socket){this.socket=socket;this.buffer=Buffer.alloc(0);this.id=0;this.pending=new Map();this.errors=[];this.fragment=[];socket.on('data',d=>this.parse(d));}
 parse(d){this.buffer=Buffer.concat([this.buffer,d]);while(this.buffer.length>=2){const b=this.buffer,op=b[0]&15;let n=b[1]&127,offset=2;if(n===126){if(b.length<4)return;n=b.readUInt16BE(2);offset=4;}else if(n===127){if(b.length<10)return;n=Number(b.readBigUInt64BE(2));offset=10;}if(b.length<offset+n)return;const msg=b.subarray(offset,offset+n);this.buffer=b.subarray(offset+n);if(op===9){this.sendFrame(msg,10);continue;}if(op===1||op===0){this.fragment.push(msg);if(b[0]&128){const data=JSON.parse(Buffer.concat(this.fragment).toString());this.fragment=[];if(data.id){const p=this.pending.get(data.id);if(p){clearTimeout(p.timeout);this.pending.delete(data.id);data.error?p.reject(Error(JSON.stringify(data.error))):p.resolve(data.result);}}else if(data.method==='Runtime.exceptionThrown')this.errors.push(data.params.exceptionDetails);}}}}
 sendFrame(data,op=1){const b=Buffer.from(data),mask=crypto.randomBytes(4);let h;if(b.length<126){h=Buffer.alloc(2);h[1]=128+b.length;}else if(b.length<65536){h=Buffer.alloc(4);h[1]=254;h.writeUInt16BE(b.length,2);}else{h=Buffer.alloc(10);h[1]=255;h.writeBigUInt64BE(BigInt(b.length),2);}h[0]=128+op;const payload=Buffer.from(b);for(let i=0;i<payload.length;i++)payload[i]^=mask[i%4];this.socket.write(Buffer.concat([h,mask,payload]));}
 call(method,params={}){return new Promise((resolve,reject)=>{const id=++this.id,timeout=setTimeout(()=>{this.pending.delete(id);reject(Error(`CDP timeout: ${method}`));},30000);this.pending.set(id,{resolve,reject,timeout});this.sendFrame(JSON.stringify({id,method,params}));});}
 static async connect(url){return new Promise((resolve,reject)=>{const req=http.request(url.replace('ws:','http:'),{headers:{Upgrade:'websocket',Connection:'Upgrade','Sec-WebSocket-Key':crypto.randomBytes(16).toString('base64'),'Sec-WebSocket-Version':'13'}});req.on('upgrade',(res,socket,head)=>{const c=new CDP(socket);if(head.length)c.parse(head);resolve(c);});req.on('error',reject);req.end();});}
}
let browser,server,cdp;const results=[];
async function ev(code){const r=await cdp.call('Runtime.evaluate',{expression:code,awaitPromise:true,returnByValue:true});if(r.exceptionDetails)throw Error(r.exceptionDetails.text+': '+(r.exceptionDetails.exception?.description||''));return r.result.value;}
async function until(code,timeout=30000){const t=Date.now();while(Date.now()-t<timeout){if(await ev(code))return;await sleep(100);}throw Error(`Condição não satisfeita: ${code}`);}
async function screenshot(name){const r=await cdp.call('Page.captureScreenshot',{format:'png',captureBeyondViewport:false});fs.writeFileSync(path.join(evidence,`${name}.png`),Buffer.from(r.data,'base64'));}
async function layout(label){await sleep(250);const result=await ev(`({document:document.documentElement.scrollWidth-document.documentElement.clientWidth,regions:[...document.querySelectorAll('.table-viewport,.chart-viewport,dialog[open]')].filter(e=>e.getBoundingClientRect().width>0).map(e=>({name:e.getAttribute('aria-label')||e.className,overflow:e.scrollWidth-e.clientWidth})),zoom:document.documentElement.style.zoom||'1'})`);assert(result.document<=2,`${label}: overflow do documento ${result.document}`);for(const r of result.regions)assert(r.overflow<=2,`${label}: overflow região ${r.name} ${r.overflow}`);results.push({teste:label,...result});}
async function click(selector){await ev(`document.querySelector(${JSON.stringify(selector)}).click()`);await sleep(350);}
(async()=>{
 try{
  server=http.createServer((req,res)=>{let url=decodeURIComponent(req.url.split('?')[0]);url=url.replace(/^\/akcit_c4_mini_projeto\/?/,'/');if(url==='/'||url==='')url='/index.html';const f=path.resolve(root,'.'+url);if(!f.startsWith(root+path.sep)||!fs.existsSync(f)){res.writeHead(404);res.end();return;}const types={'.html':'text/html','.js':'text/javascript','.css':'text/css','.json':'application/json','.csv':'text/csv'};res.setHeader('Content-Type',types[path.extname(f)]||'text/plain');fs.createReadStream(f).pipe(res);});await new Promise(r=>server.listen(8833,'127.0.0.1',r));
  const chrome=process.env.CHROME_PATH||(process.platform==='win32'?'C:/Program Files/Google/Chrome/Application/chrome.exe':'/usr/bin/google-chrome');
  const profile=path.resolve('tmp',`chrome-p08-${process.pid}`);browser=spawn(chrome,['--headless=new','--remote-debugging-port=9333',`--user-data-dir=${profile}`,'--no-first-run','--no-default-browser-check','--disable-background-networking','about:blank'],{windowsHide:true,stdio:'ignore'});
  let tabs;for(let i=0;i<100;i++){try{tabs=await(await fetch('http://127.0.0.1:9333/json')).json();if(tabs.length)break;}catch{}await sleep(100);}assert(tabs?.length,'Chromium não iniciou');cdp=await CDP.connect(tabs.find(t=>t.type==='page').webSocketDebuggerUrl);
  await cdp.call('Runtime.enable');await cdp.call('Page.enable');await cdp.call('Emulation.setDeviceMetricsOverride',{width:1920,height:1080,deviceScaleFactor:1,mobile:false});
  const target=process.argv[2]||'http://127.0.0.1:8833/akcit_c4_mini_projeto/';await cdp.call('Page.navigate',{url:target});await until(`document.body.dataset.ready==='true'`);await until(`document.getElementById('timeline').data?.length>0`);
  assert(await ev(`document.getElementById('stats').textContent.includes('Percentil 97,5 (P97,5)')`));
  results.push({teste:'Carga inicial',ms:await ev('Number(document.body.dataset.loadMs)'),url:target,generation:await ev('meta.assinatura')});
  await screenshot('desktop-visao-geral');await layout('1920x1080 · visão geral');
  await click('[data-view="admins"]');await until(`document.getElementById('ranking-chart').data?.length>0`);await screenshot('desktop-administradores');
  const bar=await ev(`(()=>{const p=document.querySelector('#ranking-chart .barlayer .point:last-child path');p.scrollIntoView({block:'center'});const r=p.getBoundingClientRect();return{x:r.x+r.width/2,y:r.y+r.height/2};})()`);
  await cdp.call('Input.dispatchMouseEvent',{type:'mousePressed',x:bar.x,y:bar.y,button:'left',clickCount:1});await cdp.call('Input.dispatchMouseEvent',{type:'mouseReleased',x:bar.x,y:bar.y,button:'left',clickCount:1});await until(`state.admin!==''`);results.push({teste:'Clique real na barra do ranking',estado:'aprovado'});
  await click('[data-admin]');await until(`state.admin!==''`);assert(await ev(`document.getElementById('admin-detail').textContent.includes('Soma reconciliada')`));
  await click('#admin-funds');await until(`document.querySelector('[data-entity]')!=null`);await click('[data-entity]');await until(`document.getElementById('entity-chart').data?.length>0`);await screenshot('desktop-fundo');
  results.push({teste:'Administrador → entidade → histórico',admin:await ev('state.admin'),entidade:await ev('state.entity')});
  await click('[data-view="portfolio"]');await until(`document.getElementById('portfolio-chart').data?.length>0`);await until(`document.getElementById('portfolio-evolution').data?.length>0`);await screenshot('desktop-carteira');await layout('1920x1080 · carteira/entidade');
  await click('#back');assert.equal(await ev('state.entity'),null);assert(await ev(`state.admin!==''`));
  await click('#clear');await until(`state.admin===''&&state.entity===null&&document.getElementById('status').textContent===''`);
  await click('[data-view="admins"]');await ev(`document.getElementById('ranking-mode').value='history';document.getElementById('ranking-mode').dispatchEvent(new Event('change'));`);await until(`document.getElementById('ranking-title').textContent.startsWith('Ranking histórico')`);assert(await ev(`document.getElementById('ranking-table').textContent.includes('fundos/classes distintos')`));results.push({teste:'Ranking histórico e vínculos distintos',estado:'aprovado'});
  await ev(`document.getElementById('ranking-mode').value='position';document.getElementById('ranking-mode').dispatchEvent(new Event('change'));`);
  const checks=await ev(`Promise.all(['estatisticas_por_competencia.csv','top25_administradores.csv','dados/carteira_'+state.month+'.csv','dicionario_analitico.csv'].map(async path=>({path,status:(await fetch(path,{method:'HEAD'})).status})))`);assert(checks.every(d=>d.status===200));results.push({teste:'Downloads CSV públicos',arquivos:checks});
  await click('[data-view="distribution"]');await until(`document.getElementById('boxplot').data?.length>0`);await screenshot('desktop-distribuicoes');
  for(const [width,height] of [[1920,1080],[1366,768],[768,1024],[390,844],[360,800]]){
   await cdp.call('Emulation.setDeviceMetricsOverride',{width,height,deviceScaleFactor:1,mobile:false});
   for(const view of ['overview','admins','funds','portfolio','distribution','method']){
    await click(`[data-view="${view}"]`);await layout(`${width}x${height} · ${view}`);
    if(width===360&&view==='admins')await screenshot('mobile-administradores');
    if(width===390&&view==='overview')await screenshot('mobile-visao-geral');
    if(width===390&&view==='method')await screenshot('mobile-metodologia');
   }
   if(width===360){
    assert(await ev(`getComputedStyle(document.querySelector('.mobile-navigation')).display!=='none'`));
    assert(await ev(`getComputedStyle(document.getElementById('start-filter')).display==='none'`));
    await click('#filter-more');assert(await ev(`document.getElementById('filter-more').getAttribute('aria-expanded')==='true'`));
    assert(await ev(`getComputedStyle(document.getElementById('start-filter')).display!=='none'`));await layout('360x800 · filtros expandidos');await click('#filter-more');
    await ev(`document.getElementById('mobile-view').value='portfolio';document.getElementById('mobile-view').dispatchEvent(new Event('change'));`);
    await until(`state.view==='portfolio'&&document.getElementById('portfolio-evolution').data?.length>0`);
    await ev(`document.getElementById('portfolio-level').value='Detalhe da carteira';document.getElementById('portfolio-level').dispatchEvent(new Event('change'));`);
    await until(`document.getElementById('portfolio-evolution').data?.length===10`);await layout('360x800 · dez categorias da carteira');
    await ev(`document.getElementById('portfolio-level').value='Ativo';document.getElementById('portfolio-level').dispatchEvent(new Event('change'));`);
    results.push({teste:'Navegação celular, filtros recolhíveis e dez categorias da carteira',estado:'aprovado'});
   }
  }
  await cdp.call('Emulation.setDeviceMetricsOverride',{width:1920,height:1080,deviceScaleFactor:1,mobile:false});await click('[data-view="overview"]');
  for(let i=0;i<10;i++)await click('#zoom-in');assert.equal(await ev('state.zoom'),2);await layout('1920x1080 · zoom 200%');await screenshot('desktop-zoom-200');
  for(let i=0;i<15;i++)await click('#zoom-out');assert.equal(await ev('state.zoom'),.5);await layout('1920x1080 · zoom 50%');await click('#zoom-reset');assert.equal(await ev('state.zoom'),1);
  await click('#overview .panel .expand');assert(await ev(`document.getElementById('expanded').open`));assert(await ev(`document.getElementById('close-expanded')===document.activeElement`));await layout('Modal expandido · 1920x1080');await screenshot('desktop-expandido');
  await cdp.call('Input.dispatchKeyEvent',{type:'keyDown',key:'Escape',code:'Escape',windowsVirtualKeyCode:27});await cdp.call('Input.dispatchKeyEvent',{type:'keyUp',key:'Escape',code:'Escape',windowsVirtualKeyCode:27});await until(`!document.getElementById('expanded').open`);assert(await ev(`document.activeElement.classList.contains('expand')`));
  results.push({teste:'Modal/Esc/foco e zoom proporcional',estado:'aprovado'});
  assert.equal(cdp.errors.length,0,JSON.stringify(cdp.errors));
  await cdp.call('Page.navigate',{url:new URL('relatorio_analise_fidc.html',target).href});await until(`document.querySelector('.report')!=null`);await layout('Relatório · 1920x1080');assert(await ev(`document.body.textContent.includes('Percentil 97,5 (P97,5)')`));
  fs.writeFileSync(path.join(evidence,'navegador.json'),JSON.stringify({estado:'concluido',gerado_em:new Date().toISOString(),browser:'Chromium headless',resultados:results,erros:cdp.errors},null,2));console.log(`${results.length} verificações de navegador aprovadas; screenshots em evidencias/p08.`);
 }catch(e){fs.writeFileSync(path.join(evidence,'navegador_falha.json'),JSON.stringify({erro:e.stack,resultados:results,erros:cdp?.errors},null,2));console.error(e);process.exitCode=1;}
 finally{cdp?.socket.destroy();browser?.kill();server?.close();}
})();
