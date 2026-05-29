local mode = TOOL.Mode -- Class name of the tool. (name of the .lua file)

TOOL.Category		= "Construction"
TOOL.Name			= "#Tool." .. mode .. ".listname"
TOOL.ConfigName		= ""
TOOL.ClientConVar[ "max_health" ] = "100"
TOOL.ClientConVar[ "health" ] = "100"
TOOL.ClientConVar[ "use_max" ] = "0"
TOOL.ClientConVar[ "unbreakable" ] = "0"
TOOL.ClientConVar[ "immune_mask" ] = "0"
TOOL.ClientConVar[ "tooltip_enabled" ] = "1"
TOOL.Information = {
	{ name = "info" },
	{ name = "left" },
	{ name = "right" },
	{ name = "reload" },
}

if CLIENT then
	local t = "tool." .. mode .. "."
	language.Add( t .. "listname",	"Advanced Health" )
	language.Add( t .. "name",		"Advanced Health Tool" )
	language.Add( t .. "desc",		"Change the health-related properties of entities." )
	language.Add( t .. "0",			"Press " .. (input.LookupBinding( "+speed" ) or "sprint key" ) .. " to target all constrained entities (can't undo!)" )
	language.Add( t .. "left",		"Apply settings" )
	language.Add( t .. "right",		"Copy settings" )
	language.Add( t .. "reload",		"Reset settings" )

	dmgEnums	= {}
	local infoNames	= { "name", "flag", "icon", "iconColorOverride" }
	local tempDmgEnums = {
		--{ "DMG_GENERIC", DMG_GENERIC }, -- useless (value is 0)
		{ "DMG_CRUSH",					DMG_CRUSH,					"icon16/anchor.png" },
		{ "DMG_BULLET",					DMG_BULLET,					"icon16/gun.png" },
		{ "DMG_SLASH",					DMG_SLASH,					"icon16/cut_red.png" },
		{ "DMG_BURN",					DMG_BURN,					"icon16/fire.png" },
		{ "DMG_VEHICLE",				DMG_VEHICLE,				"icon16/car.png" },
		{ "DMG_FALL",					DMG_FALL,					"icon16/arrow_down.png" },
		{ "DMG_BLAST",					DMG_BLAST,					"icon16/bomb.png" },
		{ "DMG_CLUB",					DMG_CLUB,					"icon16/bullet_wrench.png" },
		{ "DMG_SHOCK",					DMG_SHOCK,					"icon16/lightning.png" },
		{ "DMG_SONIC",					DMG_SONIC,					"icon16/sound.png" },
		{ "DMG_ENERGYBEAM",				DMG_ENERGYBEAM,				"icon16/wand.png" },
		{ "DMG_PREVENT_PHYSICS_FORCE",	DMG_PREVENT_PHYSICS_FORCE,	"icon16/brick_link.png" },
		{ "DMG_NEVERGIB",				DMG_NEVERGIB,				},
		{ "DMG_ALWAYSGIB",				DMG_ALWAYSGIB,				},
		{ "DMG_DROWN",					DMG_DROWN,					"icon16/drink.png" },
		{ "DMG_PARALYZE",				DMG_PARALYZE,				"icon16/bug.png", color_black },
		{ "DMG_NERVEGAS",				DMG_NERVEGAS,				"icon16/weather_clouds.png", Color(255, 200, 0) },
		{ "DMG_POISON",					DMG_POISON,					"icon16/bug.png", color_black },
		{ "DMG_RADIATION",				DMG_RADIATION,				"icon16/feed_error.png" },
		{ "DMG_DROWNRECOVER",			DMG_DROWNRECOVER,			"icon16/heart_add.png" },
		{ "DMG_ACID",					DMG_ACID,					"icon16/weather_rain.png", Color(0, 255, 0) },
		{ "DMG_SLOWBURN",				DMG_SLOWBURN,				"icon16/fire.png" },
		{ "DMG_REMOVENORAGDOLL",		DMG_REMOVENORAGDOLL,		},
		{ "DMG_PHYSGUN",				DMG_PHYSGUN,				"icon16/brick_go.png" },
		{ "DMG_PLASMA",					DMG_PLASMA,					"icon16/scratchnumber.png" },
		{ "DMG_AIRBOAT",				DMG_AIRBOAT,				"icon16/gun.png" },
		{ "DMG_DISSOLVE",				DMG_DISSOLVE,				"icon16/status_online.png", color_black },
		{ "DMG_BLAST_SURFACE",			DMG_BLAST_SURFACE,			"icon16/bomb.png" },
		{ "DMG_DIRECT",					DMG_DIRECT,					"icon16/arrow_right.png" },
		{ "DMG_BUCKSHOT",				DMG_BUCKSHOT,				"icon16/gun.png" },
		{ "DMG_SNIPER",					DMG_SNIPER,					"icon16/find.png" },
		{ "DMG_MISSILEDEFENSE",			DMG_MISSILEDEFENSE,			"icon16/bomb.png" },
	}

	dmgEnums = {}
	for i, tempDmgEnum in ipairs(tempDmgEnums) do
		dmgEnum		= {}
		dmgEnums[i]	= dmgEnum
		for j, info in ipairs(tempDmgEnum) do
			dmgEnum[infoNames[j]] = info
		end
	end

	infoNames, tempDmgEnums = nil, nil

	net.Receive( "adv_health_tool_net", function( len, ply )

		for k, v in pairs( net.ReadTable() ) do
			if isbool( v ) then v = v and 1 or 0 end
			RunConsoleCommand( mode .. "_" .. k, v )
		end

	end )

end


function TOOL:LeftClick( trace )

	local ent = trace.Entity
	if not ent or not ent:IsValid() or ent:IsWorld() or ent:IsPlayer() then return false end

	if CLIENT then return true end

	local ply = self:GetOwner()

	print("a: ", self:GetClientInfo( "max_health" ) )

	local function getNumber( name )
		return ( self:GetClientInfo( name ) ~= "" and self:GetClientNumber( name ) ) or nil
	end

	local data = {
		max_health	= getNumber( "max_health"),
		immune_mask	= getNumber( "immune_mask"),
		unbreakable = self:GetClientBool( "unbreakable" ),
	}
	data.health = ( self:GetClientBool( "use_max" ) and data.max_health ) or getNumber( "health")

	local multi = ply:KeyDown( IN_SPEED )
	local getter = multi and constraint.GetAllConstrainedEntities
	local targets = getter and getter( ent ) or { [ ent ] = ent }
	local do_undo = table.Count( targets ) <= 1
	for target in pairs( targets ) do
		AHT_ApplySettings( ply, target, data, do_undo )
	end

	return true

end


function TOOL:RightClick( trace )

	local ent = trace.Entity
	if ent:IsWorld() or not ent:IsValid() then return false end

	if CLIENT then return true end

	local ply = self:GetOwner()
	if not IsValid( ply ) then return false end

	local settings = AHT_CopySettings( ent )
	if not ( istable( settings ) and next( settings ) ) then return false end

	net.Start( "adv_health_tool_net" )
		net.WriteTable( AHT_CopySettings( ent ) )
	net.Send( self:GetOwner() )

	return true

end


function TOOL:Reload( trace )

	local ent = trace.Entity

	if ent:IsWorld() or not ent:IsValid() then return false end

	if CLIENT then return true end

	local multi = self:GetOwner():KeyDown( IN_SPEED )
	local getter = multi and constraint.GetAllConstrainedEntities
	local targets = getter and getter( ent ) or { [ ent ] = ent }
	local do_undo = table.Count( targets ) <= 1

	local data = {
		unbreakable = false,
		immune_mask = 0,
	}

	for target in pairs( targets ) do
		data.health		= target.aht_orig_health
		data.max_health	= target.aht_orig_max_health
		AHT_ApplySettings( self:GetOwner(), target, data, do_undo, "Reset health settings" )
		duplicator.ClearEntityModifier( target, "adv_health_tool" )
	end

	return true

end


if SERVER then

	function TOOL:Think()

		if not self:GetClientBool( "tooltip_enabled" ) then return end

		local ent = self:GetOwner():GetEyeTrace().Entity
		if not IsValid( ent ) then return end
		if not AHT_CopySettings then return end

		for k, v in pairs( AHT_CopySettings( ent ) ) do
			local funcKey = isbool( v ) and "SetNW2Bool" or "SetNW2Int"
			ent[ funcKey ]( ent, "aht_" .. k, v )
		end

	end

else

	local color_gold = Color( 240, 150, 40 )

	function TOOL:DrawHUD()

		if not self:GetClientBool( "tooltip_enabled" ) then return end

		local ply = self:GetOwner()

		local ent = ply:GetEyeTrace().Entity

		if not IsValid( ent ) then return end

		local vecmax = select( 2, ent:WorldSpaceAABB() )
		local pos = ent:WorldSpaceCenter()
		pos.z = vecmax.z
		pos = pos:ToScreen()
		local x, y = pos.x, pos.y

		local health	 = ent:GetNW2Int( "aht_health" )
		local max_health = ent:GetNW2Int( "aht_max_health" )
		local unbreakable	 = ent:GetNW2Bool( "aht_unbreakable" )
		local immune_mask	 = ent:GetNW2Int( "aht_immune_mask" ) or 0
		local prop = health / max_health or 1

		local text1 = ( "Health: %s / %s" ):format( health or "N / A", max_health or "N / A" )
		local text2 = max_health == 0 and "" or ( " (%s%%)" ):format( math.Round( prop * 100, 2 ) )
		local text3 = unbreakable and "Unbreakable" or ""
		text3 = ( text3 ~= "" and immune_mask ~= 0 ) and text3 .. ", " or text3
		if immune_mask ~= 0 then text3 = text3 .. "DMG Mask: " .. immune_mask end

		prop = math.Clamp( prop, 0, 3 )
		local txcol	= HSVToColor( 100 * prop, 0.65, 0.9 )
		local bgcol = HSVToColor( 100 * prop, 1, 0.1 )
			bgcol.a = 220
		local rad   = 8

		local font = "GModWorldtip"
		surface.SetFont( font )
		local tw1, th1 = surface.GetTextSize( text1 )
		local tw2, th2 = surface.GetTextSize( text2 )
		local tw3, th3 = surface.GetTextSize( text3 )
		if tw3 == 0 then th3 = 0 end
		th1 = math.max( th1, th2 )
		local tw, th = math.max( tw1 + tw2, tw3 ), th1 + th3

		y = y - th

		draw.RoundedBox( rad, x - tw / 2 - 10, y - th1 / 2 - 2, tw + 20, th + 4, bgcol )
		draw.SimpleText( text1, font, x - tw2 / 2, y, color_white, 1, 1 )
		draw.SimpleText( text2, font, x + tw1 / 2, y, txcol, 1, 1 )
		if text3 ~= "" then draw.SimpleText( text3, font, x, y + th1, color_gold, 1, 1 ) end
	end

end



local cvarlist = TOOL:BuildConVarList()

function TOOL.BuildCPanel( cPanel )

	local color_gray	= Color( 240, 240, 240 )
	local col1	= HexToColor( "#329a55" )
	local col2	= HexToColor( "#3B5670" )
	local col3	= HexToColor( "#4A90E2" )

	local function paint( panel, w, h, hcol, bgcol )
		local hh = panel:GetHeaderHeight()
		local c = not panel:GetExpanded()
		draw.RoundedBoxEx( 4, 0, 0, w, hh, hcol, true, true, c, c )
		draw.RoundedBoxEx( 8, 0, hh, w, h - hh + 5, bgcol, false, false, true, true )
	end

	local function customDForm( label, expanded, hcol, bgcol )
		local dForm = vgui.Create( "DForm", cPanel )
			cPanel:AddItem( dForm )
			dForm:SetLabel( label or "" )
			dForm:SetPaintBackground( false )
			dForm:DockPadding( 0, 0, 0, 5 )
			dForm:SetExpanded( expanded )
			function dForm:Paint( w, h ) paint( self, w, h, hcol, bgcol ) end
		return dForm
	end

	cPanel:Help( "#tool." .. mode .. ".desc" )

	cPanel:ToolPresets( mode, cvarlist )

	local limitHealth	= 2147483520
	local lowHealth		= 1

	local healthForm = customDForm( "Health and Unbreakable", true, col1, color_gray )

		healthForm:Help( "Setting Base Health higher than Max Health might create weird behavior for some NPCs." )

		local maxHealthSlider = healthForm:NumSlider( "Max Health", mode .. "_max_health", 0, 5000, 0 )
			healthForm:ControlHelp( "Sets the entity's maximum health. NPCs can heal up to this amount." )

		local healthSlider = healthForm:NumSlider( "Base Health", mode .. "_health", 0, maxHealthSlider:GetMax(), 0 )
			healthForm:ControlHelp( "The actual health value. Duped entities will spawn with this." )

		--healthForm:ControlHelp( ( "You can set these higher than %s if you want." ):format( maxHealthSlider:GetMax() ) )


		local buttonHeight				= 20
		local buttonWidth				= 160

		local healthButtonsTileLayout	= vgui.Create( "DTileLayout" )
		healthForm:AddItem( healthButtonsTileLayout )
			healthButtonsTileLayout:SetBaseSize( buttonHeight )
			healthButtonsTileLayout:SetSpaceX( 15 )

			local FR_button = vgui.Create( "DButton" )
			healthButtonsTileLayout:Add( FR_button )
				FR_button:SetSize( buttonWidth, buttonHeight )
				FR_button:SetText( "Make fragile" )
				FR_button:SetImage( "icon16/heart_delete.png" )
				function FR_button:DoClick()
					maxHealthSlider.Scratch:SetValue( lowHealth )
					healthSlider.Scratch:SetValue( lowHealth )
				end
				FR_button:SetTooltip( ( "Set Base Health and Max Health to %s." ):format( lowHealth ) )

			local NU_button = vgui.Create( "DButton" )
			healthButtonsTileLayout:Add( NU_button )
				NU_button:SetSize( buttonWidth, buttonHeight )
				NU_button:SetText( "Make near-unbreakable" )
				NU_button:SetImage( "icon16/heart_add.png" )
				function NU_button:DoClick()
					maxHealthSlider.Scratch:SetValue( limitHealth )
					healthSlider.Scratch:SetValue( limitHealth )
				end
				NU_button:SetTooltip( ( "Set Base Health and Max Health to %s." ):format( limitHealth ) )

		local healthCheckboxesTileLayout	= vgui.Create( "DTileLayout" )
		healthForm:AddItem( healthCheckboxesTileLayout )

			healthCheckboxesTileLayout:SetSpaceX( 15 )
			local STMH_checkBox = vgui.Create( "DCheckBoxLabel" )
			healthCheckboxesTileLayout:Add( STMH_checkBox )
			healthCheckboxesTileLayout:SetBaseSize( STMH_checkBox:GetTall() )
				STMH_checkBox:SetText( "Auto max health" )
				STMH_checkBox:SetDark( true )
				STMH_checkBox:SetConVar( mode .. "_use_max" )

				STMH_checkBox:SetTooltip( "Set Base Health to the same value as Max Health" )
				function STMH_checkBox:OnChange( checked )
					healthSlider:SetEnabled( not checked )
					if checked then healthSlider.Scratch:SetValue( maxHealthSlider.Scratch:GetFloatValue() ) end
				end

			local ubCheckBox = vgui.Create( "DCheckBoxLabel" )
			healthCheckboxesTileLayout:Add( ubCheckBox )
				ubCheckBox:SetText( "Unbreakable" )
				ubCheckBox:SetDark( true )
				ubCheckBox:SetConVar( mode .. "_unbreakable" )
				ubCheckBox:SetTooltip( "Make the entity immune to all damage." )


		function maxHealthSlider:OnValueChanged( value )
			if STMH_checkBox:GetChecked() then
				healthSlider.Scratch:SetValue( maxHealthSlider.Scratch:GetFloatValue() )
			end
		end

	local filterForm = customDForm( "Damage filtering", false, col2, color_gray )

		filterForm:Help( "Below you can choose and combine up to 32 types of damage for the entity to ignore. This combination is called 'Damage Mask'." )
		filterForm:ControlHelp( "\nYou can get a better understanding of damage types by checking the wiki link in the 'Help' section at the bottom." )


		local cVarName = mode .. "_immune_mask"

		local filterComboBox = filterForm:ComboBox( "Easy Presets", cVarName )
			filterComboBox:Dock( TOP )
			filterComboBox:SetSortItems( false )
			filterComboBox:AddChoice( "None", 0 )
			filterComboBox:AddChoice( "Fireproof", bit.bor( DMG_BURN, DMG_SLOWBURN ) )
			filterComboBox:AddChoice( "Bulletproof", bit.bor( DMG_BULLET, DMG_BUCKSHOT, DMG_SNIPER, DMG_AIRBOAT ) )
			filterComboBox:AddChoice( "Blast-Resistant", bit.bor( DMG_BLAST, DMG_BLAST_SURFACE, DMG_MISSILEDEFENSE ) )
			filterComboBox:AddChoice( "Anti-Combine Ball", DMG_DISSOLVE )
			filterComboBox:AddChoice( "Everything", -1 )


		filterForm:TextEntry( "Damage Mask", cVarName )

		local checkboxes = {}
		local syncing = false

		-- Get current ConVar value (default to 0 if invalid)
		local currentMask = tonumber( GetConVar( cVarName ):GetString() ) or 0

		local color_selected	= Color( 0, 255, 0, 100 )
		local tileLayout				= vgui.Create( "DTileLayout", filterForm )
		tileLayout:Dock( FILL )
		filterForm:AddItem( tileLayout )

		local h

		for _, dmgType in ipairs( dmgEnums ) do

			local panel = vgui.Create( "DPanel", tileLayout )
			tileLayout:Add( panel )
			tileLayout:SetSpaceY( 2 )
			panel:SetBackgroundColor( color_selected )
			panel:SetWide( 200 )
			-- filterForm:AddItem(panel)

				-- Create checkbox with damage type name
				local checkbox = vgui.Create( "DCheckBoxLabel", panel )
				panel:Add( checkbox )
				table.insert( checkboxes, { checkbox = checkbox, flag = dmgType.flag } )
				checkbox.Label:SetCursor( "hand" )

				checkbox:SetDark( true )
				local text = string.TrimLeft( dmgType.name, "DMG_" )
				-- text = string.sub( text, 1, 1 ) .. string.lower( string.sub( text, 2 ) )
				checkbox:SetText( text )
				checkbox:SetValue( bit.band( currentMask, dmgType.flag ) ~= 0 )
				panel:SetPaintBackground( checkbox:GetChecked() )

				-- Update ConVar on change using bitwise operations
				function checkbox:OnChange( checked )

					self:GetParent():SetPaintBackground( checked )
					if syncing then return end

					local newMask = tonumber( GetConVar( cVarName ):GetString() ) or 0 -- do NOT use cVar:GetInt() as it returns a rounded value for large ints! (e.g 33 554 431 -> 33 554 432)

					if checked then
						newMask = bit.bor( newMask, dmgType.flag )

					else
						newMask = bit.band( newMask, bit.bnot( dmgType.flag ) )
					end

					RunConsoleCommand( cVarName, newMask )

				end

				h = h or math.max( 16, checkbox:GetTall() )
				panel:SetTall(h)
				checkbox:SetPos( 5 + h, ( h - checkbox:GetTall() ) / 2 )

				if dmgType.icon then
					local icon = vgui.Create( "DImage", panel )	-- Add image to Frame
					panel:Add(icon)
					icon:SetKeepAspect(true)	-- Size it to 150x150
					icon:SetSize( h, h )
					icon:SetImage( dmgType.icon )

					if dmgType.iconColorOverride then
						icon:SetImageColor( dmgType.iconColorOverride )
					end
				end
		end

		tileLayout:SetBaseSize( h )

		-- Cvar callback --

		cvars.AddChangeCallback( cVarName, function( name, oldValue, newValue )

			print("callbaack called")
			syncing = true

			local mask = tonumber( newValue ) or 0
			for _, data in ipairs( checkboxes ) do
				local checked = bit.band( mask, data.flag ) ~= 0
				if data.checkbox:GetChecked() ~= checked then data.checkbox:SetValue( checked ) end
			end

			syncing = false

		end, "aht_menu_mask_sync" )

		-- If you use this, the callback gets removed after any menu reload
		-- function filterForm:OnRemove()
		-- 	print("REMOVED")
		-- 	cvars.RemoveChangeCallback( cVarName, "aht_menu_mask_sync" )
		-- end


	local helpForm = customDForm( "Help", true, col3, color_gray )

		local tooltipCheckBox = helpForm:CheckBox( "Enable Tooltips", mode .. "_tooltip_enabled" )
			tooltipCheckBox:SetTooltip( "Show a health tooltip when looking at something with this tool." )

		local valveButton, fpButton = vgui.Create( "DButton", helpForm ), vgui.Create( "DButton", helpForm )
			valveButton:SetText( "Damage types (Valve Wiki)" )
			fpButton:SetText( "Damage types (Facepunch Wiki)" )

			valveButton:SetImage( "games/16/hl2.png" )
			fpButton:SetImage( "games/16/garrysmod.png" )

			function valveButton:DoClick() gui.OpenURL( "https://developer.valvesoftware.com/wiki/Damage_types" ) end
			function fpButton:DoClick() gui.OpenURL( "https://wiki.facepunch.com/gmod/Enums/DMG" ) end

			helpForm:AddItem( fpButton )
			helpForm:AddItem( valveButton )

end
