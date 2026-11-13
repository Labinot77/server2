// fw-dui typing. Include on a DUI page or desktop app: <script src="nui://fw-dui/html/keys.js"></script>
// Keys arrive as { action: "dui:key", data: { key } } and are typed into the focused input / textarea (works
// with React-controlled inputs). Every key is also dispatched on window as a "dui:key" event (detail = key).
(() => {
    const SetValue = (El, V) => {
        Object.getOwnPropertyDescriptor(Object.getPrototypeOf(El), "value").set.call(El, V);
        El.dispatchEvent(new Event("input", { bubbles: true }));
    };
    const Caret = (El, P) => { try { El.setSelectionRange(P, P); } catch {} };

    const Type = Key => {
        window.dispatchEvent(new CustomEvent("dui:key", { detail: Key }));
        const El = document.activeElement;
        if (!El || !("value" in El) || El.readOnly || El.disabled) return;
        El.dispatchEvent(new KeyboardEvent("keydown", { key: Key, bubbles: true }));

        const V = El.value;
        let A = V.length, B = V.length;
        try { if (El.selectionStart !== null) { A = El.selectionStart; B = El.selectionEnd; } } catch {}

        if (Key.length === 1) {
            if (El.maxLength > 0 && V.length - (B - A) >= El.maxLength) return;
            SetValue(El, V.slice(0, A) + Key + V.slice(B)); Caret(El, A + 1);
        } else if (Key === "Backspace" && (A !== B || A > 0)) {
            const S = A === B ? A - 1 : A;
            SetValue(El, V.slice(0, S) + V.slice(B)); Caret(El, S);
        } else if (Key === "Delete" && (A !== B || A < V.length)) {
            SetValue(El, V.slice(0, A) + V.slice(A === B ? A + 1 : B)); Caret(El, A);
        } else if (Key === "ArrowLeft") Caret(El, Math.max(0, A - 1));
        else if (Key === "ArrowRight") Caret(El, Math.min(V.length, B + 1));
        else if (Key === "Enter") {
            if (El.tagName === "TEXTAREA") { SetValue(El, V.slice(0, A) + "\n" + V.slice(B)); Caret(El, A + 1); }
            else El.form?.requestSubmit();
        }
    };

    window.addEventListener("message", E => {
        let M = E.data;
        if (typeof M === "string") { try { M = JSON.parse(M); } catch { return; } }
        if (M && M.action === "dui:key" && M.data) Type(String(M.data.key));
    });
})();
