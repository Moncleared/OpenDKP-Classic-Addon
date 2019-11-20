OpenDKP_Snapshots = {};
SLASH_OPENDKP1 = '/opendkp';

function SlashCmdList.OPENDKP(msg, editbox)
	msg = string.lower(msg);
	if msg == "" then
		OpenDKP_Print("OpenDKP Usage");
		OpenDKP_Print("|cFF80FF80show|r - |cFFFF8080Displays the OpenDKP window|r");
	elseif msg == "show" then
		ShowUIPanel(OpenDKP_Attendance);
	else
		OpenDKP_Print("|cFF80FF80" .. msg .. "|r |cFFFF8080is not a valid request. Type /opendkp to check addon usage|r", true);
	end
end

function OpenDKP_Print(str, err)
	if not str then return; end;
	if err == nil then
		DEFAULT_CHAT_FRAME:AddMessage("|c006969FFOpenDKP: " .. tostring(str) .. "|r");
	else
		DEFAULT_CHAT_FRAME:AddMessage("|c006969FFOpenDKP:|r " .. "|c00FF0000Error|r|c006969FF - " .. tostring(str) .. "|r");
	end
end

function OpenDKP_RecordAttendance()
	if not UnitInRaid("player") and not OpenDKP_debugMode then
		OpenDKP_Print("You are not in a raid group", true);
		return;
    end
	OpenDKP_Snapshots[#OpenDKP_Snapshots+1] = {
		[1] = time()
	};    
    for i = 1, GetNumGroupMembers(), 1 do
		OpenDKP_Snapshots[#OpenDKP_Snapshots][i+1] = {
			[1] = GetRaidRosterInfo(i)
		};
	end
	OpenDKP_Print("Snapshot recorded");
end

function OpenDKP_UIDropDownMenu_Initialize(frame, initFunction, displayMode, level, menuList, search)
	if ( not frame ) then
		frame = self;
	end
	frame.menuList = menuList;

	if ( frame:GetName() ~= UIDROPDOWNMENU_OPEN_MENU ) then
		UIDROPDOWNMENU_MENU_LEVEL = 1;
	end

	-- Set the frame that's being intialized
	UIDROPDOWNMENU_INIT_MENU = frame:GetName();

	-- Hide all the buttons
	local button, dropDownList;
	for i = 1, UIDROPDOWNMENU_MAXLEVELS, 1 do
		dropDownList = _G["DropDownList"..i];
		if ( i >= UIDROPDOWNMENU_MENU_LEVEL or frame:GetName() ~= UIDROPDOWNMENU_OPEN_MENU ) then
			dropDownList.numButtons = 0;
			dropDownList.maxWidth = 0;
			for j=1, UIDROPDOWNMENU_MAXBUTTONS, 1 do
				button = _G["DropDownList"..i.."Button"..j];
				button:Hide();
			end
			dropDownList:Hide();
		end
	end
	frame:SetHeight(UIDROPDOWNMENU_BUTTON_HEIGHT * 2);
	
	-- Set the initialize function and call it.  The initFunction populates the dropdown list.
	if ( initFunction ) then
		frame.initialize = initFunction;
		initFunction(level, frame.menuList, search);
	end

	-- Change appearance based on the displayMode
	if ( displayMode == "MENU" ) then
		_G[frame:GetName().."Left"]:Hide();
		_G[frame:GetName().."Middle"]:Hide();
		_G[frame:GetName().."Right"]:Hide();
		_G[frame:GetName().."ButtonNormalTexture"]:SetTexture("");
		_G[frame:GetName().."ButtonDisabledTexture"]:SetTexture("");
		_G[frame:GetName().."ButtonPushedTexture"]:SetTexture("");
		_G[frame:GetName().."ButtonHighlightTexture"]:SetTexture("");
		_G[frame:GetName().."Button"]:ClearAllPoints();
		_G[frame:GetName().."Button"]:SetPoint("LEFT", frame:GetName().."Text", "LEFT", -9, 0);
		_G[frame:GetName().."Button"]:SetPoint("RIGHT", frame:GetName().."Text", "RIGHT", 6, 0);
		frame.displayMode = "MENU";
	end

end

function OpenDKP_attendanceDropdown(frame, level, menuList)
	local info = {text = "Select Raid Tick", value = 0, func = OpenDKP_attendanceChange};
	local entry = UIDropDownMenu_AddButton(info);
	for i = 1, OpenDKP_ntgetn(OpenDKP_Snapshots) do
		local info = {text = date("%d/%m/%Y %H:%M", OpenDKP_Snapshots[i][1]), value = i, func = OpenDKP_attendanceChange};
		local entry = UIDropDownMenu_AddButton(info);
	end
end

function OpenDKP_attendanceChange(self, arg1, arg2, checked)
	if (not checked) then
		UIDropDownMenu_SetSelectedName(OpenDKP_attendance_dropdown, self:GetText());
		UIDropDownMenu_SetSelectedValue(OpenDKP_attendance_dropdown, self.value);		
		if ( self.value == 0 ) then
			_G["attendance_editbox"]:SetText("No raid tick selected, use the drop down in bottom left to select a raid tick.\n");
			return;
		end
		local attendance = "";
		for i = 2, #OpenDKP_Snapshots[self.value] do
		   attendance = attendance .. tostring(OpenDKP_Snapshots[self.value][i][1]) .. "\n"; 
		end
		attendance = string.sub(attendance, 0, -2);
		_G["attendance_editbox"]:SetText(attendance);		
	end
end

function OpenDKP_ntgetn(tbl)
	if tbl == nil then
		return 0;
	end
	local n = 0;
	for _,_ in pairs(tbl) do
		n = n + 1;
	end
	return n;
end

function trim1(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
 end

function tprint (tbl, indent)
	if not indent then indent = 0 end
	for k, v in pairs(tbl) do
	  formatting = string.rep("  ", indent) .. k .. ": "
	  if type(v) == "table" then
		print(formatting)
		tprint(v, indent+1)
	  elseif type(v) == 'boolean' then
		print(formatting .. tostring(v))      
	  else
		print(formatting .. v)
	  end
	end
  end

function OpenDKP_deleteAttendance()
	local index = UIDropDownMenu_GetSelectedValue(OpenDKP_attendance_dropdown);
	if not index or index == 0 then
		OpenDKP_Print("Select a snapshot and try again", true);
		return;
	end
	OpenDKP_Print("Deleted snapshot: " .. date("%d/%m/%Y %H:%M", OpenDKP_Snapshots[index][1]));
	local size = OpenDKP_ntgetn(OpenDKP_Snapshots);
	for i = index, size-1 do
		OpenDKP_Snapshots[index] = OpenDKP_Snapshots[index+1];
	end
	OpenDKP_Snapshots[size] = nil;
	UIDropDownMenu_SetSelectedValue(OpenDKP_attendance_dropdown, 0);
end