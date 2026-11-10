// Menu layout of the illenium-appearance UI, mapped onto fw-clothes skin keys.

// Which tabs each fw-clothes menu type shows, and the one it opens on.
export const MenuTabs = {
    Creation: ["PEDS", "FACE & BODY", "FACE ADJUSTMENTS", "OVERLAYS", "HAIR", "APPAREL", "TATTOOS"],
    Clothes: ["PEDS", "APPAREL"],
    Barber: ["FACE & BODY", "FACE ADJUSTMENTS", "OVERLAYS", "HAIR"],
    Tattoos: ["TATTOOS"],
};

export const StartTab = { Creation: "FACE & BODY", Clothes: "APPAREL", Barber: "HAIR", Tattoos: "TATTOOS" };

// Apparel is two levels deep: folder -> item list.
export const ApparelFolders = {
    "OUTFITS": ["SAVED OUTFITS"],
    "CLOTHING": ["TOPS", "UNDERSHIRTS", "BOTTOMS", "SHOES"],
    "UPPER BODY ACCESSORIES": ["BODY ARMOR", "BAGS & PARACHUTES", "SCARFS & CHAINS", "DECALS"],
    "HAND & WRIST ACCESSORIES": ["GLOVES", "WATCHES", "BRACELETS"],
    "HEAD ACCESSORIES": ["MASKS", "HATS", "GLASSES", "EARS"],
};

export const TabItems = {
    "PEDS": ["PED MODELS", "CUSTOM PEDS"],
    "FACE & BODY": ["HEAD BLEND", "EYE COLOR"],
    "FACE ADJUSTMENTS": ["NOSE", "BROW", "EYES", "CHEEKS", "LIPS & JAW", "CHIN & NECK"],
    "OVERLAYS": ["BLEMISHES", "AGEING", "COMPLEXION", "SUN DAMAGE", "MOLES & FRECKLES", "BODY BLEMISHES", "MAKEUP", "BLUSH", "LIPSTICK"],
    "HAIR": ["STYLES", "FADES", "FACIAL HAIR", "EYEBROWS", "CHEST HAIR"],
    "TATTOOS": ["HEAD", "TORSO", "LEFT ARM", "RIGHT ARM", "LEFT LEG", "RIGHT LEG"],
};

// Kind decides which view is used. Id is the key in Config.CurrentSkin.Clothes.
// GtaId / GtaType are only used to find a thumbnail picture.
export const Leaves = {
    // Apparel
    "TOPS": { Kind: "component", Id: "Jacket", GtaType: "component", GtaId: 11, Cam: "body" },
    "UNDERSHIRTS": { Kind: "component", Id: "Undershirt", GtaType: "component", GtaId: 8, Cam: "body" },
    "BOTTOMS": { Kind: "component", Id: "Pants", GtaType: "component", GtaId: 4, Cam: "legs" },
    "SHOES": { Kind: "component", Id: "Shoes", GtaType: "component", GtaId: 6, Cam: "shoes" },
    "BODY ARMOR": { Kind: "component", Id: "Vest", GtaType: "component", GtaId: 9, Cam: "body" },
    "BAGS & PARACHUTES": { Kind: "component", Id: "Bags", GtaType: "component", GtaId: 5, Cam: "body" },
    "SCARFS & CHAINS": { Kind: "component", Id: "Scarfs", GtaType: "component", GtaId: 7, Cam: "body" },
    "DECALS": { Kind: "component", Id: "Decals", GtaType: "component", GtaId: 10, Cam: "body" },
    "GLOVES": { Kind: "component", Id: "Arms", GtaType: "component", GtaId: 3, Cam: "body" },
    "WATCHES": { Kind: "component", Id: "Watches", GtaType: "prop", GtaId: 6, Cam: "body", Prop: true },
    "BRACELETS": { Kind: "component", Id: "Bracelets", GtaType: "prop", GtaId: 7, Cam: "body", Prop: true },
    "MASKS": { Kind: "component", Id: "Masks", GtaType: "component", GtaId: 1, Cam: "head" },
    "HATS": { Kind: "component", Id: "Hat", GtaType: "prop", GtaId: 0, Cam: "head", Prop: true },
    "GLASSES": { Kind: "component", Id: "Glasses", GtaType: "prop", GtaId: 1, Cam: "head", Prop: true },
    "EARS": { Kind: "component", Id: "Earrings", GtaType: "prop", GtaId: 2, Cam: "head", Prop: true },
    "SAVED OUTFITS": { Kind: "outfits", Cam: "character" },

    // Peds
    "PED MODELS": { Kind: "ped", Cam: "character" },
    "CUSTOM PEDS": { Kind: "customped", Cam: "character" },

    // Face & body
    "HEAD BLEND": { Kind: "headblend", Cam: "head" },
    "EYE COLOR": { Kind: "eyecolor", Id: "FaceEyeColor", Cam: "head" },
    "NOSE": { Kind: "features", Cam: "head", Sliders: [
        ["FaceNose", 0, "WIDTH", "THIN", "WIDE"], ["FaceNose", 1, "PEAK HEIGHT", "DOWN", "UP"],
        ["FaceNose", 2, "PEAK LENGTH", "SHORT", "LONG"], ["FaceNose", 3, "BONE HEIGHT", "LOW", "HIGH"],
        ["FaceNose", 4, "PEAK LOWERING", "UP", "DOWN"], ["FaceNose", 5, "BONE TWIST", "LEFT", "RIGHT"],
    ] },
    "BROW": { Kind: "features", Cam: "head", Sliders: [
        ["FaceEyebrows", 0, "BROW HEIGHT", "HIGH", "LOW"], ["FaceEyebrows", 1, "BROW DEPTH", "OUT", "IN"],
    ] },
    "EYES": { Kind: "features", Cam: "head", Sliders: [
        ["FaceMisc", 0, "EYE OPENING", "OPEN", "SQUINT"],
    ] },
    "CHEEKS": { Kind: "features", Cam: "head", Sliders: [
        ["FaceCheeks", 0, "CHEEKBONE HEIGHT", "HIGH", "LOW"], ["FaceCheeks", 1, "CHEEKBONE WIDTH", "THIN", "WIDE"],
    ] },
    "LIPS & JAW": { Kind: "features", Cam: "head", Sliders: [
        ["FaceMisc", 1, "LIP THICKNESS", "THICK", "THIN"], ["FaceJawBone", 0, "JAW WIDTH", "THIN", "WIDE"],
        ["FaceJawBone", 1, "JAW DEPTH", "SHORT", "LONG"],
    ] },
    "CHIN & NECK": { Kind: "features", Cam: "head", Sliders: [
        ["FaceChin", 0, "CHIN HEIGHT", "UP", "DOWN"], ["FaceChin", 1, "CHIN LENGTH", "SHORT", "LONG"],
        ["FaceChin", 2, "CHIN WIDTH", "SMALL", "LARGE"], ["FaceChin", 3, "CHIN HOLE", "NONE", "DEEP"],
        ["FaceMisc", 2, "NECK THICKNESS", "THIN", "THICK"],
    ] },

    // Overlays (style grid + opacity / colours on the right)
    "BLEMISHES": { Kind: "overlay", Id: "Blemishes", Cam: "head" },
    "AGEING": { Kind: "overlay", Id: "Ageing", Cam: "head" },
    "COMPLEXION": { Kind: "overlay", Id: "Complexion", Cam: "head" },
    "SUN DAMAGE": { Kind: "overlay", Id: "SunDamage", Cam: "head" },
    "MOLES & FRECKLES": { Kind: "overlay", Id: "Moles", Cam: "head" },
    "BODY BLEMISHES": { Kind: "overlay", Id: "BodyBlemishes", Cam: "body" },
    "MAKEUP": { Kind: "overlay", Id: "Makeup", Cam: "head", Palette: "Makeup", Secondary: true },
    "BLUSH": { Kind: "overlay", Id: "Blush", Cam: "head", Palette: "Makeup" },
    "LIPSTICK": { Kind: "overlay", Id: "Lipstick", Cam: "head", Palette: "Makeup" },

    // Hair
    "STYLES": { Kind: "hair", Id: "Hair", GtaType: "component", GtaId: 2, Cam: "head", Palette: "Hair", Secondary: true },
    "FADES": { Kind: "fade", Id: "Fade", Cam: "head" },
    "FACIAL HAIR": { Kind: "overlay", Id: "Beard", Cam: "head", Palette: "Hair" },
    "EYEBROWS": { Kind: "overlay", Id: "Eyebrows", Cam: "head", Palette: "Hair", Images: "eyebrows" },
    "CHEST HAIR": { Kind: "overlay", Id: "ChestHair", Cam: "body", Palette: "Hair" },

    // Tattoos
    "HEAD": { Kind: "tattoo", Id: "TattoosHead", Zone: "Head", Cam: "head" },
    "TORSO": { Kind: "tattoo", Id: "TattoosTorso", Zone: "Torso", Cam: "body" },
    "LEFT ARM": { Kind: "tattoo", Id: "TattoosLArm", Zone: "LArm", Cam: "body" },
    "RIGHT ARM": { Kind: "tattoo", Id: "TattoosRArm", Zone: "RArm", Cam: "body" },
    "LEFT LEG": { Kind: "tattoo", Id: "TattoosLLeg", Zone: "LLeg", Cam: "legs" },
    "RIGHT LEG": { Kind: "tattoo", Id: "TattoosRLeg", Zone: "RLeg", Cam: "legs" },
};

// What "remove" puts back for drawable components (same values as Clothes/ToggleComponents).
export const RemoveDefaults = (Id, Gender) => ({
    Jacket: 15, Undershirt: 15, Arms: 15, Vest: 0, Decals: 0, Masks: 0, Bags: 0, Scarfs: 0,
    Pants: Gender == "Female" ? 17 : 61,
    Shoes: Gender == "Female" ? 35 : 34,
})[Id] ?? 0;

export const IconFor = (Label) => {
    const L = (Label || "").toUpperCase();
    const Direct = {
        "OUTFITS": "layers", "SAVED OUTFITS": "layers", "CLOTHING": "shirt", "UPPER BODY ACCESSORIES": "harness",
        "HAND & WRIST ACCESSORIES": "watch", "HEAD ACCESSORIES": "crown", "STYLES": "scissors", "FADES": "scissors",
        "FACIAL HAIR": "smile", "EYEBROWS": "eye", "CHEST HAIR": "user", "PED MODELS": "user", "CUSTOM PEDS": "users",
        "HEAD BLEND": "users", "EYE COLOR": "eye", "PEDS": "user", "HEAD": "user", "TORSO": "vest",
        "SCARFS & CHAINS": "gem", "BODY ARMOR": "vest", "EARS": "ear",
    };
    if (Direct[L]) return Direct[L];
    if (L.includes("TOP") || L.includes("UNDER")) return "shirt";
    if (L.includes("BOTTOM")) return "pants";
    if (L.includes("SHOE")) return "footprints";
    if (L.includes("BAG")) return "backpack";
    if (L.includes("DECAL")) return "tag";
    if (L.includes("GLOVE")) return "hand";
    if (L.includes("WATCH")) return "watch";
    if (L.includes("BRACELET")) return "gem";
    if (L.includes("MASK")) return "ghost";
    if (L.includes("HAT")) return "crown";
    if (L.includes("GLASS")) return "glasses";
    if (L.includes("NOSE") || L.includes("FEATURE")) return "scanface";
    if (L.includes("BROW") || L.includes("EYE")) return "eye";
    if (L.includes("CHEEK")) return "smile";
    if (L.includes("LIP") || L.includes("JAW")) return "heart";
    if (L.includes("CHIN") || L.includes("NECK")) return "user";
    if (L.includes("BLEMISH") || L.includes("MOLE")) return "circledot";
    if (L.includes("AGE")) return "hourglass";
    if (L.includes("COMPLEXION") || L.includes("SUN")) return "sun";
    if (L.includes("MAKEUP") || L.includes("BLUSH") || L.includes("LIPSTICK")) return "sparkles";
    if (L.includes("ARM")) return "paintbrush";
    if (L.includes("LEG")) return "pants";
    return "shirt";
};
