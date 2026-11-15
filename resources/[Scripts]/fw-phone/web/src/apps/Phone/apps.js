// Home screen apps. Tile = codera tile theme (icons.js), Svg = optional codera glyph, Show = optional visibility check against phone state.
export const HomeApps = [
    { Id: "bank", Label: "Bank", Icon: "landmark", Tile: "green", Svg: "bank" },
    { Id: "details", Label: "Details", Icon: "id-card", Tile: "dark", Svg: "licenses" },
    { Id: "pinger", Label: "Pinger", Icon: "map-marker-alt", Tile: "pink" },
    { Id: "yellowpages", Label: "Yellow Pages", Icon: "book-open", Tile: "amber" },
    { Id: "twatter", Label: "Twatter", Icon: "feather-alt", Tile: "dark", Svg: "socials" },
    { Id: "vehicles", Label: "Garage", Icon: "car-garage", Tile: "dark", Svg: "garage" },
    { Id: "debt", Label: "Debt", Icon: "file-invoice-dollar", Tile: "red" },
    { Id: "wenmo", Label: "Wenmo", Icon: "money-bill-wave", Tile: "teal" },
    { Id: "documents", Label: "Documents", Icon: "folder", Tile: "dark" },
    { Id: "housing", Label: "Property", Icon: "house-user", Tile: "purple" },
    { Id: "crypto", Label: "Crypto", Icon: "coins", Tile: "purple", Svg: "crypto" },
    { Id: "jobcenter", Label: "Job Center", Icon: "people-carry", Tile: "lime" },
    { Id: "employment", Label: "Business", Icon: "briefcase", Tile: "blue", Svg: "business" },
    { Id: "news", Label: "Weazel", Icon: "newspaper", Tile: "news", Svg: "news" },
    { Id: "bin", Label: "BIN", Icon: "broadcast-tower", Tile: "amber", Tooltip: "Binsbergen International Network" },
    { Id: "time-trials", Label: "Time Trials", Icon: "stopwatch", Tile: "dark", Show: S => S.HasPDRacingUsb },
    { Id: "racing", Label: "Racing", Icon: "flag-checkered", Tile: "dark", Show: S => !S.HasPDRacingUsb && S.HasRacingUsb },
    { Id: "milkroad", Label: "Milk Road", Icon: "user-secret", Tile: "dark", Show: S => S.Network == "milkroad" },
    { Id: "calculator", Label: "Calculator", Icon: "calculator", Tile: "dark", Svg: "calc" },
    { Id: "doj", Label: "Government", Icon: "gavel", Tile: "blue", Tooltip: "Department of Justice" },
    { Id: "settings", Label: "Settings", Icon: "cog", Tile: "light", Svg: "settings" },
    { Id: "tierup", Label: "TierUp!", Icon: "trophy", Tile: "blue", Show: S => S.HasVpn },
];

// The "cars" app only shows on a dealership network.
export const CarShops = {
    pdm: ["Premium Deluxe Motorsports", "car-alt"],
    bennys: ["Bennys Motorworks", "car-alt"],
    flightschool: ["Los Santos Flight School", "plane"],
    lostmc: ["The Lost MC", "motorcycle"],
    losmuertos: ["Muertos Motorcycle Shop", "motorcycle"],
    deathsinners: ["Death Sinners MC", "motorcycle"],
    darkwolves: ["Dark Wolves MC", "motorcycle"],
};

export const DockApps = [
    { Id: "calls", Label: "Calls", Icon: "phone" },
    { Id: "messages", Label: "Messages", Icon: "message" },
    { Id: "contacts", Label: "Contacts", Icon: "user" },
    { Id: "mails", Label: "Mail", Icon: "mail" },
];

export const BurnerApps = [
    { Id: "calls", Label: "Calls", Icon: "phone-alt", Tile: "green" },
    { Id: "messages", Label: "Messages", Icon: "comment", Tile: "teal" },
];

export const Hotkeys = [["U", "Notifications"], ["T", "Unfold"], ["Y", "Home"], ["↵", "Select"], ["←", "Back"], ["ESC", "Close"]];
