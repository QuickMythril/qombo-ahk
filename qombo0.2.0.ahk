#include %A_ScriptDir%
#include JSON.ahk

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
; Realtime updating
; LOTS More!

;Bug Reports:
; None yet! :)

;qombo globals
global VersionNumber := "0.2.0"
global MintersListView := ""
global AccountListView := ""
global OwnedListView := ""
global JoinedListView := ""
global GroupsListView := ""
global NamesListView := ""
global PeersListView := ""

global oMyGUI := ""
global TrayIcon := systemroot "\system32\imageres.dll"
global OutputStatus := "Welcome to qombo v" VersionNumber
;checkbox globals
global GetMinterNames := 0

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
		Menu, HelpSubmenu, Add, &About qombo, About_Clicked
		Menu, HelpSubmenu, Add, qortal &Discord Server, Discord_Clicked
		Menu, qomboMenu, Add, &Help, :HelpSubmenu
		Gui, Menu, qomboMenu
		
		col1_x := 5
		col2_x := 420
		col3_x := 480
		row_y := 5
		tabw := 540
		tabh := 420
		
		Gui, Add, StatusBar,, %OutputStatus%
		
		Gui, MyWindow:Add, Tab3, x%col1_x% y%row_y% h%tabh% w%tabw%, Account||Minters|Groups|Names|Peers|
		
		Gui, Tab
		; main window outside tabs
		
		Gui, Tab, Account
		Gui, MyWindow:Add, ListView, vAccountListView Grid h99 w510 -Hdr, | |
		Gui, MyWindow:Add, ListView, vOwnedListView Grid h100 w510, ID|Public|Members|Owned Groups|Description
		Gui, MyWindow:Add, ListView, vJoinedListView Grid h149 w510, ID|Public|Members|Joined Groups|Owner|Description|Owner Address
		Gui, MyWindow:Add, Button, gAccount_Clicked, Get Data
		
		Gui, Tab, Minters
		Gui, MyWindow:Add, ListView, vMintersListView Grid h360 w510, Level|Blocks|Name|Address|Sponsor|Sponsor Address|
		Gui, MyWindow:Add, Button, gMinters_Clicked, Get Data
		Gui, MyWindow:Add, CheckBox, x+m yp+4 vGetMinterNames gMinterNames_Clicked, Get Names?
		
		Gui, Tab, Groups
		Gui, MyWindow:Add, ListView, vGroupsListView Grid h360 w510, ID|Public|Members|Name|Owner|Description|Owner Address
		Gui, MyWindow:Add, Button, gGroups_Clicked, Get Data
		
		Gui, Tab, Names
		Gui, MyWindow:Add, ListView, vNamesListView Grid h360 w510, Name|Owner Address
		Gui, MyWindow:Add, Button, gNames_Clicked, Get Data
		
		Gui, Tab, Peers
		Gui, MyWindow:Add, ListView, vPeersListView Grid h360 w510, Direction|Address|Block Height|Build Version
		Gui, MyWindow:Add, Button, gPeers_Clicked, Get Data
		
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
	ControlMove, SysTabControl321, , , winW-28, winH-110
	ControlMove, SysListView321, , , winW-60, (winH-200)/3
	ControlMove, SysListView322, , (winH)/3 +44, winW-60, (winH-200)/3
	ControlMove, SysListView323, , (winH)/3*2 -14, winW-60, (winH-200)/3
	ControlMove, SysListView324, , , winW-60, winH-185
	ControlMove, SysListView325, , , winW-60, winH-185
	ControlMove, SysListView326, , , winW-60, winH-185
	ControlMove, SysListView327, , , winW-60, winH-185
	ControlMove, SysListView328, , , winW-60, winH-185
	ControlMove, Button1, , winH-75
	ControlMove, Button2, , winH-75
	ControlMove, Button3, , winH-72
	ControlMove, Button4, , winH-75
	ControlMove, Button5, , winH-75
	ControlMove, Button6, , winH-75
	ControlMove, Button7, , winH-75
	ControlMove, Static1, , winH-72
	ControlMove, Edit1, , winH-75
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
	LV_ModifyCol()
	
	Gui, ListView, OwnedListView
	LV_Delete()
	Gui, ListView, JoinedListView
	LV_Delete()
	
	mygroupinfo := GetUserGroups(myaddress)
	for k, v in JSON.parse(mygroupinfo) {
		membercount := GetMembers(v.groupId)
		if (v.isAdmin) {
			Gui, ListView, OwnedListView
			LV_Add("", v.groupId, v.isOpen, membercount, v.groupName, v.description)
		}
		else {
			rawownername := GetUserName(v.owner)
			if (JSON.parse(rawownername)[1].name == "") {
				groupownername := "(unregistered)"
			}
			else {
				groupownername := JSON.parse(rawownername)[1].name
			}
			Gui, ListView, JoinedListView
			LV_Add("", v.groupId, v.isOpen, membercount, v.groupName, groupownername, v.description, v.owner)
		}
	}
	
	Gui, ListView, OwnedListView
	; LV_ModifyCol()
	Gui, ListView, JoinedListView
	LV_ModifyCol()
	
	SB_SetText("Account info loaded.")
	return
}

GetMintingInfo() {
	URLtoCall := "http://127.0.0.1:12391/admin/mintingaccounts/"
	WR := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	WR.SetTimeouts("10000", "10000", "10000", "10000")
	Try {
		WR.Open("GET", URLtoCall, false)
		WR.SetRequestHeader("Content-Type","application/x-www-form-urlencoded")
		WR.Send()
		WR.WaitForResponse(-1)
		data := WR.ResponseText
	}
	return data
}

GetUserInfo(addr) {
	URLtoCall := "http://127.0.0.1:12391/addresses/" addr
	WR := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	WR.SetTimeouts("10000", "10000", "10000", "10000")
	Try {
		WR.Open("GET", URLtoCall, false)
		WR.SetRequestHeader("Content-Type","application/x-www-form-urlencoded")
		WR.Send()
		WR.WaitForResponse(-1)
		data := WR.ResponseText
	}
	return data
}

GetUserName(addr) {
	URLtoCall := "http://127.0.0.1:12391/names/address/" addr
	WR := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	WR.SetTimeouts("10000", "10000", "10000", "10000")
	Try {
		WR.Open("GET", URLtoCall, false)
		WR.SetRequestHeader("Content-Type","application/x-www-form-urlencoded")
		WR.Send()
		WR.WaitForResponse(-1)
		data := WR.ResponseText
	}
	return data
}

GetUserGroups(addr) {
	URLtoCall := "http://127.0.0.1:12391/groups/member/" addr
	WR := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	WR.SetTimeouts("10000", "10000", "10000", "10000")
	Try {
		WR.Open("GET", URLtoCall, false)
		WR.SetRequestHeader("Content-Type","application/x-www-form-urlencoded")
		WR.Send()
		WR.WaitForResponse(-1)
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
	Gui, ListView, MintersListView
	LV_Delete()
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
			sponsorname := "none"
			sponsoraddr := "none"
		}
		else {
			if (GetMinterNames) {
				sponsornameinfo := JSON.parse(rawsponsorname := GetUserName(v.minterAddress))
				sponsorname := sponsornameinfo[1].name
			}
			else {
				sponsorname := "-"
			}
			sponsoraddr := v.minterAddress
		}
		LV_Add("", memberinfo.level, totalblocks, membername, v.recipientAddress, sponsorname, sponsoraddr)
	}
	LV_ModifyCol()
	LV_ModifyCol(1, "Integer")
	LV_ModifyCol(2, "Integer")
	LV_ModifyCol(2, "SortDesc")
	LV_ModifyCol(1, "Sort")
	SB_SetText(LV_GetCount() " Minters online.")
	return
}

GetMinters() {
	URLtoCall := "http://127.0.0.1:12391/addresses/online"
	WR := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	WR.SetTimeouts("10000", "10000", "10000", "10000")
	Try {
		WR.Open("GET", URLtoCall, false)
		WR.SetRequestHeader("Content-Type","application/x-www-form-urlencoded")
		WR.Send()
		WR.WaitForResponse(-1)
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
	SB_SetText(LV_GetCount() " Groups registered.")
	return
}

GetGroups() {
	URLtoCall := "http://127.0.0.1:12391/groups?limit=0"
	WR := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	WR.SetTimeouts("10000", "10000", "10000", "10000")
	Try {
		WR.Open("GET", URLtoCall, false)
		WR.SetRequestHeader("Content-Type","application/x-www-form-urlencoded")
		WR.Send()
		WR.WaitForResponse(-1)
		data := WR.ResponseText
	}
	return data
}

GetMembers(id) {
	URLtoCall := "http://127.0.0.1:12391/groups/members/" id "?limit=1&offset=1"
	WR := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	WR.SetTimeouts("10000", "10000", "10000", "10000")
	Try {
		WR.Open("GET", URLtoCall, false)
		WR.SetRequestHeader("Content-Type","application/x-www-form-urlencoded")
		WR.Send()
		WR.WaitForResponse(-1)
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
	SB_SetText(LV_GetCount() " Names registered.")
	return
}

GetNames() {
	URLtoCall := "http://127.0.0.1:12391/names?limit=0"
	WR := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	WR.SetTimeouts("10000", "10000", "10000", "10000")
	Try {
		WR.Open("GET", URLtoCall, false)
		WR.SetRequestHeader("Content-Type","application/x-www-form-urlencoded")
		WR.Send()
		WR.WaitForResponse(-1)
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
	}
	LV_ModifyCol()
	LV_ModifyCol(3, "Integer")
	LV_ModifyCol(1, "Sort")
	LV_ModifyCol(3, "SortDesc")
	SB_SetText(LV_GetCount() " Peers connected.")
	return
}

GetPeers() {
	URLtoCall := "http://127.0.0.1:12391/peers"
	WR := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	WR.SetTimeouts("10000", "10000", "10000", "10000")
	Try {
		WR.Open("GET", URLtoCall, false)
		WR.SetRequestHeader("Content-Type","application/x-www-form-urlencoded")
		WR.Send()
		WR.WaitForResponse(-1)
		data := WR.ResponseText
	}
	return data
}