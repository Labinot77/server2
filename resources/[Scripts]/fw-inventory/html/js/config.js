let ItemsList = [], CustomTypes = [];
let HasWeaponsLicense = false;
let OtherInvData = {}, MyInventory = {};
let InventoryOpen = false;
let MaxPlayerWeight = 250.0; // Base weight, the backpack adds on top (see GetContainerMaxWeight).
let MaxPlayerSlots = 46;

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
        Accessories: [42, 46],
    },
    EquipSlots: [
        { Slot: 36, Section: 'Body', Label: 'ID Card', Icon: 'badge', Items: ['id_card'] },
        { Slot: 37, Section: 'Body', Label: 'Phone', Icon: 'smartphone', Items: ['phone', 'burnerphone'] },
        { Slot: 38, Section: 'Body', Label: 'Keys', Icon: 'key', Items: ['keyring'] },
        { Slot: 39, Section: 'Body', Label: 'Wallet', Icon: 'account_balance_wallet', Items: ['wallet'] },
        { Slot: 40, Section: 'Body', Label: 'Backpack', Icon: 'backpack', Items: ['backpack'], IsBackpack: true },
        { Slot: 41, Section: 'Body', Label: 'Radio', Icon: 'radio', Items: ['radio'] },
        { Slot: 42, Section: 'Accessories', Label: 'Hat', Icon: 'styler', Items: ['hat'] },
        { Slot: 43, Section: 'Accessories', Label: 'Mask', Icon: 'masks', Items: ['mask'] },
        { Slot: 44, Section: 'Accessories', Label: 'Glasses', Icon: 'eyeglasses', Items: ['glasses'] },
        { Slot: 45, Section: 'Accessories', Label: 'Earrings', Icon: 'diamond', Items: ['earrings'] },
        { Slot: 46, Section: 'Accessories', Label: 'Watch', Icon: 'watch', Items: ['watch'] },
    ],
    Backpacks: [
        { Name: 'backpack', Weight: 100.0, Slots: 20 },
    ],
    BackpackSlot: 40,
    MaxPlayerWeight: 250.0,
    MaxPlayerSlots: 45,
};
const SectionOrder = ['Pockets', 'Backpack', 'Body', 'Accessories'];
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