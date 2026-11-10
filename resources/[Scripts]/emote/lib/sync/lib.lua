local L0_1, L1_1
L0_1 = {}
Sync = L0_1
function L0_1(A0_2, A1_2, ...)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = DoesEntityExist
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = NetworkGetEntityIsNetworked
    L3_2 = A1_2
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L2_2 = TriggerServerEvent
      L3_2 = "sync:request"
      L4_2 = GetInvokingResource
      L4_2 = L4_2()
      L5_2 = A0_2
      L6_2 = GetPlayerServerId
      L7_2 = NetworkGetEntityOwner
      L8_2 = A1_2
      L7_2, L8_2 = L7_2(L8_2)
      L6_2 = L6_2(L7_2, L8_2)
      L7_2 = NetworkGetNetworkIdFromEntity
      L8_2 = A1_2
      L7_2 = L7_2(L8_2)
      L8_2 = ...
      L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
    end
  end
end
RequestSyncExecution = L0_1
L0_1 = Sync
function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = NetworkHasControlOfEntity
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = DeleteVehicle
    L2_2 = A0_2
    L1_2(L2_2)
  else
    L1_2 = RequestSyncExecution
    L2_2 = "DeleteVehicle"
    L3_2 = A0_2
    L1_2(L2_2, L3_2)
  end
end
L0_1.DeleteVehicle = L1_1
L0_1 = Sync
function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = NetworkHasControlOfEntity
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = DeleteEntity
    L2_2 = A0_2
    L1_2(L2_2)
  else
    L1_2 = RequestSyncExecution
    L2_2 = "DeleteEntity"
    L3_2 = A0_2
    L1_2(L2_2, L3_2)
  end
end
L0_1.DeleteEntity = L1_1
L0_1 = Sync
function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = NetworkHasControlOfEntity
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = DeletePed
    L2_2 = A0_2
    L1_2(L2_2)
  else
    L1_2 = RequestSyncExecution
    L2_2 = "DeletePed"
    L3_2 = A0_2
    L1_2(L2_2, L3_2)
  end
end
L0_1.DeletePed = L1_1
L0_1 = Sync
function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = NetworkHasControlOfEntity
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = DeleteObject
    L2_2 = A0_2
    L1_2(L2_2)
  else
    L1_2 = RequestSyncExecution
    L2_2 = "DeleteObject"
    L3_2 = A0_2
    L1_2(L2_2, L3_2)
  end
end
L0_1.DeleteObject = L1_1
L0_1 = Sync
function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = NetworkHasControlOfEntity
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = SetVehicleFuelLevel
    L3_2 = A0_2
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  else
    L2_2 = RequestSyncExecution
    L3_2 = "SetVehicleFuelLevel"
    L4_2 = A0_2
    L5_2 = A1_2
    L2_2(L3_2, L4_2, L5_2)
  end
end
L0_1.SetVehicleFuelLevel = L1_1
L0_1 = Sync
function L1_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L4_2 = NetworkHasControlOfEntity
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if L4_2 then
    L4_2 = SetVehicleTyreBurst
    L5_2 = A0_2
    L6_2 = A1_2
    L7_2 = A2_2
    L8_2 = A3_2
    L4_2(L5_2, L6_2, L7_2, L8_2)
  else
    L4_2 = RequestSyncExecution
    L5_2 = "SetVehicleTyreBurst"
    L6_2 = A0_2
    L7_2 = A1_2
    L8_2 = A2_2
    L9_2 = A3_2
    L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  end
end
L0_1.SetVehicleTyreBurst = L1_1
L0_1 = Sync
function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = NetworkHasControlOfEntity
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    L3_2 = SetVehicleDoorShut
    L4_2 = A0_2
    L5_2 = A1_2
    L6_2 = A2_2
    L3_2(L4_2, L5_2, L6_2)
  else
    L3_2 = RequestSyncExecution
    L4_2 = "SetVehicleDoorShut"
    L5_2 = A0_2
    L6_2 = A1_2
    L7_2 = A2_2
    L3_2(L4_2, L5_2, L6_2, L7_2)
  end
end
L0_1.SetVehicleDoorShut = L1_1
L0_1 = Sync
function L1_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L4_2 = NetworkHasControlOfEntity
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if L4_2 then
    L4_2 = SetVehicleDoorOpen
    L5_2 = A0_2
    L6_2 = A1_2
    L7_2 = A2_2
    L8_2 = A3_2
    L4_2(L5_2, L6_2, L7_2, L8_2)
  else
    L4_2 = RequestSyncExecution
    L5_2 = "SetVehicleDoorOpen"
    L6_2 = A0_2
    L7_2 = A1_2
    L8_2 = A2_2
    L9_2 = A3_2
    L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  end
end
L0_1.SetVehicleDoorOpen = L1_1
L0_1 = Sync
function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = NetworkHasControlOfEntity
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    L3_2 = SetVehicleDoorBroken
    L4_2 = A0_2
    L5_2 = A1_2
    L6_2 = A2_2
    L3_2(L4_2, L5_2, L6_2)
  else
    L3_2 = RequestSyncExecution
    L4_2 = "SetVehicleDoorBroken"
    L5_2 = A0_2
    L6_2 = A1_2
    L7_2 = A2_2
    L3_2(L4_2, L5_2, L6_2, L7_2)
  end
end
L0_1.SetVehicleDoorBroken = L1_1
L0_1 = Sync
function L1_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L4_2 = NetworkHasControlOfEntity
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if L4_2 then
    L4_2 = SetVehicleEngineOn
    L5_2 = A0_2
    L6_2 = A1_2
    L7_2 = A2_2
    L8_2 = A3_2
    L4_2(L5_2, L6_2, L7_2, L8_2)
  else
    L4_2 = RequestSyncExecution
    L5_2 = "SetVehicleEngineOn"
    L6_2 = A0_2
    L7_2 = A1_2
    L8_2 = A2_2
    L9_2 = A3_2
    L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  end
end
L0_1.SetVehicleEngineOn = L1_1
L0_1 = Sync
function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = NetworkHasControlOfEntity
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = SetVehicleUndriveable
    L3_2 = A0_2
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  else
    L2_2 = RequestSyncExecution
    L3_2 = "SetVehicleUndriveable"
    L4_2 = A0_2
    L5_2 = A1_2
    L2_2(L3_2, L4_2, L5_2)
  end
end
L0_1.SetVehicleUndriveable = L1_1
L0_1 = Sync
function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = NetworkHasControlOfEntity
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = SetVehicleHandbrake
    L3_2 = A0_2
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  else
    L2_2 = RequestSyncExecution
    L3_2 = "SetVehicleHandbrake"
    L4_2 = A0_2
    L5_2 = A1_2
    L2_2(L3_2, L4_2, L5_2)
  end
end
L0_1.SetVehicleHandbrake = L1_1
L0_1 = Sync
function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = NetworkHasControlOfEntity
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    L3_2 = DecorSetFloat
    L4_2 = A0_2
    L5_2 = A1_2
    L6_2 = A2_2
    L3_2(L4_2, L5_2, L6_2)
  else
    L3_2 = RequestSyncExecution
    L4_2 = "DecorSetFloat"
    L5_2 = A0_2
    L6_2 = A1_2
    L7_2 = A2_2
    L3_2(L4_2, L5_2, L6_2, L7_2)
  end
end
L0_1.DecorSetFloat = L1_1
L0_1 = Sync
function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = NetworkHasControlOfEntity
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    L3_2 = DecorSetBool
    L4_2 = A0_2
    L5_2 = A1_2
    L6_2 = A2_2
    L3_2(L4_2, L5_2, L6_2)
  else
    L3_2 = RequestSyncExecution
    L4_2 = "DecorSetBool"
    L5_2 = A0_2
    L6_2 = A1_2
    L7_2 = A2_2
    L3_2(L4_2, L5_2, L6_2, L7_2)
  end
end
L0_1.DecorSetBool = L1_1
L0_1 = Sync
function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = NetworkHasControlOfEntity
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    L3_2 = DecorSetInt
    L4_2 = A0_2
    L5_2 = A1_2
    L6_2 = A2_2
    L3_2(L4_2, L5_2, L6_2)
  else
    L3_2 = RequestSyncExecution
    L4_2 = "DecorSetInt"
    L5_2 = A0_2
    L6_2 = A1_2
    L7_2 = A2_2
    L3_2(L4_2, L5_2, L6_2, L7_2)
  end
end
L0_1.DecorSetInt = L1_1
L0_1 = Sync
function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = NetworkHasControlOfEntity
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    L3_2 = DetachEntity
    L4_2 = A0_2
    L5_2 = A1_2
    L6_2 = A2_2
    L3_2(L4_2, L5_2, L6_2)
  else
    L3_2 = RequestSyncExecution
    L4_2 = "DetachEntity"
    L5_2 = A0_2
    L6_2 = A1_2
    L7_2 = A2_2
    L3_2(L4_2, L5_2, L6_2, L7_2)
  end
end
L0_1.DetachEntity = L1_1
L0_1 = Sync
function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2)
  local L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L8_2 = NetworkHasControlOfEntity
  L9_2 = A0_2
  L8_2 = L8_2(L9_2)
  if L8_2 then
    L8_2 = SetEntityCoords
    L9_2 = A0_2
    L10_2 = A1_2
    L11_2 = A2_2
    L12_2 = A3_2
    L13_2 = A4_2
    L14_2 = A5_2
    L15_2 = A6_2
    L16_2 = A7_2
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
  else
    L8_2 = RequestSyncExecution
    L9_2 = "SetEntityCoords"
    L10_2 = A0_2
    L11_2 = A1_2
    L12_2 = A2_2
    L13_2 = A3_2
    L14_2 = A4_2
    L15_2 = A5_2
    L16_2 = A6_2
    L17_2 = A7_2
    L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  end
end
L0_1.SetEntityCoords = L1_1
L0_1 = Sync
function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = NetworkHasControlOfEntity
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = SetEntityHeading
    L3_2 = A0_2
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  else
    L2_2 = RequestSyncExecution
    L3_2 = "SetEntityHeading"
    L4_2 = A0_2
    L5_2 = A1_2
    L2_2(L3_2, L4_2, L5_2)
  end
end
L0_1.SetEntityHeading = L1_1
L0_1 = Sync
function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = NetworkHasControlOfEntity
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = FreezeEntityPosition
    L3_2 = A0_2
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  else
    L2_2 = RequestSyncExecution
    L3_2 = "FreezeEntityPosition"
    L4_2 = A0_2
    L5_2 = A1_2
    L2_2(L3_2, L4_2, L5_2)
  end
end
L0_1.FreezeEntityPosition = L1_1
L0_1 = Sync
function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = NetworkHasControlOfEntity
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = SetVehicleDoorsLocked
    L3_2 = A0_2
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  else
    L2_2 = RequestSyncExecution
    L3_2 = "SetVehicleDoorsLocked"
    L4_2 = A0_2
    L5_2 = A1_2
    L2_2(L3_2, L4_2, L5_2)
  end
end
L0_1.SetVehicleDoorsLocked = L1_1
L0_1 = Sync
function L1_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L4_2 = NetworkHasControlOfEntity
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if L4_2 then
    L4_2 = NetworkExplodeVehicle
    L5_2 = A0_2
    L6_2 = A1_2
    L7_2 = A2_2
    L8_2 = A3_2
    L4_2(L5_2, L6_2, L7_2, L8_2)
  else
    L4_2 = RequestSyncExecution
    L5_2 = "NetworkExplodeVehicle"
    L6_2 = A0_2
    L7_2 = A1_2
    L8_2 = A2_2
    L9_2 = A3_2
    L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  end
end
L0_1.NetworkExplodeVehicle = L1_1
L0_1 = Sync
function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = NetworkHasControlOfEntity
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = SetBoatAnchor
    L3_2 = A0_2
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  else
    L2_2 = RequestSyncExecution
    L3_2 = "SetBoatAnchor"
    L4_2 = A0_2
    L5_2 = A1_2
    L2_2(L3_2, L4_2, L5_2)
  end
end
L0_1.SetBoatAnchor = L1_1
L0_1 = Sync
function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = NetworkHasControlOfEntity
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = SetBoatFrozenWhenAnchored
    L3_2 = A0_2
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  else
    L2_2 = RequestSyncExecution
    L3_2 = "SetBoatFrozenWhenAnchored"
    L4_2 = A0_2
    L5_2 = A1_2
    L2_2(L3_2, L4_2, L5_2)
  end
end
L0_1.SetBoatFrozenWhenAnchored = L1_1
L0_1 = Sync
function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = NetworkHasControlOfEntity
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = SetForcedBoatLocationWhenAnchored
    L3_2 = A0_2
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  else
    L2_2 = RequestSyncExecution
    L3_2 = "SetForcedBoatLocationWhenAnchored"
    L4_2 = A0_2
    L5_2 = A1_2
    L2_2(L3_2, L4_2, L5_2)
  end
end
L0_1.SetForcedBoatLocationWhenAnchored = L1_1
L0_1 = Sync
function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = NetworkHasControlOfEntity
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = SetVehicleOnGroundProperly
    L2_2 = A0_2
    L1_2(L2_2)
  else
    L1_2 = RequestSyncExecution
    L2_2 = "SetVehicleOnGroundProperly"
    L3_2 = A0_2
    L1_2(L2_2, L3_2)
  end
end
L0_1.SetVehicleOnGroundProperly = L1_1
L0_1 = Sync
function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = NetworkHasControlOfEntity
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = SetVehicleTyreFixed
    L3_2 = A0_2
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  else
    L2_2 = RequestSyncExecution
    L3_2 = "SetVehicleTyreFixed"
    L4_2 = A0_2
    L5_2 = A1_2
    L2_2(L3_2, L4_2, L5_2)
  end
end
L0_1.SetVehicleTyreFixed = L1_1
L0_1 = Sync
function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = NetworkHasControlOfEntity
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = SetVehicleEngineHealth
    L3_2 = A0_2
    L4_2 = A1_2 + 0.0
    L2_2(L3_2, L4_2)
  else
    L2_2 = RequestSyncExecution
    L3_2 = "SetVehicleEngineHealth"
    L4_2 = A0_2
    L5_2 = A1_2 + 0.0
    L2_2(L3_2, L4_2, L5_2)
  end
end
L0_1.SetVehicleEngineHealth = L1_1
L0_1 = Sync
function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = NetworkHasControlOfEntity
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = SetVehicleBodyHealth
    L3_2 = A0_2
    L4_2 = A1_2 + 0.0
    L2_2(L3_2, L4_2)
  else
    L2_2 = RequestSyncExecution
    L3_2 = "SetVehicleBodyHealth"
    L4_2 = A0_2
    L5_2 = A1_2 + 0.0
    L2_2(L3_2, L4_2, L5_2)
  end
end
L0_1.SetVehicleBodyHealth = L1_1
L0_1 = Sync
function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = NetworkHasControlOfEntity
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = SetVehicleDeformationFixed
    L2_2 = A0_2
    L1_2(L2_2)
  else
    L1_2 = RequestSyncExecution
    L2_2 = "SetVehicleDeformationFixed"
    L3_2 = A0_2
    L1_2(L2_2, L3_2)
  end
end
L0_1.SetVehicleDeformationFixed = L1_1
L0_1 = Sync
function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = NetworkHasControlOfEntity
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = SetVehicleFixed
    L2_2 = A0_2
    L1_2(L2_2)
  else
    L1_2 = RequestSyncExecution
    L2_2 = "SetVehicleFixed"
    L3_2 = A0_2
    L1_2(L2_2, L3_2)
  end
end
L0_1.SetVehicleFixed = L1_1
L0_1 = Sync
function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = NetworkHasControlOfEntity
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = SetVehicleDeformationFixed
    L2_2 = A0_2
    L1_2(L2_2)
  else
    L1_2 = RequestSyncExecution
    L2_2 = "SetVehicleDeformationFixed"
    L3_2 = A0_2
    L1_2(L2_2, L3_2)
  end
end
L0_1.SetVehicleDeformationFixed = L1_1
L0_1 = Sync
function L1_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = NetworkHasControlOfEntity
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = SetEntityAsNoLongerNeeded
    L2_2 = A0_2
    L1_2(L2_2)
  else
    L1_2 = RequestSyncExecution
    L2_2 = "SetEntityAsNoLongerNeeded"
    L3_2 = A0_2
    L1_2(L2_2, L3_2)
  end
end
L0_1.SetEntityAsNoLongerNeeded = L1_1
L0_1 = Sync
function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = NetworkHasControlOfEntity
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = SetPedKeepTask
    L3_2 = A0_2
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  else
    L2_2 = RequestSyncExecution
    L3_2 = "SetPedKeepTask"
    L4_2 = A0_2
    L5_2 = A1_2
    L2_2(L3_2, L4_2, L5_2)
  end
end
L0_1.SetPedKeepTask = L1_1
L0_1 = Sync
function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = NetworkHasControlOfEntity
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = exports
    L2_2 = L2_2["codera-vehicles"]
    L3_2 = L2_2
    L2_2 = L2_2.SetVehicleMods
    L4_2 = A0_2
    L5_2 = A1_2
    L2_2(L3_2, L4_2, L5_2)
  else
    L2_2 = RequestSyncExecution
    L3_2 = "SetVehicleMods"
    L4_2 = A0_2
    L5_2 = A1_2
    L2_2(L3_2, L4_2, L5_2)
  end
end
L0_1.SetVehicleMods = L1_1
L0_1 = Sync
function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = NetworkHasControlOfEntity
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = exports
    L2_2 = L2_2["codera-vehicles"]
    L3_2 = L2_2
    L2_2 = L2_2.SetVehicleAppearance
    L4_2 = A0_2
    L5_2 = A1_2
    L2_2(L3_2, L4_2, L5_2)
  else
    L2_2 = RequestSyncExecution
    L3_2 = "SetVehicleAppearance"
    L4_2 = A0_2
    L5_2 = A1_2
    L2_2(L3_2, L4_2, L5_2)
  end
end
L0_1.SetVehicleAppearance = L1_1
L0_1 = Sync
function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = NetworkHasControlOfEntity
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = SetVehicleTyresCanBurst
    L3_2 = A0_2
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  else
    L2_2 = RequestSyncExecution
    L3_2 = "SetVehicleTyresCanBurst"
    L4_2 = A0_2
    L5_2 = A1_2
    L2_2(L3_2, L4_2, L5_2)
  end
end
L0_1.SetVehicleTyresCanBurst = L1_1
L0_1 = Sync
function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L6_2 = NetworkHasControlOfEntity
  L7_2 = A0_2
  L6_2 = L6_2(L7_2)
  if L6_2 then
    L6_2 = BreakOffVehicleWheel
    L7_2 = A0_2
    L8_2 = A1_2
    L9_2 = A2_2
    L10_2 = A3_2
    L11_2 = A4_2
    L12_2 = A5_2
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  else
    L6_2 = RequestSyncExecution
    L7_2 = "BreakOffVehicleWheel"
    L8_2 = A0_2
    L9_2 = A1_2
    L10_2 = A2_2
    L11_2 = A3_2
    L12_2 = A4_2
    L13_2 = A5_2
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  end
end
L0_1.BreakOffVehicleWheel = L1_1
