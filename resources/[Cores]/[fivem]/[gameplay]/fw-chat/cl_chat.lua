-- No UI here: fw-hud opens the chat on T and fw-ui draws it. This only keeps GTA's own chat off
-- and holds the spam filter fw-hud reads before running a command.

CreateThread(function()
    SetTextChatEnabled(false)
end)

local SpamFilter = {
    -- ["command or argument"] = cooldown in milliseconds,
    -- example: ["a slide"] = 2500 gives "/a slide" a 2.5 second cooldown.
    ["a passout"] = 5000,
    ["a passout2"] = 5000,
    ["a passout3"] = 5000,
    ["a passout4"] = 5000,
    ["a passout5"] = 5000,
    ["a slide"] = 5000,
}

exports("GetSpamFilter", function()
    return SpamFilter
end)
