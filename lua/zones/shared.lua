AddCSLuaFile()

zones = zones or {}

zones.ZoneEntities = zones.ZoneEntities or {}
zones.EntityData = zones.EntityData or {}

zones.REALM_CLIENT = CLIENT
zones.REALM_SERVER = SERVER
zones.REALM_SHARED = true

zones.SHAPE_BOX = 1
zones.SHAPE_SPHERE = 2
zones.SHAPE_PLANE = 3

include("sh_hooks.lua")
include("sh_persistence.lua")
include("sh_update.lua")
include("sh_settings.lua")

if SERVER then
	include("sv_ents.lua")
end

function zones.IsZone(ent)
	if isentity(ent) then
		ent = ent:GetClass()
	end

	return scripted_ents.IsBasedOn(ent, "base_zone")
end

local names = {
	"Box",
	"Sphere",
	"Plane"
}

function zones.GetShapeName(id)
	return names[id] or "*INVALID*"
end

function zones.GetActive(ent, id)
	local data = zones.EntityData[ent]

	if not data then
		return id and nil or {}
	end

	return id and data.Active[id] or table.Copy(data.Active)
end

function zones.GetAll(ent, id)
	local data = zones.EntityData[ent]

	if not data then
		return id and nil or {}
	end

	if id then
		return data.Stack[id] and table.Copy(data.Stack[id]) or {}
	else
		return table.Copy(data.Stack)
	end
end
