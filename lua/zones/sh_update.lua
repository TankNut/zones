AddCSLuaFile()

zones.UpdateBudget = 0.001 -- 1ms, need to convar later
zones.Epsilon = 1 -- Minimum distance required before we update an entity's zones

zones.Coroutine = nil -- Setting to nil here forces a restart, in-case we update the function

zones.UpdateQueued = false -- Set when new zones are added, forces every entity to update during the next cycle
zones.ForceUpdate = false

function zones.CheckEntityData(ent)
	local pos = ent:EyePos()

	if not zones.EntityData[ent] then
		zones.EntityData[ent] = {
			LastPos = pos,
			Cache = {}, -- Contains a list of cached StaticFilter results
			Stack = {}, -- Contains every zone we're inside of sorted by GetZoneID, including 'inactive' ones
			Active = {} -- Contains only the active zone, sorted by GetZoneID
		}

		return true
	end

	local data = zones.EntityData[ent]

	if zones.ForceUpdate or pos:DistToSqr(data.LastPos) > zones.Epsilon * zones.Epsilon then
		data.LastPos = pos

		return true
	end
end

function zones.Update()
	local cr = zones.Coroutine

	if not cr then
		cr = coroutine.create(zones.UpdateFunc)
	end

	local ok, err = coroutine.resume(cr)

	if not ok then
		ErrorNoHalt(debug.traceback(cr, err) .. "\n")
	end
end

local function filter(tab, callback)
	for k, v in pairs(tab) do
		if not callback(v, k) then
			tab[k] = nil
		end
	end

	return tab
end

function zones.UpdateFunc()
	if table.Count(zones.ZoneEntities) == 0 then
		return
	end

	if zones.UpdateQueued then
		zones.UpdateQueued = false
		zones.ForceUpdate = true
	end

	-- No ents.Iterator since we might be doing this over multiple ticks and I don't trust it for that.
	local entities = ents.GetAll()
	local start = SysTime()

	local function checkBudget()
		if SysTime() - start > zones.UpdateBudget then
			coroutine.yield()

			start = SysTime()
		end
	end

	for _, ent in pairs(entities) do
		if ent == game.GetWorld() or zones.ZoneEntities[ent] then
			continue
		end

		-- Check if we actually want to update this entity
		if not zones.CheckEntityData(ent) then
			checkBudget()

			continue
		end

		local pos = ent:EyePos()
		local data = zones.EntityData[ent]

		local cache = data.Cache
		local stack = data.Stack
		local active = data.Active

		local entering = {}
		local exiting = {}

		for id, zoneList in pairs(stack) do
			-- Cleaning up happens in OnRemove so we can just cut them out without doing anything else
			filter(zoneList, function(zone)
				return IsValid(zone)
			end)
		end

		for zone in pairs(zones.ZoneEntities) do
			if not zone.Realm then
				continue
			end

			if cache[zone] == nil then
				cache[zone] = zone:StaticFilter(ent)
			end

			if not cache[zone] then
				continue
			end

			local id = zone:GetZoneID()
			local alreadyInside = zone:ContainsEntity(ent)

			if zone:DynamicFilter(ent) and zone:Contains(pos) then
				if not alreadyInside then
					entering[id] = entering[id] or {}

					table.insert(entering[id], zone)

					zone.EntityCache[ent] = true
				end
			else
				if alreadyInside then
					exiting[id] = exiting[id] or {}
					exiting[id][zone] = true

					zone.EntityCache[ent] = nil
				end
			end
		end

		for id, zoneList in pairs(entering) do
			stack[id] = stack[id] or {}

			table.Add(stack[id], zoneList)
		end

		for id, zoneList in pairs(stack) do
			if #zoneList < 1 then
				continue
			end

			local exit = exiting[id]

			filter(zoneList, function(zone)
				if not IsValid(zone) then
					return false
				end

				if exit and exit[zone] then
					return false
				end

				return true
			end)

			table.sort(zoneList, function(a, b)
				if not IsValid(b) then
					return true
				end

				return a:GetZonePriority() > b:GetZonePriority()
			end)

			local current = active[id]
			local target = zoneList[1]

			if current != target then
				if IsValid(current) then
					current:OnExit(ent, target != nil)
				end

				if IsValid(target) then
					target:OnEnter(ent, current != nil)
				end

				active[id] = target
			end
		end

		checkBudget()
	end

	zones.Coroutine = nil
	zones.ForceUpdate = false
end

function zones.CleanupZone(zone)
	for _, data in pairs(zones.EntityData) do
		data.Cache[zone] = nil
	end

	zones.ZoneEntities[zone] = nil
end

function zones.CleanupEntity(ent)
	if not zones.EntityData[ent] then
		return
	end

	for zone in pairs(zones.ZoneEntities) do
		if zone.EntityCache[ent] then
			zone:OnExit(ent, false, true)
			zone.EntityCache[ent] = nil
		end
	end

	zones.EntityData[ent] = nil
end
