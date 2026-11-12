Shared = Shared or {}
Shared.Items = {}

-- Hoe meer groter het getal van de decay hoelanger hij er over doet. Minder gaat hij sneller stuk.

Shared.Items["repairhammer"] = {
    Name = "repairhammer",
    Label = "(DEV) Repair Hammer",
    Image = "w_sledgehammer.png",
    Description = "Abuser",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 0.0,
    Melee = false, HasProp = false,
    Price = 0,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["pistolparts"] = {
    Name = "pistolparts",
    Label = "Pistol Parts",
    Image = "w_pistol_parts.png",
    Description = "Illegal pistol components.",
    Weapon = false, Illegal = true,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 10,
    Melee = false, HasProp = false,
    Price = 0,
    Craft = {},
    DecayRate = 0.1,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["shotgunparts"] = {
    Name = "shotgunparts",
    Label = "Shotgun Parts",
    Image = "w_shotgun_parts.png",
    Description = "Illegal shotgun components.",
    Weapon = false, Illegal = true,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 10,
    Melee = false, HasProp = false,
    Price = 0,
    Craft = {},
    DecayRate = 0.1,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["riflebody"] = {
    Name = "riflebody",
    Label = "Rifle Body",
    Image = "w_rifle_body.png",
    Description = "Illegal rifle components.",
    Weapon = false, Illegal = true,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 10,
    Melee = false, HasProp = false,
    Price = 0,
    Craft = {},
    DecayRate = 0.1,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["smgbody"] = {
    Name = "smgbody",
    Label = "SMG Body",
    Image = "w_smg_body.png",
    Description = "Illegal SMG components.",
    Weapon = false, Illegal = true,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 10,
    Melee = false, HasProp = false,
    Price = 0,
    Craft = {},
    DecayRate = 0.1,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_huntingrifle"] = {
    Name = "weapon_huntingrifle",
    Label = "Hunting Rifle",
    Image = "w_huntingrifle.png",
    Description = "Please use this to shoot animals only.",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 17.0,
    Melee = false, HasProp = true,
    Price = 500,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_empgun"] = {
    Name = "weapon_empgun",
    Label = "(PD) EMP Gun",
    Image = "w_empgun.png",
    Description = "There goes your ride.",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 17.0,
    Melee = false, HasProp = true,
    Price = 7250,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_remington"] = {
    Name = "weapon_remington",
    Label = "(PD) Pump Shotgun",
    Image = "w_remington.png",
    Description = "This thing will blow your head off if you're not careful.",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 17.0,
    Melee = false, HasProp = true,
    Price = 750,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_expedite"] = {
    Name = "weapon_expedite",
    Label = "Pump Shotgun",
    Image = "w_expedite.png",
    Description = "",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 17.0,
    Melee = false, HasProp = true,
    Price = 250,
    Craft = {
        { Item = 'steel', Amount = 1250 },
        { Item = 'copper', Amount = 1250 },
        { Item = 'metalscrap', Amount = 1250 },
        { Item = 'shotgunparts', Amount = 1 },
    },
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_rubberslug"] = {
    Name = "weapon_rubberslug",
    Label = "(PD) Rubber Shotgun",
    Image = "w_rubberslug.png",
    Description = "Is this a rubber shotgun, or does it shoot rubber?",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 17.0,
    Melee = false, HasProp = true,
    Price = 800,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_m4"] = {
    Name = "weapon_m4",
    Label = "(PD) Tactical Rifle",
    Image = "w_m4.png",
    Description = "Compensating for something?",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 17.0,
    Melee = false, HasProp = true,
    Price = 500,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_scar"] = {
    Name = "weapon_scar",
    Label = "(PD) Heavy Rifle",
    Image = "w_scar.png",
    Description = "Did this thing come from Fortnite?",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 17.0,
    Melee = false, HasProp = true,
    Price = 600,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_groza"] = {
    Name = "weapon_groza",
    Label = "Bullpup Rifle",
    Image = "w_groza.png",
    Description = "Groza my balls bitchhhh.",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 17.0,
    Melee = false, HasProp = true,
    Price = 1,
    Craft = {
        { Item = 'aluminum', Amount = 1500 },
        { Item = 'plastic', Amount = 1500 },
        { Item = 'rubber', Amount = 1500 },
        { Item = 'riflebody', Amount = 1 },
    },
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_m70"] = {
    Name = "weapon_m70",
    Label = "Military Rifle",
    Image = "w_m70.png",
    Description = "Looks nice!",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 17.0,
    Melee = false, HasProp = true,
    Price = 1,
    Craft = {
        { Item = 'aluminum', Amount = 1500 },
        { Item = 'plastic', Amount = 1500 },
        { Item = 'rubber', Amount = 1500 },
        { Item = 'riflebody', Amount = 1 },
    },
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_ak47"] = {
    Name = "weapon_ak47",
    Label = "Assault Rifle",
    Image = "w_ak47.png",
    Description = "Ratatata, am I in the ghetto?",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 17.0,
    Melee = false, HasProp = true,
    Price = 1,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_ak74"] = {
    Name = "weapon_ak74",
    Label = "Assault Rifle Mk2",
    Image = "w_ak74.png",
    Description = "Ratatata, am I in the ghetto?",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 17.0,
    Melee = false, HasProp = true,
    Price = 1,
    Craft = {
        { Item = 'aluminum', Amount = 1500 },
        { Item = 'plastic', Amount = 1500 },
        { Item = 'rubber', Amount = 1500 },
        { Item = 'riflebody', Amount = 1 },
    },
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_rpk"] = {
    Name = "weapon_rpk",
    Label = "Machine Gun",
    Image = "w_rpk.png",
    Description = "Am I supposed to shoot zombies with this?",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 36.0,
    Melee = false, HasProp = true,
    Price = 1,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_mpx"] = {
    Name = "weapon_mpx",
    Label = "(PD) PDW",
    Image = "w_mpx.png",
    Description = "Looks like a nice weapon..",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 15.5,
    Melee = false, HasProp = true,
    Price = 500,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_draco"] = {
    Name = "weapon_draco",
    Label = "SMG Mk2",
    Image = "w_draco.png",
    Description = "Does a dragon come out of this?",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 15.5,
    Melee = false, HasProp = true,
    Price = 1,
    Craft = {
        { Item = 'metalscrap', Amount = 414 },
		{ Item = 'copper', Amount = 348 },
		{ Item = 'steel', Amount = 384 },
        { Item = 'smgbody', Amount = 1 },
    },
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_mp5"] = {
    Name = "weapon_mp5",
    Label = "SMG",
    Image = "w_mp5.png",
    Description = "This thing is getting out of hand.",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 15.5,
    Melee = false, HasProp = true,
    Price = 1,
    Craft = {
        { Item = 'aluminum', Amount = 270 },
        { Item = 'plastic', Amount = 540 },
        { Item = 'rubber', Amount = 270 },
        { Item = 'smgbody', Amount = 1 },
    },
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_mp7"] = {
    Name = "weapon_mp7",
    Label = "(PD) Tactical SMG",
    Image = "w_mp7.png",
    Description = "Is this the MP5, but with a little more compensation?",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 15.5,
    Melee = false, HasProp = true,
    Price = 500,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_mac10"] = {
    Name = "weapon_mac10",
    Label = "Mini SMG",
    Image = "w_mac10.png",
    Description = "Is this a menu at McDonald's?",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 15.5,
    Melee = false, HasProp = true,
    Price = 1,
    Craft = {
        { Item = 'metalscrap', Amount = 414 },
		{ Item = 'copper', Amount = 348 },
		{ Item = 'steel', Amount = 384 },
        { Item = 'smgbody', Amount = 1 },
    },
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_uzi"] = {
    Name = "weapon_uzi",
    Label = "Micro SMG",
    Image = "w_uzi.png",
    Description = "Looks like an Uzi..",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 15.5,
    Melee = false, HasProp = true,
    Price = 1,
    Craft = {
        { Item = 'metalscrap', Amount = 414 },
		{ Item = 'copper', Amount = 348 },
		{ Item = 'steel', Amount = 384 },
        { Item = 'smgbody', Amount = 1 },
    },
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_colt"] = {
    Name = "weapon_colt",
    Label = "Ceramic Pistol",
    Image = "w_colt.png",
    Description = "I think this one is from COD?",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 8.5,
    Melee = false,
    Price = 2500,
    Craft = {
        { Item = 'aluminum', Amount = 45 },
        { Item = 'plastic', Amount = 45 },
        { Item = 'rubber', Amount = 45 },
        { Item = 'pistolparts', Amount = 1 },
    },
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_beretta"] = {
    Name = "weapon_beretta",
    Label = "Combat Pistol",
    Image = "w_beretta.png",
    Description = "Looks like a pretty fierce gun..",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 8.5,
    Melee = false,
    Price = 2500,
    Craft = {
        { Item = 'aluminum', Amount = 45 },
        { Item = 'plastic', Amount = 45 },
        { Item = 'rubber', Amount = 45 },
        { Item = 'pistolparts', Amount = 1 },
    },
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_fnx"] = {
    Name = "weapon_fnx",
    Label = "Vintage Pistol",
    Image = "w_fnx.png",
    Description = "",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 8.5,
    Melee = false,
    Price = 2500,
    Craft = {
        { Item = 'steel', Amount = 195 },
        { Item = 'plastic', Amount = 45 },
        { Item = 'rubber', Amount = 45 },
        { Item = 'pistolparts', Amount = 1 },
    },
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_python"] = {
    Name = "weapon_python",
    Label = "Double-Action Revolver",
    Image = "w_python.png",
    Description = "Does this weapon come from the Wild West?",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 8.5,
    Melee = false,
    Price = 250,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_diamond"] = {
    Name = "weapon_diamond",
    Label = "XM3 Pistol",
    Image = "w_diamond.png",
    Description = "",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 8.5,
    Melee = false,
    Price = 1,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_heavypistol"] = {
    Name = "weapon_heavypistol",
    Label = "Heavy Pistol",
    Image = "w_heavypistol.png",
    Description = "Wow, this thing is really heavy!",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 11.0,
    Melee = false,
    Price = 1,
    Craft = {
        { Item = 'steel', Amount = 195 },
        { Item = 'plastic', Amount = 195 },
        { Item = 'rubber', Amount = 195 },
        { Item = 'pistolparts', Amount = 2 },
    },
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_glock"] = {
    Name = "weapon_glock",
    Label = "(PD) Pistol",
    Image = "w_glock.png",
    Description = "For the real gangsters!",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 8.5,
    Melee = false,
    Price = 175,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_fn57"] = {
    Name = "weapon_fn57",
    Label = "(PD) Pistol Mk2",
    Image = "w_fn57.png",
    Description = "",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 8.5,
    Melee = false,
    Price = 175,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_fn502"] = {
    Name = "weapon_fn502",
    Label = "SNS Pistol",
    Image = "w_fn502.png",
    Description = "For the real gangsters!",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 8.5,
    Melee = false,
    Price = 2500,
    Craft = {
        { Item = 'steel', Amount = 195 },
        { Item = 'plastic', Amount = 45 },
        { Item = 'rubber', Amount = 45 },
        { Item = 'pistolparts', Amount = 1 },
    },
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_glock18c"] = {
    Name = "weapon_glock18c",
    Label = "AP Pistol",
    Image = "w_appistol.png",
    Description = "For real gangsters, but automatic, so a little less badass.",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 8.5,
    Melee = false,
    Price = 1,
    Craft = {
        { Item = 'aluminum', Amount = 720 },
        { Item = 'plastic', Amount = 630 },
        { Item = 'pistolparts', Amount = 2 },
    },
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_taser"] = {
    Name = "weapon_taser",
    Label = "(PD) Taser",
    Image = "w_taser.png",
    Description = "Nothing like having a few prongs stuck in your back. Lovely!",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 8.5,
    Melee = false,
    Price = 35,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_paintball"] = {
    Name = "weapon_paintball",
    Label = "Paintball Gun",
    Image = "w_paintball.png",
    Description = "Is this what you paint with?",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 8.5,
    Melee = false, HasProp = true,
    Price = 1,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_katana"] = {
    Name = "weapon_katana",
    Label = "Katana",
    Image = "w_katana.png",
    Description = "Is this the REAL Hattori Hanzō katana?",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 4.5,
    Melee = true, HasProp = true,
    Price = 1,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_bat"] = {
    Name = "weapon_bat",
    Label = "Club",
    Image = "w_bat.png",
    Description = "You're such a club..",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 14,
    Melee = true, HasProp = true,
    Price = 250,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_machete"] = {
    Name = "weapon_machete",
    Label = "Machete",
    Image = "w_machete.png",
    Description = "Shank on your hip",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 15,
    Melee = true, HasProp = true,
    Price = 250,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_sledgeham"] = {
    Name = "weapon_sledgeham",
    Label = "Sledgehammer",
    Image = "w_sledgehammer.png",
    Description = "I think this one is from Miley Cyrus's song Wrecking Ball!",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 4.5,
    Melee = true, HasProp = true,
    Price = 1,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_flashlight"] = {
    Name = "weapon_flashlight",
    Label = "Flashlight",
    Image = "w_flashlight.png",
    Description = "Isn't this something you play with?",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 4.5,
    Melee = true,
    Price = 10,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_nightstick"] = {
    Name = "weapon_nightstick",
    Label = "(PD) Baton",
    Image = "w_nightstick.png",
    Description = "Good for your backside.",
    Weapon = true, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 4,
    Melee = true,
    Price = 1,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_switchblade"] = {
    Name = "weapon_switchblade",
    Label = "Shank",
    Image = "w_shank.png",
    Description = "Fresh off the press from England.",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 4.5,
    Melee = true,
    Price = 1,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_shiv"] = {
    Name = "weapon_shiv",
    Label = "Shiv",
    Image = "w_shiv.png",
    Description = "For the little troublemakers in prison..",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 4.5,
    Melee = true,
    Price = 1,
    Craft = {
        { Item = 'aluminum', Amount = 3 },
        { Item = 'metalscrap', Amount = 3 },
    },
    DecayRate = 0.7,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_wrench"] = {
    Name = "weapon_wrench",
    Label = "Pipe Wrench",
    Image = "w_wrench.png",
    Description = "One good hit on the wrong pipe and it's all over.",
    Weapon = true, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 4.5,
    Melee = true,
    Price = 250,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_poolcue"] = {
    Name = "weapon_poolcue",
    Label = "Pool Cue",
    Image = "w_poolcue.png",
    Description = "",
    Weapon = true, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 4.5,
    Melee = true,
    Price = 250,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_hammer"] = {
    Name = "weapon_hammer",
    Label = "Hammer",
    Image = "w_hammer.png",
    Description = "",
    Weapon = true, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 4.5,
    Melee = true,
    Price = 250,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_crowbar"] = {
    Name = "weapon_crowbar",
    Label = "Crowbar",
    Image = "w_crowbar.png",
    Description = "",
    Weapon = true, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 4.5,
    Melee = true,
    Price = 250,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_bats"] = {
    Name = "weapon_bats",
    Label = "Wooden Bat",
    Image = "w_bat.png",
    Description = "Honestly, I just play basketball with this..",
    Weapon = true, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 4.5,
    Melee = true,
    Price = 1,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_shoe"] = {
    Name = "weapon_shoe",
    Label = "Shoe",
    Image = "w_shoes.png",
    Description = "Don't smell it, it might stink..",
    Weapon = true, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 4.5,
    Melee = true,
    Price = 1,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_snowball"] = {
    Name = "weapon_snowball",
    Label = "Snowball",
    Image = "w_snowball.png",
    Description = "It's a ball made of snow.",
    Weapon = true, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 0.0,
    Melee = true,
    Price = 1,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_snowballlauncher"] = {
    Name = "weapon_snowballlauncher",
    Label = "Snowball Launcher",
    Image = "w_snowballlauncher.png",
    Description = "This thing shoots snowballs.",
    Weapon = true, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 4.5,
    Melee = true,
    Price = 1,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_banana"] = {
    Name = "weapon_banana",
    Label = "Banana",
    Image = "banana.png",
    Description = "At least you have something to suck on...",
    Weapon = true, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 4.5,
    Melee = true,
    Price = 1,
    Craft = {},
    DecayRate = 1.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_brick"] = {
    Name = "weapon_brick",
    Label = "Brick",
    Image = "brick.png",
    Description = "Bob the Builder, can we fix it!",
    Weapon = true, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 5.0,
    Melee = true,
    Price = 1,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_grenade"] = {
    Name = "weapon_grenade",
    Label = "Grenade",
    Image = "w_grenade.png",
    Description = "I think this thing goes boom!",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 5.0,
    Melee = true,
    Price = 1,
    Craft = {
        { Item = 'aluminum', Amount = 1600 },
        { Item = 'metalscrap', Amount = 1600 },
        { Item = 'rubber', Amount = 1600 },
    },
    DecayRate = 0.5,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weapon_stickybomb"] = {
    Name = "weapon_stickybomb",
    Label = "Sticky Bomb",
    Image = "w_c4.png",
    Description = "BOOM!",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 15.0,
    Melee = true,
    Price = 1,
    Craft = {},
    DecayRate = 0.5,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["silencer_oilcan"] = {
    Name = "silencer_oilcan",
    Label = "Oil Filter",
    Image = "oilcan.png",
    Description = "Old, used oil filter. Doesn't look like it'll last long.",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 15.0,
    Price = 1,
    Craft = {
        { Item = 'aluminum', Amount = 45 },
		{ Item = 'copper', Amount = 45 },
		{ Item = 'steel', Amount = 45 },
    },
    DecayRate = 0.5,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["att_muzzlebrake"] = {
    Name = "att_muzzlebrake",
    Label = "Muzzle Brake",
    Image = "att-muzzlebrake.png",
    Description = "Reduces recoil. Attach it to your weapon through Attachments.",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 1.0,
    Price = 250,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["att_grip"] = {
    Name = "att_grip",
    Label = "Grip",
    Image = "att-grip.png",
    Description = "A foregrip for better control. Attach it to your weapon through Attachments.",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 0.8,
    Price = 250,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["att_sight"] = {
    Name = "att_sight",
    Label = "Sight",
    Image = "att-sight.png",
    Description = "Scope / holographic sight. Attach it to your weapon through Attachments.",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 0.8,
    Price = 250,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["silencer"] = {
    Name = "silencer",
    Label = "Silencer",
    Image = "silencer.png",
    Description = "A pretty high-quality little silencer..",
    Weapon = true, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 15.0,
    Price = 1,
    Craft = {
        { Item = 'aluminum', Amount = 49 },
		{ Item = 'copper', Amount = 57 },
		{ Item = 'steel', Amount = 69 },
		{ Item = 'rubber', Amount = 101 },
    },
    DecayRate = 0.8,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["laptop"] = {
    Name = "laptop",
    Label = "Laptop",
    Image = "laptop.png",
    Description = "Clarity (os) 2.0",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 10,
    Price = 7500,
    Craft = {
        { Item = 'electronics', Amount = 300 }
    },
    DecayRate = 1.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["hacking_device"] = {
    Name = "hacking_device",
    Label = "Tracker Disabling Tool",
    Image = "hacking_device.png",
    Description = "Connect this and keep driving.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 0,
    Price = 1,
    Craft = {
        { Item = 'copper', Amount = 225 },
        { Item = 'glass', Amount = 225 },
        { Item = 'electronics', Amount = 225 },
        { Item = 'aluminum', Amount = 225 },
    },
    DecayRate = 1.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["security_hacking_device"] = {
    Name = "security_hacking_device",
    Label = "Security System Hacking Device",
    Image = "security_hacking_device.png",
    Description = "Marked for confiscation.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 0,
    Price = 1,
    Craft = {
        { Item = 'copper', Amount = 149 },
        { Item = 'rubber', Amount = 149 },
        { Item = 'plastic', Amount = 149 },
        { Item = 'aluminum', Amount = 149 },
    },
    DecayRate = 1.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["fake_plate"] = {
    Name = "fake_plate",
    Label = "Fake Plate Kit",
    Image = "fake_plate.png",
    Description = "Used to change a vehicle's license plate - single use..",
    Weapon = false, Illegal = true,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 0,
    Price = 50,
    Craft = {},
    DecayRate = 0.5,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["ammo"] = {
    Name = "ammo",
    Label = "Ammo",
    Image = "ammo-pistol.png",
    Description = "",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 2,
    Price = 10,
    Craft = {},
    DecayRate = 1.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["magazine"] = {
    Name = "magazine",
    Label = "Magazine",
    Image = "mag-pistol.png",
    Description = "Use it to load bullets. Press [R] while holding your weapon to reload.",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = true, -- every magazine keeps its own bullet count (Info.Bullets)
    IsBag = false, Weight = 0.3,
    Price = 50,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["bullets"] = {
    Name = "bullets",
    Label = "Bullets",
    Image = "bullets-pistol.png",
    Description = "Loose bullets. Load them into a magazine of the same type.",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 0.02,
    Price = 1,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["herion_syringe"] = {
    Name = "herion_syringe",
    Label = "Syringe",
    Image = "herion_sryinge.png",
    Description = "This thing injects, just like you.",
    Weapon = false, Illegal = true,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 1,
    Price = 150,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["narcose_syringe"] = {
    Name = "narcose_syringe",
    Label = "Anesthetic Syringe",
    Image = "narcose_syringe.png",
    Description = "An anesthetic syringe..",
    Weapon = false, Illegal = true,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 1,
    Price = 150,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["handcuffs"] = {
    Name = "handcuffs",
    Label = "Handcuffs",
    Image = "cuffs.png",
    Description = "Please keep me out of the bedroom..",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 10,
    Craft = {
        { Item = 'metalscrap', Amount = 500 },
    },
    DecayRate = 0.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["lockpick"] = {
    Name = "lockpick",
    Label = "Lockpick Set",
    Image = "lockpick.png",
    Description = "Works wonders, if you know how to use it..",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 800,
    Craft = {
        { Item = 'aluminum', Amount = 8 },
        { Item = 'plastic', Amount = 5 },
        { Item = 'rubber', Amount = 5 },
    },
    DecayRate = 0.45,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["megaphone"] = {
    Name = "megaphone",
    Label = "Megaphone",
    Image = "megaphone.png",
    Description = "Don't talk so loudly..",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 0.2,
    Price = 600,
    Craft = {
        { Item = 'plastic', Amount = 11 },
		{ Item = 'metalscrap', Amount = 2 },
		{ Item = 'electronics', Amount = 8 },
    },
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["radio"] = {
    Name = "radio",
    Label = "Standard Radio",
    Image = "radio.png",
    Description = "Use this to talk to each other over specific frequencies. If you're caught committing a crime, you'll lose it..",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 5,
    Price = 3000,
    Craft = {
        { Item = 'plastic', Amount = 22 },
		{ Item = 'aluminum', Amount = 40 },
		{ Item = 'metalscrap', Amount = 28 },
        { Item = "electronics", Amount = 27 },
    },
    DecayRate = 0.6,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["pdradio"] = {
    Name = "pdradio",
    Label = "(PD) Walkie-Talkie",
    Image = "radio.png",
    Description = "Equipment issued by the government (PD/EMS).",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 5,
    Price = 200,
    Craft = {
        { Item = 'plastic', Amount = 29 },
		{ Item = 'aluminum', Amount = 62 },
		{ Item = 'metalscrap', Amount = 35 },
        { Item = "electronics", Amount = 30 },
    },
    DecayRate = 0.6,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["pdcamera"] = {
    Name = "pdcamera",
    Label = "(PD) Camera",
    Image = "camera.png",
    Description = "Does this thing even work? Just use your smartphone instead..<br/><br/>Equipment issued by the government (PD/EMS).",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 1,
    Price = 1250,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["bloodvial"] = {
    Name = "bloodvial",
    Label = "Blood Sample",
    Image = "bloodvial.png",
    Description = "A blood sample?",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0.0,
    Price = 0.0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["armor"] = {
    Name = "armor",
    Label = "Chest Armor",
    Image = "armor.png",
    Description = "Now that shank won't hurt as much..",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 37,
    Price = 400,
    Craft = {
        { Item = 'aluminum', Amount = 8 },
        { Item = 'plastic', Amount = 8 },
        { Item = 'rubber', Amount = 8 },
    },
    DecayRate = 0.25,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["heavyarmor"] = {
    Name = "heavyarmor",
    Label = "(PD) Chest Armor",
    Image = "armor.png",
    Description = "Equipment issued by the government (PD/EMS).",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 37,
    Price = 50,
    Craft = {},
    DecayRate = 0.25,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["lighter"] = {
    Name = "lighter",
    Label = "Lighter",
    Image = "lighter.png",
    Description = "Be careful with those fireworks..",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0,
    Price = 100,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["binoculars"] = {
    Name = "binoculars",
    Label = "Binoculars",
    Image = "binoculars.png",
    Description = "Peeping on the neighbors..",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 5,
    Price = 300,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["nitrous"] = {
    Name = "nitrous",
    Label = "Nitrous Bottle",
    Image = "nitrous.png",
    Description = "Floor it with that little bottle..",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 35,
    Price = 300,
    Craft = {
        { Item = "aluminum", Amount = 900 },
        { Item = "plastic", Amount = 38 },
    },
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["pickaxe"] = {
    Name = "pickaxe",
    Label = "Mining Pickaxe",
    Image = "pickaxe.png",
    Description = "Time to do some good old Minecrafting..",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 20,
    Price = 1,
    Craft = {},
    DecayRate = 0.00277,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["repairkit"] = {
    Name = "repairkit",
    Label = "Repair Kit",
    Image = "repairkit.png",
    Description = "A box full of tools.",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 10,
    Price = 150,
    Craft = {
        { Item = "electronics", Amount = 38 }
    },
    DecayRate = 0.25,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["tirekit"] = {
    Name = "tirekit",
    Label = "Tire Repair Kit",
    Image = "tirekit.png",
    Description = "For patching up some tires.",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 5,
    Price = 20,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["harness"] = {
    Name = "harness",
    Label = "Racing Harness",
    Image = "harness.png",
    Description = "So you don't get YEETED out anymore..",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 10000,
    Craft = {
        { Item = "rubber", Amount = 15 },
    },
    DecayRate = 1.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["advlockpick"] = {
    Name = "advlockpick",
    Label = "Advanced Lockpick",
    Image = "advlockpick.png",
    Description = "Works wonders, if you know how to use it..",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 3,
    Price = 2500,
    Craft = {
        { Item = 'aluminum', Amount = 26 },
        { Item = 'plastic', Amount = 18 },
        { Item = 'steel', Amount = 39 },
        { Item = 'metalscrap', Amount = 51 },
    },
    DecayRate = 0.6,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["electronickit"] = {
    Name = "electronickit",
    Label = "Electronic Kit",
    Image = "electronickit.png",
    Description = "Some kind of motherboard?!?",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 15,
    Price = 900,
    Craft = {
        { Item = 'electronics', Amount = 420 },
    },
    DecayRate = 0.2,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["markedbills"] = {
    Name = "markedbills",
    Label = "Marked Money",
    Image = "markedbills.png",
    Description = "A little bag of ink?",
    Weapon = false, Illegal = true,
    Metal = false, NonStack = false, HasProp = true,
    IsBag = false, Weight = 0,
    Price = 300,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["inkedmoneybag"] = {
    Name = "inkedmoneybag",
    Label = "Bag of Marked Money",
    Image = "markedbills.png",
    Description = "There's quite a bit of cash in here.. Let the bag cool down for the next few days..",
    Weapon = false, Illegal = true,
    Metal = false, NonStack = false, HasProp = true,
    IsBag = false, Weight = 0,
    Price = 300,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["rolex"] = {
    Name = "rolex",
    Label = "Gold Watch",
    Image = "gold-rolex.png",
    Description = "Does this thing work?",
    Weapon = false, Illegal = true,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 0.5,
    Price = 50,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["goldchain"] = {
    Name = "goldchain",
    Label = "Gold Chain",
    Image = "gold-necklace.png",
    Description = "What a beautiful gold chain.",
    Weapon = false, Illegal = true,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 2230,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["goldbar"] = {
    Name = "goldbar",
    Label = "Gold Bar",
    Image = "gold-bar.png",
    Description = "A big, thick, heavy bar of gold.",
    Weapon = false, Illegal = true,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 6,
    Price = 2000,
    Craft = {
        { Item = "goldnugget", Amount = 3 }
    },
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["goldnugget"] = {
    Name = "goldnugget",
    Label = "Gold Nugget",
    Image = "goldnugget.png",
    Description = "A nugget of gold.",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 2000,
    Craft = {
        { Item = "golddust", Amount = 9 }
    },
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["golddust"] = {
    Name = "golddust",
    Label = "Gold Dust",
    Image = "golddust.png",
    Description = "Can you make a curtain with this?",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 0,
    Price = 2000,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["diamond-blue"] = {
    Name = "diamond-blue",
    Label = "Blue Diamond",
    Image = "diamond-blue.png",
    Description = "A blue diamond? Is it real?",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0,
    Price = 1,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["diamond-yellow"] = {
    Name = "diamond-yellow",
    Label = "Yellow Diamond",
    Image = "diamond-yellow.png",
    Description = "Who pissed on this diamond?",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0,
    Price = 1,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["cult-necklace"] = {
    Name = "cult-necklace",
    Label = "Cult Necklace",
    Image = "cult-necklace.png",
    Description = "A cult is a religion with no political power",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["white-pearl"] = {
    Name = "white-pearl",
    Label = "White Pearl",
    Image = "white-pearl.png",
    Description = "Trapped in an oyster, freed for sale.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0.5,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["diamond-skull"] = {
    Name = "diamond-skull",
    Label = "Diamond Skull",
    Image = "diamond-skull.png",
    Description = "How many diamonds are on my head?",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 2,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["diamond-chessboard"] = {
    Name = "diamond-chessboard",
    Label = "Chessboard",
    Image = "diamond-chessboard.png",
    Description = "An expensive game of chess..",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 10,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["heirloom"] = {
    Name = "heirloom",
    Label = "Signet Ring",
    Image = "heirloom.png",
    Description = "Champion!!!!",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1.5,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["platinum-record"] = {
    Name = "platinum-record",
    Label = "Platinum Record",
    Image = "platinum-record.png",
    Description = "A small hit...",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 10,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["gold-record"] = {
    Name = "gold-record",
    Label = "Gold Record",
    Image = "gold-record.png",
    Description = "A little hit....",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 10,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["diamond-record"] = {
    Name = "diamond-record",
    Label = "Diamond Record",
    Image = "diamond-record.png",
    Description = "A big hit....",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 10,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["diamond"] = {
    Name = "diamond",
    Label = "Diamant",
    Image = "diamond.png",
    Description = "A diamond from 1918.. Wow, what a beauty.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0,
    Price = 1,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["stolen-tv"] = {
    Name = "stolen-tv",
    Label = "Flat Panel TV",
    Image = "stolen-tv.png",
    Description = "What a flat thing..",
    Weapon = false, Illegal = true,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 50,
    Price = 710,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["stolen-pc"] = {
    Name = "stolen-pc",
    Label = "Computer",
    Image = "stolen-pc.png",
    Description = "Good for a few roleplay sessions.",
    Weapon = false, Illegal = true,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 50,
    Price = 475,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["stolen-micro"] = {
    Name = "stolen-micro",
    Label = "Microwave",
    Image = "stolen-micro.png",
    Description = "Perfect with some popcorn. Delicious.",
    Weapon = false, Illegal = true,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 50,
    Price = 440,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["wheelchair"] = {
    Name = "wheelchair",
    Label = "Wheelchair",
    Image = "wheelchair.png",
    Description = "Are you crippled or something?",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 20,
    Price = 150,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["scootmobile"] = {
    Name = "scootmobile",
    Label = "Mobility Scooter",
    Image = "scootmobile.png",
    Description = "For those old fat guys.",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 30,
    Price = 5000,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["oxy-box"] = {
    Name = "oxy-box",
    Label = "Suspicious Package",
    Image = "oxy-box.png",
    Description = "Package covered in tape and milk stickers. Marked for confiscation.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true, HasProp = true,
    IsBag = false, Weight = 25,
    Price = 0,
    Craft = {},
    DecayRate = 0.002,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["money-roll"] = {
    Name = "money-roll",
    Label = "Roll of Cash",
    Image = "money-roll.png",
    Description = "This isn't a Euro? Am I supposed to put cocaine in here or something?",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0.02,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["recycle-mats"] = {
    Name = "recycle-mats",
    Label = "Recyclable Materials",
    Image = "recycle-mats.png",
    Description = "A box full of recyclable stuff..",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0.5,
    Price = 20,
    Craft = {},
    DecayRate = 0.3,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["plastic"] = {
    Name = "plastic",
    Label = "Plastic",
    Image = "plastic.png",
    Description = "Don't throw this on the street!",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 0.04,
    Price = 0,
    Craft = {
        { Item = "recycle-mats", Amount = 1 }
    },
    DecayRate = 0.5,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["metalscrap"] = {
    Name = "metalscrap",
    Label = "Metal Scrap",
    Image = "metalscrap.png",
    Description = "You can probably make something sturdy with this.",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 0.04,
    Price = 0,
    Craft = {
        { Item = "recycle-mats", Amount = 1 }
    },
    DecayRate = 0.5,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["copper"] = {
    Name = "copper",
    Label = "Koper",
    Image = "copper.png",
    Description = "A useful piece of metal that you can probably put to good use.",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 0.04,
    Price = 0,
    Craft = {
        { Item = "recycle-mats", Amount = 1 }
    },
    DecayRate = 0.5,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["aluminum"] = {
    Name = "aluminum",
    Label = "Aluminum",
    Image = "aluminum.png",
    Description = "A useful piece of metal that you can probably put to good use.",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 0.04,
    Price = 0,
    Craft = {
        { Item = "recycle-mats", Amount = 1 }
    },
    DecayRate = 0.5,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["steel"] = {
    Name = "steel",
    Label = "Steel",
    Image = "steel.png",
    Description = "A useful piece of metal that you can probably put to good use.",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 0.04,
    Price = 0,
    Craft = {
        { Item = "recycle-mats", Amount = 1 }
    },
    DecayRate = 0.5,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["rubber"] = {
    Name = "rubber",
    Label = "Rubber",
    Image = "rubber.png",
    Description = "A juicy piece of rubber..",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0.04,
    Price = 0,
    Craft = {
        { Item = "recycle-mats", Amount = 1 }
    },
    DecayRate = 0.5,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["glass"] = {
    Name = "glass",
    Label = "Sheet of Glass",
    Image = "glassplate.png",
    Description = "It's quite fragile.. Be careful.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0.04,
    Price = 0,
    Craft = {
        { Item = "recycle-mats", Amount = 1 }
    },
    DecayRate = 0.5,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["electronics"] = {
    Name = "electronics",
    Label = "Electronics",
    Image = "electronics.png",
    Description = "Can I build a computer with this?",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0.04,
    Price = 0,
    Craft = {
        { Item = "recycle-mats", Amount = 1 }
    },
    DecayRate = 0.5,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["heavy-thermite"] = {
    Name = "heavy-thermite",
    Label = "Thermite Charge",
    Image = "hthermite.png",
    Description = "Wow, this is extremely flammable..",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 6,
    Price = 250,
    Craft = {
        { Item = 'aluminum', Amount = 113 },
        { Item = 'copper', Amount = 113 },
        { Item = 'rubber', Amount = 75 },
        { Item = 'plastic', Amount = 113 },
        { Item = 'electronics', Amount = 150 },
    },
    DecayRate = 1.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["coin"] = {
    Name = "coin",
    Label = "Lucky Coin",
    Image = "coin.png",
    Description = "Will a lucky coin bring you good luck??",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 0,
    Price = 40,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["dice"] = {
    Name = "dice",
    Label = "Dice",
    Image = "dice.png",
    Description = "A set of dice for a little gambling.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0,
    Price = 40,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["jail-food"] = {
    Name = "jail-food",
    Label = "Food Tray",
    Image = "jailfood.png",
    Description = "Looks just as bad as the police's aim..",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 25,
    Price = 0,
    Craft = {},
    DecayRate = 0.001,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["bandage"] = {
    Name = "bandage",
    Label = "Bandage",
    Image = "bandage.png",
    Description = "Bandages for minor wounds and bleeding.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = .25,
    Price = 85,
    Craft = {},
    DecayRate = 0.25,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["ifak"] = {
    Name = "ifak",
    Label = "(PD) IFAK",
    Image = "ifak.png",
    Description = "Equipment issued by the government (PD/EMS).",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0.25,
    Price = 85,
    Craft = {},
    DecayRate = 0.25,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["medkit"] = {
    Name = "medkit",
    Label = "(PD) Medical Kit",
    Image = "medkit.png",
    Description = "Equipment issued by the government (PD/EMS).",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0.25,
    Price = 15,
    Craft = {},
    DecayRate = 0.25,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["oxy"] = {
    Name = "oxy",
    Label = "Oxycodon 100mg",
    Image = "oxy.png",
    Description = "Welgeteld 100 milligram aan best zware medicatie.",
    Weapon = false, Illegal = true,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 3,
    Price = 1,
    Craft = {},
    DecayRate = 0.75,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["lsd-strip"] = {
    Name = "lsd-strip",
    Label = "Postage Stamp",
    Image = "postzegel.png",
    Description = "Where is the mail going?",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 200,
    Craft = {},
    DecayRate = 0.3,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["joint"] = {
    Name = "joint",
    Label = "3g Joint",
    Image = "joint.png",
    Description = "A joint to enjoy.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0.2,
    Price = 1,
    Craft = {
        { Item = 'rolling-paper', Amount = 2 },
		{ Item = 'weed-dried-bud-two', Amount = 2 },
    },
    DecayRate = 0.2,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["customjoint"] = {
    Name = "customjoint",
    Label = "3g Joint",
    Image = "joint.png",
    Description = "A joint to enjoy.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0.2,
    Price = 1,
    Craft = {},
    DecayRate = 0.2,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["health-pack"] = {
    Name = "health-pack",
    Label = "First Aid Kit",
    Image = "bandage.png",
    Description = "Something for first aid?",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 10,
    Price = 525,
    Craft = {},
    DecayRate = 0.25,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["bong"] = {
    Name = "bong",
    Label = "Bong",
    Image = "bong.png",
    Description = "Bong",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 0,
    Craft = {
        { Item = "steel", Amount = 40 },
        { Item = "aluminum", Amount = 30 },
        { Item = "copper", Amount = 30 },
    },
    DecayRate = 1.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["phone"] = {
    Name = "phone",
    Label = "Phone",
    Image = "phone.png",
    Description = "To call the girlfriend you don't have..",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 5,
    Price = 1000,
    Craft = {
		{ Item = 'plastic', Amount = 45 },
		{ Item = 'metalscrap', Amount = 8 },
		{ Item = 'electronics', Amount = 30 },
    },
    DecayRate = 1.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["burnerphone"] = {
    Name = "phone",
    Label = "Burner Telefoon",
    Image = "phone.png",
    Description = "A disposable phone for calls and texts only. - Marked for confiscation.",
    Weapon = false, Illegal = true,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 1,
    Price = 5,
    Craft = {
		{ Item = 'plastic', Amount = 135 },
		{ Item = 'metalscrap', Amount = 23 },
		{ Item = 'electronics', Amount = 90 },
    },
    DecayRate = 1.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["sandwich"] = {
    Name = "sandwich",
    Label = "Sandwich",
    Image = "bread.png",
    Description = "A sandwich with filling.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 5,
    Price = 50,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["water_bottle"] = {
    Name = "water_bottle",
    Label = "Water",
    Image = "water.png",
    Description = "Have a refreshing drink.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 50,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["slushy"] = {
    Name = "slushy",
    Label = "The best slushy ever",
    Image = "slushy.png",
    Description = "The only thing that tastes good in prison.. It's a pretty heavy cup, though..",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 15,
    Price = 60,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["kurkakola"] = {
    Name = "kurkakola",
    Label = "E-Cola",
    Image = "ecola.png",
    Description = "A can of E-Cola. Pretty tasty.",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 50,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["sprunk"] = {
    Name = "sprunk",
    Label = "Sprunk",
    Image = "sprunk.png",
    Description = "Want some Sprunk with that?",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 50,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["whiskey"] = {
    Name = "whiskey",
    Label = "Whiskey",
    Image = "whiskey.png",
    Description = "Best served with ice cubes.",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 5,
    Price = 80,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["beer"] = {
    Name = "beer",
    Label = "Bier",
    Image = "beer.png",
    Description = "Want a beer with that?",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 80,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["beer-heineken"] = {
    Name = "beer-heineken",
    Label = "Heineken",
    Image = "beer-heineken.png",
    Description = "Want a beer with that?",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 80,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["beer-hertogjan"] = {
    Name = "beer-hertogjan",
    Label = "Hertog Jan",
    Image = "beer-hertogjan.png",
    Description = "Want a beer with that?",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 80,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["beer-grolsch"] = {
    Name = "beer-grolsch",
    Label = "Grolsch",
    Image = "beer-grolsch.png",
    Description = "Want a beer with that?",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 80,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["red-wine"] = {
    Name = "red-wine",
    Label = "Red Wine",
    Image = "red-wine.png",
    Description = "Want a glass of red wine?",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 80,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["white-wine"] = {
    Name = "white-wine",
    Label = "White Wine",
    Image = "white-wine.png",
    Description = "Want a glass of white wine?",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 80,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["bacardi"] = {
    Name = "bacardi",
    Label = "Bacardi",
    Image = "bacardi.png",
    Description = "Want some Bacardi?",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 80,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["vodka"] = {
    Name = "vodka",
    Label = "Vodka",
    Image = "vodka.png",
    Description = "Want some vodka?",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 80,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["goldstrike"] = {
    Name = "goldstrike",
    Label = "Goldstrike Shot",
    Image = "goldstrike.png",
    Description = "Want a shot?",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 80,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["flugel"] = {
    Name = "flugel",
    Label = "Flugel Shot",
    Image = "flugel.png",
    Description = "Want a shot?",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 80,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["goldstrike"] = {
    Name = "goldstrike",
    Label = "Tequila Shot",
    Image = "tequila.png",
    Description = "Want a shot?",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 80,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["cocktail-split"] = {
    Name = "cocktail-split",
    Label = "Split",
    Image = "cocktail-split.png",
    Description = "Oohhh, a COCKtail.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 80,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["cocktail-pinacolada"] = {
    Name = "cocktail-pinacolada",
    Label = "Pina Colada",
    Image = "cocktail-pinacolada.png",
    Description = "Oohhh, a COCKtail.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 80,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["cocktail-aperolspritz"] = {
    Name = "cocktail-aperolspritz",
    Label = "Aperol Spritz",
    Image = "cocktail-aperolspritz.png",
    Description = "Oohhh, a COCKtail.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 80,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["chocolade"] = {
    Name = "chocolade",
    Label = "Chocolate Bar",
    Image = "chocolade.png",
    Description = "A chocolate bar. Careful, you'll get fat!",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 50,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["coffee"] = {
    Name = "coffee",
    Label = "Koffie",
    Image = "coffee.png",
    Description = "Great for the morning.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 50,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["420-choco"] = {
    Name = "420-choco",
    Label = "420 Chocolate Bar",
    Image = "420-choco.png",
    Description = "Is this bar from Jonko Jay?",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0.2,
    Price = 50,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["chips"] = {
    Name = "chips",
    Label = "Chips",
    Image = "chips.png",
    Description = "Tasty chips.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 50,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["macncheese"] = {
    Name = "macncheese",
    Label = "Mac and Cheese",
    Image = "macncheese.png",
    Description = "Just like Grandma used to make.. Delicious!",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 50,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["fristi"] = {
    Name = "fristi",
    Label = "Fristi",
    Image = "Fristi.png",
    Description = "Pink poison?",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 50,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["chocomelk"] = {
    Name = "chocomelk",
    Label = "chocomelk",
    Image = "chocomelk.png",
    Description = "Liquid poop in a bottle",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 50,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["fernandes"] = {
    Name = "fernandes",
    Label = "Fernandes",
    Image = "fernandes.png",
    Description = "Nice and sweet.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 50,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["mint"] = {
    Name = "mint",
    Label = "Peppermint",
    Image = "pepermint.png",
    Description = "Freshen up your stinky breath.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 50,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["cocktail-1"] = {
    Name = "cocktail-1",
    Label = "Naughty Bullet",
    Image = "cocktail-1.png",
    Description = "Oohhh, a COCKtail.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 80,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["cocktail-2"] = {
    Name = "cocktail-2",
    Label = "Arju(n) Hot",
    Image = "cocktail-2.png",
    Description = "This is very, very pink.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 80,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["cocktail-3"] = {
    Name = "cocktail-3",
    Label = "Noahs Ark",
    Image = "cocktail-3.png",
    Description = "Looks tasty and tropical.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 80,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["scuba-gear"] = {
    Name = "scuba-gear",
    Label = "Diving Gear",
    Image = "scuba-gear.png",
    Description = "Hope you don't suffocate..",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 45,
    Price = 2500,
    Craft = {},
    DecayRate = 1.5,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["fishingrod"] = {
    Name = "fishingrod",
    Label = "Fishing Rod",
    Image = "fishingrod.png",
    Description = "Time to do some fishing..",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 10,
    Price = 100,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["fish"] = {
    Name = "fish",
    Label = "Fish",
    Image = "fish-bass.png",
    Description = "A bass not the guitar bass but the fish bass.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0.5,
    Price = 1,
    Craft = {},
    DecayRate = 0.02,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["plasticbag"] = {
    Name = "plasticbag",
    Label = "Plastic Bag",
    Image = "plasticbag.png",
    Description = "Put the bag over your head and go, right??",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 2,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["shoe"] = {
    Name = "shoe",
    Label = "Old Shoe",
    Image = "shoe.png",
    Description = "Quite a sporty little model.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 2,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["hunting-knife"] = {
    Name = "hunting-knife",
    Label = "Hunting Knife",
    Image = "hunting-knife.png",
    Description = "Don't play around with it like The Knife Goes Chop Chop Chop..",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 11,
    Price = 100,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["hunting-bait"] = {
    Name = "hunting-bait",
    Label = "Bait",
    Image = "hunting-bait.png",
    Description = "I don't think this is for human consumption.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 50,
    Craft = {},
    DecayRate = 0.02,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["hunting-carcass-one"] = {
    Name = "hunting-carcass-one",
    Label = "Poor-Quality Carcass",
    Image = "hunting-carcass1.png",
    Description = "What is this? Did you shoot the animal with an AK?",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true, HasProp = true,
    IsBag = false, Weight = 50,
    Price = 0,
    Craft = {},
    DecayRate = 0.02,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["hunting-carcass-two"] = {
    Name = "hunting-carcass-two",
    Label = "Average-Quality Carcass",
    Image = "hunting-carcass2.png",
    Description = "Not a bad carcass, actually..",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true, HasProp = true,
    IsBag = false, Weight = 50,
    Price = 0,
    Craft = {},
    DecayRate = 0.02,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["hunting-carcass-three"] = {
    Name = "hunting-carcass-three",
    Label = "Perfect Carcass",
    Image = "hunting-carcass3.png",
    Description = "This could make a decent profit..",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true, HasProp = true,
    IsBag = false, Weight = 50,
    Price = 0,
    Craft = {},
    DecayRate = 0.02,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["hunting-carcass-four"] = {
    Name = "hunting-carcass-four",
    Label = "Perfect Carcass",
    Image = "hunting-carcass4.png",
    Description = "Is dit karkas wel legaal?",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true, HasProp = true,
    IsBag = false, Weight = 50,
    Price = 0,
    Craft = {},
    DecayRate = 0.02,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["licence"] = {
    Name = "licence",
    Label = "Permit",
    Image = "licence.png",
    Description = "Official documents.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 0,
    Price = 1,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["id_card"] = {
    Name = "id_card",
    Label = "ID Card",
    Image = "license-id.png",
    Description = "A card containing all your personal information.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 0,
    Price = 500,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["driver_license"] = {
    Name = "driver_license",
    Label = "Driver's License",
    Image = "license-drive.png",
    Description = "Proof that you are allowed to drive a vehicle.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 0,
    Price = 500,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["big-repair"] = {
    Name = "big-repair",
    Label = "Large Repair Kit",
    Image = "big-repair.png",
    Description = "A large repair kit.",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 20,
    Price = 100,
    Craft = {
        { Item = "electronics", Amount = 23 },
        { Item = "aluminum", Amount = 23 },
    },
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["walkstick"] = {
    Name = "walkstick",
    Label = "Walking Cane",
    Image = "walkstick.png",
    Description = "For the old men.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0,
    Price = 150,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["jerry_can"] = {
    Name = "jerry_can",
    Label = "Jerrycan",
    Image = "jerry_can.png",
    Description = "I usually take a sniff of this. I love it.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 8,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["parachute"] = {
    Name = "parachute",
    Label = "Parachute",
    Image = "parachute.png",
    Description = "For the real daredevils.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 30,
    Price = 350,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["moneybag"] = {
    Name = "moneybag",
    Label = "Bag of Money",
    Image = "moneybag.png",
    Description = "I think there's some money in here.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 10,
    Price = 0,
    Craft = {},
    DecayRate = 1.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["rentalpapers"] = {
    Name = "rentalpapers",
    Label = "Rental Documents",
    Image = "rentalpapers.png",
    Description = "Proof of payment. Use this to get an extra set of keys.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 0,
    Price = 0,
    Craft = {},
    DecayRate = 0.018,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["xray-brain"] = {
    Name = "xray-brain",
    Label = "Brain MRI",
    Image = "xray-hersen.png",
    Description = "Someone's brain MRI.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0,
    Price = 1,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["xray-arm"] = {
    Name = "xray-arm",
    Label = "Arm X-ray",
    Image = "xray-arm.png",
    Description = "Someone's arm X-ray.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0,
    Price = 1,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["teddy"] = {
    Name = "teddy",
    Label = "Teddy Bear",
    Image = "teddy.png",
    Description = "Hug me.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 1,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["melissa-teddy"] = {
    Name = "melissa-teddy",
    Label = "Teddie",
    Image = "melissa-teddy.png",
    Description = "I'd keep the zipper closed..",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 1,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["umbrella"] = {
    Name = "umbrella",
    Label = "Umbrella",
    Image = "umbrella.png",
    Description = "To avoid getting too wet..",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0.5,
    Price = 500,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["hat"] = {
    Name = "hat",
    Label = "Cap",
    Image = "hat.png",
    Description = "A little hat.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 1,
    Price = 10,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["mask"] = {
    Name = "mask",
    Label = "Mask",
    Image = "mask.png",
    Description = "A little mask.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 1,
    Price = 10,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["glasses"] = {
    Name = "glasses",
    Label = "Glasses",
    Image = "glasses.png",
    Description = "A pair of glasses.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 1,
    Price = 10,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["earrings"] = {
    Name = "earrings",
    Label = "Earrings",
    Image = "white-pearl.png",
    Description = "A pair of earrings.",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 0.5,
    Price = 10,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["watch"] = {
    Name = "watch",
    Label = "Watch",
    Image = "m_watch.png",
    Description = "What time is it?",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 0.5,
    Price = 10,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["wallet"] = {
    Name = "wallet",
    Label = "Wallet",
    Image = "wallet.png",
    Description = "A wallet.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 0.5,
    Price = 50,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["keyring"] = {
    Name = "keyring",
    Label = "Key Ring",
    Image = "keyfob.png",
    Description = "All your keys on one ring.",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 0.5,
    Price = 25,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["backpack"] = {
    Name = "backpack",
    Label = "Backpack",
    Image = "duffel-bag.png",
    Description = "Equip it in your BODY slot to gain extra slots and carrying capacity.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = true, Weight = 2.0,
    Price = 500,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["hairtie"] = {
    Name = "hairtie",
    Label = "Scrunchie",
    Image = "scrunchie.png",
    Description = "We all know what this is really for...",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 25,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["vpn"] = {
    Name = "vpn",
    Label = "VPN",
    Image = "vpn.png",
    Description = "Can I use this to connect through other countries?",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 5,
    Price = 300,
    Craft = {},
    DecayRate = 1.0,
    FullDecay = true,
    InsertInto = {},
}

-- Shared.Items["printerdocument"] = {
--     Name = "printerdocument",
--     Label = "Document",
--     Image = "printerdocument.png",
--     Description = "",
--     Weapon = false, Illegal = false,
--     Metal = false, NonStack = true,
--     IsBag = false, Weight = 0,
--     Price = 0,
--     Craft = {},
--     DecayRate = 0.0,
--     FullDecay = false,
--     InsertInto = {},
-- }

Shared.Items["spikestrip"] = {
    Name = "spikestrip",
    Label = "(PD) Spijkermat",
    Image = "spikestrip.png",
    Description = "Equipment issued by the government (PD/EMS).",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 12,
    Price = 450,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["welcome"] = {
    Name = "welcome",
    Label = "Welcome Gift",
    Image = "welcome.png",
    Description = "A gift for a new citizen!",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 0,
    Price = 0,
    Craft = {},
    DecayRate = 0.02,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["bitterbal"] = {
    Name = "bitterbal",
    Label = "Dutch Meatball",
    Image = "bitterbal.png",
    Description = "A tasty Dutch meatball.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 5,
    Price = 250,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["frikandel"] = {
    Name = "frikandel",
    Label = "Frikandel Sandwich",
    Image = "frikandel.png",
    Description = "A tasty frikandel.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 5,
    Price = 250,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["car-polish"] = {
    Name = "car-polish",
    Label = "Fantastic Cleaning Kit",
    Image = "car-polish.png",
    Description = "To keep your car sparkling clean..",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 3,
    Price = 1,
    Craft = {
        { Item = "water_bottle", Amount = 1 },
        { Item = "plastic", Amount = 8 },
    },
    DecayRate = 1.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["cannabiscup"] = {
    Name = "cannabiscup",
    Label = "Trophy",
    Image = "cannabiscup.png",
    Description = "A real winner, that's you!",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 1,
    Price = 1,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

-- Shared.Items["printer"] = {
--     Name = "printer",
--     Label = "Printer",
--     Image = "printer.png",
--     Description = "Something involving ink and paper...",
--     Weapon = false, Illegal = false,
--     Metal = false, NonStack = true,
--     IsBag = false, Weight = 30,
--     Price = 3000,
--     Craft = {
--         { Item = 'plastic', Amount = 60 },
--         { Item = 'aluminum', Amount = 128 },
--         { Item = 'metalscrap', Amount = 75 },
--         { Item = "electronics", Amount = 60 },
--     },
--     DecayRate = 0.0,
--     FullDecay = false,
--     InsertInto = {},
-- }

-- Shared.Items["printer-pack-paper"] = {
--     Name = "printer-pack-paper",
--     Label = "Printer Pak Papier",
--     Image = "printer-pack-paper.png",
--     Description = "A pack with some sheets of paper..",
--     Weapon = false, Illegal = false,
--     Metal = false, NonStack = true,
--     IsBag = false, Weight = 7,
--     Price = 685,
--     Craft = {
--         { Item = 'plastic', Amount = 45 },
--     },
--     DecayRate = 5.0,
--     FullDecay = true,
--     InsertInto = {},
-- }

-- Shared.Items["printer-paper"] = {
--     Name = "printer-paper",
--     Label = "Printer Papier",
--     Image = "printer-paper.png",
--     Description = "What will you print on the paper this time?",
--     Weapon = false, Illegal = false,
--     Metal = false, NonStack = false,
--     IsBag = false, Weight = 1,
--     Price = 0,
--     Craft = {},
--     DecayRate = 0.0,
--     FullDecay = false,
--     InsertInto = {},
-- }

Shared.Items["nightvision"] = {
    Name = "nightvision",
    Label = "Night Vision Goggles",
    Image = "nightvision.png",
    Description = "Mil-Spec. High price, low quality.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 10,
    Price = 5000,
    Craft = {},
    DecayRate = 0.2,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["ingredient"] = {
    Name = "ingredient",
    Label = "Ingredient",
    Image = "ingredient.png",
    Description = "Used to prepare food.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0.5,
    Price = 1,
    Craft = {},
    DecayRate = 0.5,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["uwu-mystery-box"] = {
    Name = "uwu-mystery-box",
    Label = "Mystery Box",
    Image = "uwu-toy-package.png",
    Description = "Contains a random UwU Cafe toy.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["uwu-toy-biker"] = {
    Name = "uwu-toy-biker",
    Label = "Motor Poesje",
    Image = "uwu-toy-biker.png",
    Description = "UwU Cafe (1/9). Collect them all!",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

-- Shared.Items["uwu-toy-banggang"] = {
--     Name = "uwu-toy-banggang",
--     Label = "Bang Gang Poesje",
--     Image = "uwu-toy-banggang.png",
--     Description = "UwU Cafe (2/11). Collect them all!",
--     Weapon = false, Illegal = false,
--     Metal = false, NonStack = false,
--     IsBag = false, Weight = 1,
--     Price = 0,
--     Craft = {},
--     DecayRate = 0.0,
--     FullDecay = false,
--     InsertInto = {},
-- }

Shared.Items["uwu-toy-business"] = {
    Name = "uwu-toy-business",
    Label = "Ondernemer Poesje",
    Image = "uwu-toy-business.png",
    Description = "UwU Cafe (2/9). Collect them all!",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["uwu-toy-burglar"] = {
    Name = "uwu-toy-burglar",
    Label = "Overvaller Poesje",
    Image = "uwu-toy-burglar.png",
    Description = "UwU Cafe (3/9). Collect them all!",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["uwu-toy-doctor"] = {
    Name = "uwu-toy-doctor",
    Label = "Doktor Poesje",
    Image = "uwu-toy-doctor.png",
    Description = "UwU Cafe (4/9). Collect them all!",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

-- Shared.Items["uwu-toy-cringe"] = {
--     Name = "uwu-toy-cringe",
--     Label = "Cringe Boys Poesje",
--     Image = "uwu-toy-cringe.png",
--     Description = "UwU Cafe (6/11). Collect them all!",
--     Weapon = false, Illegal = false,
--     Metal = false, NonStack = false,
--     IsBag = false, Weight = 1,
--     Price = 0,
--     Craft = {},
--     DecayRate = 0.0,
--     FullDecay = false,
--     InsertInto = {},
-- }

Shared.Items["uwu-toy-fisher"] = {
    Name = "uwu-toy-fisher",
    Label = "Visser Poesje",
    Image = "uwu-toy-fisher.png",
    Description = "UwU Cafe (5/9). Collect them all!",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["uwu-toy-maid"] = {
    Name = "uwu-toy-maid",
    Label = "Schoonmaakster Poesje",
    Image = "uwu-toy-maid.png",
    Description = "UwU Cafe (6/9). Collect them all!",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["uwu-toy-officer"] = {
    Name = "uwu-toy-officer",
    Label = "Politie Poesje",
    Image = "uwu-toy-officer.png",
    Description = "UwU Cafe (7/9). Collect them all!",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["uwu-toy-wizard"] = {
    Name = "uwu-toy-wizard",
    Label = "Heksen Poesje",
    Image = "uwu-toy-wizard.png",
    Description = "UwU Cafe (8/9). Collect them all!",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["uwu-toy-worker"] = {
    Name = "uwu-toy-worker",
    Label = "Bouwvakker Poesje",
    Image = "uwu-toy-worker.png",
    Description = "UwU Cafe (9/9). Collect them all!",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["tcg-binder"] = {
    Name = "tcg-binder",
    Label = "Trading Card Binder",
    Image = "tcg-binder.png",
    Description = "A binder for storing all your trading cards.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 10,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["tcg-card"] = {
    Name = "tcg-card",
    Label = "Trading Card",
    Image = "tcg-card.png",
    Description = "",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 0,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["tcg-case"] = {
    Name = "tcg-case",
    Label = "Hard Case",
    Image = "tcg-case.png",
    Description = "",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 1,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["tcg-booster"] = {
    Name = "tcg-booster",
    Label = "Booster Pack",
    Image = "tcg-booster.png",
    Description = "All set booster pack met 3 kaarten.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["tcg-civbooster"] = {
    Name = "tcg-civbooster",
    Label = "Booster Pack",
    Image = "tcg-civbooster.png",
    Description = "Civ set booster pack met 3 kaarten.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["tcg-crewbooster"] = {
    Name = "tcg-crewbooster",
    Label = "Booster Pack",
    Image = "tcg-crewbooster.png",
    Description = "Crew set booster pack met 3 kaarten.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["tcg-govbooster"] = {
    Name = "tcg-govbooster",
    Label = "Booster Pack",
    Image = "tcg-govbooster.png",
    Description = "Gov set booster pack met 3 kaarten.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["tcg-promobooster"] = {
    Name = "tcg-promobooster",
    Label = "Booster Pack",
    Image = "tcg-promobooster.png",
    Description = "All set booster pack met 6 kaarten.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["tcg-promopack"] = {
    Name = "tcg-promopack",
    Label = "Promotional Pack",
    Image = "tcg-promopack.png",
    Description = "2x Civs Booster - 2x Crews Booster 2x Gov Booster",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["business-ticket"] = {
    Name = "business-ticket",
    Label = "Bestelling Bon",
    Image = "business-ticket.png",
    Description = "This receipt contains an order that needs to be prepared quickly!",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0.15,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["worstenbroodje"] = {
    Name = "worstenbroodje",
    Label = "Sausage Roll",
    Image = "sausageroll.png",
    Description = "A sausage roll with a touch of Brabant.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 5,
    Price = 50,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["moneycase"] = {
    Name = "moneycase",
    Label = "Suitcase",
    Image = "moneycase.png",
    Description = "Holds around €50k in large bills.",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 10,
    Price = 500,
    Craft = {},
    DecayRate = 1.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["advmoneycase"] = {
    Name = "advmoneycase",
    Label = "Large Suitcase",
    Image = "advmoneycase.png",
    Description = "Holds around €100k in large bills.",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 20,
    Price = 1000,
    Craft = {},
    DecayRate = 1.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["explosive"] = {
    Name = "explosive",
    Label = "Explosief",
    Image = "explosive.png",
    Description = "Be careful with those fireworks..",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 15,
    Price = 4500,
    Craft = {
        { Item = "metalscrap", Amount = 1400 },
        { Item = "plastic", Amount = 1800 },
        { Item = "rubber", Amount = 320 },
        { Item = "electronickit", Amount = 5 },
    },
    DecayRate = 1.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["business-bag"] = {
    Name = "business-bag",
    Label = "Company Bag",
    Image = "business-bag.png",
    Description = "There's some nice stuff in here.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = true, Weight = 1,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["zombie-antidote"] = {
    Name = "zombie-antidote",
    Label = "Infect Antidote",
    Image = "syringe.png",
    Description = "A syringe filled with some green stuff..",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 1,
    Price = 10,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["receipt"] = {
    Name = "receipt",
    Label = "Receipt",
    Image = "business-ticket.png",
    Description = "A receipt with some codes written on it..",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 1,
    Price = 500,
    Craft = {},
    DecayRate = 0.1,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["yacht-pad"] = {
    Name = "yacht-pad",
    Label = "Pepega Pad",
    Image = "yacht-pad.png",
    Description = "Preconfigured to access certain systems. Marked for confiscation.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 10,
    Price = 1,
    Craft = {},
    DecayRate = 0.075,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["heist-codes"] = {
    Name = "heist-codes",
    Label = "Access Codes",
    Image = "business-ticket.png",
    Description = "Temporary code used to disable certain security systems. Marked for confiscation.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 1,
    Price = 500,
    Craft = {},
    DecayRate = 0.1,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["foodchain-food-item"] = {
    Name = "foodchain-food-item",
    Label = "Food",
    Image = "foodchain-food-item.png",
    Description = "",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 2,
    Price = 5,
    Craft = {},
    DecayRate = 0.04,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["foodchain-side-item"] = {
    Name = "foodchain-side-item",
    Label = "Side",
    Image = "foodchain-side-item.png",
    Description = "",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 2,
    Price = 5,
    Craft = {},
    DecayRate = 0.04,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["foodchain-dessert-item"] = {
    Name = "foodchain-dessert-item",
    Label = "Dessert",
    Image = "foodchain-dessert-item.png",
    Description = "",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 2,
    Price = 5,
    Craft = {},
    DecayRate = 0.04,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["foodchain-drink-item"] = {
    Name = "foodchain-drink-item",
    Label = "Drink",
    Image = "foodchain-drink-item.png",
    Description = "",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 2,
    Price = 5,
    Craft = {},
    DecayRate = 0.04,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["foodchain-alcohol-item"] = {
    Name = "foodchain-alcohol-item",
    Label = "Alcohol",
    Image = "foodchain-alcohol-item.png",
    Description = "",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 2,
    Price = 5,
    Craft = {},
    DecayRate = 0.04,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["detcord"] = {
    Name = "detcord",
    Label = "(PD) Det. Cord",
    Image = "detcord.png",
    Description = "Equipment issued by the government (PD/EMS).",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 5.0,
    Price = 150,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["cryptostick"] = {
    Name = "cryptostick",
    Label = "Crypto Stick",
    Image = "cryptostick.png",
    Description = "Een USB met 0 Crypto erop.",
    Weapon = false, Illegal = true,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 750,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["farming-seed"] = {
    Name = "farming-seed",
    Label = "Seed",
    Image = "farming-seed.png",
    Description = "Seeds.",
    Weapon = false, Illegal = true,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0,
    Price = 100,
    Craft = {},
    DecayRate = 0.75,
    FullDecay = true,
    InsertInto = { 'farming-hoe' },
}

Shared.Items["farming-seedbag"] = {
    Name = "farming-seedbag",
    Label = "Bag of Seeds",
    Image = "farming-seedbag.png",
    Description = "A bag of seeds 💦. Keep your seed collection safe with you.",
    Weapon = false, Illegal = true,
    Metal = false, NonStack = true,
    IsBag = true, Weight = 1,
    Price = 200,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["producebasket"] = {
    Name = "producebasket",
    Label = "Fruit Basket",
    Image = "producebasket.png",
    Description = "A hand-woven basket for storing the produce from your harvest.",
    Weapon = false, Illegal = true,
    Metal = false, NonStack = true,
    IsBag = true, Weight = 5,
    Craft = {},
    Price = 340,
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["farming-wateringcan"] = {
    Name = "farming-wateringcan",
    Label = "Watering Can",
    Image = "farming-wateringcan.png",
    Description = "Water?",
    Weapon = false, Illegal = true,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 2,
    Price = 700,
    Craft = {},
    DecayRate = 5.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["farming-pitchfork"] = {
    Name = "farming-pitchfork",
    Label = "Pitchfork",
    Image = "farming-pitchfork.png",
    Description = "A pitchfork to stick up your backside.",
    Weapon = false, Illegal = true,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 2,
    Price = 1100,
    Craft = {},
    DecayRate = 0.25,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["farming-hoe"] = {
    Name = "farming-hoe",
    Label = "Hoe",
    Image = "farming-hoe.png",
    Description = "Can be used to plant multiple seeds at once.",
    Weapon = false, Illegal = true,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 2,
    Price = 900,
    Craft = {},
    DecayRate = 0.25,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["gang-chain"] = {
    Name = "gang-chain",
    Label = "Loser Necklace",
    Image = "gold-necklace.png",
    Description = "You're a loser if you wear this necklace..",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 1.0,
    Price = 10,
    Craft = {
        { Item = "goldbar", Amount = 3 },
        { Item = 'aluminum', Amount = 150 },
        { Item = "copper", Amount = 150 },
    },
    DecayRate = 0.25,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["identification-badge"] = {
    Name = "identification-badge",
    Label = "Work ID",
    Image = "badge.png",
    Description = "An ID card proving that you work somewhere.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 0,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["newscamera"] = {
    Name = "newscamera",
    Label = "News Camera",
    Image = "newscamera.png",
    Description = "A little dusty.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 11,
    Price = 100,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["newsmic"] = {
    Name = "newsmic",
    Label = "News Microphone",
    Image = "newsmic.png",
    Description = "Is this thing on?",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 1,
    Price = 100,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["goldpan"] = {
    Name = "goldpan",
    Label = "Gold Pan",
    Image = "goldpan.png",
    Description = "Nice piece of equipment.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 1,
    Price = 6500,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["jewelry-part"] = {
    Name = "jewelry-part",
    Label = "Jewelry Component",
    Image = "jewelry-part.png",
    Description = "A jewelry component. You could get a fair amount of money for selling this!",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0,
    Price = 0,
    Craft = {
        { Item = 'golddust', Amount = 5 }
    },
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["lawnchair"] = {
    Name = "lawnchair",
    Label = "Lawnchair",
    Image = "lawnchair.png",
    Description = "Perfect for relaxing in your backyard.",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 0.85,
    Price = 300,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

-- Weed
Shared.Items["fertilizer"] = {
    Name = "fertilizer",
    Label = "Manure",
    Image = "fertilizer.png",
    Description = "Did you poop in this?",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 2.5,
    Price = 76,
    Craft = {
        { Item = "ingredient", CustomType = "Cabbage", Amount = 2 },
        { Item = "ingredient", CustomType = "Carrot", Amount = 2 },
        { Item = "ingredient", CustomType = "Potato", Amount = 2 },
        { Item = "ingredient", CustomType = "Tomato", Amount = 2 },
    },
    DecayRate = 0.25,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["weed-seed-male"] = {
    Name = "weed-seed-male",
    Label = "Weed Seed (Male)",
    Image = "weed-seeds.png",
    Description = "Let my young ones grow!",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1.5,
    Price = 1,
    Craft = {},
    DecayRate = 0.1,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weed-seed-female"] = {
    Name = "weed-seed-female",
    Label = "Weed Seed (Female)",
    Image = "weed-seeds.png",
    Description = "Let my young ones grow!",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1.5,
    Price = 101,
    Craft = {},
    DecayRate = 0.1,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weed-branch"] = {
    Name = "weed-branch",
    Label = "Weed Branch",
    Image = "weed-branch.png",
    Description = "The best smell ever!!!",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false, HasProp = true,
    IsBag = false, Weight = 25.0,
    Price = 1,
    Craft = {},
    DecayRate = 0.1,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weed-dried-bud-one"] = {
    Name = "weed-dried-bud-one",
    Label = "Dried Bud (7g)",
    Image = "weed-dried-bud-one.png",
    Description = "The best smell ever!!!",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 5.0,
    Price = 1,
    Craft = {},
    DecayRate = 0.1,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weed-dried-bud-two"] = {
    Name = "weed-dried-bud-two",
    Label = "Dried Bud (3g)",
    Image = "weed-dried-bud-one.png",
    Description = "The best smell ever!!!",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 3.0,
    Price = 1,
    Craft = {
        { Item = 'weed-dried-bud-one', Amount = 2 },
    },
    DecayRate = 0.1,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weed-bag"] = {
    Name = "weed-bag",
    Label = "Zakje (7g)",
    Image = "weed-bagged.png",
    Description = "Sold on the streets, yo.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0.7,
    Price = 1,
    Craft = {
		{ Item = 'emptybaggies', Amount = 2 },
		{ Item = 'weed-dried-bud-one', Amount = 2 },
    },
    DecayRate = 0.3,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["weed-bag-1g"] = {
    Name = "weed-bag-1g",
    Label = "Zakje (1g)",
    Image = "weed-bagged.png",
    Description = "Sold on the streets, yo.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0.7,
    Price = 1,
    Craft = {
		{ Item = 'emptybaggies', Amount = 7 },
		{ Item = 'weed-dried-bud-one', Amount = 1 },
    },
    DecayRate = 0.3,
    FullDecay = false,
    InsertInto = { "bong" },
}

Shared.Items["rolling-paper"] = {
    Name = "rolling-paper",
    Label = "Rolling Papers",
    Image = "rollingpaper.png",
    Description = "Required to roll joints!",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0.3,
    Price = 2,
    Craft = {},
    DecayRate = 0.3,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["emptybaggies"] = {
    Name = "emptybaggies",
    Label = "Empty Bags",
    Image = "m_emptybaggies.png",
    Description = "Why is this empty?!",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0.1,
    Price = 8,
    Craft = {
        { Item = "plastic", Amount = 1 },
    },
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["scales"] = {
    Name = "scales",
    Label = "Scale",
    Image = "scales.png",
    Description = "Is this even accurate?!",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 2.5,
    Price = 95,
    Craft = {
        { Item = "metalscrap", Amount = 4 },
        { Item = "aluminum", Amount = 3 },
        { Item = "electronics", Amount = 3 },
    },
    DecayRate = 0.1,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["generic-mechanic-part"] = {
    Name = "generic-mechanic-part",
    Label = "Mechanical Part",
    Image = "generic-mechanic-part-a.png",
    Description = "",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 10,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["vehicle-clutch"] = {
    Name = "vehicle-clutch",
    Label = "Clutch (?)",
    Image = "clutch-a.png",
    Description = "Unknown-Class Clutch",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 10,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["vehicle-axle"] = {
    Name = "vehicle-axle",
    Label = "Driveshaft (?)",
    Image = "axle-a.png",
    Description = "Unknown-Class Driveshaft",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 10,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["vehicle-brakes"] = {
    Name = "vehicle-brakes",
    Label = "Brakes (?)",
    Image = "brakes-a.png",
    Description = "Unknown-Class Brakes",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 10,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["vehicle-engine"] = {
    Name = "vehicle-engine",
    Label = "Engine (?)",
    Image = "engine-a.png",
    Description = "Unknown-Class Engine",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 10,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["vehicle-injectors"] = {
    Name = "vehicle-injectors",
    Label = "Injectors (?)",
    Image = "injectors-a.png",
    Description = "Unknown-Class Fuel Injectors",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 10,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["vehicle-transmission"] = {
    Name = "vehicle-transmission",
    Label = "Transmission (?)",
    Image = "transmission-a.png",
    Description = "Unknown-Class Transmission",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 10,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = true,
    InsertInto = {},
}

-- Version 2.1
Shared.Items["gang-spray"] = {
    Name = "gang-spray",
    Label = "Spray Can",
    Image = "spraycan.png",
    Description = "A spray can.",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 2,
    Price = 10,
    Craft = {},
    DecayRate = 0.066,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["scrubbingcloth"] = {
    Name = "scrubbingcloth",
    Label = "Scrubbing Cloth",
    Image = "scrubbingcloth.png",
    Description = "Seems to dry out quickly..",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 35,
    Price = 100,
    Craft = {},
    DecayRate = 0.000694,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["mugoftea"] = {
    Name = "mugoftea",
    Label = "Mug of Tea",
    Image = "mugoftea.png",
    Description = "Slurp, slurp...",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0,
    Price = 1,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

-- Shared.Items["casino-member"] = {
--     Name = "casino-member",
--     Label = "Casino Membership",
--     Image = "casino_member.png",
--     Description = "All the games, all the fun. Diamond Casino.",
--     Weapon = false, Illegal = false,
--     Metal = false, NonStack = true,
--     IsBag = false, Weight = 1,
--     Price = 1,
--     Craft = {},
--     DecayRate = 0.25,
--     FullDecay = true,
--     InsertInto = {},
-- }

-- Shared.Items["casino-vip"] = {
--     Name = "casino-vip",
--     Label = "High Roller Membership",
--     Image = "casino_member_high.png",
--     Description = "Spend even more cash. Diamond Casino.",
--     Weapon = false, Illegal = false,
--     Metal = false, NonStack = true,
--     IsBag = false, Weight = 1,
--     Price = 1,
--     Craft = {},
--     DecayRate = 0.25,
--     FullDecay = true,
--     InsertInto = {},
-- }

-- Shared.Items["casino-loyalty"] = {
--     Name = "casino-loyalty",
--     Label = "Loyalty Membership",
--     Image = "casino_member.png",
--     Description = "%gamba",
--     Weapon = false, Illegal = false,
--     Metal = false, NonStack = true,
--     IsBag = false, Weight = 1,
--     Price = 1,
--     Craft = {},
--     DecayRate = 0.25,
--     FullDecay = true,
--     InsertInto = {},
-- }

-- Shared.Items["casino-free-ticket"] = {
--     Name = "casino-free-ticket",
--     Label = "Free Spin!",
--     Image = "casino_spin.png",
--     Description = "Free! Free! Spin!",
--     Weapon = false, Illegal = false,
--     Metal = false, NonStack = true,
--     IsBag = false, Weight = 1,
--     Price = 1,
--     Craft = {},
--     DecayRate = 0.25,
--     FullDecay = true,
--     InsertInto = {},
-- }

-- Drugs
Shared.Items["cocainebrick"] = {
    Name = "cocainebrick",
    Label = "Airtight Cocaine Brick (1kg)",
    Image = "cocainebrick.png",
    Description = "Good stuff, bro.",
    Weapon = false, Illegal = true,
    Metal = false, NonStack = false, HasProp = true,
    IsBag = false, Weight = 20,
    Price = 50000,
    Craft = {},
    DecayRate = 0.5,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["10gcocaine"] = {
    Name = "10gcocaine",
    Label = "10g Cocaine",
    Image = "cocainebaggy.png",
    Description = "Smells like high-quality coke.",
    Weapon = false, Illegal = true,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0,
    Price = 100,
    Craft = {
        { Item = "cocainebrick", Amount = 2 }
    },
    DecayRate = 0.5,
    FullDecay = true,
    InsertInto = { "ammonium-bicarbonate" },
}

Shared.Items["5gcocaine"] = {
    Name = "5gcocaine",
    Label = "Coke Baggy (5g)",
    Image = "cocainebaggy.png",
    Description = "I think you could make drywall with this.",
    Weapon = false, Illegal = true,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0,
    Price = 100,
    Craft = {},
    DecayRate = 0.5,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["5gcrack"] = {
    Name = "5gcrack",
    Label = "5g Crack",
    Image = "crackbaggy.png",
    Description = "Little crack treats.. anyone hungry?",
    Weapon = false, Illegal = true,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0,
    Price = 100,
    Craft = {
        { Item = "bakingsoda", Amount = 2 },
        { Item = "5gcocaine", Amount = 2 },
    },
    DecayRate = 0.5,
    FullDecay = true,
    InsertInto = { "crackpipe" },
}

Shared.Items["bakingsoda"] = {
    Name = "bakingsoda",
    Label = "Baking Soda",
    Image = "bakingsoda.png",
    Description = "You should sprinkle this on pancakes. Delicious!",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0,
    Price = 50,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["ammonium-bicarbonate"] = {
    Name = "ammonium-bicarbonate",
    Label = "Ammonium Bicarbonate",
    Image = "ammonium-bicarbonate.png",
    Description = "Very good at breaking things down. This compound has many names, reflecting its long history.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0,
    Price = 50,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["crackpipe"] = {
    Name = "crackpipe",
    Label = "Crack Pipe",
    Image = "crackpipe.png",
    Description = "HMMM YAAAASSS",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 5,
    Price = 0,
    Craft = {
        { Item = 'glass', Amount = 15 },
        { Item = '5gcrack', Amount = 2 },
    },
    DecayRate = 0.1,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["methusb"] = {
    Name = "methusb",
    Label = "USB Device",
    Image = "heist-usb-black.png",
    Description = "I wonder what you could do with this?",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 10,
    Price = 0,
    Craft = {},
    DecayRate = 1.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["methtable"] = {
    Name = "methtable",
    Label = "A Table",
    Image = "methtable.png",
    Description = "Looks like a table you can place.",
    Weapon = false, Illegal = true,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 50,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["methbatch"] = {
    Name = "methbatch",
    Label = "Batch of Raw Meth",
    Image = "methbatch.png",
    Description = "Crystalline. Should be stored somewhere cool and dry to harden.",
    Weapon = false, Illegal = true,
    Metal = false, NonStack = true, HasProp = true,
    IsBag = false, Weight = 15,
    Price = 0,
    Craft = {},
    DecayRate = 1.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["methcured"] = {
    Name = "methcured",
    Label = "Batch of Cured Meth",
    Image = "methcured.png",
    Description = "Ready for bagging!",
    Weapon = false, Illegal = true,
    Metal = false, NonStack = true, HasProp = true,
    IsBag = false, Weight = 15,
    Price = 0,
    Craft = {},
    DecayRate = 1.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["1gmeth"] = {
    Name = "1gmeth",
    Label = "Meth (1g)",
    Image = "meth.png",
    Description = "",
    Weapon = false, Illegal = true,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 0,
    Craft = {},
    DecayRate = 0.5,
    FullDecay = true,
    InsertInto = { "methpipe" },
}

Shared.Items["methpipe"] = {
    Name = "methpipe",
    Label = "Meth Pipe",
    Image = "methpipe.png",
    Description = "Good stuff, bro.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 5,
    Price = 0,
    Craft = {
        { Item = 'glass', Amount = 113 },
        { Item = '1gmeth', Amount = 2 },
    },
    DecayRate = 0.1,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["floorcleaner"] = {
    Name = "floorcleaner",
    Label = "Floor Cleaner",
    Image = "floorcleaner.png",
    Description = "A bottle of floor cleaner containing a large amount of hard drugs..",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 5,
    Price = 0,
    Craft = {},
    DecayRate = 0.01,
    FullDecay = true,
    InsertInto = {},
}

-- Beehives
Shared.Items["bee-wax"] = {
    Name = "bee-wax",
    Label = "Beeswax",
    Image = "bee-wax.png",
    Description = "This is really sticky, what the heck..",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0.75,
    Price = 1,
    Craft = {},
    DecayRate = 0.2,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["bee-queen"] = {
    Name = "bee-queen",
    Label = "Queen Bee",
    Image = "bee-queen.png",
    Description = "Looks like this is the queen!",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0.15,
    Price = 125,
    Craft = {},
    DecayRate = 0.1,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["beehive"] = {
    Name = "beehive",
    Label = "Beehive",
    Image = "beehive.png",
    Description = "ZZZzzzZZZZzzzzzzzz..",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 11.5,
    Price = 450,
    Craft = {},
    DecayRate = 0.1,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["carwax"] = {
    Name = "carwax",
    Label = "Car Wash Kit",
    Image = "carwax.png",
    Description = "Spread beeswax over your car so it doesn't get dirty as quickly..",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 3,
    Price = 1,
    Craft = {
        { Item = "bee-wax", Amount = 5 },
        { Item = "water_bottle", Amount = 1 },
        { Item = "plastic", Amount = 9 },
    },
    DecayRate = 1.0,
    FullDecay = true,
    InsertInto = {},
}

-- Stealing rims hehe
Shared.Items["screwdriver"] = {
    Name = "screwdriver",
    Label = "Screwdriver",
    Image = "screwdriver.png",
    Description = "",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 0,
    Craft = {},
    DecayRate = 0.5,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["stolen-vehicle-rim"] = {
    Name = "stolen-vehicle-rim",
    Label = "Vehicle Rim",
    Image = "stolen-vehicle-rim.png",
    Description = "Looks like a wheel rim?",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 10,
    Price = 0,
    Craft = {},
    DecayRate = 0.5,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["evidence"] = {
    Name = "evidence",
    Label = "Evidence Marker",
    Image = "evidence-yellow.png",
    Description = "Use to mark evidence.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0.15,
    Price = 1,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = { 'dna-reader' },
}

Shared.Items["evidence-collected"] = {
    Name = "evidence-collected",
    Label = "Evidence Marker",
    Image = "evidence-yellow.png",
    Description = "Use to mark evidence.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 0.15,
    Price = 1,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = { 'dna-reader' },
}

Shared.Items["dna-reader"] = {
    Name = "dna-reader",
    Label = "(PD) DNA Reader",
    Image = "dna-reader.png",
    Description = "Can be used to read DNA.<br/><br/>Equipment issued by the government (PD/EMS).",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 15,
    Price = 150,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["tow-rope"] = {
    Name = "tow-rope",
    Label = "Tow Rope",
    Image = "tow-rope.png",
    Description = "You can attach it to a car, but perhaps to other things as well..?",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 10,
    Price = 10,
    Craft = {},
    DecayRate = 0.2,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["atm-blackbox"] = {
    Name = "atm-blackbox",
    Label = "Black Box",
    Image = "atm-blackbox.png",
    Description = "How did you manage to pull this thing out of the wall..?",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 100,
    Price = 10,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

-- Heists rework
Shared.Items["heist-loot"] = {
    Name = "heist-loot",
    Label = "Valuable Goods",
    Image = "valuable-goods.png",
    Description = "Marked for confiscation.",
    Weapon = false, Illegal = true,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 1,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["heist-loot-usb"] = {
    Name = "heist-loot-usb",
    Label = "USB Device",
    Image = "h_usb_device.png",
    Description = "I think this contains some illegal crypto.. Marked for confiscation.",
    Weapon = false, Illegal = true,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 1,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["heist-usb"] = {
    Name = "heist-usb",
    Label = "USB",
    Image = "heist-usb-green.png",
    Description = "Marked for confiscation.",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 10,
    Price = 1,
    Craft = {},
    DecayRate = 1.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["heist-laptop"] = {
    Name = "heist-laptop",
    Label = "Laptop",
    Image = "heist-laptop-green.png",
    Description = "Marked for confiscation.",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 1,
    Craft = {},
    DecayRate = 0.0075,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["heist-decrypter-basic"] = {
    Name = "heist-decrypter-basic",
    Label = "Basic Decrypter",
    Image = "h_decrypter_basic.png",
    Description = "",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 10,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["heist-decrypter-adv"] = {
    Name = "heist-decrypter-adv",
    Label = "Advanced Decrypter",
    Image = "h_decrypter_adv.png",
    Description = "",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 10,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["heist-decrypter-hard"] = {
    Name = "heist-decrypter-hard",
    Label = "Hardened Decrypter",
    Image = "h_decrypter_hard.png",
    Description = "",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 10,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["heist-drill-basic"] = {
    Name = "heist-drill-basic",
    Label = "Basic Drill",
    Image = "h_drill_basic.png",
    Description = "",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 5,
    Price = 10,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["heist-drill-adv"] = {
    Name = "heist-drill-adv",
    Label = "Advanced Drill",
    Image = "h_drill_adv.png",
    Description = "",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 5,
    Price = 10,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["heist-drill-hard"] = {
    Name = "heist-drill-hard",
    Label = "Hardened Drill",
    Image = "h_drill_hard.png",
    Description = "",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 5,
    Price = 10,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["heist-electronic-kit-adv"] = {
    Name = "heist-electronic-kit-adv",
    Label = "Advanced Electronic Kit",
    Image = "h_electronickit_adv.png",
    Description = "",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 10,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["heist-electronic-kit-hard"] = {
    Name = "heist-electronic-kit-hard",
    Label = "Hardened Electronic Kit",
    Image = "h_electronickit_hard.png",
    Description = "",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 10,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["jammingdevice"] = {
    Name = "jammingdevice",
    Label = "Jamming Device",
    Image = "radioscanner.png",
    Description = "",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 0,
    Price = 10,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["heist-entrykeycard"] = {
    Name = "heist-entrykeycard",
    Label = "Entry Keycard",
    Image = "h_entrykeycard.png",
    Description = "",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0,
    Price = 10,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["heist-keycard-vault"] = {
    Name = "heist-keycard-vault",
    Label = "Keycard",
    Image = "h_keycard_vault.png",
    Description = "Keycard voor bepaalde kluizen.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0,
    Price = 10,
    Craft = {},
    DecayRate = 0.1,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["heist-box"] = {
    Name = "heist-box",
    Label = "Doos",
    Image = "h_box.png",
    Description = "Een doos gemaakt van 6 planken.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 10,
    Price = 10,
    Craft = {},
    DecayRate = 0.0075,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["heist-safecracking"] = {
    Name = "heist-safecracking",
    Label = "Safe Cracking Tool",
    Image = "h_safecracking.png",
    Description = "Marked for confiscation.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 3,
    Price = 0,
    Craft = {},
    DecayRate = 0.2,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["heist-safe-codes"] = {
    Name = "heist-safe-codes",
    Label = "Private Note",
    Image = "business-ticket.png",
    Description = "Marked for confiscation.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0,
    Price = 0,
    Craft = {},
    DecayRate = 0.07,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["gruppe6"] = {
    Name = "gruppe6",
    Label = "G6 Card",
    Image = "gruppe6.png",
    Description = "Looks useful..",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

-- Racing
Shared.Items["racing-usb"] = {
    Name = "racing-usb",
    Label = "Phone USB",
    Image = "c_racing_usb.png",
    Description = "Marked for confiscation.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 10,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["racing-usb-pd"] = {
    Name = "racing-usb-pd",
    Label = "(PD) Phone USB",
    Image = "c_racing_usb.png",
    Description = "Gives you access to the Time Trials app.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 10,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["adrenaline"] = {
    Name = "adrenaline",
    Label = "Adrenaline Pen",
    Image = "adrenaline.png",
    Description = "Not a ballpoint pen, but a pen full of adrenaline.",
    Weapon = false, Illegal = true,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 3,
    Price = 1,
    Craft = {},
    DecayRate = 0.75,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["ibuprofen"] = {
    Name = "ibuprofen",
    Label = "Ibuprofen 400mg",
    Image = "ibuprofen.png",
    Description = "A box of ibuprofen tablets. Available only with a prescription from Crusade Medical Center.",
    Weapon = false, Illegal = true,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 3,
    Price = 1,
    Craft = {},
    DecayRate = 0.75,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["ketamine"] = {
    Name = "ketamine",
    Label = "Ketamine 200mg",
    Image = "ketamine.png",
    Description = "A good anesthetic, though it's for pussies.. Available only with a prescription from Crusade Medical Center.",
    Weapon = false, Illegal = true,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 3,
    Price = 1,
    Craft = {},
    DecayRate = 0.75,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["melatonin"] = {
    Name = "melatonin",
    Label = "Melatonine 299mcg",
    Image = "melatonin.png",
    Description = "Sleep tight, you sausage.",
    Weapon = false, Illegal = true,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 3,
    Price = 1,
    Craft = {},
    DecayRate = 0.75,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["morphine"] = {
    Name = "morphine",
    Label = "Morfine 15mg",
    Image = "morphine.png",
    Description = "Time to get nice and drowsy. Bring it on. Available only with a prescription from Crusade Medical Center.",
    Weapon = false, Illegal = true,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 3,
    Price = 1,
    Craft = {},
    DecayRate = 0.75,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["painkillers"] = {
    Name = "painkillers",
    Label = "Paracetamol 500mg",
    Image = "painkillers.png",
    Description = "I heard that if you take 20 of these, you'll get a stomach ache and then sleep very well..",
    Weapon = false, Illegal = true,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 3,
    Price = 1,
    Craft = {},
    DecayRate = 0.75,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["food-box"] = {
    Name = "food-box",
    Label = "Bag of Food",
    Image = "food-box.png",
    Description = "Ooh, if I were you, I'd sneak a little taste!",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true, HasProp = true,
    IsBag = false, Weight = 25,
    Price = 0,
    Craft = {},
    DecayRate = 0.002,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["metaldetector"] = {
    Name = "metaldetector",
    Label = "Metal Detector",
    Image = "metaldetector.png",
    Description = "If the internet is to be believed, you can use this to find gold diggers..",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 20,
    Price = 25000,
    Craft = {
        { Item = 'aluminum', Amount = 300 },
        { Item = 'copper', Amount = 300 },
        { Item = 'rubber', Amount = 300 },
        { Item = 'plastic', Amount = 300 },
    },
    DecayRate = 0.5,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["trowel"] = {
    Name = "trowel",
    Label = "Trowel",
    Image = "trowel.png",
    Description = "Useful for digging small holes..",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 2,
    Price = 400,
    Craft = {},
    DecayRate = 1.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["heavy-cutters"] = {
    Name = "heavy-cutters",
    Label = "Bolt Cutters",
    Image = "heavy-cutters.png",
    Description = "",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 9,
    Price = 700,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

-- Polaroid
Shared.Items["polaroid-camera"] = {
    Name = "polaroid-camera",
    Label = "Polaroid Camera",
    Image = "m_polaroid_camera.png",
    Description = "Time to take some snapshots..",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 10,
    Price = 1300,
    Craft = {
		{Item = 'glass', Amount = 57},
		{Item = 'plastic', Amount = 57},
		{Item = 'aluminum', Amount = 32},
    },
    DecayRate = 1,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["polaroid-paper"] = {
    Name = "polaroid-paper",
    Label = "Polaroid Film",
    Image = "m_polaroid_paper.png",
    Description = "I think you'll need this to take a snapshot..",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 10,
    Craft = {
		{Item = 'plastic', Amount = 6},
	},
    DecayRate = 1,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["polaroid-photo"] = {
    Name = "polaroid-photo",
    Label = "Polaroid Photo",
    Image = "m_polaroid_photo.png",
    Description = "A photo taken with a Polaroid camera.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 1,
    Price = 0,
    Craft = {},
    DecayRate = 1,
    FullDecay = false,
    InsertInto = {"polaroid-binder"},
}

Shared.Items["polaroid-binder"] = {
    Name = "polaroid-binder",
    Label = "Polaroid Photobook",
    Image = "m_polaroid_binder.png",
    Description = "A photo album for Polaroid pictures.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 5,
    Price = 1500,
    Craft = {
        {Item = 'plastic', Amount = 111},
        {Item = 'aluminum', Amount = 9},
    },
    DecayRate = 0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["polaroid-battery"] = {
    Name = "polaroid-battery",
    Label = "Polaroid Battery Pack",
    Image = "m_polaroid_battery.png",
    Description = "A battery pack for a Polaroid camera.",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Price = 900,
    Craft = {
		{Item = 'aluminum', Amount = 35},
    },
    DecayRate = 0.1,
    FullDecay = true,
    InsertInto = {"polaroid-camera"},
}

Shared.Items["pdwatch"] = {
    Name = "pdwatch",
    Label = "(PD) Watch & Compass",
    Image = "m_watch.png",
    Description = "Equipment issued by the government (PD/EMS).",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 0.0,
    Price = 50,
    Craft = {},
    DecayRate = 0.6,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["book"] = {
    Name = "book",
    Label = "Book",
    Image = "book.png",
    Description = "",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 0.0,
    Price = 400,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["paper"] = {
    Name = "paper",
    Label = "Paper",
    Image = "paper.png",
    Description = "Paper for writing a book.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 1.0,
    Price = 25,
    Craft = {},
    DecayRate = 1.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["walkman"] = {
    Name = "walkman",
    Label = "Walkman",
    Image = "walkman.png",
    Description = "A blast from the past: an old device for listening to old-school music..",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 1.0,
    Price = 100,
    Craft = {
        { Item = "plastic", Amount = 9 },
        { Item = "electronics", Amount = 9 }
    },
    DecayRate = 1.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["musictape"] = {
    Name = "musictape",
    Label = "Cassette Tape",
    Image = "musictape.png",
    Description = "An empty cassette tape..",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = true,
    IsBag = false, Weight = 0.0,
    Price = 1,
    Craft = {
        { Item = "plastic", Amount = 2 },
        { Item = "electronics", Amount = 2 }
    },
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = { "walkman" },
}

Shared.Items["goldbanana"] = {
    Name = "goldbanana",
    Label = "Golden Banana",
    Image = "goldbanana.png",
    Description = "At least you have something to suck on...",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = true,
    IsBag = false, Weight = 4.5,
    Melee = true,
    Price = 1,
    Craft = {},
    DecayRate = 2.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["arcadetoken"] = {
    Name = "arcadetoken",
    Label = "Arcade Token",
    Image = "arcadetoken.png",
    Description = "You can insert this into the arcade machines at Cooper's Arcade.",
    Weapon = false, Illegal = false,
    Metal = true, NonStack = false,
    IsBag = false, Weight = 1,
    Melee = false,
    Price = 1,
    Craft = {},
    DecayRate = 0.5,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["notepad"] = {
    Name = "notepad",
    Label = "Notepad",
    Image = "notepad.png",
    Description = "A notepad with 10 pages..",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0,
    Melee = false,
    Price = 200,
    Craft = {},
    DecayRate = 1.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["notepad-page"] = {
    Name = "notepad-page",
    Label = "A Note",
    Image = "notepad-page.png",
    Description = "A note with some writing on it?",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0,
    Melee = false,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["antique-vase"] = {
    Name = "antique-vase",
    Label = "Antique Vase",
    Image = "antique-vase-1.png",
    Description = "An antique vase. I'd sell it!",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 2,
    Melee = false,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["painting"] = {
    Name = "painting",
    Label = "Painting",
    Image = "painting-1.png",
    Description = "Is this finger paint?",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 2,
    Melee = false,
    Price = 0,
    Craft = {},
    DecayRate = 0.0,
    FullDecay = false,
    InsertInto = {},
}

Shared.Items["panicbutton"] = {
    Name = "panicbutton",
    Label = "Panic Button",
    Image = "panicbutton.png",
    Description = "Use this to send an emergency alert.",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 0,
    Melee = false,
    Price = 10,
    Craft = {},
    DecayRate = 1.0,
    FullDecay = true,
    InsertInto = {},
}

Shared.Items["radioscanner"] = {
    Name = "radioscanner",
    Label = "Radio Scanner",
    Image = "radioscanner.png",
    Description = "A little device for picking up random radio communications..",
    Weapon = false, Illegal = false,
    Metal = false, NonStack = false,
    IsBag = false, Weight = 15.0,
    Price = 500,
    Craft = {
        { Item = 'aluminum', Amount = 2504 },
        { Item = 'plastic', Amount = 1168 },
        { Item = 'rubber', Amount = 1168 },
    },
    DecayRate = 1.0,
    FullDecay = false,
    InsertInto = {},
}