<script>
    import AppWrapper from "../../components/AppWrapper.svelte";
    import { OnEvent, SendEvent } from "../../utils/Utils";

    let Visible = false;
    let Label = "";
    let Duration = 0;
    let RunId = 0; // re-creates the fill element so the animation restarts

    OnEvent("Progressbar", "Progress", (Data) => {
        Label = Data.Label || "";
        Duration = Data.Duration || 0;
        RunId++;
        Visible = true;
    });

    OnEvent("Progressbar", "Cancel", () => {
        Visible = false;
    });

    const OnFinished = () => {
        if (!Visible) return;
        Visible = false;
        SendEvent("Progressbar/Finish", {});
    };
</script>

<AppWrapper AppName="Progressbar" Focused={false}>
    {#if Visible}
        <div class="progress-bar-container">
            <div class="progressbar-text">{Label}</div>
            
            <div class="progress-bar">
                {#key RunId}
                    <div
                        class="progress-bar__fill"
                        style="animation-duration: {Duration}ms"
                        on:animationend={OnFinished}
                    ></div>
                {/key}
            </div>
        </div>
    {/if}
</AppWrapper>

<style>
@import url("https://fonts.googleapis.com/css2?family=Barlow+Condensed:ital,wght@0,600;0,700;1,600;1,700&display=swap");

.progress-bar-container {
    display: flex;
    flex-direction: column;
    justify-content: center;

    z-index: 5;
    color: #fff;
    width: 45vh;

    position: fixed;
    bottom: 4vh;
    left: 50%;

    margin-left: auto;
    margin-right: auto;

    font-family: "Barlow Condensed", sans-serif;

    transform: translateX(-50%);
    opacity: 0;

    animation: progress-in 0.28s ease-out forwards;
}

@keyframes progress-in {
    from {
        opacity: 0;
        transform: translate(-50%, 0.8vh);
        filter: blur(2px);
    }

    to {
        opacity: 1;
        transform: translate(-50%, 0);
        filter: blur(0);
    }
}

.progress-bar {
    background: rgba(0, 0, 0, 0.55);

    height: 0.8vh;
    width: 100%;

    position: relative;
    display: block;

    border-radius: 0.45vh;
    overflow: hidden;
}

.progress-bar__fill {
    background: linear-gradient(90deg, #22c3f0 0%, #2be6a8 100%);

    width: 0%;
    height: 100%;

    border-radius: 0.45vh;

    animation-name: progress-fill;
    animation-timing-function: linear;
    animation-fill-mode: forwards;

    box-shadow: 0 0 1.4vh rgba(43, 230, 168, 0.7);
}

@keyframes progress-fill {
    from {
        width: 0%;
    }

    to {
        width: 100%;
    }
}

.progressbar-text {
    margin-bottom: 1.4vh;

    font-size: 2.4vh;
    line-height: 1;

    position: relative;

    color: #f5f5f5;
    z-index: 10;

    font-weight: 700;
    font-style: italic;

    text-transform: uppercase;
    letter-spacing: 0.04em;

    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;

    text-shadow: 0 0.15vh 0.3vh rgba(0, 0, 0, 0.65);
    text-align: left;
}
</style>