<script>
    import { LocalImage } from "../images";
    export let CheckoutLabel = "CHECKOUT";
</script>

<div class="keybinds">
    <div class="row">
        <div class="hint">
            <svg viewBox="0 0 24 28" class="mouse" fill="none" stroke="white" stroke-width="1.6"><path d="M5 11V9a7 7 0 0 1 7-7v9z" fill="white" stroke="none"/><rect x="5" y="2" width="14" height="24" rx="7"/><path d="M5 11h14M12 2v9"/></svg>
            <span>ROTATE PED</span>
        </div>
        <span class="sep">/</span>
        <div class="hint">
            <svg viewBox="0 0 24 28" class="mouse" fill="none" stroke="white" stroke-width="1.6"><path d="M19 11V9a7 7 0 0 0-7-7v9z" fill="white" stroke="none"/><rect x="5" y="2" width="14" height="24" rx="7"/><path d="M5 11h14M12 2v9"/></svg>
            <span>ORBIT CAMERA</span>
        </div>
        <span class="sep">/</span>
        <div class="hint">
            <svg viewBox="0 0 24 28" class="mouse" fill="none" stroke="white" stroke-width="1.6"><rect x="5" y="2" width="14" height="24" rx="7"/><path d="M5 11h14M12 2v9"/><rect x="10.2" y="4.5" width="3.6" height="5.5" rx="1.8" fill="white" stroke="none"/></svg>
            <span>ZOOM</span>
        </div>
    </div>
    <div class="row">
        <div class="hint"><span class="key">A</span><span class="key">D</span><span>TURN</span></div>
        <span class="sep">/</span>
        <div class="hint"><img src={LocalImage("keys/keyboard_escape.png")} alt="ESC" /><span>EXIT</span></div>
        <span class="sep">/</span>
        <div class="hint"><img src={LocalImage("keys/keyboard_tab.png")} alt="TAB" /><span>{CheckoutLabel}</span></div>
    </div>
</div>

<style>
    .keybinds { position: absolute; bottom: 16px; right: 48px; width: 428px; display: flex; flex-direction: column; gap: 12px; background: rgba(20, 22, 27, 0.85); padding: 12px 20px; pointer-events: none; }
    .row { display: flex; align-items: center; justify-content: space-between; }
    .hint { display: flex; align-items: center; gap: 8px; }
    .hint span:not(.key) { font-weight: 700; font-style: italic; font-size: 16px; text-transform: uppercase; line-height: 1; white-space: nowrap; }
    .sep { font-family: 'Barlow Condensed', sans-serif; font-size: 20px; color: rgba(255,255,255,.35); line-height: 1; }
    .mouse { height: 26px; width: 22px; flex-shrink: 0; }
    .hint img { height: 26px; width: auto; object-fit: contain; }
    .key { display: inline-flex; align-items: center; justify-content: center; width: 24px; height: 24px; background: white; color: #14161b; border-radius: 4px; font-weight: 700; font-size: 14px; }
</style>
