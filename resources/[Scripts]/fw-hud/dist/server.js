/*
 * ATTENTION: The "eval" devtool has been used (maybe by default in mode: "development").
 * This devtool is neither made for production nor for readable output files.
 * It uses "eval()" calls to create a separate source file in the browser devtools.
 * If you are trying to read the output file, select a different devtool (https://webpack.js.org/configuration/devtool/)
 * or disable the default devtool with "devtool: false".
 * If you are looking for production-ready output files, see mode: "production" (https://webpack.js.org/configuration/mode/).
 */
/******/ (() => { // webpackBootstrap
/******/ 	"use strict";
/******/ 	var __webpack_modules__ = ({

/***/ "./src/server/config.ts"
/*!******************************!*\
  !*** ./src/server/config.ts ***!
  \******************************/
(__unused_webpack_module, exports) {

eval("{\nObject.defineProperty(exports, \"__esModule\", ({ value: true }));\nexports.Buffs = void 0;\nexports.Buffs = {\n    'Stress': { HudId: 'Stress' }, // Decreases Stress\n    'Recoil': { HudId: 'Buff.Recoil' }, // Decreases Horizontal Recoil\n    'Bank': { HudId: 'Buff.Bank' }, // Increased Bank Loot\n    'Hunting': { HudId: 'Buff.Hunting' }, // Increased Hunting Loot\n    'Swimming': { HudId: 'Buff.Swimming' }, // Increased Swimming Stamina\n    'Fishing': { HudId: 'Buff.Fishing' }, // Increased Fishing Loot\n    'Smartness': { HudId: 'Buff.Smartness' }, // Increased Minigame Timers\n    'Stores': { HudId: 'Buff.Stores' }, // Increased Stores Loot\n    'Strength': { HudId: 'Buff.Strength' }, // Increased Melee Damage\n    'Radio': { HudId: 'Buff.Radio' }, // Increased Radio Range\n    'Beekeeping': { HudId: 'Buff.Beekeeping' }, // Increased Beequeen chance\n    'Salary': { HudId: 'Buff.Salary' }, // Increased Job Salary\n    'Health': { HudId: 'Health' }, // Slow Health Regen\n};\n// Contract for the modules the minimap script imports.\n// In Lua these were shared globals (Config, CoderaHud, HudScreen);\n// in TypeScript each one needs to be a real module exporting these shapes.\n\n\n//# sourceURL=webpack://robijn-hud/./src/server/config.ts?\n}");

/***/ },

/***/ "./src/server/handlers/buffs.ts"
/*!**************************************!*\
  !*** ./src/server/handlers/buffs.ts ***!
  \**************************************/
(__unused_webpack_module, exports, __webpack_require__) {

eval("{\nObject.defineProperty(exports, \"__esModule\", ({ value: true }));\nconst utils_1 = __webpack_require__(/*! ../../shared/utils */ \"./src/shared/utils.ts\");\nconst config_1 = __webpack_require__(/*! ../config */ \"./src/server/config.ts\");\nconst server_1 = __webpack_require__(/*! ../server */ \"./src/server/server.ts\");\nlet BuffedPlayers = {};\nserver_1.FW.Functions.CreateCallback(\"fw-hud:Server:GetBuffs\", (Source, Cb) => {\n    Cb(config_1.Buffs);\n});\nserver_1.FW.Functions.CreateCallback(\"fw-hud:Server:DoesPlayerHaveBuff\", (Source, Cb, BuffId) => {\n    Cb(DoesPlayerHaveBuff(Source, BuffId));\n});\nserver_1.FW.RegisterServer(\"fw-hud:Server:ApplyBuff\", (Source, BuffId, Percentage) => {\n    if (!config_1.Buffs[BuffId])\n        return console.log(`Failed to add buff to player, invalid BuffId. | Source: ${Source}; BuffId: ${BuffId}; Percentage: ${Percentage}`);\n    const Player = server_1.FW.Functions.GetPlayer(Source);\n    if (!Player)\n        return;\n    if (!BuffedPlayers[Source])\n        BuffedPlayers[Source] = [];\n    BuffedPlayers[Source].push(BuffId);\n    emitNet(\"fw-hud:Client:SetCurrentBuff\", Source, BuffId, {\n        HudId: config_1.Buffs[BuffId].HudId,\n        Value: Percentage\n    });\n    emitNet(\"fw-hud:Client:ApplyBuff\", Source, BuffId, Percentage);\n});\nserver_1.FW.RegisterServer(\"fw-hud:Server:RemoveBuff\", (Source, BuffId) => {\n    emitNet(\"fw-hud:Client:RemoveBuff\", Source, BuffId);\n    if (!BuffedPlayers[Source] || !BuffedPlayers[Source].includes(BuffId)) {\n        return console.warn(`A buff was removed from a player, but the server was unknown of this buff. | Source: ${Source}; BuffId: ${BuffId}`);\n    }\n    ;\n    BuffedPlayers[Source].filter(Val => Val != BuffId);\n});\nconst DoesPlayerHaveBuff = (Source, BuffId) => {\n    if (!BuffedPlayers[Source])\n        return false;\n    return BuffedPlayers[Source].includes(BuffId);\n};\n(0, utils_1.exp)(\"DoesPlayerHaveBuff\", DoesPlayerHaveBuff);\n\n\n//# sourceURL=webpack://robijn-hud/./src/server/handlers/buffs.ts?\n}");

/***/ },

/***/ "./src/server/handlers/preferences.ts"
/*!********************************************!*\
  !*** ./src/server/handlers/preferences.ts ***!
  \********************************************/
(__unused_webpack_module, exports, __webpack_require__) {

eval("{\nObject.defineProperty(exports, \"__esModule\", ({ value: true }));\nconst server_1 = __webpack_require__(/*! ../server */ \"./src/server/server.ts\");\nserver_1.FW.Commands.Add([\"hud\", \"binds\"], \"HUD instellingen\", [], false, (Source, Args) => {\n    const Player = server_1.FW.Functions.GetPlayer(Source);\n    if (!Player)\n        return;\n    emitNet('fw-hud:Client:TogglePreferences', Source, true);\n});\n\n\n//# sourceURL=webpack://robijn-hud/./src/server/handlers/preferences.ts?\n}");

/***/ },

/***/ "./src/server/server.ts"
/*!******************************!*\
  !*** ./src/server/server.ts ***!
  \******************************/
(__unused_webpack_module, exports, __webpack_require__) {

eval("{\nObject.defineProperty(exports, \"__esModule\", ({ value: true }));\nexports.FW = void 0;\nconst utils_1 = __webpack_require__(/*! ../shared/utils */ \"./src/shared/utils.ts\");\nexports.FW = utils_1.exp['fw-core'].GetCoreObject();\nconst config_1 = __webpack_require__(/*! ../shared/config */ \"./src/shared/config.ts\");\n__webpack_require__(/*! ./handlers/buffs */ \"./src/server/handlers/buffs.ts\");\n__webpack_require__(/*! ./handlers/preferences */ \"./src/server/handlers/preferences.ts\");\nconst GetHudId = (Id) => {\n    return config_1.Hud.findIndex(Val => Val.Id == Id);\n};\n(0, utils_1.exp)(\"GetHudId\", GetHudId);\nexports.FW.Commands.Add(\"cash\", \"Hoeveel contant hebbie?\", [], false, (Source, Args) => {\n    const Player = exports.FW.Functions.GetPlayer(Source);\n    if (!Player)\n        return;\n    emitNet('fw-hud:Client:ShowCash', Source);\n});\n\n\n//# sourceURL=webpack://robijn-hud/./src/server/server.ts?\n}");

/***/ },

/***/ "./src/shared/config.ts"
/*!******************************!*\
  !*** ./src/shared/config.ts ***!
  \******************************/
(__unused_webpack_module, exports) {

eval("{\nObject.defineProperty(exports, \"__esModule\", ({ value: true }));\nexports.BuffMessages = exports.Hud = exports.Config = exports.HudSettingsBrand = exports.Safezone = exports.Chat = exports.Minimap = void 0;\nexports.Minimap = {\n    Zoom: 100.0,\n    MaskScale: 1.0,\n    MaskOffsetX: 0,\n    MaskOffsetY: 0.0,\n    EngineScaleX: 1,\n    EngineScaleY: 1,\n    AutoCalibrate: true,\n    CenterOffset: 0.25, // pulls the player arrow to the ring center (fraction of Zoom, tune with /minimapcal center)\n};\n// ADD THIS to the bottom of project/src/shared/config.ts (next to the `Minimap` export from the minimap step).\nexports.Chat = {\n    Enabled: true,\n    Control: 245, // INPUT_MP_TEXT_CHAT_ALL (T), same control your old chat used\n    MaxLength: 120,\n    MaxHistory: 50,\n    VisibleWhenClosed: 6, // messages shown while the input is closed\n    FadeAfter: 8000, // ms until a message starts fading\n    FadeDuration: 400,\n    InputWidth: 340, // px at 1080p\n};\nexports.Safezone = {\n    Show: true,\n    Required: 0.99, // warning shows while GetSafeZoneSize() is below this\n};\nexports.HudSettingsBrand = \"FW HUD\";\nconst PresetPreferences = {\n    'Status.ShowHealth': true,\n    'Status.HealthValue': 95,\n    'Status.ShowArmor': true,\n    'Status.ArmorValue': 95,\n    'Status.ShowFood': true,\n    'Status.FoodValue': 95,\n    'Status.ShowWater': true,\n    'Status.WaterValue': 95,\n    'Status.ShowStress': true,\n    'Status.ShowOxygen': true,\n    'Status.ShowBuffs': false,\n    'Status.RadioVisibility': 'Relevant',\n    'Vehicle.ShowMapOutline': true,\n    'Vehicle.ShowControls': true,\n    'BlackBars.Show': false,\n    'BlackBars.Percentage': 10,\n    'Compass.Show': true,\n    'Crosshair.Show': true,\n    'Phone.Brand': 'Android',\n    'Phone.Background': 'https://i.imgur.com/3KTfLIV.jpg',\n    'Phone.Animation': 'Rechteroor',\n    'Radio.Animation': 'Schouder',\n    'Phone.DisableMovement': true,\n    'Notifications.SMS': true,\n    'Notifications.Tweet': true,\n    'Notifications.Email': true,\n    'Images.Embedded': true,\n    'Audio.RadioClicksOut': true,\n    'Audio.RadioClicksIn': true,\n    'Audio.RadioVolume': 0.5,\n    'Audio.PhoneVolume': 0.5,\n    'Audio.RadioBalance': 50,\n    'Audio.PhoneBalance': 50,\n    'Binds.F2': '',\n    'Binds.F3': '',\n    'Binds.F5': '',\n    'Binds.F6': '',\n    'Binds.F7': '',\n    'Binds.F9': '',\n    'Binds.F10': '',\n};\nexports.Config = {\n    MyPreferences: { ...PresetPreferences },\n    PresetPreferences: { ...PresetPreferences },\n};\nexports.Hud = [\n    {\n        Id: 'Voice',\n        Show: true,\n        Color: '#fff', Icon: 'microphone',\n        Value: 66.0, ShowDanger: false,\n        AutoHide: false, AutoShow: false,\n        Buffed: false, IsEnhancement: false,\n        InsideText: false,\n    },\n    {\n        Id: 'Health',\n        Show: true,\n        Color: '#3bb273', Icon: 'heart',\n        Value: 100.0, ShowDanger: true,\n        AutoHide: false, AutoShow: false,\n        Buffed: false, IsEnhancement: false\n    },\n    {\n        Id: 'Armor',\n        Show: true,\n        Color: '#1565c0', Icon: 'shield-alt',\n        Value: 100.0, ShowDanger: true,\n        AutoHide: false, AutoShow: false,\n        Buffed: false, IsEnhancement: false\n    },\n    {\n        Id: 'Food',\n        Show: true,\n        Color: '#ff6d00', Icon: 'hamburger',\n        Value: 100.0, ShowDanger: true,\n        AutoHide: false, AutoShow: false,\n        Buffed: false, IsEnhancement: false\n    },\n    {\n        Id: 'Water',\n        Show: true,\n        Color: '#0277bd', Icon: 'glass',\n        Value: 100.0, ShowDanger: true,\n        AutoHide: false, AutoShow: false,\n        Buffed: false, IsEnhancement: false\n    },\n    {\n        Id: 'Stress',\n        Show: true,\n        Color: '#d50000', Icon: 'brain',\n        Value: 0.0, ShowDanger: false,\n        AutoHide: true, AutoShow: false,\n        Buffed: false, IsEnhancement: false\n    },\n    {\n        Id: 'Oxygen',\n        Show: false,\n        Color: '#90a4ae', Icon: 'lungs',\n        Value: 100.0, ShowDanger: true,\n        AutoHide: false, AutoShow: false,\n        Buffed: false, IsEnhancement: false\n    },\n    {\n        Id: 'Nitrous',\n        Show: false,\n        Color: '#e43f5a', Icon: 'meteor',\n        Value: 0.0, ShowDanger: false,\n        AutoHide: true, AutoShow: true,\n        Buffed: false, IsEnhancement: false\n    },\n    {\n        Id: 'Harness',\n        Show: false,\n        Color: '#dd4dfa', Icon: 'user-slash',\n        Value: 0.0, ShowDanger: false,\n        AutoHide: true, AutoShow: true,\n        Buffed: false, IsEnhancement: false\n    },\n    {\n        Id: 'PursuitMode',\n        Show: false,\n        Color: '#ff4a68', Icon: 'tachometer-alt',\n        Value: 0.0, ShowDanger: false,\n        AutoHide: true, AutoShow: true,\n        Buffed: false, IsEnhancement: false\n    },\n    {\n        Id: 'Timer',\n        Show: false,\n        Color: 'rgb(153, 93, 194)', Icon: 'stopwatch-20',\n        Value: 50.0, ShowDanger: false,\n        AutoHide: true, AutoShow: true,\n        Buffed: false, IsEnhancement: false\n    },\n    {\n        Id: 'Boosting',\n        Show: false,\n        Color: '#e43f5a', Icon: 'microchip',\n        Value: 0.0, ShowDanger: false,\n        AutoHide: true, AutoShow: true,\n        Buffed: false, IsEnhancement: false\n    },\n    {\n        Id: 'FireMode',\n        Show: false,\n        Color: 'rgb(255, 74, 104)', Icon: 'stream',\n        Value: 0, ShowDanger: false,\n        AutoHide: true, AutoShow: true,\n        Buffed: false, IsEnhancement: false\n    },\n    {\n        Id: 'Infection',\n        Show: false,\n        Color: 'rgb(71, 225, 12)', Icon: 'biohazard',\n        Value: 0, ShowDanger: false,\n        AutoHide: true, AutoShow: true,\n        Buffed: false, IsEnhancement: false\n    },\n    // Buffs\n    {\n        Id: 'Buff.Recoil',\n        Show: false,\n        Color: '#ffd700', Icon: 'crosshairs',\n        Value: 0.0, ShowDanger: false,\n        AutoHide: true, AutoShow: true,\n        Buffed: true, IsEnhancement: true\n    },\n    {\n        Id: 'Buff.Bank',\n        Show: false,\n        Color: '#ffd700', Icon: 'sack-dollar',\n        Value: 0.0, ShowDanger: false,\n        AutoHide: true, AutoShow: true,\n        Buffed: true, IsEnhancement: true\n    },\n    {\n        Id: 'Buff.Hunting',\n        Show: false,\n        Color: '#ffd700', Icon: 'deer',\n        Value: 0.0, ShowDanger: false,\n        AutoHide: true, AutoShow: true,\n        Buffed: true, IsEnhancement: true\n    },\n    {\n        Id: 'Buff.Swimming',\n        Show: false,\n        Color: '#ffd700', Icon: 'swimmer',\n        Value: 0.0, ShowDanger: false,\n        AutoHide: true, AutoShow: true,\n        Buffed: true, IsEnhancement: true\n    },\n    {\n        Id: 'Buff.Fishing',\n        Show: false,\n        Color: '#ffd700', Icon: 'fish',\n        Value: 0.0, ShowDanger: false,\n        AutoHide: true, AutoShow: true,\n        Buffed: true, IsEnhancement: true\n    },\n    {\n        Id: 'Buff.Smartness',\n        Show: false,\n        Color: '#ffd700', Icon: 'lightbulb',\n        Value: 0.0, ShowDanger: false,\n        AutoHide: true, AutoShow: true,\n        Buffed: true, IsEnhancement: true\n    },\n    {\n        Id: 'Buff.Stores',\n        Show: false,\n        Color: '#ffd700', Icon: 'shopping-basket',\n        Value: 0.0, ShowDanger: false,\n        AutoHide: true, AutoShow: true,\n        Buffed: true, IsEnhancement: true\n    },\n    {\n        Id: 'Buff.Strength',\n        Show: false,\n        Color: '#ffd700', Icon: 'boxing-glove',\n        Value: 0.0, ShowDanger: false,\n        AutoHide: true, AutoShow: true,\n        Buffed: true, IsEnhancement: true\n    },\n    {\n        Id: 'Buff.Radio',\n        Show: false,\n        Color: '#ffd700', Icon: 'broadcast-tower',\n        Value: 0.0, ShowDanger: false,\n        AutoHide: true, AutoShow: true,\n        Buffed: true, IsEnhancement: true\n    },\n    {\n        Id: 'Buff.Beekeeping',\n        Show: false,\n        Color: '#ffd700', Icon: 'crown',\n        Value: 0.0, ShowDanger: false,\n        AutoHide: true, AutoShow: true,\n        Buffed: true, IsEnhancement: true\n    },\n    {\n        Id: 'Buff.Salary',\n        Show: false,\n        Color: '#ffd700', Icon: 'dollar-sign',\n        Value: 0.0, ShowDanger: false,\n        AutoHide: true, AutoShow: true,\n        Buffed: true, IsEnhancement: true\n    },\n];\nexports.BuffMessages = {\n    Stress: \"Je voelt jezelf minder opgelucht..\",\n    // Recoil: \"\",\n    // Bank: \"\",\n    // Hunting: \"\",\n    // Swimming: \"\",\n    // Fishing: \"\",\n    Smartness: \"Je voelt jezelf minder slim..\",\n    // Stores: \"\",\n    Strength: \"Je voelt jezelf minder sterk..\",\n    // Radio: \"\",\n    // Beekeeping: \"\",\n    Salary: \"Je voelt jezelf minder gemotiveerd..\",\n    // Health: \"Je voelt jezelf minder gezond\",\n};\n\n\n//# sourceURL=webpack://robijn-hud/./src/shared/config.ts?\n}");

/***/ },

/***/ "./src/shared/utils.ts"
/*!*****************************!*\
  !*** ./src/shared/utils.ts ***!
  \*****************************/
(__unused_webpack_module, exports, __webpack_require__) {

eval("{\nObject.defineProperty(exports, \"__esModule\", ({ value: true }));\nexports.RegisterNUICallback = exports.SetUIFocus = exports.SendUIMessage = exports.GetRandom = exports.Delay = exports.exp = void 0;\nexports.exp = __webpack_require__.g.exports;\nconst Delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));\nexports.Delay = Delay;\nconst GetRandom = (Min, Max) => Math.floor(Math.random() * (Max - Min + 1)) + Min;\nexports.GetRandom = GetRandom;\nexports.SendUIMessage = !IsDuplicityVersion() ? (App, Event, Data) => {\n    exports.exp['fw-ui'].SendUIMessage(App, Event, Data);\n} : () => console.warn(`SendUIMessage does exist on server.`);\nexports.SetUIFocus = !IsDuplicityVersion() ? (HasFocus, HasCursor) => {\n    exports.exp['fw-ui'].SetUIFocus(HasFocus, HasCursor);\n} : () => console.warn(`SetUIFocus does exist on server.`);\nexports.RegisterNUICallback = !IsDuplicityVersion() ? (Name, Cb) => {\n    RegisterNuiCallbackType(Name);\n    on(`__cfx_nui:${Name}`, Cb);\n} : () => console.log(`RegisterNUICallback can't be used on server.`);\n\n\n//# sourceURL=webpack://robijn-hud/./src/shared/utils.ts?\n}");

/***/ }

/******/ 	});
/************************************************************************/
/******/ 	// The module cache
/******/ 	const __webpack_module_cache__ = {};
/******/ 	
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/ 		// Check if module is in cache
/******/ 		const cachedModule = __webpack_module_cache__[moduleId];
/******/ 		if (cachedModule !== undefined) {
/******/ 			return cachedModule.exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		const module = __webpack_module_cache__[moduleId] = {
/******/ 			// no module.id needed
/******/ 			// no module.loaded needed
/******/ 			exports: {}
/******/ 		};
/******/ 	
/******/ 		// Execute the module function
/******/ 		if (!(moduleId in __webpack_modules__)) {
/******/ 			delete __webpack_module_cache__[moduleId];
/******/ 			const e = new Error("Cannot find module '" + moduleId + "'");
/******/ 			e.code = 'MODULE_NOT_FOUND';
/******/ 			throw e;
/******/ 		}
/******/ 		__webpack_modules__[moduleId](module, module.exports, __webpack_require__);
/******/ 	
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/ 	
/************************************************************************/
/******/ 	/* webpack/runtime/global */
/******/ 	__webpack_require__.g = (function() {
/******/ 		if (typeof globalThis === 'object') return globalThis;
/******/ 		try {
/******/ 			return this || new Function('return this')();
/******/ 		} catch (e) {
/******/ 			if (typeof window === 'object') return window;
/******/ 		}
/******/ 	})();
/******/ 	
/************************************************************************/
/******/ 	
/******/ 	// startup
/******/ 	// Load entry module and return exports
/******/ 	// This entry module is referenced by other modules so it can't be inlined
/******/ 	let __webpack_exports__ = __webpack_require__("./src/server/server.ts");
/******/ 	
/******/ })()
;