let ItemsList = [], CustomTypes = [];
let HasWeaponsLicense = false;
let OtherInvData = {}, MyInventory = {};
let InventoryOpen = false;
let MaxPlayerWeight = 250.0; // Base weight, the backpack adds on top (see GetContainerMaxWeight).
let MaxPlayerSlots = 53;

// Mirrors Config.SlotLayout / Config.EquipSlots / Config.Backpacks from config/_sh_config.lua.
// Overwritten by the Lua side on load (SetItemsList -> Layout), these are just defaults.
let Layout = {
    Magazines: {
        Pistol: { Label: 'Pistol', Capacity: 12 }, Smg: { Label: 'SMG', Capacity: 30 }, Rifle: { Label: 'AR', Capacity: 30 },
        Shotgun: { Label: 'Shotgun', Capacity: 8 }, Sniper: { Label: 'Sniper', Capacity: 5 }, Revolver: { Label: 'Revolver', Capacity: 6 },
    },
    SlotLayout: {
        Pockets: [1, 15],
        Backpack: [16, 35],
        Body: [36, 41],
        Clothing: [42, 53],
    },
    EquipSlots: [
        { Slot: 36, Section: 'Body', Label: 'ID Card', Icon: 'badge', Items: ['id_card'] },
        { Slot: 37, Section: 'Body', Label: 'Phone', Icon: 'smartphone', Items: ['phone', 'burnerphone'] },
        { Slot: 38, Section: 'Body', Label: 'Keys', Icon: 'key', Items: ['keyring'] },
        { Slot: 39, Section: 'Body', Label: 'PD Watch', Icon: 'watch', Items: ['pdwatch'] },
        { Slot: 40, Section: 'Body', Label: 'Backpack', Icon: 'backpack', Items: ['backpack'], IsBackpack: true },
        { Slot: 41, Section: 'Body', Label: 'Radio', Icon: 'radio', Items: ['radio'] },
        { Slot: 42, Section: 'Clothing', Label: 'Hat', Icon: 'styler', Items: ['hat'] },
        { Slot: 43, Section: 'Clothing', Label: 'Mask', Icon: 'masks', Items: ['mask'] },
        { Slot: 44, Section: 'Clothing', Label: 'Glasses', Icon: 'eyeglasses', Items: ['glasses'] },
        { Slot: 45, Section: 'Clothing', Label: 'Earrings', Icon: 'diamond', Items: ['earrings'] },
        { Slot: 46, Section: 'Clothing', Label: 'Watch', Icon: 'watch', Items: ['watch'] },
        { Slot: 47, Section: 'Clothing', Label: 'Shirt', Icon: 'apparel', Items: ['shirt'] },
        { Slot: 48, Section: 'Clothing', Label: 'Undershirt', Icon: 'checkroom', Items: ['undershirt'] },
        { Slot: 49, Section: 'Clothing', Label: 'Gloves', Icon: 'back_hand', Items: ['gloves'] },
        { Slot: 50, Section: 'Clothing', Label: 'Pants', Icon: 'accessibility_new', Items: ['pants'] },
        { Slot: 51, Section: 'Clothing', Label: 'Shoes', Icon: 'steps', Items: ['shoes'] },
        { Slot: 52, Section: 'Clothing', Label: 'Chain', Icon: 'link', Items: ['chain'] },
        { Slot: 53, Section: 'Clothing', Label: 'Bracelet', Icon: 'trip_origin', Items: ['bracelet'] },
    ],
    Backpacks: [
        { Name: 'backpack', Weight: 100.0, Slots: 20 },
    ],
    BackpackSlot: 40,
    MaxPlayerWeight: 250.0,
    MaxPlayerSlots: 53,
};
const SectionOrder = ['Pockets', 'Backpack', 'Body', 'Clothing'];
let PlayerCash = 0;
let IgnoredIntoInvDrag = ['Store', 'Crafting'];

let HiddenMetadata = [
    // metadata that starts with '_' is ignored.
    // '_decryptFailed',
    // '_Description',
    // '_EvidenceData',
    // '_IsDehashed',
    // '_LastCook',
    // '_Purities',
    // '_Purity',
    'InkedBagExpiration',
    'BagId',
    'Image',
    'CookTime',
    'Buff',
    'BuffPercentage',
    'Date',
    'Photos',
    'Mag',          // magazine in the weapon (shown as its own line)
    'Attachments',  // attachments on the weapon (shown as their own lines)
    'Prop',     // clothing drawable (hat/mask/...)
    'Texture',  // clothing texture
];

let ItemI18n = {
    'magazine': { 'Bullets': 'Kogels' },
    "id_card": {
        citizenid: "BSN",
        firstname: "Първо Име",
        lastname: "Второ Име",
        birthdate: "Дата на раждане",
        nationality: "Националност",
        gender: "Пол",
    },
    "driver_license": {
        citizenid: "BSN",
        birthdate: "Дата на раждане",
        lastname: "Второ Име",
        firstname: "Първо Име",
        type: "Вид",
    },
    "identification-badge": {
        Rang: "Functie",
        Callsign: "Roepnummer",
        Name: "Naam"
    },
    "burnerphone": {
        PhoneNumber: "Номер на телефон",
    },
    "filled_evidence_bag": {
        label: "Type",
        street: "Straatnaam",
        bloodtype: "Bloed Type",
        fingerid: "Vingerafdruk",
        slimeid: "DNA-code",
        hairid: "DNA-code",
        ammo: "Ammo",
        ammotype: "Ammo Type",
        serie: "Serienummer"
    },
    "evidence": {
        Serial: "Сериен Номер",
        Fingerprint: "Пръстен Отпечатък",
        BloodType: "Bloed Type",
        BloodId: "DNA-code",
    },
    "polaroid-photo": {
        Description: "Beschrijving",
    }
}

let SpecificItemsInv = [
    {
        Inv: "cassettebox-",
        Items: [
            "musictape"
        ],
    },
    {
        Inv: "seed-bag-",
        Items: [
            "farming-seed"
        ],
    },
    {
        Inv: "produce-basket-",
        Items: [
            "farming-seed",
            "ingredient",
            "foodchain-food-item",
            "foodchain-side-item",
            "foodchain-dessert-item",
            "foodchain-drink-item",
            "foodchain-alcohol-item",
        ],
    },
    {
        Inv: "traphouse-",
        Items: [
            "markedbills",
            "money-roll",
        ],
    },
    {
        Inv: "arcade-tokens-",
        Items: [
            "arcadetoken"
        ]
    }
];