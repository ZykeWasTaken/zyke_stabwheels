Config = Config or {}

Config.Settings = {
    weapons = {
        ["weapon_dagger"] = true,
        ["weapon_bottle"] = true,
        ["weapon_crowbar"] = true,
        ["weapon_hatchet"] = true,
        ["weapon_knife"] = true,
        ["weapon_machete"] = true,
        ["weapon_switchblade"] = true,
        ["weapon_battleaxe"] = true,
        ["weapon_stone_hatchet"] = true,
        -- Add any other weapons you wish, these are the default ones that makes sense to me
    },
    disabledVehicles = {
        -- Add any vehicles you wish to disable from being able to be sabotaged, by default it's just some emergency vehicles
        -- Note that most servers will have more police vehicles than there are listed below, these are just the default ones, so I recommend adding your own
        "police",
        "police2",
        "police3",
        "police4",
        "policeb",
        "policet",
        "sheriff",
        "sheriff2",
        "fbi",
        "fbi2",
        "pranger",
        "ambulance",
        "firetruk",
        "riot",
        "riot2",
        "barracks",
        "barracks2",
        "barracks3",
        "crusader",
        "rhino",
    }
}