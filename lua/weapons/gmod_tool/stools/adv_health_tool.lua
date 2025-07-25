local mode = TOOL.Mode -- Class name of the tool. (name of the .lua file) 

TOOL.Category		= "Construction"
TOOL.Name			= "#Tool."..mode..".listname"
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

	local t = "tool."..mode.."."
	language.Add( t.."listname",	"Advanced Health" )
	language.Add( t.."name",		"Advanced Health Tool" )
	language.Add( t.."desc",		"Change the health-related properties of entities." )
	language.Add( t.."0",			"Press "..input.LookupBinding( "+speed" ).." to target all constrained entities" )
	language.Add( t.."left",		"Apply settings" )
	language.Add( t.."right",		"Copy settings" )
	language.Add( t.."reload",		"Reset entity settings" )


	local k1, k2 = "name", "flag"
	dmgEnums = {
		--{ [k1] = "DMG_GENERIC", [k2] = DMG_GENERIC }, -- sadly its value is 0
		{ [k1] = "DMG_CRUSH", [k2] = DMG_CRUSH },
		{ [k1] = "DMG_BULLET", [k2] = DMG_BULLET },
		{ [k1] = "DMG_SLASH", [k2] = DMG_SLASH },
		{ [k1] = "DMG_BURN", [k2] = DMG_BURN },
		{ [k1] = "DMG_VEHICLE", [k2] = DMG_VEHICLE },
		{ [k1] = "DMG_FALL", [k2] = DMG_FALL },
		{ [k1] = "DMG_BLAST", [k2] = DMG_BLAST },
		{ [k1] = "DMG_CLUB", [k2] = DMG_CLUB },
		{ [k1] = "DMG_SHOCK", [k2] = DMG_SHOCK },
		{ [k1] = "DMG_SONIC", [k2] = DMG_SONIC },
		{ [k1] = "DMG_ENERGYBEAM", [k2] = DMG_ENERGYBEAM },
		{ [k1] = "DMG_PREVENT_PHYSICS_FORCE", [k2] = DMG_PREVENT_PHYSICS_FORCE },
		{ [k1] = "DMG_NEVERGIB", [k2] = DMG_NEVERGIB },
		{ [k1] = "DMG_ALWAYSGIB", [k2] = DMG_ALWAYSGIB },
		{ [k1] = "DMG_DROWN", [k2] = DMG_DROWN },
		{ [k1] = "DMG_PARALYZE", [k2] = DMG_PARALYZE },
		{ [k1] = "DMG_NERVEGAS", [k2] = DMG_NERVEGAS },
		{ [k1] = "DMG_POISON", [k2] = DMG_POISON },
		{ [k1] = "DMG_RADIATION", [k2] = DMG_RADIATION },
		{ [k1] = "DMG_DROWNRECOVER", [k2] = DMG_DROWNRECOVER },
		{ [k1] = "DMG_ACID", [k2] = DMG_ACID },
		{ [k1] = "DMG_SLOWBURN", [k2] = DMG_SLOWBURN },
		{ [k1] = "DMG_REMOVENORAGDOLL", [k2] = DMG_REMOVENORAGDOLL },
		{ [k1] = "DMG_PHYSGUN", [k2] = DMG_PHYSGUN },
		{ [k1] = "DMG_PLASMA", [k2] = DMG_PLASMA },
		{ [k1] = "DMG_AIRBOAT", [k2] = DMG_AIRBOAT },
		{ [k1] = "DMG_DISSOLVE", [k2] = DMG_DISSOLVE },
		{ [k1] = "DMG_BLAST_SURFACE", [k2] = DMG_BLAST_SURFACE },
		{ [k1] = "DMG_DIRECT", [k2] = DMG_DIRECT },
		{ [k1] = "DMG_BUCKSHOT", [k2] = DMG_BUCKSHOT },
		{ [k1] = "DMG_SNIPER", [k2] = DMG_SNIPER },
		{ [k1] = "DMG_MISSILEDEFENSE", [k2] = DMG_MISSILEDEFENSE },
	}

end


local function AHT_CopySettings( ent )
	return {
		health		= isfunction( ent.Health ) and ent:Health(),
		max_health	= isfunction( ent.GetMaxHealth ) and ent:GetMaxHealth(),
		unbreakable = ent:GetVar( "aht_unbreakable" ) or false,
		immune_mask = ent:GetVar( "aht_immune_mask" ) or 0,
	}
end


local function AHT_ApplyNRemember( ent, newval, setter, getter, orig_key )
	if not ( newval and isfunction( setter ) ) then return false end
	local o = ent[ orig_key ] or getter( ent )
	ent[ orig_key ] = o ~= newval and o or nil
	setter( ent, newval )
	return true
end

function AHT_ApplySettings( ply, ent, data, do_undo, undo_text )

	local k1, k2 = "unbreakable", "immune_mask"

	local legacyUnbreak = ent.EntityMods and ent.EntityMods.Unbreakable
	if legacyUnbreak then
		if data.getLegacy then 
			data[k1] = data[k1] or legacyUnbreak and legacyUnbreak.On
		else
			if legacyUnbreak then ent.EntityMods.Unbreakable.On = data[k1] end
		end
		data.getLegacy = nil
	end

	local oldData
	if SERVER and do_undo ~= false then
		oldData = AHT_CopySettings( ent )
		do_undo = false
		for k, v in pairs( data ) do
			if v ~= oldData[k] then do_undo = true end
		end
	end

	AHT_ApplyNRemember( ent, data.health, ent.SetHealth, ent.Health, "aht_orig_health" )
	AHT_ApplyNRemember( ent, data.max_health, ent.SetMaxHealth, ent.GetMaxHealth, "aht_orig_max_health" )
	ent["aht_"..k1] = data[k1] or nil
	ent["aht_"..k2] = data[k2] ~= 0 and data[k2] or nil
	ent.aht_damage_filtered = data[k1] or data[k2] ~= 0 or nil
	if data.health > 0 and data.max_health > 0 then 
		ent:SetSaveValue("m_takedamage", 1) 
	else
		ent:SetSaveValue("m_takedamage", 0) 
	end

	if SERVER then
		data.getLegacy = true -- for (one-way) compability with the other addon
		duplicator.StoreEntityModifier( ent, "adv_health_tool", data )
		if do_undo then
			undo_text = undo_text or "Set health settings"
			undo.Create( undo_text.." ("..( ent:GetModel() or "?" )..")" )
				undo.AddFunction( function( undo )
					if not IsValid( ent ) then return false end
					AHT_ApplySettings( ply, ent, oldData, false )
				end )
				undo.SetPlayer( ply )
			undo.Finish()
		end
	end
end


if SERVER then

	duplicator.RegisterEntityModifier( "adv_health_tool", AHT_ApplySettings )

	local vector_zero = Vector(0,0,0)
	
	local nodmgforce = CreateConVar("sv_adv_health_tool_nodmgforce", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED, "Prevent damage force", 0, 1)
	hook.Add( "EntityTakeDamage", "aht_damage_filtering", function( target, dmginfo )
		if not target.aht_damage_filtered then return end
		if target.aht_unbreakable or ( target.aht_immune_mask and dmginfo:IsDamageType( target.aht_immune_mask ) ) then
			dmginfo:SetDamage( 0 )
			if nodmgforce:GetBool() then
				dmginfo:SetDamageType(DMG_PREVENT_PHYSICS_FORCE)
				dmginfo:SetDamageForce(vector_zero)
			end
		end
	end )

	function TOOL:Think()

		if not self:GetClientBool( "tooltip_enabled" ) then return end

		local ent = self:GetOwner():GetEyeTrace().Entity
		if not IsValid( ent ) then return end 

		for k, v in pairs( AHT_CopySettings( ent ) ) do
			local funcKey = isbool( v ) and "SetNW2Bool" or "SetNW2Int"
			ent[ funcKey ]( ent, "aht_"..k, v )
		end

	end
	
else
	CreateConVar("sv_adv_health_tool_nodmgforce", 1, FCVAR_REPLICATED, "Prevent damage force", 0, 1)
end


function TOOL:LeftClick( trace )
	
	local ent = trace.Entity
	if not ent or not ent:IsValid() or ent:IsWorld() or ent:IsPlayer() then return false end
	local ply = self:GetOwner()
	
	local data = {
		max_health	= self:GetClientNumber( "max_health" ),
		immune_mask	= self:GetClientNumber( "immune_mask" ),
		unbreakable = self:GetClientBool( "unbreakable" ),
	}
	data.health = self:GetClientBool( "use_max" ) and data.max_health or self:GetClientNumber( "health" )

	local multi = self:GetOwner():KeyDown( IN_SPEED )
	local getter = multi and constraint.GetAllConstrainedEntities
	local targets = getter and getter( ent ) or { [ ent ] = ent }
	local do_undo = #targets <= 1
	for target in pairs( targets ) do
		AHT_ApplySettings( self:GetOwner(), target, data, do_undo )
	end

	return true

end


function TOOL:RightClick( trace )
	
	local ent = trace.Entity
	if ent:IsWorld() or not ent:IsValid() then return false end

	for k, v in pairs( AHT_CopySettings( ent ) ) do
		if isbool( v ) then v = v and 1 or 0 end
		RunConsoleCommand( mode.."_"..k, v )
	end
	return true
end


function TOOL:Reload( trace )

	local ent = trace.Entity

	if ent:IsWorld() or not ent:IsValid() then return false end

	if SERVER then duplicator.ClearEntityModifier( ent, "adv_health_tool" ) end

	local multi = self:GetOwner():KeyDown( IN_SPEED )
	local getter = multi and constraint.GetAllConstrainedEntities
	local targets = getter and getter( ent ) or { [ ent ] = ent }
	local do_undo = #targets <= 1
	
	local data = {
		unbreakable = false,
		immune_mask = 0,
	}

	for target in pairs( targets ) do
		data.health = target.aht_orig_health
		data.max_health = target.aht_orig_max_health
		AHT_ApplySettings( self:GetOwner(), target, data, do_undo, "Reset health settings" )
	end

	return true

end


if CLIENT then

	local color_gold = Color( 240, 150, 40 )

	function TOOL:DrawHUD()

		if not self:GetClientBool("tooltip_enabled") then return end

		local ply = self:GetOwner()

		local ent = ply:GetEyeTrace().Entity

		if not IsValid( ent ) then return end

		local vecmin, vecmax = ent:WorldSpaceAABB()
		local pos = ent:WorldSpaceCenter()
		pos.z = vecmax.z
		pos = pos:ToScreen()
		local x, y = pos.x, pos.y
		
		local health	 = ent:GetNW2Int( "aht_health" )
		local max_health = ent:GetNW2Int( "aht_max_health" )
		local unbreakable	 = ent:GetNW2Bool( "aht_unbreakable" )
		local immune_mask	 = ent:GetNW2Int( "aht_immune_mask" ) or 0
		local prop = health / max_health or 1

		local text1 = ( "Health: %s / %s" ):format( health or "N/A", max_health or "N/A" )
		local text2 = max_health == 0 and "" or ( " (%s%%)" ):format( math.Round( prop*100, 2 ) )
		local text3 = unbreakable and "Unbreakable" or ""
		local text3 = ( text3 ~= "" and immune_mask ~= 0 ) and text3..", " or text3
		if immune_mask ~= 0 then text3 = text3.."DMG Mask: "..immune_mask end

		prop = math.Clamp( prop, 0, 3 )
		local txcol	= HSVToColor( 100*prop, 0.65, 0.9 )
		local bgcol = HSVToColor( 100*prop, 1, 0.1 )
			bgcol.a = 220
		local rad   = 8

		local font = "GModWorldtip"
		surface.SetFont( font )
		local tw1, th1 = surface.GetTextSize( text1 )
		local tw2, th2 = surface.GetTextSize( text2 )
		local tw3, th3 = surface.GetTextSize( text3 )
		if tw3 == 0 then th3 = 0 end
		local tw, th = math.max( tw1 + tw2, tw3 ), th1 + th3

		y = y - th

		draw.RoundedBox( rad, x - tw/2 - 10, y - th1/2 - 2, tw + 20, th + 4, bgcol )
		draw.SimpleText( text1, font, x - tw2/2, y, color_white, 1, 1 )
		draw.SimpleText( text2, font, x + tw1/2, y, txcol, 1, 1 )
		if text3 ~= "" then draw.SimpleText( text3, font, x, y + th1, color_gold, 1, 1 ) end
	end

end



local cvarlist = TOOL:BuildConVarList()

function TOOL.BuildCPanel( cPanel )

	local color_gray	= Color( 240, 240, 240 )
	local color_red		= Color( 220, 40, 20 )
	local color_orange	= Color( 220, 120, 20 )
	local color_green	= Color( 35, 155, 100 )

	local function paint( panel, w, h, hcol, bgcol )
		local topHeight = panel:GetHeaderHeight()
		local c = not panel:GetExpanded()
		draw.RoundedBoxEx( 4, 0, 0, w, topHeight, hcol, true, true, c, c )
		draw.RoundedBoxEx( 8, 0, topHeight, w, h - topHeight + 5, bgcol, false, false, true, true )
	end

	cPanel:Help( "#tool."..mode..".desc" )

	cPanel:ToolPresets( mode, cvarlist )

	local limitHealth	= 2^31 - 1 --2147483520
	local lowHealth		= 1

	local healthForm = vgui.Create( "DForm", cPanel )
		cPanel:AddItem( healthForm )
		healthForm:SetExpanded( true )
		healthForm:SetLabel( "Health and Max Health" )
		healthForm:SetPaintBackground( false )
		healthForm:DockPadding( 0, 0, 0, 5 )
		function healthForm:Paint( w, h )
			paint( self, w, h, color_red, color_gray )
		end

		local maxHealthSlider = healthForm:NumSlider( "Max Health", mode.."_max_health", 0, 5000, 0 )
			maxHealthSlider:SetToolTip("Sets the entity's maximum health. NPCs can heal up to this amount.")
			healthForm:ControlHelp( "I recommend using a value greather than that of Base Health to prevent weird behavior for NPCs." )

		local healthSlider = healthForm:NumSlider( "Base Health", mode.."_health", 0, maxHealthSlider:GetMax(), 0 )
			healthSlider:SetToolTip("Sets the current and duped health of the entity.")

		healthForm:ControlHelp( ("You can set these higher than %s if you want."):format( maxHealthSlider:GetMax() ) )

		local FR_button = vgui.Create( "DButton" )
			FR_button:Dock( TOP )
			FR_button:SetText( "Make fragile" )	
			FR_button:SetImage( "icon32/hand_property.png" )
			function FR_button:DoClick()
				maxHealthSlider.Scratch:SetValue( lowHealth )
				healthSlider.Scratch:SetValue( lowHealth )
			end
			FR_button:SetToolTip( ("Set Base Health and Max Health to %s."):format( lowHealth ) )

		local NU_button = vgui.Create( "DButton" )
			NU_button:Dock( TOP )
			NU_button:SetText( "Make near-unbreakable" )	
			NU_button:SetImage( "icon32/tool.png" )
			function NU_button:DoClick()
				maxHealthSlider.Scratch:SetValue( limitHealth )
				healthSlider.Scratch:SetValue( limitHealth )
			end
			NU_button:DockMargin( 15, 0, 0, 0 )
			NU_button:SetToolTip( ("Set Base Health and Max Health to %s."):format( limitHealth ) )
		
		healthForm:AddItem( FR_button, NU_button )

		local STMH_checkBox = healthForm:CheckBox( "Heal", mode.."_use_max" )
			STMH_checkBox:SetToolTip( ( "Set Base Health to the same value as Max Health" ) )
			function STMH_checkBox:OnChange( checked )
				healthSlider:SetEnabled( not checked )
				if checked then healthSlider.Scratch:SetValue( maxHealthSlider.Scratch:GetFloatValue() ) end
			end

		function maxHealthSlider:OnValueChanged( value )
			if STMH_checkBox:GetChecked() then
				healthSlider.Scratch:SetValue( maxHealthSlider.Scratch:GetFloatValue() )
			end
		end

	local filterForm = vgui.Create( "DForm", cPanel )
		cPanel:AddItem( filterForm )
		filterForm:SetExpanded( true )
		filterForm:SetLabel( "Damage filtering" )
		filterForm:SetPaintBackground( false )
		filterForm:DockPadding( 0, 0, 0, 5 )
		function filterForm:Paint( w, h )
			paint( self, w, h, color_orange, color_gray )
		end

		local ubCheckBox = filterForm:CheckBox( "Unbreakable", mode.."_unbreakable" )
			ubCheckBox:SetToolTip( "Make the entity unable to take damage of any kind." )

		filterForm:Help("Below you can choose and combine 32 types of damage to ignore.")
		filterForm:ControlHelp("You can get a better understanding of damage types by checking the wiki link in the 'Help' section at the bottom.")


		local cVarName = mode.."_immune_mask"

		local filterComboBox = filterForm:ComboBox( "Easy Presets", cVarName )
			filterComboBox:Dock( TOP )
			filterComboBox:SetSortItems( false )
			filterComboBox:AddChoice( "None", 0 )
			filterComboBox:AddChoice( "Fireproof", bit.bor( DMG_BURN, DMG_SLOWBURN ) )
			filterComboBox:AddChoice( "Bulletproof", bit.bor( DMG_BULLET, DMG_BUCKSHOT, DMG_SNIPER, DMG_AIRBOAT ) )
			filterComboBox:AddChoice( "Blast-Resistant", bit.bor( DMG_BLAST, DMG_BLAST_SURFACE ) )
			filterComboBox:AddChoice( "Anti-Combine Ball", DMG_DISSOLVE )
			filterComboBox:AddChoice( "Everything", -1 )


		filterForm:TextEntry( "Damage Mask", cVarName )

		local cVar = GetConVar( cVarName )
		local checkboxes = {}
		local syncing = false

		-- Get current ConVar value (default to 0 if invalid)
		local currentMask = tonumber( cVar:GetString() ) or 0
		
		for _, dmgType in ipairs( dmgEnums ) do
			-- Create checkbox with damage type name
			local checkbox = vgui.Create( "DCheckBoxLabel", filterForm )
			checkbox:SetDark( true )
			checkbox:SetText( dmgType.name )
			checkbox:SetValue( bit.band( currentMask, dmgType.flag ) ~= 0 )
			
			-- Update ConVar on change using bitwise operations
			function checkbox:OnChange( checked )

				if syncing then return end

				local newMask = tonumber( cVar:GetString() ) or 0 -- do NOT use cVar:GetInt() as it returns a rounded value for large ints! (e.g 33 554 431 -> 33 554 432)
				
				if checked then
					newMask = bit.bor( newMask, dmgType.flag )
				else
					newMask = bit.band( newMask, bit.bnot( dmgType.flag ) )
				end
				
				RunConsoleCommand( cVarName, newMask )

			end

			table.insert( checkboxes, { checkbox = checkbox, flag = dmgType.flag } )
			filterForm:AddItem( checkbox )
		end

		-- Cvar callback --

		cvars.AddChangeCallback( cVarName, function( name, oldValue, newValue )

			syncing = true

			local mask = tonumber( newValue ) or 0
			for _, data in ipairs( checkboxes ) do
				local checked = bit.band( mask, data.flag ) ~= 0
				if data.checkbox:GetChecked() ~= checked then data.checkbox:SetValue( checked ) end
			end

			syncing = false

		end, "aht_menu_mask_sync" )

		function filterForm:OnRemove()
			cvars.RemoveChangeCallback( cVarName, "aht_menu_mask_sync" )
		end


	local helpForm = vgui.Create( "DForm", cPanel )
		cPanel:AddItem( helpForm )
		helpForm:SetExpanded( true )
		helpForm:SetLabel( "Help" )
		helpForm:SetPaintBackground( false )
		helpForm:DockPadding( 0, 0, 0, 5 )
		function helpForm:Paint( w, h )
			paint( self, w, h, color_green, color_gray )
		end

		local tooltipCheckBox = helpForm:CheckBox( "Enable Tooltips", mode.."_tooltip_enabled" )
			tooltipCheckBox:SetToolTip( "Show a health tooltip when looking at something with this tool." )

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

