// Codera-style 24x24 stroke icons.
export const Icons = {
    phone: '<path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/>',
    message: '<path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>',
    user: '<path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>',
    users: '<path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/>',
    mail: '<rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3 7l9 6 9-6"/>',
    camera: '<path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/><circle cx="12" cy="13" r="4"/>',
    search: '<circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>',
    plus: '<line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>',
    send: '<line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/>',
    arrowl: '<line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/>',
    bell: '<path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/>',
    info: '<circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/>',
    pin: '<path d="M21 10c0 7-9 13-9 13S3 17 3 10a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/>',
    image: '<rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/>',
    smile: '<circle cx="12" cy="12" r="10"/><path d="M8 14s1.5 2 4 2 4-2 4-2"/><line x1="9" y1="9" x2="9.01" y2="9"/><line x1="15" y1="9" x2="15.01" y2="9"/>',
    x: '<line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>',
};

// Codera filled app glyphs (48x48). Elements with class "cut" use the tile's --cut colour.
export const Glyphs = {
    bank: '<path d="M24 5L6 14.5V18h36v-3.5z"/><rect x="8" y="20" width="32" height="3" rx="1"/><rect x="10" y="25" width="5.5" height="11" rx="1"/><rect x="17.5" y="25" width="5.5" height="11" rx="1"/><rect x="25" y="25" width="5.5" height="11" rx="1"/><rect x="32.5" y="25" width="5.5" height="11" rx="1"/><rect x="8" y="37.5" width="32" height="3" rx="1"/><rect x="5" y="41.5" width="38" height="3" rx="1"/>',
    crypto: '<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="30" height="30" stroke-width="1.2" opacity=".55"/><path d="M9 9h20M9 9v13M5.5 18.5L9 22l3.5-3.5M39 39H19M39 39V26M35.5 29.5L39 26l3.5 3.5" stroke-width="2"/><path d="M31 18.5a8.5 8.5 0 1 0 0 11" stroke-width="5" stroke-linecap="butt"/></g>',
    garage: '<path d="M5 41V16.5a4 4 0 0 1 2.2-3.6l15-7.3a4 4 0 0 1 3.6 0l15 7.3A4 4 0 0 1 43 16.5V41h-7V23H12v18z"/><path d="M16 28.5h16l2.6 6v6.5h-4.3v-2H17.7v2h-4.3v-6.5z"/><circle class="cut" cx="17.8" cy="34.4" r="1.5"/><circle class="cut" cx="30.2" cy="34.4" r="1.5"/>',
    licenses: '<path d="M7 13a4 4 0 0 1 4-4h26a4 4 0 0 1 4 4v1.5H7z"/><path d="M7 17.5h34V35a4 4 0 0 1-4 4H11a4 4 0 0 1-4-4z"/><circle class="cut" cx="16" cy="25" r="3.2"/><path class="cut" d="M10.5 34c.6-3.2 2.8-4.6 5.5-4.6s4.9 1.4 5.5 4.6z"/><rect class="cut" x="25" y="23" width="12" height="2.6" rx="1.3"/><rect class="cut" x="25" y="29" width="9" height="2.6" rx="1.3"/>',
    settings: '<circle cx="24" cy="24" r="12"/><rect x="20.5" y="4.5" width="7" height="39" rx="2.5"/><rect x="20.5" y="4.5" width="7" height="39" rx="2.5" transform="rotate(45 24 24)"/><rect x="20.5" y="4.5" width="7" height="39" rx="2.5" transform="rotate(90 24 24)"/><rect x="20.5" y="4.5" width="7" height="39" rx="2.5" transform="rotate(135 24 24)"/><circle class="cut" cx="24" cy="24" r="5.5"/>',
    news: '<rect x="5" y="15" width="21" height="10" fill="#d4262c"/><text x="15.5" y="23" text-anchor="middle" font-family="Arial,sans-serif" font-weight="900" font-size="9" textLength="18" lengthAdjust="spacingAndGlyphs" fill="#fff">NEWS</text><g fill="#15171a"><rect x="28" y="15.5" width="15" height="2"/><rect x="28" y="19.5" width="15" height="2"/><rect x="28" y="23.5" width="15" height="2"/><rect x="5" y="28.5" width="38" height="2"/><rect x="5" y="32.5" width="38" height="2"/><rect x="5" y="36.5" width="38" height="2"/></g>',
    business: '<path d="M17 15v-3.5a3.5 3.5 0 0 1 3.5-3.5h7a3.5 3.5 0 0 1 3.5 3.5V15" fill="none" stroke="currentColor" stroke-width="3.2"/><rect x="6" y="15" width="36" height="25" rx="5"/><rect class="cut" x="6" y="26" width="36" height="2.4"/><rect x="21" y="23.5" width="6" height="7" rx="1.5"/>',
    socials: '<path d="M16 7h16a10 10 0 0 1 10 10v9a10 10 0 0 1-10 10h-6.5l-6.3 6.5a1.6 1.6 0 0 1-2.7-1.1V36H16A10 10 0 0 1 6 26v-9A10 10 0 0 1 16 7z" fill="#2fb0f0"/><g fill="#fff"><rect x="13" y="15" width="9.5" height="3.8" rx="1.9"/><rect x="25.5" y="15" width="9.5" height="3.8" rx="1.9"/><rect x="13" y="22" width="9.5" height="3.8" rx="1.9"/><rect x="25.5" y="22" width="9.5" height="3.8" rx="1.9"/></g>',
    calc: '<rect x="9" y="5" width="30" height="38" rx="6"/><rect class="cut" x="13.5" y="9.5" width="21" height="8.5" rx="2"/><g class="cut"><circle cx="17.5" cy="25" r="2.4"/><circle cx="24" cy="25" r="2.4"/><circle cx="30.5" cy="25" r="2.4"/><circle cx="17.5" cy="31.5" r="2.4"/><circle cx="24" cy="31.5" r="2.4"/><circle cx="30.5" cy="31.5" r="2.4"/><circle cx="17.5" cy="38" r="2.4"/><circle cx="24" cy="38" r="2.4"/><circle cx="30.5" cy="38" r="2.4"/></g>',
};

// Codera tile themes: background, glyph colour, knock-out colour.
export const Tiles = {
    light: ["linear-gradient(145deg,#c4e0fc,#a9d0f8)", "#10151c", "#b9d9fb"],
    dark: ["rgba(12,13,16,.82)", "#aab1bd", "#1b1d22"],
    green: ["linear-gradient(145deg,#3ddc4f,#0b8a2b)", "#fff", "#1d9c35"],
    purple: ["linear-gradient(145deg,#7b22d9,#38097a)", "#fff", "#4d12a8"],
    blue: ["linear-gradient(145deg,#4f8cff,#2a5bd7)", "#fff", "#3a70e4"],
    teal: ["linear-gradient(145deg,#2dd4bf,#0f9488)", "#fff", "#0f9488"],
    amber: ["linear-gradient(145deg,#ffd35c,#f2a81d)", "#4a3200", "#f2a81d"],
    lime: ["linear-gradient(145deg,#f3f63c,#cdee24)", "#26330a", "#cdee24"],
    pink: ["linear-gradient(145deg,#fff,#e6d9de)", "#e0457b", "#e6d9de"],
    news: ["linear-gradient(145deg,#fff,#e4e6ea)", "#15171a", "#e4e6ea"],
    red: ["linear-gradient(145deg,#ff6b6b,#c62828)", "#fff", "#c62828"],
    gray: ["linear-gradient(145deg,#9aa3ae,#6b7480)", "#fff", "#6b7480"],
};
