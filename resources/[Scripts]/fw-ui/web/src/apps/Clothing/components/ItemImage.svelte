<script>
    // Walks a list of candidate URLs until one loads. The fallback slot stays visible until a
    // picture has actually loaded, so slow or missing pictures never leave an empty tile.
    // Remembers per list which URL worked so tiles that scroll back into view don't retry failed requests.
    import { Resolved } from "./resolved.js";

    export let Candidates = [];

    let Index = 0, Loaded = false, LastKey;
    $: Key = Candidates.join("|");
    $: if (Key !== LastKey) {
        LastKey = Key;
        Index = Resolved.has(Key) ? Resolved.get(Key) : 0;
        Loaded = false;
    }
    $: Src = Index < Candidates.length ? Candidates[Index] : undefined;

    const OnError = () => {
        Index += 1;
        if (Index >= Candidates.length) Resolved.set(Key, Index);
    };

    const OnLoad = () => {
        Resolved.set(Key, Index);
        Loaded = true;
    };
</script>

{#if !Loaded}
    <slot />
{/if}

{#if Src}
    {#key Src}
        <img src={Src} alt="" draggable="false" loading="lazy" on:load={OnLoad} on:error={OnError} style={Loaded ? "" : "position: absolute; width: 1px; height: 1px; opacity: 0;"} />
    {/key}
{/if}
