local mode = TOOL.Mode -- Class name of the tool. (name of the .lua file) 

TOOL.Category		= "Construction"
TOOL.Name			= "#Tool."..mode..".listname"
TOOL.ConfigName		= ""
TOOL.ClientConVar[ "max_health" ] = "100"
TOOL.ClientConVar[ "health" ] = "100"
TOOL.ClientConVar[ "unbreakable" ] = "0"
TOOL.ClientConVar[ "use_max" ] = "1"
TOOL.ClientConVar[ "tooltip_enabled" ] = "1"
TOOL.Information = {
	{ name = "left" },
	{ name = "right" },
	{ name = "reload" },
}


if CLIENT then
	local t = "tool."..mode.."."
	language.Add( t.."listname",	"Health Changer" )
	language.Add( t.."name",		"Health Changer" )
	language.Add( t.."desc",		"Change the health and max health of an object" )
	language.Add( t.."left",		"Apply health settings" )
	language.Add( t.."right",		"Copy health settings" )
	language.Add( t.."reload",		"Reset health parameters" )

end


-- creates the damage filter to be used for unbreakable entities
if SERVER then
	local function HC_InitalizeFilter()
		local filter = ents.Create( "filter_activator_name" )
		filter:SetKeyValue( "TargetName", "hc_damage_filter" )
		filter:SetKeyValue( "negated", "1" ) -- say no to damage
		filter:Spawn()
		filter:CallOnRemove( "hc_initalize_filter", function() timer.Simple( 0, HC_InitalizeFilter ) end )
	end

	hook.Add( "InitPostEntity", "hc_initalize_filter", HC_InitalizeFilter )
end


function HC_ApplyHealthSettings( ply, ent, data )

	local set = false

	-- could check to see if hc_origin (max) health == data.Health
	if data.Health and isfunction( ent.SetHealth ) then
		if not ent.hc_origHealth then ent.hc_origHealth = ent:Health() end
		if ent.hc_origHealth == data.Health then ent.hc_origHealth = nil end
		ent:SetHealth( data.Health )
		set = true
	end

	if data.MaxHealth and isfunction( ent.SetMaxHealth ) then
		if not ent.hc_origMaxHealth then ent.hc_origMaxHealth = ent:GetMaxHealth() end
		if ent.hc_origMaxHealth == data.MaxHealth then ent.hc_origMaxHealth = nil end
		ent:SetMaxHealth( data.MaxHealth )
		set = true
	end

	local unbreak = data.Unbreakable
	if unbreak ~= nil then
		ent:SetVar( "hc_unbreakable", unbreak or nil )
		ent:Fire( "SetDamageFilter", unbreak and "hc_damage_filter" or "" )
		set = true
	end

	if SERVER and set then duplicator.StoreEntityModifier( ent, "health_changer", data ) end

	return set

end



if SERVER then

	duplicator.RegisterEntityModifier( "health_changer", HC_ApplyHealthSettings )

end


function TOOL:LeftClick(trace)
	
	local ent = trace.Entity
	
	if ent:IsWorld() or not ent:IsValid() then return false end
		
	local data = {
		MaxHealth	= self:GetClientNumber( "max_health" ),
		Unbreakable = self:GetClientBool( "unbreakable" ),
	}
	data.Health = self:GetClientBool( "use_max" ) and data.MaxHealth or self:GetClientNumber( "health" )

	return HC_ApplyHealthSettings( self:GetOwner(), ent, data )

end


function TOOL:RightClick(trace)
	
	local ent = trace.Entity
	
	if ent:IsWorld() or not ent:IsValid() then return false end

	if isfunction( ent.Health ) then RunConsoleCommand( mode.."_health", ent:Health() ) end
	if isfunction( ent.GetMaxHealth ) then RunConsoleCommand( mode.."_max_health", ent:GetMaxHealth() ) end
	RunConsoleCommand( mode.."_unbreakable", ent:GetVar( "hc_unbreakable" ) and 1 or 0 )

	return true

end


function TOOL:Reload( trace )

	local ent = trace.Entity

	if ent:IsWorld() or not ent:IsValid() then return false end

	duplicator.ClearEntityModifier( ent, "health_changer" )

	return HC_ApplyHealthSettings( nil, ent, {
		Health		= ent.hc_origHealth,
		MaxHealth	= ent.hc_origMaxHealth,
		Unbreakable = false,
	}
	)

end


if SERVER then

	function TOOL:Think()
		local ent = self:GetOwner():GetEyeTrace().Entity

		local health = isfunction( ent.Health ) and ent:Health()
		local max_health = isfunction( ent.GetMaxHealth ) and ent:GetMaxHealth()
		if health then ent:SetNWFloat( "HC_Health", health ) end
		if max_health then ent:SetNWFloat( "HC_MaxHealth", max_health ) end
		ent:SetNWBool( "HC_Unbreakable", ent:GetVar( "hc_unbreakable" ) or false )

	end

end


if CLIENT then

	function TOOL:DrawHUD()

		if not self:GetClientBool("tooltip_enabled") then return end

		local ply = self:GetOwner()

		local ent = ply:GetEyeTrace().Entity

		if not IsValid( ent ) then return end

		local pos = ( ent:GetPos() + ent:OBBCenter() ):ToScreen()
		local x, y = pos.x, pos.y - 15
		
		local health = ent:GetNWFloat( "HC_Health" )
		local max_health = ent:GetNWFloat( "HC_MaxHealth" )
		local unbreakable = ent:GetNWBool( "HC_Unbreakable" )
		local prop = max_health ~= 0 and math.Clamp( health / max_health, 0, 1 ) or 1
		local text = ("Health: %s / %s ( %s%% )"):format( math.Round( health, 0 ) or "N/A", math.Round( max_health, 0 ) or "N/A", math.Round( 100*prop, 1 ) or "N/A" )
		if unbreakable then text = text..", Unbreakable" end

		local olcol = HSVToColor( 100*prop, 1, 0.5 )
		local bgcol = HSVToColor( 100*prop, 0.75, 0.9 )
		local font  = "GModWorldtip"
		local rad   = 8
		
		surface.SetFont( font )
		local tw, th = surface.GetTextSize( text )
		
		draw.RoundedBox( rad, x - tw/2 - 12, y - th/2 - 4, tw + 24, th + 8, olcol )
		draw.RoundedBox( rad, x - tw/2 - 10, y - th/2 - 2, tw + 20, th + 4, bgcol )
		draw.SimpleText( text, font, x, y, color_black, 1, 1 )
	end

end



local cvarlist = TOOL:BuildConVarList()

function TOOL.BuildCPanel( cPanel )

	cPanel:Help( "#tool."..mode..".desc" )

	cPanel:ToolPresets( mode, cvarlist )

	local maxHealth = 2147483520
	local lowHealth = 1

	local maxHealthSlider = cPanel:NumSlider( "Max Health", mode.."_max_health", 0, maxHealth, 0 )

	local healthSlider = cPanel:NumSlider( "Health", mode.."_health", 0, maxHealth, 0 )

	local FR_button = vgui.Create( "DButton" )
		FR_button:Dock( TOP )
		FR_button:SetText( "Make fragile" )	
		FR_button:SetImage( "icon32/hand_property.png" )
		function FR_button:DoClick()
			maxHealthSlider:SetValue( lowHealth )
			healthSlider:SetValue( lowHealth )
		end
		FR_button:SetToolTip( ("Set Health and Max Health to %s."):format( lowHealth ) )

	local NU_button = vgui.Create( "DButton" )
		NU_button:Dock( TOP )
		NU_button:SetText( "Make near-unbreakable" )	
		NU_button:SetImage( "icon32/tool.png" )
		function NU_button:DoClick()
			maxHealthSlider:SetValue( maxHealth )
			healthSlider:SetValue( maxHealth )
		end
		NU_button:DockMargin( 15, 0, 0, 0 )
		NU_button:SetToolTip( ("Set Health and Max Health to %s."):format( maxHealth ) )
	
	cPanel:AddItem( FR_button, NU_button )

	local STMH_checkBox = cPanel:CheckBox( "Set Health to Max Health", mode.."_use_max" )
		function STMH_checkBox:OnChange( checked )
			healthSlider:SetEnabled( not checked )
			if checked then healthSlider:SetValue( maxHealthSlider:GetValue() ) end
		end

	function maxHealthSlider:OnValueChanged( value )
		if STMH_checkBox:GetChecked() then
			healthSlider:SetValue( value )
		end
	end

	local ubCheckBox = cPanel:CheckBox( "Make fully unbreakable", mode.."_unbreakable" )
		ubCheckBox:SetToolTip( "Make the entity unable to take damage." )

	local tooltipCheckBox = cPanel:CheckBox( "Enable Tooltips", mode.."_tooltip_enabled" )
		tooltipCheckBox:SetToolTip( "Show a health tooltip when pointing something with the tool." )


end

