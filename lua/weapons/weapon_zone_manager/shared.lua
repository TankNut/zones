AddCSLuaFile()

SWEP.PrintName = "Zone Manager"
SWEP.Author = "TankNut"

SWEP.Instructions = [[
Primary: Build Shape
Use + Primary: Build Shape (Alt)

Secondary: Create Zone

Reload: Open Menu
Use + Reload: Reset Shape
]]

SWEP.Slot = 5

SWEP.Spawnable = true

SWEP.ViewModel = Model("models/weapons/c_arms.mdl")
SWEP.WorldModel = Model("models/weapons/w_slam.mdl")

SWEP.Primary.Automatic = true
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Ammo = "none"

SWEP.Secondary.Automatic = false
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Ammo = "none"

include("sh_box.lua")
include("sh_plane.lua")
include("sh_sphere.lua")

include("sh_ui.lua")

SWEP.ShapeConvar = CreateConVar("zones_shape", zones.SHAPE_BOX, bit.bor(FCVAR_ARCHIVE, FCVAR_USERINFO), "What shape to use when creating zones.", zones.SHAPE_BOX, zones.SHAPE_PLANE)

function SWEP:Initialize()
	self:SetHoldType("slam")
end

function SWEP:SetupDataTables()
	self:NetworkVar("Int", "LastShape")
	self:NetworkVar("Bool", "Active")

	-- Shape vars
	self:NetworkVar("Vector", "ZonePos")
	self:NetworkVar("Vector", "Normal")
	self:NetworkVar("Vector", "Mins")
	self:NetworkVar("Vector", "Maxs")

	self:NetworkVar("Float", "Radius")

	-- Defaults
	self:SetLastShape(0)
	self:SetActive(false)
end

function SWEP:Deploy()
	self:SetHoldType("slam")
end

function SWEP:GetShape()
	return self.ShapeConvar:GetInt(zones.SHAPE_BOX)
end

function SWEP:GetTrace()
	return self:GetOwner():GetEyeTrace()
end

function SWEP:Think()
	if self:GetLastShape() != self:GetShape() then
		self:SetActive(false)
		self:SetLastShape(self:GetShape())
	end
end

function SWEP:PrimaryAttack()
	local tr = self:GetTrace()

	if tr.StartSolid then
		return
	end

	local shape = self:GetShape()

	if shape == zones.SHAPE_BOX then
		self:BuildBox(tr)
	elseif shape == zones.SHAPE_SPHERE then
		self:BuildSphere(tr)
	elseif shape == zones.SHAPE_PLANE then
		self:BuildPlane(tr)
	end
end

function SWEP:SecondaryAttack()
	if SERVER then
		if game.SinglePlayer() then
			self:CallOnClient("SecondaryAttack")
		end

		return
	end

	self:OpenBuildMenu()
end

function SWEP:Reload()
	local ply = self:GetOwner()

	if not ply:KeyPressed(IN_RELOAD) then
		return
	end

	if ply:KeyDown(IN_USE) then
		self:SetActive(false)

		return
	end

	if game.SinglePlayer() then
		self:CallOnClient("ToggleUI")
	elseif CLIENT then
		self:ToggleUI()
	end
end

if CLIENT then
	function SWEP:DrawHUDBackground()
		local zone = self.SelectedZone

		if not IsValid(zone) then
			return
		end

		local pos = zone:GetPos():ToScreen()

		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawLine(ScrW() * 0.5, ScrH() * 0.5, pos.x, pos.y)

		surface.DrawLine(pos.x - 10, pos.y, pos.x + 10, pos.y)
		surface.DrawLine(pos.x, pos.y - 10, pos.x, pos.y + 10)
	end

	function SWEP:PostDrawTranslucentRenderables(depth, skybox, skybox3d)
		if not self:GetActive() or skybox or skybox3d then
			return
		end

		local shape = self:GetShape()

		if shape == zones.SHAPE_BOX then
			self:DrawBox()
		elseif shape == zones.SHAPE_SPHERE then
			self:DrawSphere()
		elseif shape == zones.SHAPE_PLANE then
			self:DrawPlane()
		end
	end
end
