function ldUnreadBlackboard(){
    return (taxiData.blackboard||[]).filter(function(p){return Number(p.is_read)!==1;}).length;
}

function ldBlackboardCanManage(){
    return taxiData.self&&(taxiData.self.canManageBlackboard||taxiData.self.isDispatcher);
}

function ldBlackboardCard(post){
    let unread=Number(post.is_read)!==1;
    let readCount=Number(post.read_count)||0;
    let driverCount=Number(post.driver_count)||0;
    let html='<div class="bb-card '+(unread?'unread':'read')+'">';
    html+='<div class="bb-head"><div><b>'+(post.pinned==1?'📌 ':'')+esc(post.title)+'</b><small>'+esc(post.author_name||'Leitung')+' · '+esc(post.created_at||'')+'</small></div><span class="pill">'+(unread?'Neu':'Gelesen')+'</span></div>';
    html+='<p>'+esc(post.content).replace(/\n/g,'<br>')+'</p>';
    html+='<div class="bb-foot"><span>Gelesen: '+readCount+' / '+driverCount+'</span><div class="actions">';
    if(unread){html+='<button data-bb-read="'+post.id+'">Als gelesen markieren</button>';}
    if(ldBlackboardCanManage()){
        html+='<button data-bb-pin="'+post.id+'">'+(post.pinned==1?'Lösen':'Anheften')+'</button>';
        html+='<button class="danger" data-bb-delete="'+post.id+'">Löschen</button>';
    }
    html+='</div></div></div>';
    return html;
}

function ldBlackboardView(){
    let posts=taxiData.blackboard||[];
    let html='';
    if(ldBlackboardCanManage()){
        html+='<div style="margin-bottom:14px"><button class="dispatch-main-btn" data-bb-new="1">+ Neuer Beitrag</button></div>';
    }
    if(!posts.length){return html+'<div class="empty-state"><h1>📢 Schwarzes Brett</h1><p>Keine Mitteilungen vorhanden.</p></div>';}
    return html+'<div class="bb-list">'+posts.map(ldBlackboardCard).join('')+'</div>';
}

function ldOpenBlackboardModal(){
    modal.classList.remove('hidden');
    modal.innerHTML='<div class="modal-card"><h2>Neuer Beitrag</h2><label>Titel</label><input id="bb-title" placeholder="z.B. Neue Dienstanweisung"><label>Text</label><textarea id="bb-content" class="modal-textarea" placeholder="Mitteilung schreiben..."></textarea><label><input id="bb-pinned" type="checkbox" style="width:auto;margin-right:8px">Anheften</label><div class="modal-actions"><button id="bb-cancel">Abbrechen</button><button id="bb-save">Veröffentlichen</button></div></div>';
    document.getElementById('bb-cancel').onclick=closeModal;
    document.getElementById('bb-save').onclick=function(){
        let title=document.getElementById('bb-title').value;
        let content=document.getElementById('bb-content').value;
        let pinned=document.getElementById('bb-pinned').checked;
        if(!title||!content){showToast('Schwarzes Brett','Titel und Text fehlen.');return;}
        post('blackboardCreate',{title:title,content:content,pinned:pinned});
        closeModal();
    };
}

let ldOldBindUi=bindUi;
bindUi=function(){
    ldOldBindUi();
    document.querySelectorAll('[data-bb-new]').forEach(function(btn){btn.addEventListener('click',ldOpenBlackboardModal);});
    document.querySelectorAll('[data-bb-read]').forEach(function(btn){btn.addEventListener('click',function(){post('blackboardRead',{postId:Number(btn.dataset.bbRead)});});});
    document.querySelectorAll('[data-bb-delete]').forEach(function(btn){btn.addEventListener('click',function(){post('blackboardDelete',{postId:Number(btn.dataset.bbDelete)});});});
    document.querySelectorAll('[data-bb-pin]').forEach(function(btn){btn.addEventListener('click',function(){post('blackboardPin',{postId:Number(btn.dataset.bbPin)});});});
};

pages.blackboard.render=ldBlackboardView;
let ldOldHomeRender=pages.home.render;
pages.home.render=function(){
    let html=ldOldHomeRender();
    let unread=ldUnreadBlackboard();
    if(unread>0){
        html=html.replace('Schwarzes Brett</button>','Schwarzes Brett <span class="bb-badge">'+unread+'</span></button>');
    }
    return html;
};
