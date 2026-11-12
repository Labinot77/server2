<div {...$$restProps} class="phone-paperlist {$$restProps.class}">
    <slot />
</div>

<style>
    .phone-paperlist {
        position: absolute;
        top: 9.7vh;
        left: 0;
        right: 0;
        margin: 0 auto;
        width: 90%;
        height: 46.5vh;
        overflow-y: auto;
    }

    .phone-paperlist::-webkit-scrollbar { display: none; }
</style>
