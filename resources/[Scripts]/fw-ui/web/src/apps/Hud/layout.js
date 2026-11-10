// Layout elements that can be moved/scaled from /hudsettings (port of ELEMENTS in codera settings.js).
// `Origin` is the corner an element is anchored to, `Base` keeps a transform the stylesheet already used.
import { get } from "svelte/store";
import { HudSettings, LayoutRevision } from "./hud.store.js";

export const LayoutElements = [
    {
        Id: "compass",
        Label: "Minimap & compass",
        Origin: "left top",
        Base: "",
        BaseScale: 1,
        Measure: [
            { Sel: ".compass__ring" },
            { Sel: ".compass__degree" },
            { Sel: ".compass__zone" },
            { Sel: ".compass__street", Text: true },
            { Sel: ".compass__waypoint" },
        ],
    },
    {
        Id: "player",
        Label: "Health, armor & needs",
        Origin: "left bottom",
        Base: "",
        BaseScale: 1,
        Measure: [
            { Sel: ".player-hud" },
            { Sel: ".needs" },
        ],
    },
    {
        Id: "status",
        Label: "Stamina, oxygen & engine bars",
        Origin: "center bottom",
        Base: "translateX(-50%)",
        BaseScale: 1,
        Measure: [{ Sel: ".center-status" }],
    },
    {
        Id: "weapon",
        Label: "Ammo counter",
        Origin: "right top",
        Base: "",
        BaseScale: 1,
        Measure: [{ Sel: ".weapon-hud" }],
    },
    {
        Id: "vehicle",
        Label: "Speedometer",
        Origin: "right bottom",
        Base: "",
        BaseScale: 1,
        Measure: [
            { Sel: ".speedometer" },
            { Sel: ".icons" },
        ],
    },
];

const Apply = (Node, Definition, Settings) => {
    const Layout = Settings?.layout?.[Definition.Id];
    if (!Node || !Layout) return;

    const X = Layout.x * window.innerWidth;
    const Y = Layout.y * window.innerHeight;
    const Scale = Definition.BaseScale * Layout.scale;

    Node.style.transformOrigin = Definition.Origin;
    Node.style.transform = `translate(${X}px, ${Y}px) ${Definition.Base} scale(${Scale})`;

    LayoutRevision.update((Val) => Val + 1);
};

// Svelte action: <div use:Layout={"compass"}> keeps that node's transform in sync with HudSettings.
// The node must not have a Svelte-managed `style="..."` attribute (use style:prop directives instead),
// otherwise Svelte would overwrite the transform when that attribute updates.
export const Layout = (Node, Id) => {
    const Definition = LayoutElements.find((Val) => Val.Id == Id);
    if (!Definition) return {};

    const Update = () => Apply(Node, Definition, get(HudSettings));
    const Unsubscribe = HudSettings.subscribe(Update);

    window.addEventListener("resize", Update);

    return {
        destroy() {
            Unsubscribe();
            window.removeEventListener("resize", Update);
        },
    };
};
