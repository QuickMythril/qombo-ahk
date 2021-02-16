#include %A_ScriptDir%
#include JSON.ahk

;Added in 0.1.0:
; Current minting account info
; All registered Names and Groups
; Member count for Groups
; All online minters info

;To do list:
;- LOTS!

;Bug Reports:
;- None yet! :)

;qombo globals
global VersionNumber := "0.1.0"
global MintersListView := ""
global AccountListView := ""
global NamesListView := ""
global GroupsListView := ""

;GUI globals
global oMyGUI := ""
global TrayIcon := systemroot "\system32\imageres.dll"
global OutputStatus := "Welcome to qombo v" VersionNumber

;Checkbox globals
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
return
;END:	default run commands

;BEGIN: GUI Defs
class MyGui {
	Width := "550"
	Height := "450"
	
	__New()
	{
		Gui, MyWindow:New
		Gui, MyWindow:+Resize -MaximizeBox 
		
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
		
		Gui, Add, StatusBar,, %OutputStatus%
		
		Gui, MyWindow:Add, Tab3, x%col1_x% y%row_y% h420 w540, Account|Minters||Groups|Names|
		
		Gui, Tab
		; main window outside tabs
		
		Gui, Tab, Account
		Gui, MyWindow:Add, ListView, vAccountListView Grid h360 w510, | |
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

Reload_Clicked:
{
	Reload
	return
}

Exit_Clicked:
{
	ExitApp
	return
}

MinterNames_Clicked:
{
	GetMinterNames := !GetMinterNames
	oMyGUI.Update()
	return
}

Discord_Clicked:
{
	Run, % "https://discord.com/invite/zZq6ev47S6"
	return
}

About_Clicked:
{
	MsgBox, , About qombo v%VersionNumber%, qombo v%VersionNumber% by QuickMythril`n`nA QORTAL blockchain explorer.`n(requires API enabled)
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