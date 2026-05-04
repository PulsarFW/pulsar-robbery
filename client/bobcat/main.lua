local _, relHash = AddRelationshipGroup("BOBCAT_SECURITY")
SetRelationshipBetweenGroups(5, `BOBCAT_SECURITY`, `PLAYER`)
SetRelationshipBetweenGroups(5, `PLAYER`, `BOBCAT_SECURITY`)

AddEventHandler("Robbery:Client:Setup", function()
	CreateThread(function()
		local interiorid = GetInteriorAtCoords(883.4142, -2282.372, 31.44168)
		if not GlobalState["Bobcat:VaultDoor"] then
			RequestIpl("prologue06_int")
			ActivateInteriorEntitySet(interiorid, "np_prolog_clean")
			DeactivateInteriorEntitySet(interiorid, "np_prolog_broken")
		else
			ActivateInteriorEntitySet(interiorid, "np_prolog_broken")
			RemoveIpl(interiorid, "np_prolog_broken")
			DeactivateInteriorEntitySet(interiorid, "np_prolog_clean")
		end
		RefreshInterior(interiorid)
	end)

	exports['pulsar-polyzone']:CreatePoly("bobcat", {
		vector2(907.62103271484, -2256.4008789062),
		vector2(884.54675292969, -2254.3540039062),
		vector2(884.14483642578, -2258.1083984375),
		vector2(875.30352783203, -2257.1977539062),
		vector2(875.5947265625, -2253.6535644531),
		vector2(862.10314941406, -2252.4174804688),
		vector2(858.14068603516, -2301.7275390625),
		vector2(864.97967529297, -2302.4465332031),
		vector2(862.97448730469, -2326.4291992188),
		vector2(893.88073730469, -2329.2299804688),
		vector2(898.49328613281, -2282.5910644531),
		vector2(905.71173095703, -2282.4621582031),
		vector2(905.96569824219, -2275.7841796875),
		vector2(902.26873779297, -2275.3005371094),
		vector2(902.99908447266, -2266.6032714844),
		vector2(906.78369140625, -2266.6918945312),
	}, {
		-- debugPoly = true,
		minZ = 25.34613609314,
		maxZ = 35.549388885498,
	})

	exports.ox_target:addBoxZone({
		id = "bobcat-secure",
		coords = vector3(876.94, -2262.69, 30.47),
		size = vector3(0.8, 1.4, 2.0),
		rotation = 356,
		debug = false,
		minZ = 29.87,
		maxZ = 31.47,
		options = {
			{
				icon = "fas fa-lock",
				label = "Secure Building",
				groups = { "police" },
				onSelect = function()
					TriggerEvent("Robbery:Client:Bobcat:StartSecuring", id)
				end,
				canInteract = function()
					return (
						GlobalState["Bobcat:ExtrDoor"]
						or GlobalState["Bobcat:FrontDoor"]
						or GlobalState["Bobcat:SecuredDoor"]
						or GlobalState["Bobcat:VaultDoor"]
					) and not GlobalState["Bobcat:Secured"]
				end,
			},
		}
	})

	exports.ox_target:addBoxZone({
		id = "bobcat-c4",
		coords = vector3(873.44, -2294.37, 30.47),
		size = vector3(1.4, 1.4, 2.0),
		rotation = 355,
		debug = false,
		minZ = 29.47,
		maxZ = 31.67,
		options = {
			{
				icon = "fas fa-bomb",
				label = "Grab Breaching Charge",
				event = "Robbery:Client:Bobcat:GrabC4",
				canInteract = function()
					return LocalPlayer.state.inBobcat
						and not GlobalState["BobcatC4"]
						and GlobalState["Bobcat:ExtrDoor"]
						and GlobalState["Bobcat:FrontDoor"]
						and GlobalState["Bobcat:SecuredDoor"]
				end,
			},
		}
	})

	exports.ox_target:addBoxZone({
		id = "bobcat-front-pc-hack",
		coords = vector3(875.15, -2263.83, 30.47),
		size = vector3(0.8, 1.2, 2.0),
		rotation = 354,
		debug = false,
		minZ = 28.92,
		maxZ = 31.32,
		options = {
			{
				icon = "fas fa-terminal",
				label = "Hack Terminal",
				event = "Robbery:Client:Bobcat:HackFrontPC",
				item = "electronics_kit",
				canInteract = function()
					return LocalPlayer.state.inBobcat
						and not GlobalState["Bobcat:PCHacked"]
						and GlobalState["Bobcat:ExtrDoor"]
						and GlobalState["Bobcat:FrontDoor"]
				end,
			},
		}
	})

	exports.ox_target:addBoxZone({
		id = "bobcat-securiy-hack",
		coords = vector3(887.07, -2299.13, 30.47),
		size = vector3(3.0, 1.0, 2.0),
		rotation = 264,
		debug = false,
		minZ = 29.47,
		maxZ = 31.27,
		options = {
			{
				icon = "fas fa-terminal",
				label = "Hack Terminal",
				event = "Robbery:Client:Bobcat:HackSecuriyPC",
				canInteract = function()
					return LocalPlayer.state.inBobcat
						and not GlobalState["Bobcat:SecurityPCHacked"]
						and GlobalState["Bobcat:ExtrDoor"]
						and GlobalState["Bobcat:FrontDoor"]
						and GlobalState["Bobcat:SecuredDoor"]
						and GlobalState["Bobcat:SecurityDoor"]
				end,
			},
		}
	})

	while GlobalState["Bobcat:LootLocations"] == nil do
		Wait(1)
	end

	for k, v in ipairs(GlobalState["Bobcat:LootLocations"]) do
		exports.ox_target:addBoxZone({
			id = string.format("bobcat-loot-%s", k),
			coords = v.coords,
			size = vector3(v.width, v.length, 2.0),
			rotation = v.options.heading or 0,
			debug = false,
			minZ = v.options.minZ,
			maxZ = v.options.maxZ,
			options = {
				{
					icon = "fas fa-hand-paper",
					label = "Grab Loot",
					lootId = v.data.id,
					onSelect = function()
						exports["pulsar-core"]:ServerCallback("Robbery:Bobcat:CheckLoot", v.data, function(s)
							if s then
								exports["pulsar-core"]:ServerCallback("Robbery:Bobcat:Loot", v.data, function(s2) end)
							end
						end)
					end,
					canInteract = function()
						return LocalPlayer.state.inBobcat
							and GlobalState["Bobcat:ExtrDoor"]
							and GlobalState["Bobcat:FrontDoor"]
							and GlobalState["Bobcat:SecuredDoor"]
							and GlobalState["Bobcat:VaultDoor"]
							and not GlobalState[string.format("Bobcat:Loot:%s", v.data.id)]
					end,
				},
			}
		})
	end

	exports["pulsar-core"]:RegisterClientCallback("Robbery:Bobcat:SetupPeds", function(data, cb)
		SetupPeds(data.peds, data.isBobcat, data.skipLeaveVeh)
	end)
end)

AddEventHandler("Robbery:Client:Bobcat:StartSecuring", function(entity, data)
	exports['pulsar-hud']:Progress({
		name = "secure_bobcat",
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
			exports["pulsar-core"]:ServerCallback("Robbery:Bobcat:Secure", {})
		end
	end)
end)

-- AddEventHandler("Robbery:Client:Bobcat:HackFrontPC", function(entity, t)
-- 	exports["pulsar-core"]:ServerCallback("Robbery:Bobcat:CheckFrontPC", {}, function(data)
-- 		if data then
-- 			_capPass = 1
-- 			DoCaptcha(data.passes, data.config, data.data, function(isSuccess, extra)
-- 				exports["pulsar-core"]:ServerCallback("Robbery:Bobcat:FrontPCResults", {
-- 					state = isSuccess,
-- 				}, function() end)
-- 			end)
-- 		end
-- 	end)
-- end)

-- AddEventHandler("Robbery:Client:Bobcat:HackSecurityPC", function(entity, t)
-- 	exports["pulsar-core"]:ServerCallback("Robbery:Bobcat:CheckSecurityPC", {}, function(data)
-- 		if data then
-- 			_capPass = 1
-- 			DoCaptcha(data.passes, data.config, data.data, function(isSuccess, extra)
-- 				exports["pulsar-core"]:ServerCallback("Robbery:Bobcat:SecurityPCResults", {
-- 					state = isSuccess,
-- 				}, function() end)
-- 			end)
-- 		end
-- 	end)
-- end)

RegisterNetEvent("Robbery:Client:Bobcat:UpdateIPL", function(state)
	local interiorid = GetInteriorAtCoords(883.4142, -2282.372, 31.44168)
	if not state then
		RequestIpl("prologue06_int")
		ActivateInteriorEntitySet(interiorid, "np_prolog_clean")
		DeactivateInteriorEntitySet(interiorid, "np_prolog_broken")
	else
		ActivateInteriorEntitySet(interiorid, "np_prolog_broken")
		RemoveIpl(interiorid, "np_prolog_broken")
		DeactivateInteriorEntitySet(interiorid, "np_prolog_clean")
	end
	RefreshInterior(interiorid)
end)

AddEventHandler("Robbery:Client:Bobcat:GrabC4", function()
	exports['pulsar-hud']:Progress({
		name = "bobcat_c4",
		duration = (math.random(5) + 5) * 1000,
		label = "Grabbing Breach Charge",
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
			anim = "type",
		},
	}, function(status)
		if not status then
			exports["pulsar-core"]:ServerCallback("Robbery:Bobcat:PickupC4", {}, function(s) end)
		end
	end)
end)

AddEventHandler("Robbery:Client:Bobcat:GrabLoot", function(entity, data)
	exports["pulsar-core"]:ServerCallback("Robbery:Bobcat:CheckLoot", data, function(s)
		if s then
			exports['pulsar-hud']:Progress({
				name = "bobcat_loot",
				duration = (math.random(10) + 5) * 1000,
				label = "Grabbing Fat Lewts",
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
					anim = "type",
				},
			}, function(status)
				if not status then
					exports["pulsar-core"]:ServerCallback("Robbery:Bobcat:Loot", data, function(s2) end)
				else
					exports["pulsar-core"]:ServerCallback("Robbery:Bobcat:CancelLoot", data, function(s2) end)
				end
			end)
		end
	end)
end)

AddEventHandler("Polyzone:Enter", function(id, point, insideZone, data)
	if id == "bobcat" then
		LocalPlayer.state:set("inBobcat", true, true)
	end
end)

AddEventHandler("Polyzone:Exit", function(id, point, insideZone, data)
	if id == "bobcat" then
		if LocalPlayer.state.inBobcat then
			LocalPlayer.state:set("inBobcat", false, true)
		end
	end
end)

function SetupPeds(peds, isBobcat, skipLeaveVeh)
	for k, v in ipairs(peds) do
		while not DoesEntityExist(NetworkGetEntityFromNetworkId(v)) do
			Wait(1)
		end

		local ped = NetworkGetEntityFromNetworkId(v)

		local interior = GetInteriorFromEntity(ped)
		if interior ~= 0 then
			local roomHash = GetRoomKeyFromEntity(ped)
			if roomHash ~= 0 then
				ForceRoomForEntity(ped, interior, roomHash)
			end
		end

		DecorSetBool(ped, "ScriptedPed", true)
		SetEntityAsMissionEntity(ped, 1, 1)

		if isBobcat then
			SetEntityMaxHealth(ped, 2000)
			SetEntityHealth(ped, 2000)
			SetPedArmour(ped, 1000)
		else
			SetEntityMaxHealth(ped, 1150)
			SetEntityHealth(ped, 1150)
			SetPedArmour(ped, 350)
		end

		SetPedRelationshipGroupDefaultHash(ped, `BOBCAT_SECURITY`)
		SetPedRelationshipGroupHash(ped, `BOBCAT_SECURITY`)
		SetPedRelationshipGroupHash(ped, `HATES_PLAYER`)
		SetCanAttackFriendly(ped, false, true)
		SetPedAsCop(ped)

		TaskTurnPedToFaceEntity(ped, PlayerPedId(), 1.0)
	end

	for k, v in ipairs(peds) do
		local ped = NetworkGetEntityFromNetworkId(v)

		SetPedCombatAttributes(ped, 0, 1)
		SetPedCombatAttributes(ped, 3, 1)
		SetPedCombatAttributes(ped, 5, 1)
		SetPedCombatAttributes(ped, 46, 1)
		SetPedSeeingRange(ped, 3000.0)
		SetPedHearingRange(ped, 3000.0)
		SetPedAlertness(ped, 3)
		SetPedCombatRange(ped, 2)
		SetPedCombatMovement(ped, 2)
		SetPedCanSwitchWeapon(ped, true)
		SetPedSuffersCriticalHits(ped, false)
		SetRunSprintMultiplierForPlayer(ped, 1.49)
		TaskCombatHatedTargetsInArea(ped, GetEntityCoords(ped), 200.0, false)
		SetPedAsEnemy(ped, true)
		SetPedFleeAttributes(ped, 0, 0)

		local _, cur = GetCurrentPedWeapon(ped, true)
		SetPedInfiniteAmmo(ped, true, cur)
		SetPedDropsWeaponsWhenDead(ped, false)

		SetEntityInvincible(ped, false)

		TaskGoToEntityWhileAimingAtEntity(ped, PlayerPedId(), PlayerPedId(), 16.0, true, 0, 15, 1, 1, 1566631136)
		TaskCombatPed(ped, PlayerPedId(), 0, 16)
	end
end
