local L0_1, L1_1, L2_1
L0_1 = TriggerServerEvent
L1_1 = "np:sync:player:ready"
L0_1(L1_1)
L0_1 = RegisterNetEvent
L1_1 = "sync:execute"
L0_1(L1_1)
L0_1 = AddEventHandler
L1_1 = "sync:execute"
function L2_1(A0_2, A1_2, ...)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = NetworkGetEntityFromNetworkId
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  L3_2 = DoesEntityExist
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L3_2 = TriggerServerEvent
    L4_2 = "sync:execute:aborted"
    L5_2 = A0_2
    L6_2 = A1_2
    return L3_2(L4_2, L5_2, L6_2)
  end
  L3_2 = Sync
  L3_2 = L3_2[A0_2]
  if L3_2 then
    L3_2 = Sync
    L3_2 = L3_2[A0_2]
    L4_2 = L2_2
    L5_2, L6_2 = ...
    L3_2(L4_2, L5_2, L6_2)
  end
end
L0_1(L1_1, L2_1)
function L0_1(A0_2, A1_2, ...)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = NetworkGetEntityIsNetworked
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = NetworkHasControlOfEntity
    L3_2 = A1_2
    L2_2 = L2_2(L3_2)
    if not L2_2 then
      goto lbl_18
    end
  end
  L2_2 = Sync
  L2_2 = L2_2[A0_2]
  L3_2 = A1_2
  L4_2, L5_2 = ...
  L2_2(L3_2, L4_2, L5_2)
  goto lbl_23
  ::lbl_18::
  L2_2 = RequestSyncExecution
  L3_2 = A0_2
  L4_2 = A1_2
  L5_2 = ...
  L2_2(L3_2, L4_2, L5_2)
  ::lbl_23::
end
SyncedExecution = L0_1
L0_1 = exports
L1_1 = "SyncedExecution"
L2_1 = SyncedExecution
L0_1(L1_1, L2_1)
function L0_1(A0_2, A1_2, A2_2, ...)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = TriggerServerEvent
  L4_2 = "codera-sync:executeSyncNative"
  L5_2 = A0_2
  L6_2 = A1_2
  L7_2 = A2_2
  L8_2 = table
  L8_2 = L8_2.pack
  L9_2 = ...
  L8_2, L9_2 = L8_2(L9_2)
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
end
syncNative = L0_1
L0_1 = exports
L1_1 = "syncNative"
L2_1 = syncNative
L0_1(L1_1, L2_1)
L0_1 = RegisterNetEvent
L1_1 = "codera-sync:clientExecuteSyncNative"
L0_1(L1_1)
L0_1 = AddEventHandler
L1_1 = "codera-sync:clientExecuteSyncNative"
function L2_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  if A2_2 then
    L4_2 = A2_2.entity
    if L4_2 then
      L4_2 = pairs
      L5_2 = A2_2.entity
      L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
      for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
        L10_2 = NetworkGetEntityFromNetworkId
        L11_2 = A3_2[L9_2]
        L10_2 = L10_2(L11_2)
        A3_2[L9_2] = L10_2
      end
    end
  end
  if "0xB736A491E64A32CF" == A0_2 then
    L4_2 = SetEntityAsNoLongerNeeded
    L5_2 = A3_2[1]
    L4_2(L5_2)
    return
  end
  L4_2 = Citizen
  L4_2 = L4_2.InvokeNative
  L5_2 = A0_2
  L6_2 = table
  L6_2 = L6_2.unpack
  L7_2 = A3_2
  L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L6_2(L7_2)
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
end
L0_1(L1_1, L2_1)
