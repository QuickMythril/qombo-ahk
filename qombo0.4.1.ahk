#include %A_ScriptDir%
#include JSON.ahk

global VersionNumber := "0.4.1"

;Fixed in 0.4.1
; Fix for buttons disappearing when resizing
; Added Menu link to list of all Qortal settings
; https://github.com/QuickMythril/qombo/blob/main/defaultsettings.json

;Added in 0.4.0
; Settings Tab to manage qortal settings.json
; Added Name Lookup to Lookup Tab
; Added Start Core/UI to Menu
; Added persistent text to dislplay totals
; Removed Totals option (now always on-screen)
; Cleaned up window resizing

;Fixed in 0.3.1
; Changed to UTF-8 BOM encoding.
; Also changed to "Msxml2.XMLHTTP"
; from "WinHttp.WinHttpRequest.5.1"
; to fix Unicode character display.

;Added in 0.3.0:
; QORT Balance on Account Tab
; Lookup tab for Address or Group ID
; Show Totals option on Minter Tab

;Added in 0.2.0:
; Owned/Joined Groups on Account Tab
; Peers tab with connection info
; Dynamically resizable window elements

;Added in 0.1.0:
; Current minting account info
; All registered Names and Groups
; Member count for Groups
; All online minters info

;To do list:
; Settings Mgr
; Color Picker
; 
; LOG of minter count/growth.
; Get QORA/Founders:
; Fix when not minting.
; SEARCH
; LTC BTC balance/address
; Realtime updating
; LOTS More!

;Bug Reports:
; Status Bar text empties on resize

;qombo globals
global MintersListView := ""
global AccountListView := ""
global JoinedListView := ""
global GroupsListView := ""
global NamesListView := ""
global PeersListView := ""
global LookupListView := ""
global SettingsListView := ""

global oMyGUI := ""
global TrayIcon := systemroot "\system32\imageres.dll"
global SettingsFile := {}
global OutputStatus := "Welcome to qombo v" VersionNumber
;checkbox globals
global GetMinterNames := 0
global MinterTotals := ""

if FileExist(TrayIcon) {
	if (SubStr(A_OSVersion, 1, 2) == 10) {
		Menu, Tray, Icon, %TrayIcon%, 300
	}
	else if (A_OSVersion == "WIN_8") {
		Menu, Tray, Icon, %TrayIcon%, 284
	}
	else if (A_OSVersion == "WIN_7") {
		Menu, Tray, Icon, %TrayIcon%, 78
	}
	else if (A_OSVersion == "WIN_VISTA") {
		Menu, Tray, Icon, %TrayIcon%, 77
	} ; WIN_8.1, WIN_2003, WIN_XP, WIN_2000, WIN_NT4, WIN_95, WIN_98, WIN_ME
}
if (!oMyGUI) {
	oMyGUI := new MyGui()
}

;First run checks and setup
oMyGUI.Update()
;Check for resizing window
OnMessage(0x0005, "ResizeControls")
return
;END:	default run commands

;BEGIN: GUI Defs
class MyGui {
	Width := "550"
	Height := "450"
	
	__New()
	{
		Gui, MyWindow:New
		Gui, MyWindow:+Resize
		
		Menu, FileSubmenu, Add, &Reload qombo, Reload_Clicked
		Menu, FileSubmenu, Add, E&xit qombo, Exit_Clicked
		Menu, qomboMenu, Add, &File, :FileSubmenu
		Menu, QortalSubmenu, Add, Start Qortal &Core, QStart_Clicked
		Menu, QortalSubmenu, Add, Start Qortal &UI, UIStart_Clicked
		Menu, QortalSubmenu, Add, &Open Settings/DB Folder, OpenFolder_Clicked
		Menu, QortalSubmenu, Add, Open Qortal Settings &List, OpenList_Clicked
		Menu, qomboMenu, Add, &Qortal, :QortalSubmenu
		Menu, HelpSubmenu, Add, &About qombo, About_Clicked
		Menu, HelpSubmenu, Add, qortal &Discord Server, Discord_Clicked
		Menu, qomboMenu, Add, &Help, :HelpSubmenu
		Gui, Menu, qomboMenu
		
		col1_x := 5
		col2_x := 420
		col3_x := 480
		row_y := 5
		tabw := 542
		tabh := 420
		
		Gui, Add, StatusBar,, %OutputStatus%
		
		Gui, MyWindow:Add, Tab3, x%col1_x% y%row_y% h%tabh% w%tabw%, Account||Minters|Groups|Names|Peers|Lookup|Settings|
		
		Gui, Tab
		; main window outside tabs
		
		Gui, Tab, Account
		Gui, MyWindow:Add, ListView, vAccountListView Grid h115 w517 -Hdr, | |
		Gui, MyWindow:Add, ListView, vJoinedListView Grid h238 w517, ID|Public|Members|Joined Groups|Owner|Description|Owner Address
		Gui, MyWindow:Add, Button, gAccount_Clicked, Get Data
		
		Gui, Tab, Minters
		Gui, MyWindow:Add, ListView, vMintersListView Grid h360 w517, Level|Blocks|Name|Address|Sponsor|Sponsor Address|
		Gui, MyWindow:Add, Button, gMinters_Clicked, Get Data
		Gui, MyWindow:Add, CheckBox, x+m yp+4 vGetMinterNames gMinterNames_Clicked, Get Names?
		Gui, MyWindow:Add, Edit, r1 vMinterTotals w362 x+m yp-4 ReadOnly, Press  -Get Data-  to retrieve online Minters
		
		Gui, Tab, Groups
		Gui, MyWindow:Add, ListView, vGroupsListView Grid h360 w517, ID|Public|Members|Name|Owner|Description|Owner Address
		Gui, MyWindow:Add, Button, gGroups_Clicked, Get Data
		Gui, MyWindow:Add, Text, x+m yp+4, Press to retrieve Groups

		Gui, Tab, Names
		Gui, MyWindow:Add, ListView, vNamesListView Grid h360 w517, Name|Owner Address
		Gui, MyWindow:Add, Button, gNames_Clicked, Get Data
		Gui, MyWindow:Add, Text, x+m yp+4, Press to retrieve Names
		
		Gui, Tab, Peers
		Gui, MyWindow:Add, ListView, vPeersListView Grid h360 w517, Direction|Address|Block Height|Build Version
		Gui, MyWindow:Add, Button, gPeers_Clicked, Get Data
		Gui, MyWindow:Add, Text, x+m yp+4, Press to retrieve Peers
		
		Gui, Tab, Lookup
		Gui, MyWindow:Add, ListView, vLookupListView Grid h360 w517 -Hdr, | |
		Gui, MyWindow:Add, Button, gLookup_Clicked, Check
		Gui, MyWindow:Add, Text, x+m yp+4, Address or Group ID:
		Gui, MyWindow:Add, Edit, r1 vLookupValue w274 x+m yp-4, 74 ;qombo groupid :)
		Gui, MyWindow:Add, Button, x+m yp gNameLookup_Clicked, Check Name

		Gui, Tab, Settings
		Gui, MyWindow:Add, ListView, vSettingsListView gSettings_Edit Grid AltSubmit h360 w517, Qortal Settings|Value (Right-Click to Edit)
		Gui, MyWindow:Add, Button, gSettings_Clicked, Get Data
		Gui, MyWindow:Add, Button, x+m yp gNewSetting_Clicked, Add New
		Gui, MyWindow:Add, Button, x+m yp gRemoveSetting_Clicked, Remove
		
		this.Show()
	}
	
	Show() {
		;check if minimized if so leave it be
		WinGet, OutputVar , MinMax, qombo v%VersionNumber%
		if (OutputVar = -1) {
			return
		}
		nW := this.Width
		nH := this.Height
		Gui, MyWindow:Show, w%nW% h%nH%, qombo v%VersionNumber%
	}
	
	Hide() {
		Gui, MyWindow:Hide
	}
	
	Submit() {
		Gui, MyWindow:Submit, NoHide
	}
	
	Update() {
		GuiControl, MyWindow:, GetMinterNames, % GetMinterNames
	}
	
	
}

ResizeControls() {
	WinGetPos, , , winW, winH
	lwinH := winH
	offset := 0
	if (winW < 425) {
		lwinH := lwinH-20
		offset := 21
	}
	ControlMove, SysTabControl321, , , winW-28, winH-110
	ControlMove, SysListView321, , , winW-60, ((lwinH-200)/2)-73
	ControlMove, SysListView322, , ((lwinH)/2)-63+offset, winW-60, ((lwinH-200)/2)+81
	ControlMove, SysListView323, , , winW-60, lwinH-185
	ControlMove, SysListView324, , , winW-60, lwinH-185
	ControlMove, SysListView325, , , winW-60, lwinH-185
	ControlMove, SysListView326, , , winW-60, lwinH-185
	ControlMove, SysListView327, , , winW-60, lwinH-185
	ControlMove, SysListView328, , , winW-60, lwinH-185
	ControlMove, SysListView329, , , winW-60, lwinH-185
	ControlMove, Button1, , winH-75
	ControlMove, Button2, , winH-75
	ControlMove, Button3, , winH-72
	ControlMove, Button4, , winH-75
	ControlMove, Button5, , winH-75
	ControlMove, Button6, , winH-75
	ControlMove, Button7, , winH-75
	ControlMove, Button8, winW-119, winH-75
	ControlMove, Button9, , winH-75
	ControlMove, Button10, , winH-75
	ControlMove, Button11, , winH-75
	ControlMove, Button12, , winH-75
	ControlMove, Button13, , winH-75
	ControlMove, Static1, , winH-72
	ControlMove, Static2, , winH-72
	ControlMove, Static3, , winH-72
	ControlMove, Static4, , winH-72
	ControlMove, Edit1, , winH-75, winW-253
	ControlMove, Edit2, , winH-75, winW-363
	SB_SetText(statustext)
	return
}

Reload_Clicked: ;menu
{
	Reload
	return
}

Exit_Clicked: ;menu
{
	ExitApp
	return
}

Discord_Clicked: ;menu
{
	Run, % "https://discord.com/invite/zZq6ev47S6"
	return
}

About_Clicked: ;menu
{
	MsgBox, , About qombo v%VersionNumber%, qombo v%VersionNumber% by QuickMythril`n`nA QORTAL blockchain explorer.`n(requires API enabled)
	return
}

QStart_Clicked:
{
	Process, Exist, Qortal.exe
	qortalpid := ErrorLevel
	if (qortalpid) {
		SB_SetText("Qortal Core is running.")
	}
	else {
		Run, C:\Program Files\Qortal\Qortal.exe
		SB_SetText("Starting Qortal Core...")
	}
	return
}

UIStart_Clicked:
{
	Process, Exist, Qortal UI.exe
	qortaluipid := ErrorLevel
	if (qortaluipid) {
		SB_SetText("Qortal UI is running.")
	}
	else {
		Run, C:\Program Files\Qortal UI\Qortal UI.exe
		SB_SetText("Starting Qortal UI...")
	}
	return
}

OpenFolder_Clicked:
{
	Run, %localappdata%\Qortal\
	return
}

OpenList_Clicked:
{
	Run, https://github.com/QuickMythril/qombo/blob/main/defaultsettings.json
	return
}

MinterNames_Clicked: ;checkbox, minters tab
{
	GetMinterNames := !GetMinterNames
	oMyGUI.Update()
	return
}

Account_Clicked:
{
	ParseAccount()
	return
}

ParseAccount() {
	Gui, MyWindow:Default
	SB_SetText("Please wait a moment...")
	Gui, ListView, AccountListView
	LV_Delete()
	mintinginfo := GetMintingInfo()
	if (mintinginfo == []) {
		return
	}
	for k, v in JSON.parse(mintinginfo)[1]
	{
		if (k == "recipientAccount") {
			myaddress := v
		}
		else if (k == "mintingAccount") {
			mysponsor := v
		}
	}
	
	nameinfo := GetUserName(myaddress)
	for k, v in JSON.parse(nameinfo)[1]
	{
		if (k == "name") {
			myname := v
		}
	}
	
	sponsorname := GetUserName(mysponsor)
	for k, v in JSON.parse(sponsorname)[1]
	{
		if (k == "name") {
			mysponsorname := v
		}
	}
	
	userinfo := GetUserInfo(myaddress)
	myblocks := 0
	for k, v in JSON.parse(userinfo)
	{
		if (k == "level") {
			mylevel := v
		}
		else if (k == "blocksMinted") {
			myblocks += v
		}
		else if (k == "blocksMintedAdjustment") {
			myblocks += v
		}
	}
	LV_Add("", "Minting Name", myname)
	LV_Add("", "Minting Address", myaddress)
	LV_Add("", "Minting Level", mylevel)
	LV_Add("", "Blocks Minted", myblocks)
	LV_Add("", "Sponsor Name", mysponsorname)
	LV_Add("", "Sponsor Address", mysponsor)
	LV_Add("", "QORT Balance", GetUserBalance(myaddress))
	LV_ModifyCol()

	Gui, ListView, JoinedListView
	LV_Delete()
	mygroupinfo := GetUserGroups(myaddress)
	for k, v in JSON.parse(mygroupinfo) {
		membercount := GetMembers(v.groupId)
		rawownername := GetUserName(v.owner)
		if (JSON.parse(rawownername)[1].name == "") {
			groupownername := "(unregistered)"
		}
		else {
			groupownername := JSON.parse(rawownername)[1].name
		}
		Gui, ListView, JoinedListView
		; ID|Public|Members|Name|Owner|Description|Owner Address
		LV_Add("", v.groupId, v.isOpen, membercount, v.groupName, groupownername, v.description, v.owner)
	}
	Gui, ListView, JoinedListView
	LV_ModifyCol()
	SB_SetText("Account info loaded.")
	return
}

GetMintingInfo() {
	URLtoCall := "http://localhost:12391/admin/mintingaccounts/"
	WR := ComObjCreate("Msxml2.XMLHTTP")
	Try {
		WR.Open("GET", URLtoCall, false)
		WR.SetRequestHeader("Pragma", "no-cache")
		WR.SetRequestHeader("Cache-Control", "no-cache, no-store")
		WR.SetRequestHeader("If-Modified-Since", "Sat, 1 Jan 2000 00:00:00 GMT")
		WR.Send()
		data := WR.ResponseText
	}
	return data
}

GetUserInfo(addr) {
	URLtoCall := "http://localhost:12391/addresses/" addr
	WR := ComObjCreate("Msxml2.XMLHTTP")
	Try {
		WR.Open("GET", URLtoCall, false)
		WR.SetRequestHeader("Pragma", "no-cache")
		WR.SetRequestHeader("Cache-Control", "no-cache, no-store")
		WR.SetRequestHeader("If-Modified-Since", "Sat, 1 Jan 2000 00:00:00 GMT")
		WR.Send()
		data := WR.ResponseText
	}
	return data
}

GetUserName(addr) {
	URLtoCall := "http://localhost:12391/names/address/" addr
	WR := ComObjCreate("Msxml2.XMLHTTP")
	Try {
		WR.Open("GET", URLtoCall, false)
		WR.SetRequestHeader("Pragma", "no-cache")
		WR.SetRequestHeader("Cache-Control", "no-cache, no-store")
		WR.SetRequestHeader("If-Modified-Since", "Sat, 1 Jan 2000 00:00:00 GMT")
		WR.Send()
		data := WR.ResponseText
	}
	return data
}

GetUserGroups(addr) {
	URLtoCall := "http://localhost:12391/groups/member/" addr
	WR := ComObjCreate("Msxml2.XMLHTTP")
	Try {
		WR.Open("GET", URLtoCall, false)
		WR.SetRequestHeader("Pragma", "no-cache")
		WR.SetRequestHeader("Cache-Control", "no-cache, no-store")
		WR.SetRequestHeader("If-Modified-Since", "Sat, 1 Jan 2000 00:00:00 GMT")
		WR.Send()
		data := WR.ResponseText
	}
	return data
}

GetUserBalance(addr) {
	URLtoCall := "http://localhost:12391/addresses/balance/" addr
	WR := ComObjCreate("Msxml2.XMLHTTP")
	Try {
		WR.Open("GET", URLtoCall, false)
		WR.SetRequestHeader("Pragma", "no-cache")
		WR.SetRequestHeader("Cache-Control", "no-cache, no-store")
		WR.SetRequestHeader("If-Modified-Since", "Sat, 1 Jan 2000 00:00:00 GMT")
		WR.Send()
		data := WR.ResponseText
	}
	return data
}

Minters_Clicked:
{
	ParseMinters()
	return
}

ParseMinters() {
	Gui, MyWindow:Default
	SB_SetText("Please wait a moment...")
	rawminters := GetMinters()
	minterlvs := [0,0,0,0,0,0,0,0,0,0,0]
	Gui, ListView, MintersListView
	LV_Delete()
	if !(rawminters) {
		SB_SetText(LV_GetCount() "No Minters found.  Try again later.")
	}
	for k, v in JSON.parse(rawminters)
	{
		if (GetMinterNames) {
			membernameinfo := JSON.parse(GetUserName(v.recipientAddress))
			if (membernameinfo[1].name == "") {
				membername := "(unregistered)"
			}
			else {
				membername := membernameinfo[1].name
			}
		}
		else {
			membername := "-"
		}
		
		memberinfo := JSON.parse(rawmemberinfo := GetUserInfo(v.recipientAddress))
		totalblocks := (memberinfo.blocksMinted + memberinfo.blocksMintedAdjustment)
		if (v.recipientAddress == v.minterAddress) {
			sponsorname := "(none)"
			sponsoraddr := "(none)"
		}
		else {
			if (GetMinterNames) {
				sponsornameinfo := JSON.parse(rawsponsorname := GetUserName(v.minterAddress))
				if (sponsornameinfo[1].name == "") {
					sponsorname := "(unregistered)"
				}
				else {
					sponsorname := sponsornameinfo[1].name
				}
			}
			else {
				sponsorname := "-"
			}
			sponsoraddr := v.minterAddress
		}
		
		LV_Add("", memberinfo.level, totalblocks, membername, v.recipientAddress, sponsorname, sponsoraddr)
		minterlvs[memberinfo.level + 1] += 1
	}
	LV_ModifyCol()
	LV_ModifyCol(1, "Integer")
	LV_ModifyCol(2, "Integer")
	LV_ModifyCol(2, "SortDesc")
	LV_ModifyCol(1, "Sort")
	SB_SetText(LV_GetCount() " Minters online.")
	minterreport := LV_GetCount() " Minters: Lv0=" minterlvs[1] ", Lv1=" minterlvs[2] ", Lv2=" minterlvs[3] ", Lv3=" minterlvs[4] ", Lv4=" minterlvs[5] ", Lv5=" minterlvs[6]
	; ", 6: " minterlvs[7] "`nLevel 7: " minterlvs[8] "`nLevel 8: " minterlvs[9] "`nLevel 9: " minterlvs[10] "`nLevel 10: " minterlvs[11]
	; add more levels later
	GuiControl, Text, MinterTotals, % minterreport
	return
}

GetMinters() {
	URLtoCall := "http://localhost:12391/addresses/online"
	WR := ComObjCreate("Msxml2.XMLHTTP")
	Try {
		WR.Open("GET", URLtoCall, false)
		WR.SetRequestHeader("Pragma", "no-cache")
		WR.SetRequestHeader("Cache-Control", "no-cache, no-store")
		WR.SetRequestHeader("If-Modified-Since", "Sat, 1 Jan 2000 00:00:00 GMT")
		WR.Send()
		data := WR.ResponseText
	}
	return data
}

GetBlockHeight() {
	URLtoCall := "http://localhost:12391/blocks/height"
	WR := ComObjCreate("Msxml2.XMLHTTP")
	Try {
		WR.Open("GET", URLtoCall, false)
		WR.SetRequestHeader("Pragma", "no-cache")
		WR.SetRequestHeader("Cache-Control", "no-cache, no-store")
		WR.SetRequestHeader("If-Modified-Since", "Sat, 1 Jan 2000 00:00:00 GMT")
		WR.Send()
		data := WR.ResponseText
	}
	return data
}

Groups_Clicked:
{
	ParseGroups()
	return
}

ParseGroups() {
	Gui, MyWindow:Default
	SB_SetText("Please wait a moment...")
	rawgroups := GetGroups()
	Gui, ListView, GroupsListView
	LV_Delete()
	for k, v in JSON.parse(rawgroups)
	{
		membercount := GetMembers(v.groupId)
		rawownername := GetUserName(v.owner)
		if (JSON.parse(rawownername)[1].name == "") {
			groupownername := "(unregistered)"
		}
		else {
			groupownername := JSON.parse(rawownername)[1].name
		}
		LV_Add("", v.groupId, v.isOpen, membercount, v.groupName, groupownername, v.description, v.owner)
	}
	LV_ModifyCol()
	LV_ModifyCol(1, "Integer")
	LV_ModifyCol(3, "Integer")
	GuiControl, Text, Static1, % LV_GetCount() " Groups"
	SB_SetText(LV_GetCount() " Groups registered.")
	return
}

GetGroups() {
	URLtoCall := "http://localhost:12391/groups?limit=0"
	WR := ComObjCreate("Msxml2.XMLHTTP")
	Try {
		WR.Open("GET", URLtoCall, false)
		WR.SetRequestHeader("Pragma", "no-cache")
		WR.SetRequestHeader("Cache-Control", "no-cache, no-store")
		WR.SetRequestHeader("If-Modified-Since", "Sat, 1 Jan 2000 00:00:00 GMT")
		WR.Send()
		data := WR.ResponseText
	}
	return data
}

GetMembers(id) {
	URLtoCall := "http://localhost:12391/groups/members/" id "?limit=1&offset=1"
	WR := ComObjCreate("Msxml2.XMLHTTP")
	Try {
		WR.Open("GET", URLtoCall, false)
		WR.SetRequestHeader("Pragma", "no-cache")
		WR.SetRequestHeader("Cache-Control", "no-cache, no-store")
		WR.SetRequestHeader("If-Modified-Since", "Sat, 1 Jan 2000 00:00:00 GMT")
		WR.Send()
		data := JSON.parse(WR.ResponseText)
	}
	return data.membercount
}

Names_Clicked:
{
	ParseNames()
	return
}

ParseNames() {
	Gui, MyWindow:Default
	SB_SetText("Please wait a moment...")
	rawnames := GetNames()
	Gui, ListView, NamesListView
	LV_Delete()
	for k, v in JSON.parse(rawnames)
	{
		LV_Add("", v.name, v.owner)
	}
	LV_ModifyCol()
	GuiControl, Text, Static2, % LV_GetCount() " Names"
	SB_SetText(LV_GetCount() " Names registered.")
	return
}

GetNames() {
	URLtoCall := "http://localhost:12391/names?limit=0"
	WR := ComObjCreate("Msxml2.XMLHTTP")
	Try {
		WR.Open("GET", URLtoCall, false)
		WR.SetRequestHeader("Pragma", "no-cache")
		WR.SetRequestHeader("Cache-Control", "no-cache, no-store")
		WR.SetRequestHeader("If-Modified-Since", "Sat, 1 Jan 2000 00:00:00 GMT")
		WR.Send()
		data := WR.ResponseText
	}
	return data
}

Peers_Clicked:
{
	ParsePeers()
	return
}

ParsePeers() {
	Gui, MyWindow:Default
	SB_SetText("Please wait a moment...")
	rawpeers := GetPeers()
	Gui, ListView, PeersListView
	LV_Delete()
	for k, v in JSON.parse(rawpeers)
	{
		LV_Add("", v.direction, v.address, v.lastHeight, v.version)
		heightlist.push(v.lastHeight)
		; Direction|Address|Block Height|Build Version
	}
	LV_ModifyCol()
	LV_ModifyCol(3, "Integer")
	LV_ModifyCol(4, "SortDesc")
	LV_ModifyCol(3, "SortDesc")
	Sleep, 500
	GuiControl, Text, Static3, % LV_GetCount() " Peers"
	SB_SetText(LV_GetCount() " Peers connected.")
	if !(LV_GetCount()) {
		SB_SetText("No peers found.  Try again later.")
		return ;finish if no peers found.
	}
	return
}

GetPeers() {
	URLtoCall := "http://localhost:12391/peers"
	WR := ComObjCreate("Msxml2.XMLHTTP")
	Try {
		WR.Open("GET", URLtoCall, false)
		WR.SetRequestHeader("Pragma", "no-cache")
		WR.SetRequestHeader("Cache-Control", "no-cache, no-store")
		WR.SetRequestHeader("If-Modified-Since", "Sat, 1 Jan 2000 00:00:00 GMT")
		WR.Send()
		data := WR.ResponseText
	}
	return data
}

Lookup_Clicked:
{
	GuiControlGet, LookupValue
	if LookupValue is integer
	{
		LookupGroup(LookupValue)
	}
	else if (StrLen(LookupValue) = 34) {
		if (InStr(LookupValue, "Q", CaseSensitive := true) = 1) {
			LookupAddress(LookupValue)
		}
		else {
			MsgBox % "Please enter a valid Address or Group ID."
		}
	}
	else {
		MsgBox % "Please enter a valid Address or Group ID."
	}
	return
}

NameLookup_Clicked:
{
	LookupName()
	return
}

LookupName()
{
	GuiControlGet, LookupValue
	SB_SetText("Please wait a moment...")
	rawnames := GetNames()
	for k, v in JSON.parse(rawnames)
	{
		if (v.name = LookupValue) {
			LookupAddress(v.owner)
			SB_SetText("Name Lookup complete.")
			return
		}
	}
	SB_SetText("Name not found.")
	return
}

LookupAddress(addr) {
	Gui, MyWindow:Default
	SB_SetText("Please wait a moment...")
	Gui, ListView, LookupListView
	LV_Delete()
	LV_Add("", "Address", addr)
	nameinfo := GetUserName(addr)
	for k, v in JSON.parse(nameinfo)[1]
	{
		if (k == "name") {
			name := v
		}
	}
	LV_Add("", "Name", name)
	userinfo := GetUserInfo(addr)
	myblocks := 0
	for k, v in JSON.parse(userinfo)
	{
		if (k == "level") {
			level := v
		}
		else if (k == "blocksMinted") {
			blocks += v
		}
		else if (k == "blocksMintedAdjustment") {
			blocks += v
		}
	}
	LV_Add("", "Minting Level", level)
	LV_Add("", "Blocks Minted", blocks)
	LV_Add("", "QORT Balance", GetUserBalance(addr))
	rewardshares := JSON.parse(GetRewardShares(addr))
	if (rewardshares.Count()) {
		for k, v in rewardshares
		{	
			if !(v.recipient == v.mintingAccount) {
				if (v.recipient == addr) {
					sponsor := v.mintingAccount
					sponsorname := GetUserName(sponsor)
					for kk, vv in JSON.parse(sponsorname)[1]
					{
						if (kk == "name") {
							sponsorname := vv
						}
					}
					LV_Add("", "Sponsor Name", sponsorname)
					LV_Add("", "Sponsor Address", sponsor)
				}
				else if (v.mintingAccount == addr) {
					sponsee := v.recipient
					sponseename := GetUserName(sponsee)
					for kk, vv in JSON.parse(sponseename)[1]
					{
						if (kk == "name") {
							sponseename := vv
						}
					}
					LV_Add("", "Sponsee Name", sponseename)
					LV_Add("", "Sponsee Address", sponsee)
				}
			}
		}
	}	
	groupinfo := JSON.parse(GetUserGroups(addr))
	LV_Add("", "Groups", groupinfo.Count())
	for k, v in groupinfo
	{
		if (v.owner == addr) {
			LV_Add("", "Owner", v.groupName)
		}
		else if (v.isAdmin) {
			LV_Add("", "Admin", v.groupName)
		}
		else {
			LV_Add("", "Member", v.groupName)
		}
	}
	LV_ModifyCol()
	SB_SetText("Address Lookup complete.")
	return
}

GetRewardShares(addr) {
	URLtoCall := "http://localhost:12391/addresses/rewardshares?involving=" addr
	WR := ComObjCreate("Msxml2.XMLHTTP")
	Try {
		WR.Open("GET", URLtoCall, false)
		WR.SetRequestHeader("Pragma", "no-cache")
		WR.SetRequestHeader("Cache-Control", "no-cache, no-store")
		WR.SetRequestHeader("If-Modified-Since", "Sat, 1 Jan 2000 00:00:00 GMT")
		WR.Send()
		data := WR.ResponseText
	}
	return data
}

LookupGroup(id) {
	Gui, MyWindow:Default
	SB_SetText("Please wait a moment...")
	rawgroup := GetGroupInfo(id)
	Gui, ListView, LookupListView
	LV_Delete()
	for k, v in JSON.parse(rawgroup)
	{
		if (k == "groupName") {
			name := v
		}
		else if (k == "description") {
			desc := v
		}
		else if (k == "owner") {
			owneraddress := v
		}
		else if (k == "isOpen") {
			public := v
		}
	}
	if (public) {
	LV_Add("", "Group ID", id " (Public)")
	}
	else {
	LV_Add("", "Group ID", id " (Private)")
	}
	LV_Add("", "Group Name", name)
	LV_Add("", "Group Description", desc)
	
	rawownername := GetUserName(owneraddress)
	if (JSON.parse(rawownername)[1].name == "") {
		ownername := "(unregistered)"
	}
	else {
		ownername := JSON.parse(rawownername)[1].name
	}
	LV_Add("", "Owner Name", ownername)
	LV_Add("", "Owner Address", owneraddress)
	
	rawmembers := GetAllMembers(id)
	members := JSON.parse(rawmembers).membercount
	LV_Add("", "Members", members)
	for k, v in JSON.parse(rawmembers).members
	{
		for kk, vv in v {
			if (kk == "member") {
				rawmembername := GetUserName(vv)
				if (JSON.parse(rawmembername)[1].name == "") {
					membername := "(unregistered)"
				}
				else {
					membername := JSON.parse(rawmembername)[1].name
				}
				LV_Add("", membername, vv)
			}
		}
	}
	LV_ModifyCol()
	SB_SetText("Group Lookup complete.")	
	return
}

GetGroupInfo(id) {
	URLtoCall := "http://localhost:12391/groups/" id
	WR := ComObjCreate("Msxml2.XMLHTTP")
	Try {
		WR.Open("GET", URLtoCall, false)
		WR.SetRequestHeader("Pragma", "no-cache")
		WR.SetRequestHeader("Cache-Control", "no-cache, no-store")
		WR.SetRequestHeader("If-Modified-Since", "Sat, 1 Jan 2000 00:00:00 GMT")
		WR.Send()
		data := WR.ResponseText
	}
	return data
}

GetAllMembers(id) {
	URLtoCall := "http://localhost:12391/groups/members/" id
	WR := ComObjCreate("Msxml2.XMLHTTP")
	Try {
		WR.Open("GET", URLtoCall, false)
		WR.SetRequestHeader("Pragma", "no-cache")
		WR.SetRequestHeader("Cache-Control", "no-cache, no-store")
		WR.SetRequestHeader("If-Modified-Since", "Sat, 1 Jan 2000 00:00:00 GMT")
		WR.Send()
		data := WR.ResponseText
	}
	return data
}

Settings_Clicked:
{
	ParseSettings()
	return
}

ParseSettings() {
	Gui, MyWindow:Default
	SB_SetText("Please wait a moment...")
	Gui, ListView, SettingsListView
	LV_Delete()
	FileRead, SettingsFile, %localappdata%\Qortal\settings.json
	for k, v in JSON.parse(SettingsFile)
	{
		LV_Add("", k, v)
	}
	LV_ModifyCol()
	LV_ModifyCol(1, "Sort")
	SB_SetText("Qortal settings.json file loaded.")
	return
}

Settings_Edit:
{
	if (A_GuiEvent != "RightClick") {
		return
	}
	oldsetting := ""
	newsetting := ""
	thissetting := ""
	row := A_EventInfo
	if !(row) {
		return
	}
	LV_GetText(oldsetting, row, 2)
	LV_GetText(thissetting, row, 1)
	InputBox, newsetting, Qortal settings.json, Please enter a new value for:`n%thissetting%, , , , , , , , %oldsetting%
	FileRead, SettingsFile, %localappdata%\Qortal\settings.json
	currentsettings := JSON.parse(SettingsFile)
	for k, v in currentsettings
	{
		if (k == thissetting) {
			currentsettings[k] := newsetting
		}
	}
	updatedsettings := JSON.stringify(currentsettings)
	FileDelete, %localappdata%\Qortal\settings.json
	FileAppend, %updatedsettings%, %localappdata%\Qortal\settings.json
	ParseSettings()
	SB_SetText("Qortal settings.json file updated.")
	return
}

NewSetting_Clicked:
{
	FileRead, SettingsFile, %localappdata%\Qortal\settings.json
	currentsettings := JSON.parse(SettingsFile)
	InputBox, settingname, Qortal settings.json, Please enter a new settings.json entry., , , , , , , ,
	if (ErrorLevel) {
		SB_SetText("Add new setting cancelled.")
		return
	}
	while (currentsettings.HasKey(settingname)) {
		InputBox, settingname, Qortal settings.json, This entry exists.  Please enter a new setting`, or right click an existing one to edit., , , , , , , ,
			if (ErrorLevel) {
			SB_SetText("Add new setting cancelled.")
			return
		}
	}
	InputBox, settingvalue, Qortal settings.json, Please enter a value for:`n%settingname%, , , , , , , ,
	if (ErrorLevel) {
		SB_SetText("Add new setting cancelled.")
		return
	}
	currentsettings[settingname] := settingvalue
	updatedsettings := JSON.stringify(currentsettings)
	FileDelete, %localappdata%\Qortal\settings.json
	FileAppend, %updatedsettings%, %localappdata%\Qortal\settings.json
	ParseSettings()
	SB_SetText("Qortal settings.json file updated.")
	return
}

RemoveSetting_Clicked:
{
	Gui, MyWindow:Default
	Gui, ListView, SettingsListView
	row := 0
	row := LV_GetNext()
	if !(row) {
		SB_SetText("Nothing selected to remove.")
		return
	}
	LV_GetText(delsetting, row, 1)
	MsgBox, 4, Qortal settings.json., Removing the following entry:`n %delsetting% `n`nAre you sure?
	IfMsgBox, No
	{
		SB_SetText("Remove setting cancelled.")
		return
	}
	FileRead, SettingsFile, %localappdata%\Qortal\settings.json
	currentsettings := JSON.parse(SettingsFile)
	currentsettings.Delete(delsetting)
	updatedsettings := JSON.stringify(currentsettings)
	FileDelete, %localappdata%\Qortal\settings.json
	FileAppend, %updatedsettings%, %localappdata%\Qortal\settings.json
	ParseSettings()
	SB_SetText("Qortal settings.json file updated.")
	return
}