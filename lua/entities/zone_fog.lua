AddCSLuaFile()
DEFINE_BASECLASS("base_zone")

ENT.Base = "base_zone"

ENT.PrintName = "Fog"

ENT.Realm = zones.REALM_CLIENT
ENT.Color = Color(153, 178, 204, 50)

local steps = 20
local fogColor = Color(153, 178, 204)

if CLIENT then
	function ENT:StaticFilter(ent)
		return ent == LocalPlayer()
	end

	function ENT:OnEnter(ent, transition)
		local func = function() return self:DrawFog() end

		hook.Add("SetupWorldFog", self, func)
		hook.Add("SetupSkyboxFog", self, func)
	end

	function ENT:OnExit(ent, transition, removing)
		hook.Remove("SetupWorldFog", self)
		hook.Remove("SetupSkyboxFog", self)
	end

	function ENT:DrawFog(frac)
		render.FogMode(MATERIAL_FOG_LINEAR)
		render.FogStart(-750)
		render.FogEnd(1000)
		render.FogMaxDensity(1)
		render.FogColor(fogColor.r, fogColor.g, fogColor.b)

		return true
	end

	hook.Add("PostDrawTranslucentRenderables", "zone_fog", function(depth, skybox, skybox3d)
		if skybox or skybox3d then
			return
		end

		if IsValid(zones.GetActive(LocalPlayer(), "zone_fog")) then
			return
		end

		local weapon = LocalPlayer():GetActiveWeapon()

		if IsValid(weapon) and weapon:GetClass() == "weapon_zone_manager" then
			return
		end

		render.SetStencilEnable(true)
		render.ClearStencil()

		render.SetStencilTestMask(255)
		render.SetStencilWriteMask(255)
		render.SetStencilReferenceValue(1)

		render.SetStencilPassOperation(STENCIL_REPLACE)
		render.SetStencilFailOperation(STENCIL_KEEP)
		render.SetStencilZFailOperation(STENCIL_KEEP)

		render.SetStencilCompareFunction(STENCIL_ALWAYS)
		render.SetColorMaterial()

		render.OverrideColorWriteEnable(true, false)
			for _, zone in pairs(ents.FindByClass("zone_fog")) do
				zone:DrawShape(color_white)
			end
		render.OverrideColorWriteEnable(false)

		render.SetStencilCompareFunction(STENCIL_EQUAL)

		local eye = EyePos()

		render.OverrideDepthEnable(true, true)

		fogColor.a = 255

		render.DrawSphere(eye, -1000, 20, 20, fogColor)

		for i = 1, steps do
			fogColor.a = math.Remap(i, 1, steps, 100, 10)
			render.DrawSphere(eye, math.Remap(i, 1, steps, -1000, -10), 20, 20, fogColor)
		end

		render.OverrideDepthEnable(false, true)

		render.SetStencilEnable(false)
	end)
end
