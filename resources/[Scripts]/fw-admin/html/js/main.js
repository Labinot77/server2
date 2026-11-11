// fw-admin NUI — UI styled after codera-adminmenu.
// Keeps fw-admin's NUI contract: OpenMenu / CloseMenu / CopyClipboard / LoadBindableItems
// messages and the Close, Trigger/Button, Trigger/Cloak, Trigger/Focus, Favorites, SaveBinds callbacks.
(() => {
    const RESOURCE = (typeof window.GetParentResourceName === 'function') ? window.GetParentResourceName() : 'fw-admin';

    const app = document.getElementById('app');
    const listEl = document.getElementById('list');
    const searchEl = document.getElementById('search');
    const searchWrap = searchEl.parentElement;
    const countEl = document.getElementById('count');
    const countUnitEl = document.getElementById('countUnit');
    const viewLabel = document.getElementById('viewLabel');
    const navItems = Array.from(document.querySelectorAll('.nav-item'));
    const btnCloak = document.getElementById('btnCloak');
    const btnFocus = document.getElementById('btnFocus');
    const btnResetFavs = document.getElementById('btnResetFavs');
    const menuBtn = document.getElementById('menuBtn');
    const menuPop = document.getElementById('menuPop');
    const searchCount = document.getElementById('searchCount');

    const CATEGORY_LABELS = {
        all: 'ALL COMMANDS',
        player: 'PLAYER COMMANDS',
        utility: 'UTILITY COMMANDS',
        user: 'USER COMMANDS',
        fun: 'FUN COMMANDS',
    };
    const COMMAND_CATS = ['all', 'player', 'utility', 'user', 'fun'];
    const BIND_COUNT_DEFAULT = 5;

    // ---- State ----
    let items = [];            // Config.AdminMenus (0-based here)
    let players = [];
    let favourites = [];       // array of item indices (same format the old UI stored)
    let enabled = {};          // toggle state per item index
    let formState = {};        // { [index]: { [optionId]: value } }
    let currentTarget = false; // shared 'player' target across commands (old UI behaviour)
    let bindable = [];
    let bindValues = {};
    let bindCount = BIND_COUNT_DEFAULT;

    let view = 'commands';     // commands | players | settings
    let activeCategory = 'all';
    let selectedIndex = 0;
    let openRowKey = null;
    let isOpen = false;
    let cloaked = false;
    let fullFocus = true;
    let listLayout = false;
    try { listLayout = localStorage.getItem('fw-admin:layout') === 'list'; } catch (e) {}

    const money = new Intl.NumberFormat('nl-NL', { style: 'currency', currency: 'EUR' });

    // ---- Helpers ----
    function post(name, body) {
        return fetch(`https://${RESOURCE}/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(body || {}),
        }).catch(() => {});
    }

    function esc(value) {
        return String(value === undefined || value === null ? '' : value)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;');
    }

    const ICON_STAR = '<svg viewBox="0 0 576 512" fill="currentColor"><path d="M259.3 17.8L194 150.2 47.9 171.5c-26.2 3.8-36.7 36.1-17.7 54.6l105.7 103-25 145.5c-4.5 26.3 23.2 46 46.4 33.7L288 439.6l130.7 68.7c23.2 12.2 50.9-7.4 46.4-33.7l-25-145.5 105.7-103c19-18.5 8.5-50.8-17.7-54.6L382 150.2 316.7 17.8c-11.7-23.6-45.6-23.9-57.4 0z"/></svg>';
    const ICON_RUN = '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M3 5h18a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H3a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1zm2 3v2h2V8zm4 0v2h2V8zm4 0v2h2V8zm4 0v2h2V8zM7 14v2h10v-2z"/></svg>';
    const ICON_CHEVRON = '<svg viewBox="0 0 448 512" fill="currentColor"><path d="M207.029 381.476L12.686 187.132c-9.373-9.373-9.373-24.569 0-33.941l22.667-22.667c9.357-9.357 24.522-9.375 33.901-.04L224 284.505l154.745-154.021c9.379-9.335 24.544-9.317 33.901.04l22.667 22.667c9.373 9.373 9.373 24.569 0 33.941L240.971 381.476c-9.373 9.372-24.569 9.372-33.942 0z"/></svg>';

    function isTyping() {
        const el = document.activeElement;
        return !!el && (el.tagName === 'INPUT' || el.tagName === 'SELECT' || el.tagName === 'TEXTAREA');
    }

    function isPanelField(el) {
        return !!el && !!el.closest && !!el.closest('.row__panel, .settings');
    }

    function hasPlayerOption(item) {
        return Array.isArray(item.Options) && item.Options.some(o => o.Id === 'player');
    }

    function isChoice(opt) {
        const t = String(opt.Type || '').toLowerCase();
        return t === 'input-choice' || t === 'text-choice';
    }

    function itemDesc(item) {
        if (item.Desc) return item.Desc;
        if (item.Toggle) return 'Toggle on / off';
        if (!item.Collapse || !Array.isArray(item.Options) || !item.Options.length) return 'Runs instantly';
        return item.Options.map(o => String(o.Name || o.Id).replace(/:\s*$/, '').replace(/\s*\(Not Required\)/i, ' (optional)')).join(' · ');
    }

    // ---- Lists ----
    function visibleCommands() {
        const q = searchEl.value.trim().toLowerCase();
        const rows = items
            .map((item, idx) => ({ item, idx }))
            .filter(r => activeCategory === 'all' || r.item.Category === activeCategory)
            .filter(r => !q || String(r.item.Name).toLowerCase().includes(q));

        // Favourites first, otherwise keep config order
        return rows.sort((a, b) => {
            const fa = favourites.includes(a.idx) ? 0 : 1;
            const fb = favourites.includes(b.idx) ? 0 : 1;
            return fa - fb || a.idx - b.idx;
        });
    }

    function visiblePlayers() {
        const q = searchEl.value.trim().toLowerCase();
        return players
            .slice()
            .sort((a, b) => a.ServerId - b.ServerId)
            .filter(p => !q || [p.ServerId, p.Name, p.Steam, p.CharName, p.Cid]
                .some(v => String(v === undefined || v === null ? '' : v).toLowerCase().includes(q)));
    }

    function currentRows() {
        if (view === 'commands') return visibleCommands().map(r => ({ key: 'c' + r.idx, ...r }));
        if (view === 'players') return visiblePlayers().map(p => ({ key: 'p' + p.ServerId, player: p }));
        return [];
    }

    // ---- Field rendering ----
    function fieldValue(idx, opt) {
        if (opt.Id === 'player') return currentTarget === false ? '' : currentTarget;
        const s = formState[idx];
        if (s && s[opt.Id] !== undefined) return s[opt.Id];
        return opt.Value !== undefined ? opt.Value : '';
    }

    function playerOptions() {
        return '<option value=""></option>' + players
            .map(p => `<option value="${esc(p.ServerId)}">${esc(`(${p.ServerId}) ${p.Name} ${p.Steam}`)}</option>`)
            .join('');
    }

    function fieldsHTML(item, idx) {
        if (!Array.isArray(item.Options)) return '';

        return item.Options.map(opt => {
            const label = String(opt.Name || opt.Id).replace(/:\s*$/, '');
            const value = fieldValue(idx, opt);

            if (isChoice(opt)) {
                const choices = opt.Id === 'player'
                    ? playerOptions()
                    : '<option value=""></option>' + (opt.Choices || []).map(c => `<option value="${esc(c.Val)}">${esc(c.Text)}</option>`).join('');

                return `<div class="field">
                    <label>${esc(label)}</label>
                    <select class="ui search selection dropdown" data-choice="${esc(opt.Id)}" data-value="${esc(value)}">${choices}</select>
                </div>`;
            }

            return `<div class="field">
                <label>${esc(label)}</label>
                <input type="text" data-key="${esc(opt.Id)}" value="${esc(value)}" autocomplete="off" />
            </div>`;
        }).join('');
    }

    // ---- Render ----
    function render() {
        const showSearch = view !== 'settings';
        searchWrap.classList.toggle('is-hidden', !showSearch);
        searchEl.placeholder = view === 'players' ? 'Search players...' : 'Search commands...';
        searchCount.textContent = `${searchEl.value.length}/100`;
        listEl.classList.toggle('is-list', listLayout);

        if (view === 'settings') {
            viewLabel.textContent = 'KEYBINDS';
            countEl.textContent = bindCount;
            countUnitEl.textContent = 'KEYBINDS';
            renderSettings();
            return;
        }

        const rows = currentRows();
        countEl.textContent = rows.length;
        countUnitEl.textContent = view === 'players' ? 'PLAYERS' : 'COMMANDS';
        viewLabel.textContent = view === 'players' ? 'PLAYER LIST' : (CATEGORY_LABELS[activeCategory] || 'ALL COMMANDS');

        if (!rows.length) {
            listEl.innerHTML = `<div class="empty">${view === 'players' ? 'No players match your search.' : 'No commands match your search.'}</div>`;
            return;
        }

        if (selectedIndex >= rows.length) selectedIndex = rows.length - 1;
        if (selectedIndex < 0) selectedIndex = 0;

        // Independent columns: an open card only pushes down cards in its own column.
        const cols = Array.from({ length: listLayout ? 1 : 3 }, () => []);
        rows.forEach((row, i) => cols[i % cols.length].push(view === 'players' ? playerRowHTML(row, i) : commandRowHTML(row, i)));
        listEl.innerHTML = cols.map(c => `<div class="col">${c.join('')}</div>`).join('');
        initDropdowns();

        const sel = listEl.querySelector('.row.is-selected');
        if (sel) sel.scrollIntoView({ block: 'nearest' });
    }

    function commandRowHTML(row, i) {
        const { item, idx, key } = row;
        const isFav = favourites.includes(idx);
        const classes = ['row', i === selectedIndex ? 'is-selected' : '', openRowKey === key ? 'is-open' : ''].join(' ');
        const panel = item.Collapse ? `<div class="row__panel">
                ${openRowKey === key ? fieldsHTML(item, idx) : ''}
                <button class="run-btn" data-run="${idx}">Execute</button>
            </div>` : '';
        const state = item.Toggle && !item.Collapse
            ? `<span class="row__state ${enabled[idx] ? 'is-on' : ''}">${enabled[idx] ? 'ON' : 'OFF'}</span>` : '';

        const icon = panel
            ? `<span class="row__icon row__icon--chevron">${ICON_CHEVRON}</span>`
            : `<span class="row__icon">${ICON_RUN}</span>`;

        return `<div class="${classes}" data-key="${key}" data-i="${i}" data-idx="${idx}">
            <div class="row__head" data-head="${key}">
                <span class="row__star ${isFav ? 'is-fav' : ''}" data-fav="${idx}">${ICON_STAR}</span>
                <div class="row__card">
                    <div class="row__text">
                        <div class="row__title">${esc(item.Name)}</div>
                        <div class="row__desc">${esc(itemDesc(item))}</div>
                    </div>
                    ${state}
                    ${icon}
                </div>
            </div>
            ${panel}
        </div>`;
    }

    function playerRowHTML(row, i) {
        const p = row.player;
        const classes = ['row', i === selectedIndex ? 'is-selected' : '', openRowKey === row.key ? 'is-open' : ''].join(' ');
        const info = [
            ['Character Name', p.CharName],
            ['CID', p.Cid],
            ['Server ID', p.ServerId],
            ['Steam ID', p.Steam],
            ['Cash', money.format(p.Cash || 0)],
            ['Bank', money.format(p.Bank || 0)],
            ['Job', `${p.Job} / ${p.Grade} [${p.GradeName}]`],
            ['High Command', p.Highcommand ? 'Yes' : 'No'],
            ['Apartment ID', p.ApartmentId],
            ['Bank / Phone Number', `${p.Account} / ${p.Phone}`],
        ].map(([l, v]) => `<div class="info"><span class="info__label">${esc(l)}</span><span class="info__value">${esc(v)}</span></div>`).join('');

        return `<div class="${classes}" data-key="${row.key}" data-i="${i}">
            <div class="row__head" data-head="${row.key}">
                <span class="row__badge">${esc(p.ServerId)}</span>
                <div class="row__card">
                    <div class="row__text">
                        <div class="row__title">${esc(p.Name)}</div>
                        <div class="row__desc">${esc(`${p.CharName || ''} · ${p.Cid || ''} · ${p.Steam || ''}`)}</div>
                    </div>
                    <span class="row__icon row__icon--chevron">${ICON_CHEVRON}</span>
                </div>
            </div>
            <div class="row__panel">
                <div class="info-grid">${info}</div>
                <div class="btn-row">
                    <button class="run-btn" data-goto="${esc(p.ServerId)}">Teleport to Player</button>
                    <button class="run-btn" disabled>Spectate (Use TX)</button>
                </div>
            </div>
        </div>`;
    }

    function initDropdowns() {
        if (!window.jQuery || !jQuery.fn.dropdown) return;

        jQuery(listEl).find('select[data-choice]').each(function () {
            const $sel = jQuery(this);
            const optId = $sel.attr('data-choice');
            const idx = Number($sel.closest('.row').attr('data-idx'));
            const value = $sel.attr('data-value');

            $sel.dropdown({
                allowAdditions: true,
                fullTextSearch: true,
                onChange: (val) => {
                    if (optId === 'player') {
                        currentTarget = val;
                    } else {
                        formState[idx] = formState[idx] || {};
                        formState[idx][optId] = val;
                    }
                },
            });
            if (value !== '') $sel.dropdown('set selected', value);
        });

        jQuery(listEl).find('select[data-bind]').each(function () {
            const $sel = jQuery(this);
            const v = bindValues[$sel.attr('data-bind')];
            $sel.dropdown({ fullTextSearch: true });
            if (v !== undefined && v !== null && v !== '') $sel.dropdown('set selected', String(v));
        });
    }

    function renderSettings() {
        const options = `<option value="0">None</option>` +
            bindable.map(b => `<option value="${esc(b.Key)}">${esc(b.Label)}</option>`).join('');

        let html = '<div class="settings">';
        for (let i = 1; i <= bindCount; i++) {
            html += `<div class="field">
                <label>Bind ${i}</label>
                <p class="field__hint">Select option for Bind ${i}</p>
                <select class="ui search selection dropdown" data-bind="bind_${i}">${options}</select>
            </div>`;
        }
        html += `<button class="run-btn" id="saveBinds">Save</button></div>`;
        listEl.innerHTML = html;

        initDropdowns();
    }

    // ---- Actions ----
    function onHeadActivate(key) {
        if (key[0] === 'p') {
            openRowKey = openRowKey === key ? null : key;
            render();
            return;
        }

        const idx = Number(key.slice(1));
        const item = items[idx];
        if (!item) return;

        if (item.Collapse) {
            openRowKey = openRowKey === key ? null : key;
            render();
            return;
        }

        if (item.Toggle) enabled[idx] = !enabled[idx];
        post('Trigger/Button', { Event: item.Event, EventType: item.EventType, Result: item.Toggle ? !!enabled[idx] : false });
        render();
    }

    function runCommand(idx) {
        const item = items[idx];
        if (!item) return;

        const result = {};
        const rowEl = listEl.querySelector(`.row[data-idx="${idx}"]`);
        if (rowEl) {
            rowEl.querySelectorAll('input[data-key]').forEach(inp => { result[inp.getAttribute('data-key')] = inp.value; });
            rowEl.querySelectorAll('select[data-choice]').forEach(sel => { result[sel.getAttribute('data-choice')] = sel.value; });
        }

        post('Trigger/Button', {
            Player: currentTarget,
            Event: item.Event,
            EventType: item.EventType,
            Result: result,
        });
    }

    function toggleFavourite(idx) {
        const at = favourites.indexOf(idx);
        if (at >= 0) favourites.splice(at, 1); else favourites.push(idx);
        post('Favorites', { Favorites: favourites });
        render();
    }

    function setView(nextView, cat) {
        view = nextView;
        if (cat) activeCategory = cat;
        selectedIndex = 0;
        openRowKey = null;
        searchEl.value = '';
        navItems.forEach(b => {
            const match = b.getAttribute('data-view') === view && (view !== 'commands' || b.getAttribute('data-cat') === activeCategory);
            b.classList.toggle('is-active', match);
        });
        render();
    }

    function closeMenu() {
        if (!isOpen) return;
        isOpen = false;
        app.classList.add('hidden');
        if (document.activeElement) document.activeElement.blur();
        post('Close');
    }

    // ---- Events ----
    navItems.forEach(btn => {
        btn.addEventListener('click', () => setView(btn.getAttribute('data-view'), btn.getAttribute('data-cat')));
    });

    searchEl.addEventListener('input', () => {
        selectedIndex = 0;
        openRowKey = null;
        render();
    });

    listEl.addEventListener('click', (e) => {
        const fav = e.target.closest('[data-fav]');
        if (fav) { e.stopPropagation(); toggleFavourite(Number(fav.getAttribute('data-fav'))); return; }

        const run = e.target.closest('[data-run]');
        if (run) { runCommand(Number(run.getAttribute('data-run'))); return; }

        const go = e.target.closest('[data-goto]');
        if (go) {
            post('Trigger/Button', { Event: 'Admin:Teleport', EventType: null, Result: { player: go.getAttribute('data-goto'), type: 'Goto' } });
            return;
        }

        if (e.target.id === 'saveBinds') {
            const data = {};
            listEl.querySelectorAll('select[data-bind]').forEach(sel => { data[sel.getAttribute('data-bind')] = sel.value; });
            bindValues = data;
            post('SaveBinds', data);
            return;
        }

        const head = e.target.closest('[data-head]');
        if (head) {
            const rowEl = head.closest('.row');
            selectedIndex = Number(rowEl.getAttribute('data-i'));
            onHeadActivate(head.getAttribute('data-head'));
        }
    });

    // Keep typed values across re-renders
    listEl.addEventListener('input', (e) => {
        const input = e.target;
        const rowEl = input.closest('.row[data-idx]');
        if (!rowEl || !input.hasAttribute('data-key')) return;
        if (input.getAttribute('data-key') === 'player') { currentTarget = input.value; return; }
        const idx = Number(rowEl.getAttribute('data-idx'));
        formState[idx] = formState[idx] || {};
        formState[idx][input.getAttribute('data-key')] = input.value;
    });

    // Focus handling (same behaviour as the old UI): when Full Focus is off,
    // typing in a field temporarily grabs full focus.
    document.addEventListener('focusin', (e) => {
        if (fullFocus || e.target.tagName !== 'INPUT') return;
        post('Trigger/Focus', { Focus: true });
    });
    document.addEventListener('focusout', (e) => {
        if (fullFocus || e.target.tagName !== 'INPUT') return;
        post('Trigger/Focus', { Focus: false });
    });

    menuBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        menuBtn.classList.toggle('is-open', menuPop.classList.toggle('is-open'));
    });
    document.addEventListener('click', (e) => {
        if (menuPop.contains(e.target)) return;
        menuPop.classList.remove('is-open');
        menuBtn.classList.remove('is-open');
    });

    btnCloak.addEventListener('click', () => {
        cloaked = !cloaked;
        btnCloak.classList.toggle('is-active', cloaked);
        post('Trigger/Cloak', { Cloak: cloaked });
    });

    btnFocus.addEventListener('click', () => {
        fullFocus = !fullFocus;
        btnFocus.classList.toggle('is-active', fullFocus);
        post('Trigger/Focus', { Focus: fullFocus });
    });

    btnResetFavs.addEventListener('click', () => {
        favourites = [];
        post('Favorites', { Favorites: [] });
        render();
    });

    document.addEventListener('keydown', (e) => {
        if (!isOpen) return;

        if (e.key === 'Escape') { closeMenu(); return; }

        const inPanel = isPanelField(document.activeElement);

        const step = { ArrowDown: listLayout ? 1 : 3, ArrowUp: listLayout ? -1 : -3, ArrowRight: 1, ArrowLeft: -1 }[e.key];
        if (step) {
            if (inPanel || view === 'settings') return;
            if (document.activeElement === searchEl && (e.key === 'ArrowLeft' || e.key === 'ArrowRight')) return;
            e.preventDefault();
            searchEl.blur();
            selectedIndex = Math.max(0, selectedIndex + step);
            render();
            return;
        }

        if (e.key === 'Enter') {
            if (inPanel || view === 'settings') return;
            const row = currentRows()[selectedIndex];
            if (row) onHeadActivate(row.key);
            return;
        }

        if (isTyping()) return;

        const k = e.key.toLowerCase();
        if (k === 'f' && view === 'commands') {
            const row = currentRows()[selectedIndex];
            if (row) toggleFavourite(row.idx);
        } else if (k === 'q' || k === 'e') {
            const dir = k === 'q' ? 1 : -1;
            const nextCat = view === 'commands'
                ? COMMAND_CATS[(COMMAND_CATS.indexOf(activeCategory) + dir + COMMAND_CATS.length) % COMMAND_CATS.length]
                : 'all';
            setView('commands', nextCat);
        } else if (k === 'x') {
            listLayout = !listLayout;
            try { localStorage.setItem('fw-admin:layout', listLayout ? 'list' : 'grid'); } catch (err) {}
            render();
        } else if (k === '/' ) {
            e.preventDefault();
            searchEl.focus();
        }
    });

    window.addEventListener('message', (event) => {
        const data = event.data || {};
        switch (data.Action) {
            case 'LoadBindableItems':
                bindable = data.BindableItems || [];
                bindValues = data.Values || {};
                bindCount = data.Binds || BIND_COUNT_DEFAULT;
                if (isOpen && view === 'settings') render();
                break;

            case 'OpenMenu':
                items = Array.isArray(data.AdminItems) ? data.AdminItems : Object.values(data.AdminItems || {});
                players = Array.isArray(data.AllPlayers) ? data.AllPlayers : Object.values(data.AllPlayers || {});
                favourites = Object.values(data.Favorites || {}).map(Number).filter(n => !isNaN(n));
                isOpen = true;
                app.classList.remove('hidden');
                if (view === 'settings') setView('commands', 'all'); else render();
                if (view === 'commands') searchEl.focus();
                break;

            case 'CloseMenu':
                if (!isOpen) return;
                isOpen = false;
                app.classList.add('hidden');
                break;

            case 'CopyClipboard': {
                const area = document.createElement('textarea');
                area.value = data.Text || '';
                area.style.position = 'fixed';
                area.style.opacity = '0';
                document.body.appendChild(area);
                area.select();
                document.execCommand('copy');
                area.remove();
                break;
            }
        }
    });
})();
