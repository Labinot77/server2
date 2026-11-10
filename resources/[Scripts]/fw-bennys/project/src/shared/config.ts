// Prices are flat per slot unless a tier array is given (index = mod level, -1/stock is free).
export const Config = {
    // Discount applied when the player works at a mechanic business (not used yet, payment is a console.log for now).
    MechanicMultiplier: 0.7,

    Prices: {
        Repair: 0, // calculated from damage, see menu.ts
        ColorType: 500,
        Color: 500,
        Wheels: 650,
        WindowTint: 400,
        PlateIndex: 350,
        Xenon: 500,
        XenonColor: 450,
        Neon: 550,
        NeonColor: 450,
        Turbo: 15000,
        Livery: 300,
        Extra: 150,
        Stance: 850,

        // Visual mods (keyed by GTA mod type)
        Mods: {
            0: 750,  // Spoiler
            1: 600,  // Front Bumper
            2: 600,  // Rear Bumper
            3: 550,  // Skirts
            4: 550,  // Exhaust
            5: 500,  // Frame / Rollcage
            6: 500,  // Grille
            7: 600,  // Hood
            8: 450,  // Left Fender
            9: 450,  // Right Fender
            10: 600, // Roof
            14: 300, // Horns
            25: 250, 26: 250, 27: 350, 28: 250, 29: 350, 30: 300, 31: 300, 32: 400,
            33: 350, 34: 300, 35: 250, 36: 350, 37: 400, 38: 1500, 39: 450, 40: 400,
            41: 450, 42: 350, 43: 250, 44: 350, 45: 400, 46: 300, 48: 300,
        } as Record<number, number>,

        // Performance tiers, index = mod level (0 = level 1)
        Performance: {
            11: [3250, 5500, 10450, 15250, 20500], // Engine
            12: [3250, 5500, 10450, 15250, 20500], // Brakes
            13: [3250, 5500, 10450, 15250, 20500], // Transmission
            15: [3250, 5500, 10450, 15250, 20500], // Suspension
            16: [3250, 5500, 10450, 15250, 20500], // Armor
        } as Record<number, number[]>,
    },

    // Stancer limits (wheel offsets are in metres from the vehicle centre, camber in radians).
    Stance: {
        Spacers: { Min: 0.45, Max: 1.25, Step: 0.01 },
        Camber: { Min: 0.0, Max: 0.35, Step: 0.01 },
        Width: { Min: 0.5, Max: 1.25, Step: 0.01 },
        Suspension: { Min: -0.12, Max: 0.12, Step: 0.005 },
    },
};

export const WheelTypes: Array<{ Id: number; Label: string }> = [
    { Id: 0, Label: "Sport" },
    { Id: 1, Label: "Muscle" },
    { Id: 2, Label: "Lowrider" },
    { Id: 3, Label: "SUV" },
    { Id: 4, Label: "Offroad" },
    { Id: 5, Label: "Tuner" },
    { Id: 7, Label: "High End" },
    { Id: 8, Label: "Benny's Original" },
    { Id: 9, Label: "Benny's Bespoke" },
    { Id: 10, Label: "Open Wheel" },
    { Id: 11, Label: "Street" },
    { Id: 12, Label: "Track" },
];

export const WindowTints = [
    { Label: "None", Value: 0 },
    { Label: "Pure Black", Value: 1 },
    { Label: "Dark Smoke", Value: 2 },
    { Label: "Light Smoke", Value: 3 },
    { Label: "Limo", Value: 5 },
    { Label: "Green", Value: 6 },
];

export const PlateIndexes = [
    { Label: "Blue on White 1", Value: 0 },
    { Label: "Yellow on Black", Value: 1 },
    { Label: "Yellow on Blue", Value: 2 },
    { Label: "Blue on White 2", Value: 3 },
    { Label: "Blue on White 3", Value: 4 },
    { Label: "Yankton", Value: 5 },
];

export const XenonColors = [
    { Label: "Stock", Value: -1 },
    { Label: "White", Value: 0 },
    { Label: "Blue", Value: 1 },
    { Label: "Electric Blue", Value: 2 },
    { Label: "Mint Green", Value: 3 },
    { Label: "Lime Green", Value: 4 },
    { Label: "Yellow", Value: 5 },
    { Label: "Golden Shower", Value: 6 },
    { Label: "Orange", Value: 7 },
    { Label: "Red", Value: 8 },
    { Label: "Pony Pink", Value: 9 },
    { Label: "Hot Pink", Value: 10 },
    { Label: "Purple", Value: 11 },
    { Label: "Blacklight", Value: 12 },
];

// [Left, Right, Front, Back]
export const NeonLayouts: Array<{ Label: string; Value: boolean[] }> = [
    { Label: "Off", Value: [false, false, false, false] },
    { Label: "Front", Value: [false, false, true, false] },
    { Label: "Back", Value: [false, false, false, true] },
    { Label: "Sides", Value: [true, true, false, false] },
    { Label: "Front & Back", Value: [false, false, true, true] },
    { Label: "Front & Sides", Value: [true, true, true, false] },
    { Label: "Back & Sides", Value: [true, true, false, true] },
    { Label: "All Around", Value: [true, true, true, true] },
];

// Paint finishes for primary / secondary (GTA paint types).
export const PaintTypes = [
    { Label: "Normal", Value: 0 },
    { Label: "Metallic", Value: 1 },
    { Label: "Pearl", Value: 2 },
    { Label: "Matte", Value: 3 },
    { Label: "Metal", Value: 4 },
    { Label: "Chrome", Value: 5 },
];

// GTA colour index -> hex, used to map the colour picker onto indexed colours
// (pearlescent, wheels, dashboard, interior) and to show the current colour.
export const ColorPalette: string[] = [
    "#0d1116", "#1c1d21", "#32383d", "#454b4f", "#999da0", "#c2c4c6", "#979a97", "#637380", "#63625c", "#3c3f47",
    "#444e54", "#1d2129", "#13181f", "#26282a", "#515554", "#151921", "#1e2429", "#333a3c", "#8c9095", "#39434d",
    "#506272", "#1e232f", "#363a3f", "#a0a199", "#d3d3d3", "#b7bfca", "#778794", "#c00e1a", "#da1918", "#b6111b",
    "#a51e23", "#7b1a22", "#8e1b1f", "#6f1818", "#49111d", "#b60f25", "#d44a17", "#c2944f", "#f78616", "#cf1f21",
    "#732021", "#f27d20", "#ffc91f", "#9c1016", "#de0f18", "#8f1e17", "#a94744", "#b16c51", "#371c25", "#132428",
    "#122e2b", "#12383c", "#31423f", "#155c2d", "#1b6770", "#66b81f", "#22383e", "#1d5a3f", "#2d423f", "#45594b",
    "#65867f", "#222e46", "#233155", "#304c7e", "#47578f", "#637ba7", "#394762", "#d6e7f1", "#76afbe", "#345e72",
    "#0b9cf1", "#2f2d52", "#282c4d", "#2354a1", "#6ea3c6", "#112552", "#1b203e", "#275190", "#608592", "#2446a8",
    "#4271e1", "#3b39e0", "#1f2852", "#253aa7", "#1c3551", "#4c5f81", "#58688e", "#74b5d8", "#ffcf20", "#fbe212",
    "#916532", "#e0e13d", "#98d223", "#9b8c78", "#503218", "#473f2b", "#221b19", "#653f23", "#775c3e", "#ac9975",
    "#6c6b4b", "#402e2b", "#a4965f", "#46231a", "#752b19", "#bfae7b", "#dfd5b2", "#f7edd5", "#3a2a1b", "#785f33",
    "#b5a079", "#fffff6", "#eaeaea", "#b0ab94", "#453831", "#2a282b", "#726c57", "#6a747c", "#354158", "#9ba0a8",
    "#5870a1", "#eae6de", "#dfddd0", "#f2ad2e", "#f9a458", "#83c566", "#f1cc40", "#4cc3da", "#4e6443", "#bcac8f",
    "#f8b658", "#fcf9f1", "#fffffb", "#81844c", "#ffffff", "#f21f99", "#fdd6cd", "#df5891", "#f6ae20", "#b0ee6e",
    "#08e9fa", "#0a0c17", "#0c0d18", "#0e0d14", "#9f9e8a", "#621276", "#0b1421", "#11141a", "#6b1f7b", "#1e1d22",
    "#bc1917", "#2d362a", "#696748", "#7a6c55", "#c3b492", "#5a6352", "#81827f", "#afd6e4", "#7a6440", "#7f6a48",
];
