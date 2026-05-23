local _inPoly = nil
local _polys = {}
local _trolleyProps = {}


local function CleanupBankTrolleys(bankId)
	for key, prop in pairs(_trolleyProps) do
		if string.sub(key, 1, #bankId + 1) == bankId .. "_" then
			if DoesEntityExist(prop) then
				exports.ox_target:removeLocalEntity(prop)
				SetEntityAsMissionEntity(prop, false, false)
				DeleteObject(prop)
			end
			_trolleyProps[key] = nil
		end
	end
end

AddEventHandler("Characters:Client:Spawn", function()
	FleecaThreads()
end)

AddEventHandler("onResourceStop", function(resource)
	if resource ~= GetCurrentResourceName() then return end
	for key, prop in pairs(_trolleyProps) do
		if DoesEntityExist(prop) then
			exports.ox_target:removeLocalEntity(prop)
			SetEntityAsMissionEntity(prop, false, false)
			DeleteObject(prop)
		end
	end
	_trolleyProps = {}
end)

AddEventHandler("Robbery:Client:Setup", function()
	_polys = {}

	while GlobalState["FleecaRobberies"] == nil do
		Wait(10)
	end

	for k, v in ipairs(GlobalState["FleecaRobberies"]) do
		local bankData = GlobalState[string.format("FleecaRobberies:%s", v)]
		exports['pulsar-polyzone']:CreateBox(bankData.id, bankData.coords, bankData.width, bankData.length,
			bankData.options)
		_polys[bankData.id] = true

		SetupFleecaVaults(bankData)

		if bankData.reset ~= nil then
			exports.ox_target:addBoxZone({
				id = string.format("fleeca-%s-reset", bankData.id),
				coords = bankData.reset.coords,
				size = vector3(bankData.reset.length, bankData.reset.width, 2.0),
				rotation = bankData.reset.options.heading or 0,
				debug = false,
				minZ = bankData.reset.options.minZ,
				maxZ = bankData.reset.options.maxZ,
				options = {
					{
						icon = "fas fa-lock",
						label = "Secure Bank",
						groups = { "police" },
						bankId = bankData.id,
						onSelect = function(data)
							TriggerEvent("Robbery:Client:Fleeca:StartSecuring", data.bankId)
						end,
						canInteract = function()
							local fleeca = LocalPlayer.state.fleeca
							local vaultDoor = GlobalState[string.format("Fleeca:%s:VaultDoor", fleeca)]
							return (
								(
									vaultDoor ~= nil
									and (vaultDoor.state == 2 or vaultDoor.state == 3)
								)
								or not exports['ox_doorlock']:IsLocked(string.format("%s_gate", fleeca))
							)
						end,
					},
				}
			})
		end
	end

	exports["pulsar-core"]:RegisterClientCallback("Robbery:Fleeca:Keypad:Vault", function(data, cb)
		exports['pulsar-games']:MinigamePlayKeypad(data, 5, 10000, false, {
			onSuccess = function(data)
				cb(true, data)
			end,
			onFail = function(data)
				cb(false, data)
			end,
		}, {
			useWhileDead = false,
			vehicle = false,
			controlDisables = {
				disableMovement = true,
				disableCarMovement = true,
				disableMouse = false,
				disableCombat = true,
			},
			animation = {
				animDict = "amb@prop_human_atm@male@idle_a",
				anim = "idle_b",
				flags = 49,
			},
		})
	end)
end)

AddEventHandler("Polyzone:Enter", function(id, testedPoint, insideZones, data)
	if _polys[id] and GlobalState[id] == nil and GlobalState[string.format("FleecaRobberies:%s", id)] ~= nil then
		_inPoly = id
		LocalPlayer.state:set("fleeca", id, true)
	end
end)

AddEventHandler("Polyzone:Exit", function(id, testedPoint, insideZones, data)
	if _polys[id] then
		_inPoly = nil
		if LocalPlayer.state.fleeca ~= nil then
			LocalPlayer.state:set("fleeca", nil, true)
		end
	end
end)

RegisterNetEvent("Robbery:Client:Fleeca:OpenVaultDoor", function(fleecaId)
	if GlobalState[string.format("FleecaRobberies:%s", fleecaId)] ~= nil then
		local myCoords = GetEntityCoords(LocalPlayer.state.ped)
		if #(myCoords - GlobalState[string.format("FleecaRobberies:%s", fleecaId)].coords) <= 100 then
			OpenDoor(
				GlobalState[string.format("FleecaRobberies:%s", fleecaId)].points.laptopLoc.coords,
				GlobalState[string.format("FleecaRobberies:%s", fleecaId)].doors.vaultDoor
			)
		end
	end
end)

RegisterNetEvent("Robbery:Client:Fleeca:CloseVaultDoor", function(fleecaId)
	if GlobalState[string.format("FleecaRobberies:%s", fleecaId)] ~= nil then
		local myCoords = GetEntityCoords(LocalPlayer.state.ped)
		if #(myCoords - GlobalState[string.format("FleecaRobberies:%s", fleecaId)].coords) <= 100 then
			CloseDoor(
				GlobalState[string.format("FleecaRobberies:%s", fleecaId)].points.laptopLoc.coords,
				GlobalState[string.format("FleecaRobberies:%s", fleecaId)].doors.vaultDoor
			)
		end
	end
end)

AddEventHandler("Robbery:Client:Fleeca:StartSecuring", function(entity, data)
	exports['pulsar-hud']:Progress({
		name = "secure_fleeca",
		duration = 30000,
		label = "Securing",
		useWhileDead = false,
		canCancel = true,
		ignoreModifier = true,
		controlDisables = {
			disableMovement = true,
			disableCarMovement = true,
			disableMouse = false,
			disableCombat = true,
		},
		animation = {
			anim = "cop3",
		},
	}, function(status)
		if not status then
			exports["pulsar-core"]:ServerCallback("Robbery:Fleeca:SecureBank", {})
		end
	end)
end)

AddEventHandler("Robbery:Client:Fleeca:Drill", function(entity, data)
	exports["pulsar-core"]:ServerCallback("Robbery:Fleeca:Drill", data, function() end)
end)

AddEventHandler("Robbery:Client:Fleeca:GrabTrolley", function(bankId, data)
	exports["pulsar-core"]:ServerCallback("Robbery:Fleeca:GrabTrolley", data, function() end)
end)

RegisterNetEvent("Robbery:Client:Fleeca:LootSuccess")
AddEventHandler("Robbery:Client:Fleeca:LootSuccess", function(fleecaId, index, trolley)
	if not trolley then return end

	local playerPed = LocalPlayer.state.ped
	local propKey   = string.format("%s_%s", fleecaId, index)
	local fullProp  = _trolleyProps[propKey]
	if not fullProp or not DoesEntityExist(fullProp) then return end

	local trolleyCoords  = GetEntityCoords(fullProp)
	local trolleyHeading = GetEntityHeading(fullProp)
	local _, _, rotz     = table.unpack(GetEntityRotation(fullProp))
	local x, y, z       = trolleyCoords.x, trolleyCoords.y, trolleyCoords.z
	local emptyModel     = trolley.empty

	local dict     = "anim@heists@ornate_bank@grab_cash"
	local handHash = trolley.type == "gold" and GetHashKey("ch_prop_gold_bar_01a") or GetHashKey("hei_prop_heist_cash_pile")
	local bagHash  = GetHashKey("hei_p_m_bag_var22_arm_s")

	RequestAnimDict(dict)
	RequestModel(handHash)
	RequestModel(bagHash)
	while not HasAnimDictLoaded(dict) or not HasModelLoaded(handHash) or not HasModelLoaded(bagHash) do
		Wait(1)
	end

	exports['pulsar-hud']:Progress({
		name           = "fleeca_trolley_grab",
		duration       = math.floor((GetAnimDuration(dict, "intro") + GetAnimDuration(dict, "grab") + GetAnimDuration(dict, "exit")) * 1000),
		label          = "Looting Trolley",
		useWhileDead   = false,
		canCancel      = false,
		ignoreModifier = true,
	}, function() end)

	local bag = CreateObject(bagHash, GetEntityCoords(playerPed), false, false, false)
	FreezeEntityPosition(bag, true)
	SetEntityInvincible(bag, true)
	SetEntityNoCollisionEntity(bag, playerPed, true)

	-- hold trolley at start of cart_cash_dissapear (paused)
	local trolleyScene = CreateSynchronizedScene(x, y, z, 0.0, 0.0, rotz, 2, true, false, 1065353216, 0, 1065353216)
	PlaySynchronizedEntityAnim(fullProp, trolleyScene, "cart_cash_dissapear", dict, 1000.0, -4.0, 1)
	SetSynchronizedScenePhase(trolleyScene, 0.0)
	SetSynchronizedSceneRate(trolleyScene, 0.0)

	-- PHASE 1: intro
	local introScene = CreateSynchronizedScene(x, y, z, 0.0, 0.0, rotz, 2, true, false, 1065353216, 0, 1065353216)
	PlaySynchronizedEntityAnim(bag, introScene, "bag_intro", dict, 1.0, -1.0, 0, 0x447a0000)
	ForceEntityAiAndAnimationUpdate(bag)
	TaskSynchronizedScene(playerPed, introScene, dict, "intro", 1.5, -1.0, 13, 16, 1.5, 0)
	while GetSynchronizedScenePhase(introScene) < 0.99 do Wait(0) end

	-- PHASE 2: grab — ped, bag, and trolley all share the same scene so they advance together
	local cashProp = nil
	local grabDone = false

	CreateThread(function()
		while not grabDone do
			if IsEntityPlayingAnim(playerPed, dict, "grab", 3) then
				if HasAnimEventFired(playerPed, GetHashKey("CASH_APPEAR")) then
					if cashProp and not IsEntityVisible(cashProp) then
						SetEntityVisible(cashProp, true, false)
					end
				end
				if HasAnimEventFired(playerPed, GetHashKey("RELEASE_CASH_DESTROY")) then
					if cashProp and IsEntityVisible(cashProp) then
						SetEntityVisible(cashProp, false, false)
					end
				end
			end
			Wait(1)
		end
	end)

	local grabScene = CreateSynchronizedScene(x, y, z, 0.0, 0.0, rotz, 2, true, false, 1065353216, 1.0, 0.0)
	SetSynchronizedSceneRate(grabScene, 0.89)
	PlaySynchronizedEntityAnim(bag,      grabScene, "bag_grab",           dict, 1000.0,  1.0, 0, 0x447a0000)
	ForceEntityAiAndAnimationUpdate(bag)
	TaskSynchronizedScene(playerPed, grabScene, dict, "grab", 4.0, 1.0, 13, 16, 1148846080, 0)
	PlaySynchronizedEntityAnim(fullProp, grabScene, "cart_cash_dissapear", dict, 1000.0, -4.0, 1)
	ForceEntityAiAndAnimationUpdate(fullProp)

	cashProp = CreateObject(handHash, GetEntityCoords(playerPed), false, false, false)
	FreezeEntityPosition(cashProp, true)
	SetEntityInvincible(cashProp, true)
	SetEntityNoCollisionEntity(cashProp, playerPed, true)
	SetEntityVisible(cashProp, false, false)
	AttachEntityToEntity(cashProp, playerPed, GetPedBoneIndex(playerPed, 60309), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)

	while GetSynchronizedScenePhase(grabScene) < 0.99 do Wait(0) end
	grabDone = true

	if DoesEntityExist(cashProp) then DeleteObject(cashProp) end
	SetModelAsNoLongerNeeded(handHash)

	-- PHASE 3: exit — freeze trolley at fully-emptied state while ped walks away
	local exitScene = CreateSynchronizedScene(x, y, z, 0.0, 0.0, rotz, 2, true, false, 1065353216, 1.0, 0.0)
	PlaySynchronizedEntityAnim(bag, exitScene, "bag_exit", dict, 1000.0, -1000.0, 0, 0x447a0000)
	ForceEntityAiAndAnimationUpdate(bag)
	TaskSynchronizedScene(playerPed, exitScene, dict, "exit", 4.0, -4.0, 13, 16, 1148846080, 0)

	local freezeScene = CreateSynchronizedScene(x, y, z, 0.0, 0.0, rotz, 2, false, true, 1065353216, 0, 1065353216)
	PlaySynchronizedEntityAnim(fullProp, freezeScene, "cart_cash_dissapear", dict, 1000.0, -4.0, 1)
	SetSynchronizedScenePhase(freezeScene, 1.0)
	SetSynchronizedSceneRate(freezeScene, 0.0)

	while GetSynchronizedScenePhase(exitScene) < 0.99 do Wait(0) end

	-- cleanup scenes and ped
	DeleteObject(bag)
	SetModelAsNoLongerNeeded(bagHash)
	ClearPedTasks(playerPed)
	StopSynchronizedEntityAnim(fullProp, freezeScene)
	DisposeSynchronizedScene(introScene)
	DisposeSynchronizedScene(grabScene)
	DisposeSynchronizedScene(exitScene)
	DisposeSynchronizedScene(trolleyScene)
	DisposeSynchronizedScene(freezeScene)

	-- prop swap
	local emptyLoaded = false
	if emptyModel then
		RequestModel(emptyModel)
		local t = 0
		while not HasModelLoaded(emptyModel) and t < 3000 do Wait(10); t = t + 10 end
		emptyLoaded = HasModelLoaded(emptyModel)
	end

	Wait(100)

	if fullProp and DoesEntityExist(fullProp) then
		SetEntityAsMissionEntity(fullProp, false, false)
		DeleteObject(fullProp)
		_trolleyProps[propKey] = nil
	end

	Wait(100)

	if emptyLoaded then
		local bankData   = GlobalState[string.format("FleecaRobberies:%s", fleecaId)]
		local slotCoords = bankData and bankData.trolleys and bankData.trolleys[index] and bankData.trolleys[index].coords
		local spawnZ     = slotCoords and slotCoords.z or z

		local emptyProp = CreateObject(emptyModel, x, y, spawnZ, false, false, false)
		SetEntityAsMissionEntity(emptyProp, true, true)
		SetEntityHeading(emptyProp, trolleyHeading)
		FreezeEntityPosition(emptyProp, true)
		SetModelAsNoLongerNeeded(emptyModel)
		_trolleyProps[propKey] = emptyProp
	end
end)

function OpenDoor(checkOrigin, door)
	local obj =
		GetClosestObjectOfType(checkOrigin[1], checkOrigin[2], checkOrigin[3], 25.0, door.object, false, false, false)

	if obj ~= 0 and tonumber(string.format("%.3f", GetEntityHeading(obj))) == door.originalHeading then
		local count = 0
		repeat
			SetEntityHeading(obj, GetEntityHeading(obj) + door.step)
			count = count + 1
			Wait(10)
		until count == 150
	end
end

function CloseDoor(checkOrigin, door)
	local obj =
		GetClosestObjectOfType(checkOrigin[1], checkOrigin[2], checkOrigin[3], 25.0, door.object, false, false, false)

	if obj ~= 0 and tonumber(string.format("%.3f", GetEntityHeading(obj))) ~= door.originalHeading then
		local count = 0
		repeat
			SetEntityHeading(obj, GetEntityHeading(obj) - door.step)
			count = count + 1
			Wait(10)
		until count == 150
	end
end

local function SpawnTrolley(bankId, index, trolley, coords, heading)
	if not trolley then return end

	local trolleyId = string.format("%s_trolley_%s", bankId, index)
	local lootKey   = string.format("Fleeca:%s:Loot:%s", bankId, trolleyId)
	local isLooted  = GlobalState[lootKey] ~= nil

	local model = isLooted and trolley.empty or trolley.hash
	if not model then return end

	RequestModel(model)
	while not HasModelLoaded(model) do Wait(10) end
	local prop = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
	SetEntityAsMissionEntity(prop, true, true)
	if heading then SetEntityHeading(prop, heading) end
	FreezeEntityPosition(prop, true)
	SetModelAsNoLongerNeeded(model)
	_trolleyProps[string.format("%s_%s", bankId, index)] = prop

	if isLooted then return end

	local _grabLabels = { cash = "Grab Cash Bags", gold = "Grab Gold Bars", gems = "Grab Gem Cases" }
	local _grabIcons  = { cash = "fas fa-sack-dollar", gold = "fas fa-coins", gems = "fas fa-gem" }
	exports.ox_target:addLocalEntity(prop, {
		{
			icon      = _grabIcons[trolley.type]  or "fas fa-sack-dollar",
			label     = _grabLabels[trolley.type] or "Loot Trolley",
			bankId    = bankId,
			lootName  = trolleyId,
			lootIndex = index,
			onSelect  = function(data)
				TriggerEvent("Robbery:Client:Fleeca:GrabTrolley", data.bankId, { id = data.lootName, index = data.lootIndex, bankId = data.bankId })
			end,
			canInteract = function()
				local vaultDoor = GlobalState[string.format("Fleeca:%s:VaultDoor", bankId)]
				return vaultDoor ~= nil
					and vaultDoor.state == 3
					and (GlobalState[lootKey] == nil or GetCloudTimeAsInt() >= GlobalState[lootKey])
			end,
		},
	})
end

RegisterNetEvent("Robbery:Client:Fleeca:ResetTrolleys")
AddEventHandler("Robbery:Client:Fleeca:ResetTrolleys", function(fleecaId)
	CleanupBankTrolleys(fleecaId)
	Wait(500)
	local bankData = GlobalState[string.format("FleecaRobberies:%s", fleecaId)]
	if bankData and bankData.trolleys then
		for i, slot in ipairs(bankData.trolleys) do
			if slot.trolley then
				CreateThread(function()
					SpawnTrolley(bankData.id, i, slot.trolley, slot.coords, slot.coords.w)
				end)
			end
		end
	end
end)

RegisterNetEvent("Robbery:Client:Fleeca:TrolleySwap")
AddEventHandler("Robbery:Client:Fleeca:TrolleySwap", function(bankId, index, emptyModel)
	local propKey  = string.format("%s_%s", bankId, index)
	local fullProp = _trolleyProps[propKey]
	if not fullProp or not DoesEntityExist(fullProp) then return end

	local fullCoords  = GetEntityCoords(fullProp)
	local fullHeading = GetEntityHeading(fullProp)

	local emptyLoaded = false
	if emptyModel then
		RequestModel(emptyModel)
		local t = 0
		while not HasModelLoaded(emptyModel) and t < 3000 do Wait(10); t = t + 10 end
		emptyLoaded = HasModelLoaded(emptyModel)
	end

	exports.ox_target:removeLocalEntity(fullProp)
	SetEntityAsMissionEntity(fullProp, false, false)
	DeleteObject(fullProp)
	_trolleyProps[propKey] = nil

	Wait(100)

	if emptyLoaded then
		local bankData   = GlobalState[string.format("FleecaRobberies:%s", bankId)]
		local slotCoords = bankData and bankData.trolleys and bankData.trolleys[index] and bankData.trolleys[index].coords
		local spawnZ = slotCoords and slotCoords.z or fullCoords.z

		local emptyProp = CreateObject(emptyModel, fullCoords.x, fullCoords.y, spawnZ, false, false, false)
		SetEntityAsMissionEntity(emptyProp, true, true)
		SetEntityHeading(emptyProp, fullHeading)
		FreezeEntityPosition(emptyProp, true)
		SetModelAsNoLongerNeeded(emptyModel)
		_trolleyProps[propKey] = emptyProp
	end
end)

function SetupFleecaVaults(bankData)
	CleanupBankTrolleys(bankData.id)
	if bankData.trolleys then
		for i, slot in ipairs(bankData.trolleys) do
			if slot.trolley then
				CreateThread(function()
					SpawnTrolley(bankData.id, i, slot.trolley, slot.coords, slot.coords.w)
				end)
			end
		end
	end

	for k, v in ipairs(bankData.loots) do

		exports.ox_target:addBoxZone({
			id = string.format("fleeca-%s", v.options.name),
			coords = v.coords,
			size = vector3(v.width, v.length, 2.0),
			rotation = v.options.heading or 0,
			debug = false,
			minZ = v.options.minZ,
			maxZ = v.options.maxZ,
			options = {
				{
					icon = "fas fa-drill",
					label = "Use Drill",
					item = "drill",
					bankId = bankData.id,
					lootName = v.options.name,
					lootIndex = k,
					onSelect = function(data)
						TriggerEvent("Robbery:Client:Fleeca:Drill", data.bankId, { id = data.lootName, index = data.lootIndex })
					end,
					canInteract = function()
						local fleeca = LocalPlayer.state.fleeca
						local vaultDoor = GlobalState[string.format("Fleeca:%s:VaultDoor", fleeca)]
						local lootKey = string.format("Fleeca:%s:Loot:%s", fleeca, v.options.name)
						return vaultDoor ~= nil
							and vaultDoor.state == 3
							and (GlobalState[lootKey] == nil or GetCloudTimeAsInt() >= GlobalState[lootKey])
							and (k <= 2 or not exports['ox_doorlock']:IsLocked(string.format("%s_gate", fleeca)))
					end,
				},
			}
		})
	end
end
