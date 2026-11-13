(() => {
    'use strict';

    const IS_GAME = typeof window.GetParentResourceName === 'function';
    const RESOURCE = IS_GAME ? window.GetParentResourceName() : 'fw-mainmenu';

    // ---------------------------------------------------------------------
    // Map: GTA's own pause-map textures (your streamed minimap_*.ytd), decoded and split into tiles.
    // World <-> image calibration (fitted against 2400+ matching points, ~1.4 m error)
    // ---------------------------------------------------------------------
    const CAL = { ax: 1.454373, bx: -4107.551, ay: -1.469958, by: 8443.498 };
    const IMG_W = 6144, IMG_H = 9216;  // full map size in px (level 0)
    const TILE = 512;                  // tile size in px
    const LEVELS = 4;                  // level k = full size / 2^k
    const tileUrl = (k, x, y) => `tiles/${k}/${x}_${y}.webp`;

    const worldToImg = (x, y) => [(x - CAL.bx) / CAL.ax, (y - CAL.by) / CAL.ay];
    const imgToWorld = (ix, iy) => [CAL.ax * ix + CAL.bx, CAL.ay * iy + CAL.by];

    // GTA blip colour index -> hex
    const BLIP_COLORS = [
        '#fefefe', '#e03232', '#71cb71', '#5db6e5', '#f0f0f0', '#eec64e', '#c25050', '#9c6eaf', '#fe7ac3', '#f59d79',
        '#b18f83', '#8dcea7', '#70a8ae', '#d3d1e7', '#8f7e98', '#6ac4bf', '#d5c398', '#ea8e50', '#97cae9', '#b26287',
        '#8f8d79', '#a6755e', '#afa8a8', '#e88e9b', '#bbd65b', '#0c7b56', '#7ac3fe', '#ab3ce6', '#cda80c', '#4561ab',
        '#29a5b8', '#b89b7b', '#c8e0fe', '#f0f096', '#ed8ca1', '#f98a8a', '#fbeea5', '#fefefe', '#2c6db8', '#9a9a9a',
        '#4c4c4c', '#f29d9d', '#6cb7d6', '#afeda8', '#ffa75f', '#f1f1f1', '#ecf029', '#ff9a18', '#f644a5', '#e03b3b',
        '#8a6de3', '#ff8b5c', '#416c41', '#b3ddf3', '#3a6469', '#a0a0a0', '#846b28', '#5ea0ca', '#4b4175', '#e13b3b',
        '#f0a442', '#c36f9a', '#aaaaaa', '#3c8eab', '#ff7f00', '#a3889b', '#f0a442', '#5db6e5', '#5db6e5', '#71cb71',
        '#f0a442', '#f0a442', '#ffffff', '#f0a442', '#5db6e5', '#e03232', '#780000', '#5db6e5', '#3a4a6c', '#e03232',
        '#5db6e5', '#f0a442', '#71cb71', '#a854f2', '#5db6e5', '#4c4c4c',
    ];
    const blipColor = (c) => {
        c = c >>> 0;
        if (c > 255) return '#' + (c >>> 8).toString(16).padStart(6, '0');
        return BLIP_COLORS[c] || '#fefefe';
    };

    // ---------------------------------------------------------------------
    // State
    // ---------------------------------------------------------------------
    const $ = (id) => document.getElementById(id);
    const app = $('app'), viewport = $('viewport'), tilesBg = $('tiles-bg'), tilesCur = $('tiles-cur');
    const markerLayer = $('marker-layer'), tooltip = $('tooltip'), legendEl = $('legend'), searchEl = $('search');
    const youRow = $('you-row'), routeLine = $('route-line'), routeOutline = $('route-outline');
    const zoneEl = $('loc-zone'), streetEl = $('loc-street'), routeInfo = $('loc-route'), routeText = $('loc-route-text');

    const store = {
        get(k, d) { try { const v = localStorage.getItem('fw-mainmenu:' + k); return v === null ? d : JSON.parse(v); } catch (e) { return d; } },
        set(k, v) { try { localStorage.setItem('fw-mainmenu:' + k, JSON.stringify(v)); } catch (e) { /* ignore */ } },
    };

    const S = {
        open: false,
        legend: [],
        entryById: {},
        blips: [],
        byCat: {},
        cycle: {},
        hidden: new Set(store.get('hidden', [])),
        selected: -1,            // index in visible rows; -1 = YOU
        visibleRows: [],
        player: { x: 0, y: 0, h: 0 },
        origin: null,
        waypoint: null,
        route: null,             // { points: [[x, y], ...], length, straight? }
        focusBlip: null,
        view: { cx: IMG_W / 2, cy: IMG_H / 2, scale: store.get('scale', 0.6) },
        target: null,
        dirty: true,
        playerDirty: false,
    };

    const post = (name, data = {}) => {
        if (!IS_GAME) return Promise.resolve(null);
        return fetch(`https://${RESOURCE}/${name}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data),
        }).then((r) => r.json()).catch(() => null);
    };

    // ---------------------------------------------------------------------
    // Camera
    // ---------------------------------------------------------------------
    const panelWidth = () => { const p = $('panel'); return p ? p.offsetWidth + window.innerHeight * 0.026 : 0; };
    const mapCenterScreen = () => [(window.innerWidth - panelWidth()) / 2, window.innerHeight / 2];
    const minScale = () => (window.innerHeight / IMG_H) * 0.95;
    const maxScale = () => 2.2;
    const clampScale = (s) => Math.min(maxScale(), Math.max(minScale(), s));

    const imgToScreen = (ix, iy, v = S.view) => {
        const [mx, my] = mapCenterScreen();
        return [(ix - v.cx) * v.scale + mx, (iy - v.cy) * v.scale + my];
    };
    const screenToImg = (sx, sy, v = S.view) => {
        const [mx, my] = mapCenterScreen();
        return [(sx - mx) / v.scale + v.cx, (sy - my) / v.scale + v.cy];
    };
    const worldToScreen = (x, y) => imgToScreen(...worldToImg(x, y));

    const clampView = (v) => {
        v.scale = clampScale(v.scale);
        v.cx = Math.min(IMG_W, Math.max(0, v.cx));
        v.cy = Math.min(IMG_H, Math.max(0, v.cy));
        return v;
    };

    const animateTo = (cx, cy, scale) => {
        S.target = clampView({ cx, cy, scale: scale === undefined ? S.view.scale : scale });
        S.dirty = true;
    };

    const focusWorld = (x, y, minZoom) => {
        const [ix, iy] = worldToImg(x, y);
        animateTo(ix, iy, minZoom ? Math.max(S.view.scale, minZoom) : S.view.scale);
    };

    const zoomAt = (factor, sx, sy) => {
        const base = S.target || S.view;
        const newScale = clampScale(base.scale * factor);
        if (sx === undefined) [sx, sy] = mapCenterScreen();
        const [ix, iy] = screenToImg(sx, sy, base);
        const [mx, my] = mapCenterScreen();
        animateTo(ix - (sx - mx) / newScale, iy - (sy - my) / newScale, newScale);
        store.set('scale', newScale);
    };

    // ---------------------------------------------------------------------
    // Tiles: only the tiles on screen are in the page, at the level that fits the zoom
    // ---------------------------------------------------------------------
    const levelW = (k) => IMG_W >> k, levelH = (k) => IMG_H >> k;
    const tilesX = (k) => Math.ceil(levelW(k) / TILE), tilesY = (k) => Math.ceil(levelH(k) / TILE);

    const makeTile = (k, x, y) => {
        const img = document.createElement('img');
        img.className = 'tile';
        img.draggable = false;
        img.decoding = 'async';
        img.src = tileUrl(k, x, y);
        // edge tiles are smaller than TILE, so size every tile exactly
        img.style.left = `${x * TILE}px`;
        img.style.top = `${y * TILE}px`;
        img.style.width = `${Math.min(TILE, levelW(k) - x * TILE)}px`;
        img.style.height = `${Math.min(TILE, levelH(k) - y * TILE)}px`;
        return img;
    };

    // background: the smallest level, always present under the sharp tiles
    (() => {
        const k = LEVELS - 1;
        tilesBg.style.width = `${levelW(k)}px`;
        tilesBg.style.height = `${levelH(k)}px`;
        for (let y = 0; y < tilesY(k); y++) for (let x = 0; x < tilesX(k); x++) tilesBg.appendChild(makeTile(k, x, y));
    })();

    let curLevel = -1;
    const curTiles = new Map();          // "x_y" -> img

    const pickLevel = (scale) => Math.max(0, Math.min(LEVELS - 2, Math.floor(Math.log2(1 / scale) + 0.15)));

    const placeLevel = (el, k) => {
        const v = S.view, [mx, my] = mapCenterScreen();
        const f = v.scale * (1 << k);    // level-k px -> screen px
        el.style.transform = `translate3d(${(mx - v.cx * v.scale).toFixed(1)}px, ${(my - v.cy * v.scale).toFixed(1)}px, 0) scale(${f})`;
    };

    const updateTiles = () => {
        const k = pickLevel(S.view.scale);
        if (k !== curLevel) {
            curLevel = k;
            curTiles.forEach((img) => img.remove());
            curTiles.clear();
            tilesCur.style.width = `${levelW(k)}px`;
            tilesCur.style.height = `${levelH(k)}px`;
        }

        // visible area in level-k px
        const [x0, y0] = screenToImg(0, 0), [x1, y1] = screenToImg(window.innerWidth, window.innerHeight);
        const d = 1 << k;
        const tx0 = Math.max(0, Math.floor(x0 / d / TILE)), ty0 = Math.max(0, Math.floor(y0 / d / TILE));
        const tx1 = Math.min(tilesX(k) - 1, Math.floor(x1 / d / TILE)), ty1 = Math.min(tilesY(k) - 1, Math.floor(y1 / d / TILE));

        const want = new Set();
        for (let y = ty0; y <= ty1; y++) for (let x = tx0; x <= tx1; x++) {
            const key = `${x}_${y}`;
            want.add(key);
            if (!curTiles.has(key)) { const img = makeTile(k, x, y); tilesCur.appendChild(img); curTiles.set(key, img); }
        }
        curTiles.forEach((img, key) => { if (!want.has(key)) { img.remove(); curTiles.delete(key); } });

        placeLevel(tilesBg, LEVELS - 1);
        placeLevel(tilesCur, k);
    };

    // warm the cache in the background so the first open is instant
    const preloadTiles = () => {
        const queue = [];
        for (let k = LEVELS - 2; k >= 0; k--) {
            for (let y = 0; y < tilesY(k); y++) for (let x = 0; x < tilesX(k); x++) queue.push(tileUrl(k, x, y));
        }
        let active = 0;
        const next = () => {
            while (active < 4 && queue.length) {
                active++;
                const img = new Image();
                img.onload = img.onerror = () => { active--; next(); };
                img.src = queue.shift();
            }
        };
        next();
    };
    setTimeout(preloadTiles, 1500);

    // ---------------------------------------------------------------------
    // Markers + route
    // ---------------------------------------------------------------------
    let markerEls = [];
    let playerEl = null, waypointEl = null;

    const buildMarkers = () => {
        markerEls.forEach((m) => m.el.remove());
        markerEls = [];

        for (const b of S.blips) {
            if (b.cat && S.hidden.has(b.cat)) continue;
            const entry = b.cat ? S.entryById[b.cat] : null;
            const el = document.createElement('div');
            el.style.color = (entry && entry.Tint) || blipColor(b.c);
            if (entry && entry.Icon) {
                el.className = 'marker';
                el.innerHTML = `<i class="${entry.Icon}"></i>`;
                el.addEventListener('mouseenter', () => showTooltip(entry.Label, el));
                el.addEventListener('mouseleave', hideTooltip);
            } else {
                el.className = 'marker dot';
            }
            if (b === S.focusBlip) el.classList.add('focused');
            markerLayer.appendChild(el);
            markerEls.push({ el, blip: b });
        }

        if (!waypointEl) {
            waypointEl = document.createElement('div');
            waypointEl.className = 'marker waypoint';
            waypointEl.innerHTML = '<i class="fas fa-map-marker-alt"></i>';
            markerLayer.appendChild(waypointEl);
        }
        if (!playerEl) {
            playerEl = document.createElement('div');
            playerEl.className = 'marker player';
            playerEl.innerHTML = '<i class="fas fa-location-arrow"></i>';
            markerLayer.appendChild(playerEl);
        }
        S.dirty = true;
    };

    const placeEl = (el, x, y) => {
        const [sx, sy] = worldToScreen(x, y);
        const off = sx < -50 || sy < -50 || sx > window.innerWidth + 50 || sy > window.innerHeight + 50;
        el.style.display = off ? 'none' : '';
        if (!off) el.style.transform = `translate3d(${sx.toFixed(1)}px, ${sy.toFixed(1)}px, 0)`;
    };

    const renderRoute = () => {
        let pts = '';
        if (S.route && S.waypoint) {
            // route starts where the player is now, then follows GTA's GPS points
            const list = [[S.player.x, S.player.y], ...S.route.points];
            pts = list.map(([x, y]) => { const [sx, sy] = worldToScreen(x, y); return `${sx.toFixed(1)},${sy.toFixed(1)}`; }).join(' ');
        }
        routeLine.setAttribute('points', pts);
        routeOutline.setAttribute('points', pts);
        const straight = !!(S.route && S.route.straight);
        routeLine.classList.toggle('straight', straight);
        routeOutline.classList.toggle('straight', straight);
    };

    const renderPlayer = () => {
        if (!playerEl) return;
        placeEl(playerEl, S.player.x, S.player.y);
        // fa-location-arrow points north-east; GTA heading is counter-clockwise from north
        playerEl.firstChild.style.transform = `rotate(${(-S.player.h - 45).toFixed(1)}deg)`;
    };

    const render = () => {
        updateTiles();
        renderRoute();
        for (const m of markerEls) placeEl(m.el, m.blip.x, m.blip.y);

        if (waypointEl) {
            if (S.waypoint) { waypointEl.classList.remove('hidden'); placeEl(waypointEl, S.waypoint.x, S.waypoint.y); }
            else waypointEl.classList.add('hidden');
        }
        renderPlayer();
    };

    const tick = () => {
        if (S.open) {
            if (S.target) {
                const t = S.target, v = S.view, k = 0.22;
                v.cx += (t.cx - v.cx) * k;
                v.cy += (t.cy - v.cy) * k;
                v.scale += (t.scale - v.scale) * k;
                if (Math.abs(t.cx - v.cx) < 0.3 && Math.abs(t.cy - v.cy) < 0.3 && Math.abs(t.scale - v.scale) < 0.0005) {
                    v.cx = t.cx; v.cy = t.cy; v.scale = t.scale; S.target = null;
                }
                S.dirty = true;
            }
            if (S.dirty) { S.dirty = false; S.playerDirty = false; render(); }
            else if (S.playerDirty) { S.playerDirty = false; renderPlayer(); if (S.route) renderRoute(); }
        }
        requestAnimationFrame(tick);
    };

    const showTooltip = (text, el) => {
        const r = el.getBoundingClientRect();
        tooltip.textContent = text;
        tooltip.classList.remove('hidden');
        tooltip.style.transform = `translate(${r.right + 6}px, ${r.top + r.height / 2 - tooltip.offsetHeight / 2}px)`;
    };
    const hideTooltip = () => tooltip.classList.add('hidden');

    // ---------------------------------------------------------------------
    // Location box (zone + street under the cursor) and route distance
    // ---------------------------------------------------------------------
    let locateTimer = null, lastLocate = null;
    const setLocation = (zone, street) => {
        zoneEl.textContent = zone || '-';
        streetEl.textContent = street || '';
    };
    const locate = (x, y) => {
        lastLocate = [x, y];
        if (locateTimer) return;
        locateTimer = setTimeout(async () => {
            locateTimer = null;
            const [lx, ly] = lastLocate;
            const res = await post('locate', { x: lx, y: ly });
            if (res && S.open) setLocation(res.zone, res.street);
        }, 90);
    };

    const formatDistance = (m) => (m >= 1000 ? `${(m / 1000).toFixed(1)} km` : `${Math.round(m)} m`);
    const updateRouteInfo = () => {
        const show = !!(S.route && S.waypoint);
        routeInfo.classList.toggle('hidden', !show);
        if (show) routeText.textContent = (S.route.straight ? '~ ' : '') + formatDistance(S.route.length);
    };

    // ---------------------------------------------------------------------
    // Legend
    // ---------------------------------------------------------------------
    const pad = (n) => String(n).padStart(2, '0');

    const groupBlips = () => {
        S.byCat = {};
        const o = S.origin || S.player;
        for (const b of S.blips) {
            if (!b.cat) continue;
            (S.byCat[b.cat] = S.byCat[b.cat] || []).push(b);
        }
        for (const id in S.byCat) {
            S.byCat[id].sort((a, b) => ((a.x - o.x) ** 2 + (a.y - o.y) ** 2) - ((b.x - o.x) ** 2 + (b.y - o.y) ** 2));
            if ((S.cycle[id] || 0) >= S.byCat[id].length) S.cycle[id] = 0;
        }
    };

    const selectedEntryId = () => (S.selected >= 0 ? S.visibleRows[S.selected] : null);

    const buildLegend = () => {
        const q = searchEl.value.trim().toLowerCase();
        const prevSelected = selectedEntryId();
        legendEl.innerHTML = '';
        S.visibleRows = [];

        for (const section of S.legend) {
            const entries = section.Entries.filter((e) => (S.byCat[e.Id] || []).length > 0)
                .filter((e) => !q || e.Label.toLowerCase().includes(q) || section.Label.toLowerCase().includes(q));
            if (!entries.length) continue;

            const sec = document.createElement('div');
            sec.className = 'section';

            const offCount = entries.filter((e) => S.hidden.has(e.Id)).length;
            const secState = offCount === 0 ? '' : offCount === entries.length ? 'unchecked' : 'partial';

            const header = document.createElement('div');
            header.className = 'section-header';
            header.innerHTML = `<span>${section.Label}</span><span class="check ${secState}"><i class="fas fa-check"></i></span>`;
            header.querySelector('.check').addEventListener('click', (ev) => {
                ev.stopPropagation();
                const turnOn = offCount > 0;
                entries.forEach((e) => (turnOn ? S.hidden.delete(e.Id) : S.hidden.add(e.Id)));
                onHiddenChanged();
            });
            sec.appendChild(header);

            const rows = document.createElement('div');
            rows.className = 'rows';

            for (const e of entries) {
                const list = S.byCat[e.Id];
                const idx = S.cycle[e.Id] || 0;
                const color = e.Tint || blipColor(list[0].c);
                const rowIndex = S.visibleRows.length;
                S.visibleRows.push(e.Id);

                const row = document.createElement('div');
                row.className = 'row' + (S.hidden.has(e.Id) ? ' off' : '');
                row.dataset.index = rowIndex;
                row.innerHTML = `
                    <span class="row-icon" style="color:${color}"><i class="${e.Icon || 'fas fa-circle'}"></i></span>
                    <span class="row-label">${e.Label}</span>
                    ${list.length > 1 ? `<span class="cycler">
                        <span class="arrow prev"><i class="fas fa-chevron-left"></i></span>
                        <span class="count">${pad(idx + 1)}/${pad(list.length)}</span>
                        <span class="arrow next"><i class="fas fa-chevron-right"></i></span>
                    </span>` : ''}
                    <span class="check ${S.hidden.has(e.Id) ? 'unchecked' : ''}"><i class="fas fa-check"></i></span>`;

                row.addEventListener('click', () => { select(rowIndex); focusSelected(); });
                row.querySelector('.check').addEventListener('click', (ev) => { ev.stopPropagation(); toggleEntry(e.Id); });
                const prev = row.querySelector('.prev'), next = row.querySelector('.next');
                if (prev) prev.addEventListener('click', (ev) => { ev.stopPropagation(); select(rowIndex); cycle(-1); });
                if (next) next.addEventListener('click', (ev) => { ev.stopPropagation(); select(rowIndex); cycle(1); });

                rows.appendChild(row);
            }
            sec.appendChild(rows);
            legendEl.appendChild(sec);
        }

        if (!S.visibleRows.length) legendEl.innerHTML = `<div class="empty">No locations found</div>`;

        if (prevSelected) S.selected = S.visibleRows.indexOf(prevSelected);
        else if (S.selected >= S.visibleRows.length) S.selected = -1;
        paintSelection();
    };

    const paintSelection = () => {
        youRow.classList.toggle('selected', S.selected === -1);
        legendEl.querySelectorAll('.row').forEach((r) => {
            const on = Number(r.dataset.index) === S.selected;
            r.classList.toggle('selected', on);
            if (on) r.scrollIntoView({ block: 'nearest' });
        });
    };

    const updateCounts = () => {
        legendEl.querySelectorAll('.row').forEach((r) => {
            const id = S.visibleRows[Number(r.dataset.index)];
            const c = r.querySelector('.count');
            if (c && S.byCat[id]) c.textContent = `${pad((S.cycle[id] || 0) + 1)}/${pad(S.byCat[id].length)}`;
        });
    };

    const setFocusBlip = (b) => {
        S.focusBlip = b;
        markerEls.forEach((m) => m.el.classList.toggle('focused', m.blip === b));
    };

    const select = (i) => {
        S.selected = Math.max(-1, Math.min(S.visibleRows.length - 1, i));
        paintSelection();
    };

    const focusSelected = () => {
        const id = selectedEntryId();
        if (!id) { setFocusBlip(null); focusWorld(S.player.x, S.player.y); locate(S.player.x, S.player.y); return; }
        const b = (S.byCat[id] || [])[S.cycle[id] || 0];
        if (!b) return;
        setFocusBlip(S.hidden.has(id) ? null : b);
        focusWorld(b.x, b.y, 0.55);
        locate(b.x, b.y);
    };

    const cycle = (dir) => {
        const id = selectedEntryId();
        if (!id) return;
        const n = (S.byCat[id] || []).length;
        if (n < 1) return;
        S.cycle[id] = ((S.cycle[id] || 0) + dir + n) % n;
        updateCounts();
        focusSelected();
        post('sound', { name: 'nav' });
    };

    const toggleEntry = (id) => {
        if (S.hidden.has(id)) S.hidden.delete(id); else S.hidden.add(id);
        onHiddenChanged();
    };

    const onHiddenChanged = () => {
        store.set('hidden', [...S.hidden]);
        if (S.focusBlip && S.hidden.has(S.focusBlip.cat)) S.focusBlip = null;
        buildLegend();
        buildMarkers();
        post('sound', { name: 'toggle' });
    };

    // ---------------------------------------------------------------------
    // Input
    // ---------------------------------------------------------------------
    let drag = null;

    viewport.addEventListener('mousedown', (e) => {
        if (e.button !== 0) return;
        drag = { x: e.clientX, y: e.clientY, moved: false, start: { ...(S.target || S.view) } };
        S.target = null;
    });

    window.addEventListener('mousemove', (e) => {
        if (!S.open) return;
        if (e.target.closest && e.target.closest('#viewport')) {
            locate(...imgToWorld(...screenToImg(e.clientX, e.clientY)));
        }
        if (!drag) return;
        const dx = e.clientX - drag.x, dy = e.clientY - drag.y;
        if (!drag.moved && Math.hypot(dx, dy) > 4) { drag.moved = true; viewport.classList.add('dragging'); }
        if (drag.moved) {
            S.view.cx = drag.start.cx - dx / S.view.scale;
            S.view.cy = drag.start.cy - dy / S.view.scale;
            clampView(S.view);
            S.dirty = true;
        }
    });

    window.addEventListener('mouseup', (e) => {
        if (!drag) return;
        const wasDrag = drag.moved;
        drag = null;
        viewport.classList.remove('dragging');
        if (wasDrag || e.button !== 0 || !e.target.closest('#viewport')) return;
        handleMapClick(e.clientX, e.clientY);
    });

    const removeWaypoint = () => {
        S.waypoint = null;
        S.route = null;
        updateRouteInfo();
        S.dirty = true;
        post('removeWaypoint');
    };

    viewport.addEventListener('contextmenu', (e) => {
        e.preventDefault();
        if (S.waypoint) removeWaypoint();
    });

    const handleMapClick = (sx, sy) => {
        if (S.waypoint) {
            const [wx, wy] = worldToScreen(S.waypoint.x, S.waypoint.y);
            if (Math.hypot(wx - sx, wy - sy) < window.innerHeight * 0.03) return removeWaypoint();
        }
        const [x, y] = imgToWorld(...screenToImg(sx, sy));
        S.waypoint = { x, y };
        S.route = null;          // new route arrives from Lua once GTA has calculated it
        updateRouteInfo();
        S.dirty = true;
        post('setWaypoint', { x, y });
    };

    viewport.addEventListener('wheel', (e) => {
        e.preventDefault();
        zoomAt(e.deltaY < 0 ? 1.25 : 0.8, e.clientX, e.clientY);
    }, { passive: false });

    youRow.addEventListener('click', () => { select(-1); focusSelected(); });
    searchEl.addEventListener('input', () => { S.selected = -1; buildLegend(); });

    document.addEventListener('keydown', (e) => {
        if (!S.open) return;
        const typing = document.activeElement === searchEl;

        if (e.key === 'Escape' || (e.key === 'Backspace' && !typing)) { e.preventDefault(); close(); return; }
        if (typing) {
            if (e.key === 'Enter' || e.key === 'ArrowDown' || e.key === 'ArrowUp') searchEl.blur(); else return;
        }

        switch (e.key) {
            case 'ArrowUp': e.preventDefault(); select(S.selected - 1); focusSelected(); post('sound', { name: 'nav' }); break;
            case 'ArrowDown': e.preventDefault(); select(S.selected + 1); focusSelected(); post('sound', { name: 'nav' }); break;
            case 'ArrowLeft': e.preventDefault(); cycle(-1); break;
            case 'ArrowRight': e.preventDefault(); cycle(1); break;
            case 'PageUp': case '+': case '=': e.preventDefault(); zoomAt(1.4); break;
            case 'PageDown': case '-': e.preventDefault(); zoomAt(1 / 1.4); break;
            case 't': case 'T': { const id = selectedEntryId(); if (id) toggleEntry(id); break; }
            case 'Enter': focusSelected(); break;
            default:
                // start typing anywhere -> jump into search
                if (e.key.length === 1 && /[a-z0-9]/i.test(e.key) && !e.ctrlKey) searchEl.focus();
        }
    });

    window.addEventListener('resize', () => { S.dirty = true; });

    // ---------------------------------------------------------------------
    // Open / close / data
    // ---------------------------------------------------------------------
    const setBlips = (blips) => {
        S.blips = blips || [];
        if (S.focusBlip) {
            const f = S.focusBlip;
            S.focusBlip = S.blips.find((b) => b.cat === f.cat && Math.abs(b.x - f.x) < 2 && Math.abs(b.y - f.y) < 2) || null;
        }
        groupBlips();
    };

    const setRoute = (route) => {
        // a straight-line fallback has a single point (the waypoint); the line starts at the player
        S.route = route && route.points && route.points.length >= 1 ? route : null;
        updateRouteInfo();
        S.dirty = true;
    };

    let lastBlipSig = '';

    const open = (data) => {
        S.legend = data.legend || [];
        S.entryById = {};
        for (const s of S.legend) for (const e of s.Entries) S.entryById[e.Id] = e;
        S.player = data.player || S.player;
        S.origin = { ...S.player };
        S.waypoint = data.waypoint || null;
        S.selected = -1;
        S.focusBlip = null;
        searchEl.value = '';
        if (data.waypointColor) document.documentElement.style.setProperty('--waypoint', data.waypointColor);
        $('exit-label').textContent = data.back ? 'Back' : 'Exit';

        lastBlipSig = JSON.stringify(data.blips || []);
        setBlips(data.blips);
        setRoute(data.route);
        app.classList.remove('hidden');
        S.open = true;

        const [ix, iy] = worldToImg(S.player.x, S.player.y);
        S.view = clampView({ cx: ix, cy: iy, scale: store.get('scale', 0.6) });
        S.target = null;

        buildLegend();
        buildMarkers();
        setLocation('-', '');
        locate(S.player.x, S.player.y);
        S.dirty = true;
    };

    const close = () => {
        if (!S.open) return;
        S.open = false;
        hideTooltip();
        searchEl.blur();
        app.classList.add('hidden');
        post('close');
    };

    window.addEventListener('message', (ev) => {
        const d = ev.data || {};
        switch (d.action) {
            case 'open': open(d); break;
            case 'close': S.open = false; hideTooltip(); app.classList.add('hidden'); break;
            case 'player': if (d.player) { S.player = d.player; S.playerDirty = true; } break;
            case 'route': if (S.open) setRoute(d.route); break;
            case 'blips': {
                if (!S.open) break;
                const wp = d.waypoint || null;
                if ((wp ? 1 : 0) !== (S.waypoint ? 1 : 0) || (wp && S.waypoint && (Math.abs(wp.x - S.waypoint.x) > 1 || Math.abs(wp.y - S.waypoint.y) > 1))) {
                    S.waypoint = wp;
                    if (!wp) setRoute(null);
                    S.dirty = true;
                }
                const sig = JSON.stringify(d.blips || []);
                if (sig === lastBlipSig) break;      // nothing changed -> no DOM work
                lastBlipSig = sig;
                setBlips(d.blips);
                buildLegend();
                buildMarkers();
                break;
            }
        }
    });

    requestAnimationFrame(tick);
})();
