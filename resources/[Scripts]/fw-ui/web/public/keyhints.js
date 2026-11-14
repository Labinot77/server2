// Bottom-right key hints for placement / aim modes (plain JS so it survives Svelte rebuilds).
// Lua: exports['fw-ui']:ShowKeyHints({ { 'E', 'Place' }, { { 'PGUP', 'PGDN' }, 'Height' }, { '', 'Info only' } }) / HideKeyHints()
(() => {
    const Glyphs = {
        SPACE: '<i class="kh-space"></i>',
        BACKSPACE: '<i class="fas fa-backspace"></i>',
        SCROLL: '<i class="fas fa-mouse"></i>',
        UP: '<i class="fas fa-arrow-up"></i>',
        DOWN: '<i class="fas fa-arrow-down"></i>',
        LEFT: '<i class="fas fa-arrow-left"></i>',
        RIGHT: '<i class="fas fa-arrow-right"></i>',
    };

    const Esc = (Str) => String(Str).replace(/[&<>"]/g, (C) => `&#${C.charCodeAt(0)};`);
    const Key = (K) => `<span class="kh-key">${Glyphs[String(K).toUpperCase()] || Esc(K)}</span>`;

    const Root = document.createElement('div');
    Root.id = 'key-hints';
    document.body.appendChild(Root);

    window.addEventListener('message', ({ data }) => {
        if (data.App !== 'KeyHints') return;
        if (data.Action === 'Hide') return Root.classList.remove('show');

        Root.innerHTML = (data.Payload || []).map(([Keys, Label]) => `<div class="kh-item">${
            [].concat(Keys || []).filter(Boolean).map(Key).join('')}<span>${Esc(Label || '')}</span></div>`).join('');
        Root.classList.add('show');
    });
})();
