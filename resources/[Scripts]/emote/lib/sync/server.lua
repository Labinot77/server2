RegisterNetEvent("sync:request", function(_, name, ownerServerId, netId, ...)
    if type(name) ~= "string" or type(ownerServerId) ~= "number" or ownerServerId <= 0 then return end
    TriggerClientEvent("sync:execute", ownerServerId, name, netId, ...)
end)

RegisterNetEvent("np:sync:player:ready", function() end)
RegisterNetEvent("sync:execute:aborted", function() end)
