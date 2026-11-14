<script>
    import { Icons } from "../icons";
    export let Name = "";
</script>

<svg class="ic {$$restProps.class || ''}" viewBox="0 0 24 24">{@html Icons[Name] || ""}</svg>

<style>
    .ic {
        width: 1.4vh;
        height: 1.4vh;
        flex: none;
        fill: none;
        stroke: currentColor;
        stroke-width: 2;
        stroke-linecap: round;
        stroke-linejoin: round;
    }
</style>
