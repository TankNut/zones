AddCSLuaFile()

if SERVER then
	return
end

zones.Settings = zones.Settings or {}

zones.Settings.OnlyDrawSelected = CreateClientConVar("zones_only_draw_selected", 0, true, false, "Whether zones should only draw when they're selected", 0, 1)
