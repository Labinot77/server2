-- Always-on screens from Config.Screens: a DUI is created while you're near and released when you leave.

local function FindEntity(S)
    if S.PropId then
        if GetResourceState('fw-props') ~= 'started' then return nil end
        return exports['fw-props']:GetPropEntity(S.PropId)
    end
    local Entity = GetClosestObjectOfType(S.Coords.x, S.Coords.y, S.Coords.z, 1.0, joaat(S.Model), false, false, false)
    return Entity ~= 0 and Entity or nil
end

local function Release(S)
    if S.Id then Destroy(S.Id) end
    S.Id = nil
end

CreateThread(function()
    if #Config.Screens == 0 then return end

    while true do
        local CamCoords = GetFinalRenderedCamCoord()

        for _, S in ipairs(Config.Screens) do
            local Entity = FindEntity(S)
            local InRange = Entity and #(CamCoords - GetEntityCoords(Entity)) <= Config.DrawDistance

            if not InRange then
                Release(S)
            elseif not S.Id then
                local W, H = GetResolution(GetEntityModel(Entity))
                S.Id = Create(S.Url or ('nui://%s/html/idle.html'):format(GetCurrentResourceName()), W, H)
                if S.Id and Attach(S.Id, Entity) then
                    SetTimeout(700, function() if S.Id then Send(S.Id, 'data', S.Data or {}) end end)
                else
                    Release(S)
                end
            elseif Duis[S.Id].Entity ~= Entity then
                Attach(S.Id, Entity) -- prop respawned (fw-props streaming)
            end
        end

        Wait(1000)
    end
end)
