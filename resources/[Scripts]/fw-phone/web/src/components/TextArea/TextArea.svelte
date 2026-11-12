<script>
    import { onMount } from "svelte";

    export var Title = "No Title";
    export var Placeholder = "";
    export var MaxLength = 255;
    export let Value = "";
    export var Rows = 1;

    let TextArea;

    function updateTextareaHeight(event) {
        Value = TextArea.value;
        TextArea.style.height = "auto"; // reset the height to auto to avoid a scrollbar
        TextArea.style.height = TextArea.scrollHeight + 10 + "px"; // set the height to the scroll height
    }

    onMount(() => {
        TextArea.style.height = TextArea.scrollHeight + 10 + 'px';
    });
</script>

<div class="textarea-component-container">
    <p>{Title}</p>
    <textarea
        bind:this={TextArea}
        on:input={updateTextareaHeight}
        rows={Rows}
        placeholder={Placeholder}
        maxlength={MaxLength}>{Value}</textarea
    >

    <p class="subtext">{Value.length}/255</p>
</div>

<style>
    .textarea-component-container {
        width: 100%;
        margin-bottom: 1.2vh;
        font-size: 1.15vh;
        color: var(--phone-muted);
    }

    .textarea-component-container > p { margin: 0 0 0.5vh 0.3vh; font-weight: 500; }
    .textarea-component-container > p.subtext { margin: 0.4vh 0.3vh 0 0; text-align: right; font-size: 1vh; }

    .textarea-component-container > textarea {
        box-sizing: border-box;
        width: 100%;
        min-height: 3.4vh;
        padding: 0.9vh 1vh;
        border: none;
        outline: none;
        resize: none;
        border-radius: 1vh;
        background: var(--phone-card);
        color: white;
        font-family: Roboto;
        font-size: 1.4vh;
        transition: box-shadow 150ms;
    }

    .textarea-component-container > textarea:focus { box-shadow: 0 0 0 0.15vh var(--phone-accent); }
    .textarea-component-container > textarea::-webkit-scrollbar { display: none; }
</style>
