const tablet = document.getElementById('tablet');
const closeBtn = document.getElementById('close');
const timeEl = document.getElementById('time');
const view = document.getElementById('view');
const topbar = document.getElementById('topbar');
const pageTitle = document.getElementById('page-title');
const backBtn = document.getElementById('back');
const homeBtn = document.getElementById('home');

const pages = {
    home: {
        title: 'Home',
        render: () => `
            <h1>Los Santos Taxi</h1>
            <p class="subtitle">TaxiOS Unternehmenssystem</p>
            <div class="grid">
                ${tile('dashboard', '▦', 'Dashboard')}
                ${tile('orders', '☰', 'Aufträge')}
                ${tile('drivers', '◎', 'Fahrer')}
                ${tile('dispatch', '◉', 'Leitstelle')}
                ${tile('ratings', '★', 'Bewertungen')}
                ${tile('blackboard', '!', 'Schwarzes Brett')}
                ${tile('profile', '☻', 'Profil')}
                ${tile('settings', '⚙', 'Einstellungen')}
            </div>
        `
    },
    dashboard: {
        title: 'Dashboard',
        render: () => `
            <div class="cards">
                ${card('Dienststatus', 'Offline')}
                ${card('Fahrten heute', '0')}
                ${card('Offenes Trinkgeld', '0 $')}
                ${card('Offene Aufträge', '0')}
                ${card('Leitstellen', '0 / 2')}
                ${card('Bewertung', '—')}
            </div>
        `
    },
    orders: {
        title: 'Aufträge',
        render: () => `
            <div class="list">
                ${row('Keine offenen Aufträge', 'bereit')}
            </div>
        `
    },
    drivers: {
        title: 'Fahrer',
        render: () => `
            <div class="list">
                ${row('Fahrerübersicht vorbereitet', 'live folgt')}
            </div>
        `
    },
    dispatch: {
        title: 'Leitstelle',
        render: () => `
            <div class="cards">
                ${card('LS1', 'frei')}
                ${card('LS2', 'frei')}
                ${card('Wartende Aufträge', '0')}
            </div>
        `
    },
    ratings: { title: 'Bewertungen', render: () => cardWrap('Noch keine Bewertungen verbunden.') },
    blackboard: { title: 'Schwarzes Brett', render: () => cardWrap('Beiträge folgen im nächsten Modul.') },
    profile: { title: 'Profil', render: () => cardWrap('Profil wird mit ld_taxi verbunden.') },
    settings: { title: 'Einstellungen', render: () => cardWrap('Transparenz und Größe folgen als eigenes Modul.') }
};

let historyStack = [];
let currentPage = 'home';

function tile(page, icon, label) {
    return `<button class="tile" data-page="${page}"><b>${icon}</b>${label}</button>`;
}

function card(title, value) {
    return `<div class="card"><small>${title}</small><strong>${value}</strong></div>`;
}

function row(text, status) {
    return `<div class="row"><span>${text}</span><span class="pill">${status}</span></div>`;
}

function cardWrap(text) {
    return `<div class="card"><small>Info</small><strong style="font-size:20px">${text}</strong></div>`;
}

function openPage(page, push = true) {
    const route = pages[page] || pages.home;
    if (push && currentPage !== page) historyStack.push(currentPage);
    currentPage = page;
    pageTitle.textContent = route.title;
    topbar.classList.toggle('hidden', page === 'home');
    view.innerHTML = route.render();
    bindTiles();
}

function bindTiles() {
    document.querySelectorAll('[data-page]').forEach(btn => {
        btn.addEventListener('click', () => openPage(btn.dataset.page));
    });
}

function closeTablet() {
    fetch(`https://${GetParentResourceName()}/closeTablet`, {
        method: 'POST',
        body: JSON.stringify({})
    });
}

window.addEventListener('message', (event) => {
    const data = event.data || {};
    if (data.action === 'open') {
        tablet.classList.remove('hidden');
        openPage('home', false);
    }
    if (data.action === 'close') tablet.classList.add('hidden');
    if (data.action === 'reset') localStorage.removeItem('ld_tablet_settings');
});

closeBtn.addEventListener('click', closeTablet);
homeBtn.addEventListener('click', () => {
    historyStack = [];
    openPage('home', false);
});
backBtn.addEventListener('click', () => {
    const previous = historyStack.pop() || 'home';
    openPage(previous, false);
});

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeTablet();
});

setInterval(() => {
    const now = new Date();
    timeEl.textContent = now.toLocaleTimeString('de-DE', { hour: '2-digit', minute: '2-digit' });
}, 1000);

openPage('home', false);
