local _sbChangeHandlers = {}

function PaletoNeedsReset()
	if _bankStates.paleto.workstation or _bankStates.paleto.vaultTerminal then
		return true
	end

	for k, v in ipairs(_pbDoorIds) do
		if not exports['ox_doorlock']:IsLocked(v) then
			return true
		end
	end

	for k, v in pairs(_bankStates.paleto.securityPower) do
		if v ~= nil then
			return true
		end
	end

	for k, v in pairs(_bankStates.paleto.officeHacks) do
		if v ~= nil then
			return true
		end
	end

	for k, v in pairs(_bankStates.paleto.drillPoints) do
		if v ~= nil then
			return true
		end
	end

	if IsPaletoPowerDisabled() then
		return true
	end

	return false
end

AddEventHandler("Robbery:Client:Setup", function()
	exports['pulsar-polyzone']:CreatePoly("bank_paleto", {
		-- vector2(-102.71809387207, 6450.455078125),
		-- vector2(-103.4940032959, 6447.8139648438),
		-- vector2(-104.5740814209, 6447.9951171875),
		-- vector2(-103.34963226318, 6451.4379882812),
		-- vector2(-111.12901306152, 6459.4956054688),
		-- vector2(-109.9501953125, 6460.8173828125),
		-- vector2(-112.78342437744, 6463.6616210938),
		-- vector2(-113.99594116211, 6462.578125),
		-- vector2(-123.86438751221, 6472.3857421875),
		-- vector2(-115.0514755249, 6481.14453125),
		-- vector2(-113.489112854, 6479.6889648438),
		-- vector2(-107.47613525391, 6485.4438476562),
		-- vector2(-88.173873901367, 6465.876953125),
		-- vector2(-93.701072692871, 6460.7612304688),
		-- vector2(-93.123313903809, 6460.1650390625),
		vector2(-129.5386505127, 6470.3793945312),
		vector2(-103.76642608643, 6444.1923828125),
		vector2(-82.150863647461, 6466.1552734375),
		vector2(-107.7488861084, 6491.7861328125),
	}, {
		--debugPoly = true,
	})

	exports['pulsar-polyzone']:CreateCircle("paleto_power", vector3(-169.13, 6296.62, 31.49), 1000.0, {
		useZ = false,
		--debugPoly=true
	})

	exports['pulsar-polyzone']:CreateBox("paleto_hack_access", vector3(-107.04, 6474.16, 31.63), 1.8, 1.2, {
		heading = 315,
		--debugPoly=true,
		minZ = 30.63,
		maxZ = 32.63,
	}, {})

	for k, v in ipairs(_pbKillZones) do
		exports['pulsar-polyzone']:CreateBox(string.format("pb_killzone_%s", k), v.coords, v.length, v.width, v.options,
			v.data)
	end

	for k, v in ipairs(_pbPCHackAreas) do
		exports['pulsar-polyzone']:CreateBox(
			string.format("paleto_hack_pc_%s", v.data.pcId),
			v.coords,
			v.length,
			v.width,
			v.options,
			v.data
		)
	end

	for k, v in ipairs(_pbSubStationZones) do
		exports['pulsar-polyzone']:CreateBox(
			string.format("pb_substation_%s", v.data.subStationId),
			v.coords,
			v.length,
			v.width,
			v.options,
			v.data
		)
	end

	exports.ox_target:addBoxZone({
		id = "paleto_secure",
		coords = vector3(-109.57, 6461.51, 31.64),
		size = vector3(0.6, 0.4, 2.0),
		rotation = 315,
		debug = false,
		minZ = 31.24,
		maxZ = 32.84,
		options = {
			{
				icon = "fas fa-lock",
				label = "Secure Bank",
				event = "Robbery:Client:Paleto:StartSecuring",
				groups = { "police" },
				canInteract = PaletoNeedsReset,
			},
			{
				icon = "fas fa-bell",
				label = "Disable Alarm",
				event = "Robbery:Client:Paleto:DisableAlarm",
				groups = { "police" },
				canInteract = function()
					return _bankStates.paleto.fookinLasers
				end,
			},
		}
	})

	exports.ox_target:addBoxZone({
		id = "paleto_security",
		coords = vector3(-91.76, 6464.78, 31.63),
		size = vector3(1.4, 0.8, 2.0),
		rotation = 315,
		debug = false,
		minZ = 30.63,
		maxZ = 32.43,
		options = {
			{
				icon = "fas fa-bell",
				label = "Access Door Controls",
				event = "Robbery:Client:Paleto:Doors",
				canInteract = function()
					return IsPaletoExploitInstalled() and
						not exports['ox_doorlock']:IsLocked("bank_savings_paleto_security")
				end,
			},
		}
	})

	exports.ox_target:addBoxZone({
		id = "paleto_hack_workstation",
		coords = vector3(-106.12, 6473.87, 31.63),
		size = vector3(1.2, 0.6, 2.0),
		rotation = 315,
		debug = false,
		minZ = 31.03,
		maxZ = 32.43,
		options = {
			{
				icon = "fas fa-network-wired",
				label = "Breach Network",
				items = {
					{
						item = "adv_electronics_kit",
						count = 1,
					},
					{
						item = "vpn",
						count = 1,
					},
				},
				event = "Robbery:Client:Paleto:Workstation",
				canInteract = function()
					return IsPaletoExploitInstalled()
						and LocalPlayer.state.inPaletoWSPoint
						and (not _bankStates.paleto.workstation or GetCloudTimeAsInt() > _bankStates.paleto.workstation)
				end,
			},
		}
	})

	for k, v in ipairs(_pbOfficeHacks) do
		exports.ox_target:addBoxZone({
			id = string.format("paleto_officehack_%s", k),
			coords = v.coords,
			size = vector3(v.length, v.width, 2.0),
			rotation = v.options.heading or 0,
			debug = false,
			minZ = v.options.minZ,
			maxZ = v.options.maxZ,
			options = {
				{
					icon = "fas fa-network-wired",
					label = "Upload Exploit",
					items = {
						{
							item = "adv_electronics_kit",
							count = 1,
						},
						{
							item = "vpn",
							count = 1,
						},
					},
					officeId = v.data.officeId,
					onSelect = function()
						TriggerEvent("Robbery:Client:Paleto:OfficeHack", v.data)
					end,
					canInteract = function()
						return IsPaletoExploitInstalled()
							and (
								not _bankStates.paleto.officeHacks[v.data.officeId]
								or GetCloudTimeAsInt() > _bankStates.paleto.officeHacks[v.data.officeId]
							)
					end,
				},
			}
		})
	end

	for k, v in ipairs(_pbPowerHacks) do
		exports.ox_target:addBoxZone({
			id = string.format("paleto_electricbox_%s", k),
			coords = v.coords,
			size = vector3(v.length, v.width, 2.0),
			rotation = v.options.heading or 0,
			debug = false,
			minZ = v.options.minZ,
			maxZ = v.options.maxZ,
			options = {
				{
					icon = "fas fa-terminal",
					label = "Hack Power Interface",
					item = "adv_electronics_kit",
					boxId = v.data.boxId,
					onSelect = function()
						TriggerEvent("Robbery:Client:Paleto:ElectricBox:Hack", v.data)
					end,
					canInteract = function()
						return not _bankStates.paleto.electricalBoxes[v.data.boxId]
							or GetCloudTimeAsInt() > _bankStates.paleto.electricalBoxes[v.data.boxId]
					end,
				},
			}
		})
	end

	for k, v in ipairs(_pbLasers) do
		exports['pulsar-lasers']:Create(
			string.format("paleto_lasers_%s", k),
			v.origins,
			v.targets,
			v.options,
			false,
			function(playerBeingHit, hitPos)
				if playerBeingHit then
					exports["pulsar-core"]:ServerCallback("Robbery:Paleto:TriggeredLaser")
				end
			end
		)
	end

	for k, v in ipairs(_pbDrillPoints) do
		exports.ox_target:addBoxZone({
			id = string.format("paleto_drillpoint_%s", v.data.drillId),
			coords = v.coords,
			size = vector3(v.length, v.width, 2.0),
			rotation = v.options.heading or 0,
			debug = false,
			minZ = v.options.minZ,
			maxZ = v.options.maxZ,
			options = {
				{
					icon = "fas fa-drill",
					label = "Use Drill",
					item = "drill",
					drillId = v.data.drillId,
					onSelect = function()
						TriggerEvent("Robbery:Client:Paleto:Drill", v.data)
					end,
					canInteract = function()
						return IsPaletoExploitInstalled()
							and not exports['ox_doorlock']:IsLocked("bank_savings_paleto_vault")
							and (
								not _bankStates.paleto.drillPoints[v.data.drillId]
								or GetCloudTimeAsInt() > _bankStates.paleto.drillPoints[v.data.drillId]
							)
					end,
				},
			}
		})
	end

	exports.ox_target:addBoxZone({
		id = "paleto_office_safe",
		coords = vector3(-105.27, 6480.67, 31.63),
		size = vector3(0.8, 0.6, 2.0),
		rotation = 45,
		debug = false,
		minZ = 31.43,
		maxZ = 32.83,
		options = {
			{
				icon = "fas fa-unlock",
				label = "Crack Safe",
				event = "Robbery:Client:Paleto:Safe",
				item = "paleto_access_codes",
				canInteract = function()
					return IsPaletoExploitInstalled()
						and not exports['ox_doorlock']:IsLocked("bank_savings_paleto_office_3")
						and (not _bankStates.paleto.officeSafe or GetCloudTimeAsInt() > _bankStates.paleto.officeSafe)
				end,
			},
		}
	})

	for k, v in ipairs(_pbOfficeSearch) do
		exports.ox_target:addBoxZone({
			id = string.format("paleto_searchpoint_%s", v.data.searchId),
			coords = v.coords,
			size = vector3(v.length, v.width, 2.0),
			rotation = v.options.heading or 0,
			debug = false,
			minZ = v.options.minZ,
			maxZ = v.options.maxZ,
			options = {
				{
					icon = "fas fa-magnifying-glass",
					label = "Search",
					door = v.data.door,
					searchId = v.data.searchId,
					onSelect = function()
						TriggerEvent("Robbery:Client:Paleto:Search", v.data)
					end,
					canInteract = function()
						return IsPaletoExploitInstalled()
							and not exports['ox_doorlock']:IsLocked(v.data.door)
							and (
								not _bankStates.paleto.officeSearch[v.data.searchId]
								or GetCloudTimeAsInt() > _bankStates.paleto.officeSearch[v.data.searchId]
							)
					end,
				},
			}
		})
	end
end)

AddEventHandler("Polyzone:Enter", function(id, testedPoint, insideZones, data)
	if id == "bank_paleto" then
		LocalPlayer.state:set("inPaletoBank", true, true)

		local powerDisabled = IsPaletoPowerDisabled()
		for k, v in ipairs(_pbLasers) do
			exports['pulsar-lasers']:SetActive(string.format("paleto_lasers_%s", k), not powerDisabled)
			exports['pulsar-lasers']:SetVisible(string.format("paleto_lasers_%s", k), not powerDisabled)
		end
	elseif id == "paleto_hack_access" and not exports['ox_doorlock']:IsLocked("bank_savings_paleto_gate") then
		LocalPlayer.state:set("inPaletoWSPoint", true, true)
	elseif data.subStationId ~= nil then
		LocalPlayer.state:set("inSubStation", data.subStationId, true)
	elseif data.pcId ~= nil then
		exports.ox_target:addModel(GetHashKey("xm_prop_base_staff_desk_02"), {
			{
				label = "Upload Exploit",
				icon = "fas fa-terminal",
				pcId = data.pcId,
				onSelect = function()
					TriggerEvent("Robbery:Client:Paleto:Upload", data)
				end,
				item = "adv_electronics_kit",
				distance = 2.0,
				canInteract = function(entity, opts)
					return (not GlobalState["Paleto:Secured"] or GetCloudTimeAsInt() > GlobalState["Paleto:Secured"])
						and (
							not _bankStates.paleto.exploits[opts.pcId]
							or GetCloudTimeAsInt() > _bankStates.paleto.exploits[opts.pcId]
						)
				end,
			},
		})
	elseif id == "paleto_power" then
		LocalPlayer.state:set("inPaletoPower", true, true)
	end
end)

AddEventHandler("Polyzone:Exit", function(id, testedPoint, insideZones, data)
	if id == "bank_paleto" then
		if LocalPlayer.state.inPaletoBank then
			LocalPlayer.state:set("inPaletoBank", false, true)
		end
		for k, v in ipairs(_pbLasers) do
			exports['pulsar-lasers']:SetActive(string.format("paleto_lasers_%s", k), false)
			exports['pulsar-lasers']:SetVisible(string.format("paleto_lasers_%s", k), false)
		end
	elseif id == "paleto_hack_access" then
		if LocalPlayer.state.inPaletoWSPoint then
			LocalPlayer.state:set("inPaletoWSPoint", false, true)
		end
	elseif data.subStationId ~= nil then
		if LocalPlayer.state.inSubStation then
			LocalPlayer.state:set("inSubStation", false, true)
		end
	elseif data.pcId ~= nil then
		exports.ox_target:removeModel(GetHashKey("xm_prop_base_staff_desk_02"))
	elseif id == "paleto_power" then
		LocalPlayer.state:set("inPaletoPower", false, true)
	end
end)

AddEventHandler("Robbery:Client:Update:paleto", function()
	if LocalPlayer.state.inPaletoBank then
		local powerDisabled = IsPaletoPowerDisabled()
		for k2, v2 in ipairs(_pbLasers) do
			exports['pulsar-lasers']:SetActive(string.format("paleto_lasers_%s", k2), not powerDisabled)
			exports['pulsar-lasers']:SetVisible(string.format("paleto_lasers_%s", k2), not powerDisabled)
		end
	end
end)

AddEventHandler("Robbery:Client:Paleto:ElectricBox:Hack", function(entity, data)
	exports["pulsar-core"]:ServerCallback("Robbery:Paleto:ElectricBox:Hack", data, function() end)
end)

AddEventHandler("Robbery:Client:Paleto:Upload", function(entity, data)
	exports["pulsar-core"]:ServerCallback("Robbery:Paleto:PC:Hack", data, function() end)
end)

AddEventHandler("Robbery:Client:Paleto:Workstation", function(entity, data)
	exports["pulsar-core"]:ServerCallback("Robbery:Paleto:Workstation", data, function() end)
end)

AddEventHandler("Robbery:Client:Paleto:OfficeHack", function(entity, data)
	exports["pulsar-core"]:ServerCallback("Robbery:Paleto:OfficeHack", data, function() end)
end)

AddEventHandler("Robbery:Client:Paleto:Drill", function(entity, data)
	exports["pulsar-core"]:ServerCallback("Robbery:Paleto:Drill", data.drillId, function() end)
end)

AddEventHandler("Robbery:Client:Paleto:Search", function(entity, data)
	exports["pulsar-core"]:ServerCallback("Robbery:Paleto:Search", data, function() end)
end)

AddEventHandler("Robbery:Client:Paleto:Safe", function(entity, data)
	exports["pulsar-core"]:ServerCallback("Robbery:Paleto:StartSafe", {}, function(s)
		if s then
			exports['pulsar-hud']:InputShow("Input Access Code", "Access Code", {
				{
					id = "code",
					type = "number",
					options = {
						inputProps = {
							maxLength = 4,
						},
					},
				},
			}, "Robbery:Client:Paleto:SafeInput", data)
		end
	end)
end)

AddEventHandler("Robbery:Client:Paleto:SafeInput", function(values, data)
	exports["pulsar-core"]:ServerCallback("Robbery:Paleto:Safe", {
		code = values.code,
		data = data,
	}, function() end)
end)

AddEventHandler("Input:Closed", function(event, data)
	if event == "Robbery:Client:Paleto:SafeInput" then
		exports["pulsar-core"]:ServerCallback("Robbery:Paleto:Safe", {
			code = false,
			data = data,
		}, function() end)
	end
end)

AddEventHandler("Robbery:Client:Paleto:VaultTerminal", function()
	exports['pulsar-hud']:Progress({
		name = "disable_vault_pc",
		duration = math.random(45, 60) * 1000,
		label = "Disabling",
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
			exports["pulsar-core"]:ServerCallback("Robbery:Paleto:VaultTerminal", {})
		end
	end)
end)

AddEventHandler("Robbery:Client:Paleto:Door", function(data)
	if data.officeId ~= nil then
		exports['pulsar-hud']:InputShow("Input Access Code", "Access Code", {
			{
				id = "code",
				type = "number",
				options = {
					inputProps = {
						maxLength = 4,
					},
				},
			},
		}, "Robbery:Client:Paleto:DoorInput", data)
	else
		exports["pulsar-core"]:ServerCallback("Robbery:Paleto:UnlockDoor", {
			data = data,
		})
	end
end)

AddEventHandler("Robbery:Client:Paleto:DoorInput", function(values, data)
	exports["pulsar-core"]:ServerCallback("Robbery:Paleto:UnlockDoor", {
		code = values.code,
		data = data,
	})
end)

AddEventHandler("Robbery:Client:Paleto:Doors", function(entity, data)
	exports["pulsar-core"]:ServerCallback("Robbery:Paleto:GetDoors", {}, function(menu)
		local menu = {
			main = {
				label = "Blaine Co Savings Door Controls",
				items = menu,
			},
		}

		exports['pulsar-hud']:ListMenuShow(menu)
	end)
end)

AddEventHandler("Robbery:Client:Paleto:StartSecuring", function(entity, data)
	exports['pulsar-hud']:Progress({
		name = "secure_paleto",
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
			exports["pulsar-core"]:ServerCallback("Robbery:Paleto:SecureBank", {})
		end
	end)
end)

AddEventHandler("Robbery:Client:Paleto:DisableAlarm", function(entity, data)
	exports['pulsar-hud']:Progress({
		name = "secure_paleto",
		duration = 3000,
		label = "Disabling",
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
			exports["pulsar-core"]:ServerCallback("Robbery:Paleto:DisableAlarm", {})
		end
	end)
end)

RegisterNetEvent("Robbery:Client:Paleto:CheckLasers", function()
	if LocalPlayer.state.inPaletoBank then
		local powerDisabled = IsPaletoPowerDisabled()
		for k2, v2 in ipairs(_pbLasers) do
			exports['pulsar-lasers']:SetActive(string.format("paleto_lasers_%s", k2), not powerDisabled)
			exports['pulsar-lasers']:SetVisible(string.format("paleto_lasers_%s", k2), not powerDisabled)
		end
	end
end)
