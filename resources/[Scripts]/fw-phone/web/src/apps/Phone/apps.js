// Home screen apps. Color = gradient stops, Show = optional visibility check against phone state.
export const HomeApps = [
    { Id: "bank", Label: "Bank", Icon: "landmark", Color: ["#3ddc84", "#12924f"] },
    { Id: "details", Label: "Details", Icon: "id-card", Color: ["#5b8cff", "#3157d8"] },
    { Id: "pinger", Label: "Pinger", Icon: "map-marker-alt", Color: ["#ff9a76", "#f0644a"] },
    { Id: "yellowpages", Label: "Yellow Pages", Icon: "book-open", Color: ["#ffe066", "#f5b700"] },
    { Id: "twatter", Label: "Twatter", Icon: "feather-alt", Color: ["#5fc3ff", "#1d8fe1"] },
    { Id: "vehicles", Label: "Garage", Icon: "car-garage", Color: ["#4b4f58", "#24262b"] },
    { Id: "debt", Label: "Debt", Icon: "file-invoice-dollar", Color: ["#ff6b81", "#d63a55"] },
    { Id: "wenmo", Label: "Wenmo", Icon: "money-bill-wave", Color: ["#4ed4a0", "#169b6b"] },
    { Id: "documents", Label: "Documents", Icon: "folder", Color: ["#7fb0ff", "#4a7de0"] },
    { Id: "housing", Label: "Property", Icon: "house-user", Color: ["#a78bfa", "#6d4fe0"] },
    { Id: "crypto", Label: "Crypto", Icon: "coins", Color: ["#9f6bff", "#5b2bd6"] },
    { Id: "jobcenter", Label: "Job Center", Icon: "people-carry", Color: ["#d7f75b", "#97c21a"] },
    { Id: "employment", Label: "Business", Icon: "briefcase", Color: ["#3f7bff", "#1e3fae"] },
    { Id: "news", Label: "Weazel", Icon: "newspaper", Color: ["#ffffff", "#dcdcdc"], Glyph: "#d62828" },
    { Id: "bin", Label: "BIN", Icon: "broadcast-tower", Color: ["#ff8a3d", "#d9480f"], Tooltip: "Binsbergen International Network" },
    { Id: "time-trials", Label: "Time Trials", Icon: "stopwatch", Color: ["#ffb347", "#e07b00"], Show: S => S.HasPDRacingUsb },
    { Id: "racing", Label: "Racing", Icon: "flag-checkered", Color: ["#ff5f5f", "#b81d1d"], Show: S => !S.HasPDRacingUsb && S.HasRacingUsb },
    { Id: "milkroad", Label: "Milk Road", Icon: "user-secret", Color: ["#9a7ad6", "#5e3f9e"], Show: S => S.Network == "milkroad" },
    { Id: "calculator", Label: "Calculator", Icon: "calculator", Color: ["#5a5d66", "#2c2e33"] },
    { Id: "doj", Label: "Government", Icon: "gavel", Color: ["#4a64d8", "#24348f"], Glyph: "#f3d36b", Tooltip: "Department of Justice" },
    { Id: "settings", Label: "Settings", Icon: "cog", Color: ["#8e8e93", "#48484a"] },
    { Id: "tierup", Label: "TierUp!", Icon: "trophy", Color: ["#5aa4ff", "#2b6fc9"], Show: S => S.HasVpn },
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
    { Id: "calls", Label: "Calls", Icon: "phone-alt" },
    { Id: "messages", Label: "Messages", Icon: "comment" },
    { Id: "contacts", Label: "Contacts", Icon: "address-book" },
    { Id: "mails", Label: "Mail", Icon: "envelope" },
];

export const BurnerApps = [
    { Id: "calls", Label: "Calls", Icon: "phone-alt", Color: ["#3ddc84", "#0f9d58"] },
    { Id: "messages", Label: "Messages", Icon: "comment", Color: ["#7bd88f", "#3fa34d"] },
];

export const Hotkeys = [["Y", "Home"], ["U", "Notifications"], ["↵", "Select"], ["←", "Back"], ["ESC", "Close"]];
