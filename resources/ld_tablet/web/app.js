const tablet=document.getElementById('tablet');
const closeBtn=document.getElementById('close');
const timeEl=document.getElementById('time');
const view=document.getElementById('view');
const topbar=document.getElementById('topbar');
const pageTitle=document.getElementById('page-title');
const backBtn=document.getElementById('back');
const homeBtn=document.getElementById('home');
let taxiData={orders:[],drivers:[],dispatchers:[],stats:{openOrders:0,drivers:0,dispatchers:0,maxDispatchers:2}};
let historyStack=[];let currentPage='home';
function tile(page,icon,label){return '<button class="tile" data-page="'+page+'"><b>'+icon+'</b>'+label+'</button>';}
function card(title,value){return '<div class="card"><small>'+title+'</small><strong>'+value+'</strong></div>';}
function row(text,status){return '<div class="row"><span>'+text+'</span><span class="pill">'+status+'</span></div>';}
function info(text){return '<div class="card"><small>Info</small><strong style="font-size:20px">'+text+'</strong></div>';}
function activeDrivers(){return (taxiData.drivers||[]).filter(function(d){return d.status!=='offline'&&d.status!=='pause';}).length;}
function waitingOrders(){return (taxiData.orders||[]).filter(function(o){return o.status==='new'||o.status==='dispatch'||o.status==='returned';}).length;}
function orderButtons(o){let id=o.id;let html='';if(o.status==='dispatch'||o.status==='returned'||o.status==='new'){html+='<button data-order-action="accept" data-order-id="'+id+'">Annehmen</button>';}if(o.status==='accepted'){html+='<button data-order-action="arrive" data-order-id="'+id+'">Vor Ort</button>';}if(o.status==='arrived'){html+='<button data-order-action="start" data-order-id="'+id+'">Starten</button>';}if(o.status==='started'){html+='<button data-order-action="complete" data-order-id="'+id+'">Abschließen</button>';}if(o.status!=='completed'){html+='<button class="danger" data-order-action="return" data-order-id="'+id+'">Zurück</button>';}return '<div class="actions">'+html+'</div>';}
function orderRow(o){let title='#'+o.id+' · '+(o.pickup_label||'Abholort unbekannt');let sub=(o.customer_name||'Kunde unbekannt')+' · '+(o.assigned_driver_name||'nicht vergeben');return '<div class="row"><div class="row-main"><span>'+title+'</span><small>'+sub+'</small></div><div><span class="pill">'+(o.status||'offen')+'</span>'+orderButtons(o)+'</div></div>';}
const pages={
home:{title:'Home',render:function(){return '<h1>Los Santos Taxi</h1><p class="subtitle">TaxiOS Unternehmenssystem</p><div class="grid">'+tile('dashboard','▦','Dashboard')+tile('orders','☰','Aufträge')+tile('drivers','◎','Fahrer')+tile('dispatch','◉','Leitstelle')+tile('ratings','★','Bewertungen')+tile('blackboard','!','Schwarzes Brett')+tile('profile','☻','Profil')+tile('settings','⚙','Einstellungen')+'</div>'; }},
dashboard:{title:'Dashboard',render:function(){return '<div class="cards">'+card('Offene Aufträge',taxiData.stats.openOrders||0)+card('Fahrer gesamt',taxiData.stats.drivers||0)+card('Leitstellen',(taxiData.stats.dispatchers||0)+' / '+(taxiData.stats.maxDispatchers||2))+card('Aktive Fahrer',activeDrivers())+card('Wartende Fahrten',waitingOrders())+card('System','Live')+'</div>'; }},
orders:{title:'Aufträge',render:function(){let orders=taxiData.orders||[];if(!orders.length)return '<div class="list">'+row('Keine offenen Aufträge','bereit')+'</div>';return '<div class="list">'+orders.map(orderRow).join('')+'</div>'; }},
drivers:{title:'Fahrer',render:function(){let drivers=taxiData.drivers||[];if(!drivers.length)return '<div class="list">'+row('Keine Fahrer gefunden','offline')+'</div>';return '<div class="list">'+drivers.map(function(d){return row(d.name||d.identifier||'Unbekannt',d.status||'offline');}).join('')+'</div>'; }},
dispatch:{title:'Leitstelle',render:function(){let ds=taxiData.dispatchers||[];let ls1=ds.find(function(d){return Number(d.slot_number)===1;});let ls2=ds.find(function(d){return Number(d.slot_number)===2;});return '<div class="cards">'+card('LS1',ls1?ls1.name:'frei')+card('LS2',ls2?ls2.name:'frei')+card('Wartende Aufträge',taxiData.stats.openOrders||0)+'</div>'; }},
ratings:{title:'Bewertungen',render:function(){return info('Noch keine Bewertungen verbunden.');}},blackboard:{title:'Schwarzes Brett',render:function(){return info('Beiträge folgen im nächsten Modul.');}},profile:{title:'Profil',render:function(){return info('Profil wird mit ld_taxi verbunden.');}},settings:{title:'Einstellungen',render:function(){return info('Transparenz und Größe folgen als eigenes Modul.');}}
};
function openPage(page,push){if(push===undefined)push=true;let route=pages[page]||pages.home;if(push&&currentPage!==page)historyStack.push(currentPage);currentPage=page;pageTitle.textContent=route.title;topbar.classList.toggle('hidden',page==='home');view.innerHTML=route.render();bindUi();}
function bindUi(){document.querySelectorAll('[data-page]').forEach(function(btn){btn.addEventListener('click',function(){openPage(btn.dataset.page);});});document.querySelectorAll('[data-order-action]').forEach(function(btn){btn.addEventListener('click',function(){handleOrderAction(btn.dataset.orderAction,btn.dataset.orderId);});});}
function post(name,payload){fetch('https://'+GetParentResourceName()+'/'+name,{method:'POST',body:JSON.stringify(payload||{})});}
function closeTablet(){post('closeTablet');}
function refreshTaxiData(){post('refreshTaxiData');}
function handleOrderAction(action,orderId){let payload={action:action,orderId:Number(orderId)};if(action==='return'){payload.reason='Vom Tablet zurückgegeben';}if(action==='complete'){payload.distance=Number(prompt('Gefahrene Kilometer?', '1')||1);payload.charged=Number(prompt('Gestellte Rechnung?', '5')||5);}post('orderAction',payload);setTimeout(refreshTaxiData,400);}
window.addEventListener('message',function(event){let data=event.data||{};if(data.action==='open'){tablet.classList.remove('hidden');openPage('home',false);refreshTaxiData();}if(data.action==='close')tablet.classList.add('hidden');if(data.action==='reset')localStorage.removeItem('ld_tablet_settings');if(data.action==='taxiData'){taxiData=data.data||taxiData;openPage(currentPage,false);}});
closeBtn.addEventListener('click',closeTablet);homeBtn.addEventListener('click',function(){historyStack=[];openPage('home',false);});backBtn.addEventListener('click',function(){openPage(historyStack.pop()||'home',false);});document.addEventListener('keydown',function(e){if(e.key==='Escape')closeTablet();});setInterval(function(){let now=new Date();timeEl.textContent=now.toLocaleTimeString('de-DE',{hour:'2-digit',minute:'2-digit'});},1000);setInterval(function(){if(!tablet.classList.contains('hidden'))refreshTaxiData();},10000);openPage('home',false);
