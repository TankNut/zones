AddCSLuaFile()

function SWEP:ValidateShapeData(class, data)
	if not class then
		return false
	end

	local shape = self:GetShape()
	local ok = false

	if shape == zones.SHAPE_BOX then
		ok = self:ValidateBox(data)
	elseif shape == zones.SHAPE_SPHERE then
		ok = self:ValidateSphere(data)
	elseif shape == zones.SHAPE_PLANE then
		ok = self:ValidatePlane(data)
	end

	return ok
end

if CLIENT then
	local function installThink(ui, swep)
		local think = ui.Think

		ui.Weapon = swep
		ui.Think = function()
			if not IsValid(swep) or LocalPlayer():GetActiveWeapon() != swep then
				ui:Close()

				return
			end

			think(ui)

			if gui.IsGameUIVisible() and (not IsValid(vgui.GetKeyboardFocus()) or vgui.FocusedHasParent(ui)) and ui:IsMouseInputEnabled() then
				ui:Close()

				gui.HideGameUI()
			end
		end
	end

	function SWEP:ToggleUI()
		if IsValid(self.UI) then
			local state = not vgui.CursorVisible()

			self.Background:SetWorldClicker(state)
			self.UI:SetMouseInputEnabled(state)

			return
		end

		local background = vgui.Create("EditablePanel")

		background:Dock(FILL)
		background:SetWorldClicker(true)

		local ui = vgui.Create("DFrame")

		ui:SetSize(450, 350)
		ui:SetTitle("Zone Manager")
		ui:MakePopup()
		ui:Center()

		installThink(ui, self)

		ui:SetDraggable(true)
		ui:SetKeyboardInputEnabled(false)
		ui:RequestFocus()

		self.UI = ui
		self.Background = background

		self:AddTabs(ui)

		ui:InvalidateLayout(true)
		ui:SizeToChildren(true, true)

		ui.OnClose = function()
			self.Background:Remove()

			self.SelectedZone = nil
			self.SelectedLine = nil
		end
	end

	function SWEP:AddCreateMenu(ui)
		ui:DockPadding(10, 10, 10, 10)

		local panel = ui:Add("DPanel")

		panel:SetPaintBackground(false)
		panel:Dock(TOP)
		panel:SetTall(20)

		panel:InvalidateLayout()

		local label = panel:Add("DLabel")

		label:Dock(LEFT)
		label:InvalidateLayout(true)
		label:SetSize(150, 20)
		label:SetDark(true)
		label:SetText("Zone Shape")

		local shape = panel:Add("DComboBox")

		shape:Dock(FILL)
		shape:AddChoice("Box", zones.SHAPE_BOX, self:GetShape() == zones.SHAPE_BOX)
		shape:AddChoice("Sphere", zones.SHAPE_SPHERE, self:GetShape() == zones.SHAPE_SPHERE)
		shape:AddChoice("Plane", zones.SHAPE_PLANE, self:GetShape() == zones.SHAPE_PLANE)

		shape.OnSelect = function(_, _, _, data)
			RunConsoleCommand("zones_shape", data)
		end
	end

	function SWEP:AddManageMenu(ui)
		ui:DockPadding(10, 10, 10, 10)

		local listView
		local checkButtons
		local bottom = ui:Add("DPanel")

		bottom:DockMargin(0, 10, 0, 0)
		bottom:Dock(BOTTOM)
		bottom:SetTall(20)
		bottom:SetPaintBackground(false)

		local edit = bottom:Add("DButton")

		edit:DockMargin(0, 0, 10, 0)
		edit:Dock(LEFT)
		edit:SetText("Edit")

		edit.DoClick = function()
			local zone = self.SelectedZone
			local window = vgui.Create("DFrame")

			window:SetSize(320, 400)
			window:SetTitle(tostring(zone))
			window:SetSizable(true)
			window:MakePopup()
			window:Center()

			local control = window:Add("DEntityProperties")
			control:SetEntity(zone)
			control:Dock(FILL)

			control.OnEntityLost = function()
				window:Close()
			end
		end

		local delete = bottom:Add("DButton")

		delete:DockMargin(10, 0, 0, 0)
		delete:Dock(RIGHT)
		delete:SetText("Delete")

		delete.DoClick = function()
			local zone = self.SelectedZone
			local line = self.SelectedLine

			Derma_Query("Are you sure you want to delete the selected zone?", "Confirmation", "Yes", function()
				net.Start("zones.manager.delete")
					net.WriteEntity(zone)
				net.SendToServer()

				listView:RemoveLine(line:GetID())
				checkButtons(true)
			end, "No")
		end

		local save = bottom:Add("DButton")

		save:DockMargin(10, 0, 0, 0)
		save:Dock(RIGHT)

		save.DoClick = function()
			local zone = self.SelectedZone
			local line = self.SelectedLine

			local bool = not zone:GetSaved()

			net.Start("zones.manager.save")
				net.WriteEntity(zone)
				net.WriteBool(not zone:GetSaved())
			net.SendToServer()

			line:SetValue(3, bool and "Yes" or "")
			save:SetText(bool and "Unsave" or "Save")
		end

		checkButtons = function(force)
			local zone = self.SelectedZone
			local ply = LocalPlayer()

			if force or hook.Run("CanManageZone", ply, zone) == false then
				edit:SetDisabled(true)
				delete:SetDisabled(true)
				save:SetDisabled(true)
				save:SetText("Save")

				return
			end

			edit:SetDisabled(table.IsEmpty(zone:GetEditingData()))
			delete:SetDisabled(false)

			if hook.Run("CanPersistZone", LocalPlayer(), zone) == false then
				save:SetDisabled(true)
			else
				save:SetDisabled(false)
			end

			save:SetText(zone:GetSaved() and "Unsave" or "Save")
		end

		checkButtons(true)

		listView = ui:Add("DListView")
		listView:Dock(FILL)
		listView:SetMultiSelect(false)
		listView:AddColumn("Type")
		listView:AddColumn("Shape"):SetFixedWidth(50)
		listView:AddColumn("Saved"):SetFixedWidth(50)
		listView:AddColumn("Distance"):SetFixedWidth(60)

		for zone in pairs(zones.ZoneEntities) do
			local line = listView:AddLine(zone:GetClass(),
				zones.GetShapeName(zone:GetShape()),
				zone:GetSaved() and "Yes" or "", "")

			line.Think = function()
				if not IsValid(zone) then
					listView:RemoveLine(line:GetID())

					checkButtons(true)

					return
				end

				local dist = zone:GetPos():Distance(EyePos())

				line:SetValue(4, math.Round(dist))
			end

			line.Zone = zone
		end

		listView.OnRowSelected = function(_, _, line)
			local zone = line.Zone

			self.SelectedZone = zone
			self.SelectedLine = line

			checkButtons()
		end
	end

	function SWEP:AddSettingsMenu(ui)
		ui:DockPadding(10, 10, 10, 10)

		local drawSelected = ui:Add("DCheckBoxLabel")

		drawSelected:DockMargin(0, 0, 0, 10)
		drawSelected:Dock(TOP)
		drawSelected:SetConVar("zones_only_draw_selected")
		drawSelected:SetText("Only draw zones when selected")
		drawSelected:SetDark(true)
	end

	function SWEP:AddTabs(ui)
		local sheet = ui:Add("DPropertySheet")

		sheet:Dock(FILL)

		local create = sheet:Add("DPanel")
		local manage = sheet:Add("DPanel")
		local settings = sheet:Add("DPanel")

		self:AddCreateMenu(create)
		self:AddManageMenu(manage)
		self:AddSettingsMenu(settings)

		sheet:AddSheet("Create", create, "icon16/package_add.png")
		sheet:AddSheet("Manage", manage, "icon16/table_edit.png")
		sheet:AddSheet("Settings", settings, "icon16/cog.png")
	end

	function SWEP:OpenBuildMenu()
		if not self:GetActive() then
			return
		end

		local ui = vgui.Create("DFrame")

		ui:SetSize(450, 200)
		ui:SetTitle("Zone Creation")
		ui:MakePopup()
		ui:Center()

		installThink(ui, self)

		local bottom = ui:Add("DPanel")

		bottom:DockMargin(0, 10, 0, 0)
		bottom:Dock(BOTTOM)
		bottom:SetPaintBackground(false)
		bottom:SetTall(20)

		local submit = bottom:Add("DButton")

		submit:Dock(RIGHT)
		submit:SetText("Submit")
		submit:SetDisabled(true)

		local props = ui:Add("DProperties")

		props:Dock(FILL)

		local row = props:CreateRow("Type", "Class")
		local types = {}

		for class, data in pairs(scripted_ents.GetList()) do
			if zones.IsZone(class) then
				types[data.t.PrintName or class] = class
			end
		end

		local classChoice
		local shapeData = {}

		local shape = self:GetShape()

		local function checkSubmit()
			if not classChoice then
				submit:SetDisabled(true)

				return
			end

			local validate = self:ValidateShapeData(classChoice, shapeData) == false
			local forbid = hook.Run("CanCreateZone", LocalPlayer(), classChoice, shape) == false

			submit:SetDisabled(forbid or validate)
		end

		local function updateFunction(key, val)
			shapeData[key] = val

			checkSubmit()
		end

		row:Setup("Combo", {
			values = types
		})

		row.DataChanged = function(_, val)
			classChoice = val

			checkSubmit()
		end

		if shape == zones.SHAPE_BOX then
			self:PopulateBoxMenu(props, updateFunction)
		elseif shape == zones.SHAPE_SPHERE then
			self:PopulateSphereMenu(props, updateFunction)
		elseif shape == zones.SHAPE_PLANE then
			self:PopulatePlaneMenu(props, updateFunction)
		end

		submit.DoClick = function()
			net.Start("zones.manager.create")
				net.WriteString(classChoice)
				net.WriteTable(shapeData)
			net.SendToServer()

			ui:Close()
		end
	end
else
	util.AddNetworkString("zones.manager.create")
	util.AddNetworkString("zones.manager.save")
	util.AddNetworkString("zones.manager.delete")

	-- Todo: Access checks

	net.Receive("zones.manager.create", function(_, ply)
		local class = net.ReadString()

		if not zones.IsZone(class) then
			return
		end

		local weapon = ply:GetActiveWeapon()

		if not IsValid(weapon) or weapon:GetClass() != "weapon_zone_manager" then
			return
		end

		local data = net.ReadTable()

		if not weapon:ValidateShapeData(class, data) then
			return
		end

		local shape = weapon:GetShape()

		if hook.Run("CanCreateZone", ply, class, shape) == false then
			return
		end

		local zone

		if shape == zones.SHAPE_BOX then
			zone = zones.CreateBox(class, data.Mins, data.Maxs)
		elseif shape == zones.SHAPE_SPHERE then
			zone = zones.CreateSphere(class, data.Pos, data.Radius)
		elseif shape == zones.SHAPE_PLANE then
			zone = zones.CreatePlane(class, data.Pos, data.Angle:Forward())
		end

		zone:SetCreator(ply)
		weapon:SetActive(false)
	end)

	net.Receive("zones.manager.save", function(_, ply)
		local zone = net.ReadEntity()
		local bool = net.ReadBool()

		if not zones.ZoneEntities[zone] or zone:GetSaved() == bool then
			return
		end

		if hook.Run("CanPersistZone", ply, zone) == false then
			return
		end

		-- At this point it's no longer the player's zone, it's the server's
		zone:SetCreator(NULL)

		zone:SetSaved(bool)
		zones.Save()
	end)

	net.Receive("zones.manager.delete", function(_, ply)
		local zone = net.ReadEntity()

		if not zones.ZoneEntities[zone] then
			return
		end

		if hook.Run("CanManageZone", ply, zone) == false then
			return
		end

		local saved = zone:GetSaved()

		SafeRemoveEntity(zone)

		if saved then
			zones.Save()
		end
	end)
end
