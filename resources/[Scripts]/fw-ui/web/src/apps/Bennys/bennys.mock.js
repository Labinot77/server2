// Browser-only mock of the fw-bennys_wip client, so the UI can be developed with `npm run dev`.
import { IsEnvBrowser } from "../../utils/Utils";

const Palette = ["#0d1116", "#1c1d21", "#32383d", "#454b4f", "#999da0", "#c2c4c6", "#979a97", "#637380", "#63625c", "#3c3f47", "#444e54", "#1d2129", "#13181f", "#26282a", "#515554", "#151921", "#1e2429", "#333a3c", "#8c9095", "#39434d", "#506272", "#1e232f", "#363a3f", "#a0a199", "#d3d3d3", "#b7bfca", "#778794", "#c00e1a", "#da1918", "#b6111b", "#a51e23", "#7b1a22", "#8e1b1f", "#6f1818", "#49111d", "#b60f25", "#d44a17", "#c2944f", "#f78616", "#cf1f21", "#732021", "#f27d20", "#ffc91f", "#9c1016", "#de0f18", "#8f1e17", "#a94744", "#b16c51", "#371c25", "#132428", "#122e2b", "#12383c", "#31423f", "#155c2d", "#1b6770", "#66b81f", "#22383e", "#1d5a3f", "#2d423f", "#45594b", "#65867f", "#222e46", "#233155", "#304c7e", "#47578f", "#637ba7", "#394762", "#d6e7f1", "#76afbe", "#345e72", "#0b9cf1", "#2f2d52", "#282c4d", "#2354a1", "#6ea3c6", "#112552", "#1b203e", "#275190", "#608592", "#2446a8", "#4271e1", "#3b39e0", "#1f2852", "#253aa7", "#1c3551", "#4c5f81", "#58688e", "#74b5d8", "#ffcf20", "#fbe212", "#916532", "#e0e13d", "#98d223", "#9b8c78", "#503218", "#473f2b", "#221b19", "#653f23", "#775c3e", "#ac9975", "#6c6b4b", "#402e2b", "#a4965f", "#46231a", "#752b19", "#bfae7b", "#dfd5b2", "#f7edd5", "#3a2a1b", "#785f33", "#b5a079", "#fffff6", "#eaeaea", "#b0ab94", "#453831", "#2a282b", "#726c57", "#6a747c", "#354158", "#9ba0a8", "#5870a1", "#eae6de", "#dfddd0", "#f2ad2e", "#f9a458", "#83c566", "#f1cc40", "#4cc3da", "#4e6443", "#bcac8f", "#f8b658", "#fcf9f1", "#fffffb", "#81844c", "#ffffff", "#f21f99", "#fdd6cd", "#df5891", "#f6ae20", "#b0ee6e", "#08e9fa", "#0a0c17", "#0c0d18", "#0e0d14", "#9f9e8a", "#621276", "#0b1421", "#11141a", "#6b1f7b", "#1e1d22", "#bc1917", "#2d362a", "#696748", "#7a6c55", "#c3b492", "#5a6352", "#81827f", "#afd6e4", "#7a6440", "#7f6a48"];

const Parts = (Count, Price, Prefix = "Part") => [
    { Label: "Stock", Value: -1, Price: 0 },
    ...Array.from({ length: Count }, (_, I) => ({ Label: `${Prefix} ${I + 1}`, Value: I, Price })),
];

const Mod = (Type, Label, Description, Icon, Camera, Count, Price) => ({
    Type: "Options", Id: `Mod:${Type}`, Slot: `Mod:${Type}`, Label, Description, Icon, Camera, Options: Parts(Count, Price),
});

const Tiers = [3250, 5500, 10450, 15250, 20500];
const Perf = (Type, Label, Description, Icon) => ({
    Type: "Options", Id: `Mod:${Type}`, Slot: `Mod:${Type}`, Label, Description, Icon, Camera: "default",
    Options: [{ Label: "Stock", Value: -1, Price: 0 }, ...Tiers.slice(0, 4).map((Price, I) => ({ Label: `Level ${I + 1}`, Value: I, Price }))],
});

const Wheels = (Type, Label, Count) => ({
    Type: "Options", Id: `Wheels:${Type}`, Slot: "Wheels", Label, Description: `${Count} rims`, Icon: "fas fa-tire-rugged", Camera: "wheel",
    Options: [{ Label: "Stock", Value: { Type, Index: -1 }, Price: 0 }, ...Array.from({ length: Count }, (_, I) => ({ Label: `Rim ${I + 1}`, Value: { Type, Index: I }, Price: 650 }))],
});

const Slider = (Id, Label, Description, Icon, Camera, Sliders) => ({ Type: "Slider", Id, Label, Description, Icon, Camera, Price: 850, Sliders });

export const MockPayload = {
    Header: "Los Santos Benny's",
    SubHeader: "Motorworks for everyone",
    Palette,
    PaintTypes: [
        { Label: "Normal", Value: 0 }, { Label: "Metallic", Value: 1 }, { Label: "Pearl", Value: 2 },
        { Label: "Matte", Value: 3 }, { Label: "Metal", Value: 4 }, { Label: "Chrome", Value: 5 },
    ],
    Current: {
        "Mod:0": -1, "Mod:1": -1, "Mod:2": -1, "Mod:3": -1, "Mod:4": -1, "Mod:7": -1, "Mod:10": -1,
        "Mod:11": -1, "Mod:12": -1, "Mod:13": -1, "Mod:15": -1,
        "Wheels": { Type: 0, Index: -1 }, "Repair": false, "WindowTint": 0, "Xenon": false, "XenonColor": -1,
        "Neon": [false, false, false, false], "NeonColor": "#ff00ff", "TyreSmoke": "#ffffff",
        "Color:Primary": "#c00e1a", "Color:Secondary": "#0d1116", "ColorType:Primary": 1, "ColorType:Secondary": 0,
        "Color:Pearlescent": 5, "Color:Wheels": 156, "Color:Dashboard": 0, "Color:Interior": 0,
        "Stance:SpacersFront": 0.82, "Stance:SpacersRear": 0.8, "Stance:CamberFront": 0, "Stance:CamberRear": 0,
        "Stance:Width": 0.75, "Stance:Suspension": 0,
    },
    Categories: [
        {
            Id: "Customization", Label: "Customization", Description: "Personalized vehicles, boundless creativity", Icon: "fas fa-car-garage",
            Items: [
                { Type: "Action", Id: "Repair", Slot: "Repair", Value: true, Label: "Repair", Description: "Fix body & engine", Icon: "fas fa-wrench", Price: 412 },
                {
                    Type: "Menu", Id: "Colors", Label: "Colors", Description: "Paint your vehicle", Icon: "fas fa-fill-drip", Camera: "default",
                    Children: [
                        { Type: "Color", Id: "Color:Primary", Slot: "Color:Primary", Mode: "Custom", Label: "Primary", Description: "Select", Icon: "fas fa-paint-brush", Price: 500, TypeSlot: "ColorType:Primary", TypePrice: 500 },
                        { Type: "Color", Id: "Color:Secondary", Slot: "Color:Secondary", Mode: "Custom", Label: "Secondary", Description: "Select", Icon: "fas fa-paint-brush-alt", Price: 500, TypeSlot: "ColorType:Secondary", TypePrice: 500 },
                        { Type: "Color", Id: "TyreSmoke", Slot: "TyreSmoke", Mode: "RGB", Label: "Wheel Smoke", Description: "Select", Icon: "fas fa-smog", Price: 500 },
                        { Type: "Color", Id: "Color:Dashboard", Slot: "Color:Dashboard", Mode: "Index", Label: "Dashboard", Description: "Select", Icon: "fas fa-tachometer-alt", Price: 500 },
                        { Type: "Color", Id: "Color:Wheels", Slot: "Color:Wheels", Mode: "Index", Label: "Wheels", Description: "Select", Icon: "fas fa-tire", Price: 500 },
                        { Type: "Color", Id: "Color:Pearlescent", Slot: "Color:Pearlescent", Mode: "Index", Label: "Pearlescence", Description: "Select", Icon: "fas fa-sparkles", Price: 500 },
                    ],
                },
                Mod(0, "Spoiler", "Aero Enhancement", "fas fa-wind", "rear", 9, 750),
                Mod(1, "Front Bumper", "Impact Defense", "fas fa-car", "front", 4, 600),
                Mod(2, "Rear Bumper", "Stylish Protection", "fas fa-car-bump", "rear", 3, 600),
                Mod(3, "Skirts", "Sleek", "fas fa-car-side", "side", 2, 550),
                Mod(4, "Exhaust", "Engine's Roar", "fas fa-burn", "rear", 5, 550),
                Mod(7, "Hood", "Bonnet Styling", "fas fa-car-mechanic", "front", 6, 600),
                Mod(10, "Roof", "Top Styling", "fas fa-arrow-to-top", "top", 2, 600),
                { Type: "Menu", Id: "Wheels", Label: "Wheels", Description: "Rims & Tyres", Icon: "fas fa-tire", Camera: "wheel", Children: [Wheels(0, "Sport", 24), Wheels(1, "Muscle", 18), Wheels(7, "High End", 20)] },
                {
                    Type: "Menu", Id: "Performance", Label: "Performance", Description: "Engine & Handling", Icon: "fas fa-tachometer-alt-fastest", Camera: "default",
                    Children: [Perf(11, "Engine", "Raw Power", "fas fa-cogs"), Perf(12, "Brakes", "Stopping Power", "fas fa-compact-disc"), Perf(13, "Transmission", "Faster Shifts", "fas fa-random"), Perf(15, "Suspension", "Handling", "fas fa-sort-amount-down")],
                },
                {
                    Type: "Menu", Id: "Lights", Label: "Lighting", Description: "Xenons & Neons", Icon: "fas fa-lightbulb-on", Camera: "front",
                    Children: [
                        { Type: "Options", Id: "Xenon", Slot: "Xenon", Label: "Xenon Headlights", Description: "Bright Lights", Icon: "fas fa-lightbulb", Options: [{ Label: "Stock", Value: false, Price: 0 }, { Label: "Xenon", Value: true, Price: 500 }] },
                        { Type: "Color", Id: "NeonColor", Slot: "NeonColor", Mode: "RGB", Label: "Neon Color", Description: "Select", Icon: "fas fa-palette", Price: 450 },
                    ],
                },
                { Type: "Options", Id: "WindowTint", Slot: "WindowTint", Label: "Window Tint", Description: "Privacy", Icon: "fas fa-window-maximize", Options: ["None", "Pure Black", "Dark Smoke", "Light Smoke", "Limo", "Green"].map((Label, Value) => ({ Label, Value, Price: 400 })) },
            ],
        },
        {
            Id: "Stancer", Label: "Stancer", Description: "Stancer style, daring wheel artistry", Icon: "fas fa-tire",
            Items: [
                Slider("Spacers", "Spacers", "Wheel Spacers", "fas fa-arrows-alt-h", "wheel", [
                    { Slot: "Stance:SpacersFront", Label: "Front", Description: "Ratio Left | Ratio Right", Min: 0.45, Max: 1.25, Step: 0.01 },
                    { Slot: "Stance:SpacersRear", Label: "Rear", Description: "Ratio Left | Ratio Right", Min: 0.45, Max: 1.25, Step: 0.01 },
                ]),
                Slider("Camber", "Camber", "Wheel Camber", "fas fa-slash", "front", [
                    { Slot: "Stance:CamberFront", Label: "Front", Description: "Wheel Angle", Min: 0, Max: 0.35, Step: 0.01 },
                    { Slot: "Stance:CamberRear", Label: "Rear", Description: "Wheel Angle", Min: 0, Max: 0.35, Step: 0.01 },
                ]),
                Slider("Width", "Width", "Wheel Width", "fas fa-expand-alt", "wheel", [{ Slot: "Stance:Width", Label: "All Wheels", Description: "Requires custom rims", Min: 0.5, Max: 1.25, Step: 0.01 }]),
                Slider("Suspension", "Suspension", "Height of the vehicle", "fas fa-sort-amount-down-alt", "side", [{ Slot: "Stance:Suspension", Label: "Height", Description: "Raise | Lower", Min: -0.12, Max: 0.12, Step: 0.005 }]),
            ],
        },
    ],
};

// ---------- Fake client ----------

let Pending = {};
let Labels = {};
let Prices = {};

const Emit = (Action, Payload) => window.dispatchEvent(new MessageEvent("message", { data: { App: "Bennys", Action, Payload } }));

const SyncCart = () => {
    const Cart = Object.keys(Pending).map(Slot => ({ Slot, ...Labels[Slot], Value: Pending[Slot], Price: Prices[Slot] || 0 }));
    Emit("SetCart", { Cart, Current: { ...MockPayload.Current, ...Pending } });
};

export const MockRequest = (Event, Data) => {
    switch (Event) {
        case "Preview":
            if (JSON.stringify(MockPayload.Current[Data.Slot]) === JSON.stringify(Data.Value)) delete Pending[Data.Slot];
            else Pending[Data.Slot] = Data.Value;
            Labels[Data.Slot] = { Label: Data.Label, Option: Data.Option };
            Prices[Data.Slot] = Data.Price;
            return SyncCart();
        case "Revert":
            delete Pending[Data.Slot];
            return SyncCart();
        case "Checkout":
            console.log("[fw-bennys] Checkout (mock)", Data.Method, { ...Pending });
            Pending = {};
            return Emit("SetVisibility", { Visibility: false });
        case "Close":
            Pending = {};
            return Emit("SetVisibility", { Visibility: false });
        default:
            // console.log("[bennys mock]", Event, Data);
            return;
    }
};

export const StartMock = () => {
    if (!IsEnvBrowser()) return;
    const Params = new URLSearchParams(window.location.search);
    if (!Params.has("bennys")) return;
    setTimeout(() => {
        Emit("Open", MockPayload);
        Emit("SetVisibility", { Visibility: true });
    }, 300);
};
