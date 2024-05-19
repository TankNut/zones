AddCSLuaFile()

hook.Add("Think", "zone", function()
	zones.Update()
end)

hook.Add("OnEntityCreated", "zones", function(ent)
	if not IsValid(ent) or not zones.IsZone(ent) then
		return
	end

	zones.ZoneEntities[ent] = true
	zones.UpdateQueued = true
end)

hook.Add("EntityRemoved", "zones", function(ent, fullUpdate)
	if fullUpdate then
		return
	end

	if zones.IsZone(ent) then
		zones.CleanupZone(ent)
		zones.UpdateQueued = true
	else
		zones.CleanupEntity(ent)
	end
end)

-- Default hook configuration

hook.Add("CanCreateZone", "zones", function(ply, class, shape)
	local entityTable = scripted_ents.Get(class)

	if entityTable.AdminOnly and not ply:IsAdmin() then
		return false
	end
end)

hook.Add("CanManageZone", "zones", function(ply, zone)
	if zone:GetCreator() != ply and not ply:IsAdmin() then
		return false
	end
end)

hook.Add("CanPersistZone", "zones", function(ply, zone)
	if not ply:IsAdmin() then
		return false
	end
end)

if CLIENT then
	hook.Add("PostDrawTranslucentRenderables", "zones", function(depth, skybox, skybox3d)
		if skybox or skybox3d then
			return
		end

		if render.GetRenderTarget() != nil then
			return
		end

		local weapon = LocalPlayer():GetActiveWeapon()

		if IsValid(weapon) and weapon:GetClass() == "weapon_zone_manager" then
			local onlyDrawSelected = zones.Settings.OnlyDrawSelected:GetBool()

			if onlyDrawSelected then
				local zone = weapon.SelectedZone

				if IsValid(zone) then
					zone:DrawZoneDebug()
				end
			else
				for zone in pairs(zones.ZoneEntities) do
					zone:DrawZoneDebug()
				end
			end

			weapon:PostDrawTranslucentRenderables(depth, skybox, skybox3d)
		else
			for zone in pairs(zones.ZoneEntities) do
				zone:DrawZone()
			end
		end
	end)
else
	hook.Add("InitPostEntity", "zones", zones.Load)

	hook.Add("ShutDown", "zones", function()
		if timer.Exists("zones.save") then
			zones.Save(true)
		end
	end)

	hook.Add("CanEditVariable", "zones", function(ent, ply)
		if not zones.ZoneEntities[ent] then
			return
		end

		return hook.Run("CanManageZone", ply, ent)
	end)
end
