function ldDriverStatusLabel(driver){
    if(driver.display_status){return driver.display_status;}
    let order=(taxiData.orders||[]).find(function(o){return o.assigned_driver===driver.identifier;});
    if(order){
        if(order.status==='accepted')return 'Unterwegs zum Kunden';
        if(order.status==='arrived')return 'Wartet auf Kunden';
        if(order.status==='started')return 'Fahrgast an Bord';
        return statusLabel(order.status);
    }
    if(driver.status==='available')return 'Verfügbar';
    if(driver.status==='pause')return 'Pause';
    if(driver.status==='offline')return 'Offline';
    return driver.status||'Unbekannt';
}

function ldDriverOrder(driver){
    if(driver.current_order_id){
        return {
            id:driver.current_order_id,
            status:driver.current_order_status,
            customer_name:driver.current_customer_name,
            pickup_label:driver.current_pickup_label,
            destination_label:driver.current_destination_label
        };
    }
    return (taxiData.orders||[]).find(function(o){return o.assigned_driver===driver.identifier;});
}

function ldDriverRank(driver){
    let order=ldDriverOrder(driver);
    if(!order){
        if(driver.status==='available')return 1;
        if(driver.status==='pause')return 5;
        if(driver.status==='offline')return 6;
        return 2;
    }
    if(order.status==='accepted')return 2;
    if(order.status==='arrived')return 3;
    if(order.status==='started')return 4;
    return 2;
}

function ldDriverBoard(){
    let drivers=(taxiData.drivers||[]).slice().sort(function(a,b){
        let ar=ldDriverRank(a),br=ldDriverRank(b);
        if(ar!==br)return ar-br;
        return String(a.name||'').localeCompare(String(b.name||''));
    });
    if(!drivers.length){return '<div class="empty-section">Keine Fahrer gefunden</div>';}
    return '<div class="driver-board">'+drivers.map(function(d){
        let order=ldDriverOrder(d);
        let orderText=order?('Auftrag #'+order.id+' · '+(order.pickup_label||'Abholort offen')):'Kein Auftrag';
        return '<div class="driver-status-card rank-'+ldDriverRank(d)+'"><div><strong>'+esc(d.name||d.identifier||'Unbekannt')+'</strong><small>'+esc(orderText)+'</small></div><span class="pill">'+esc(ldDriverStatusLabel(d))+'</span></div>';
    }).join('')+'</div>';
}

let ldOldDispatchView=dispatchView;
dispatchView=function(){
    let html=ldOldDispatchView();
    if(!isDispatcher())return html;
    return html.replace('<h1 style="font-size:22px;text-align:left;margin-top:14px">Disposition</h1>','<h1 style="font-size:22px;text-align:left;margin-top:14px">Fahrerstatus</h1>'+ldDriverBoard()+'<h1 style="font-size:22px;text-align:left;margin-top:18px">Disposition</h1>');
};
