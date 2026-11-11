-- Forwards a player's screen activity (client/cl_mirror.lua) to the players around that screen.
RegisterNetEvent('fw-dui:Server:Mirror', function(Name, Target, Events)
    local Source = source
    if type(Name) ~= 'string' or type(Target) ~= 'table' or type(Target.Coords) ~= 'table' then return end
    if type(Events) ~= 'table' or #Events == 0 or #Events > 61 then return end

    local Coords = vector3(tonumber(Target.Coords.x) or 0.0, tonumber(Target.Coords.y) or 0.0, tonumber(Target.Coords.z) or 0.0)
    if #(GetEntityCoords(GetPlayerPed(Source)) - Coords) > 5.0 then return end -- must be standing at the screen

    for _, Player in ipairs(GetPlayers()) do
        local Id = tonumber(Player)
        if Id ~= Source and #(GetEntityCoords(GetPlayerPed(Id)) - Coords) <= Config.MirrorDistance then
            TriggerClientEvent('fw-dui:Client:Mirror', Id, Name, Target, Events)
        end
    end
end)
