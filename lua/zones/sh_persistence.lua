AddCSLuaFile()

if CLIENT then
	return
end

file.CreateDir("zones")

zones.SaveFile = "zones/" .. game.GetMap() .. ".json"

function zones.Save(now)
	local function save()
		local data = {}

		for zone in pairs(zones.ZoneEntities) do
			local shape = zone:GetShape()
			local entry = {
				Class = zone:GetClass(),
				Shape = shape,
				Data = zone:SaveCustomData()
			}

			if shape == zones.SHAPE_BOX then
				entry.Mins = zone:GetMins()
				entry.Maxs = zone:GetMaxs()
			elseif shape == zones.SHAPE_SPHERE then
				entry.Pos = zone:GetPos()
				entry.Radius = zone:GetRadius()
			elseif shape == zones.SHAPE_PLANE then
				entry.Pos = zone:GetPos()
				entry.Normal = zone:GetAngles():Forward()
			end

			table.insert(data, entry)
		end

		file.Write(zones.SaveFile, util.TableToJSON(data, true))
	end

	if now then
		timer.Remove("zones.save")
		save()
	end

	timer.Create("zones.save", 1, 1, save)
end

function zones.Load()
	if not file.Exists(zones.SaveFile, "DATA") then
		return
	end

	local data = util.JSONToTable(file.Read(zones.SaveFile, "DATA"))

	for _, entry in pairs(data) do
		if not zones.IsZone(entry.Class) then
			return
		end

		local zone

		if entry.Shape == zones.SHAPE_BOX then
			zone = zones.CreateBox(entry.Class, entry.Mins, entry.Maxs)
		elseif entry.Shape == zones.SHAPE_SPHERE then
			zone = zones.CreateSphere(entry.Class, entry.Pos, entry.Radius)
		elseif entry.Shape == zones.SHAPE_PLANE then
			zone = zones.CreatePlane(entry.Class, entry.Pos, entry.Normal)
		end

		if not IsValid(zone) then
			continue
		end

		zone:LoadCustomData(entry.Data)
	end
end
