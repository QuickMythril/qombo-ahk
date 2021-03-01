#include %A_ScriptDir%
#include JSON.ahk

global VersionNumber := "0.5.1"

;Added in 0.5.1
; Added General Chat / PMs to Joined Groups
; Also displays Last Message and Sender for each
; Unregistered Names in Trades no longer copy other names
; Removed Sponsor from Account Tab when Self-Sharing
; Update Fix when running uncompiled .ahk file

;Added in 0.5.0
; Can view Open & Completed Trades
; Current BH & Peers in StatusBar
; CTRL-C to copy rows
; Check for Updates
; Changes to window are saved
; Code cleanup:
; (Faster API Calls)
; (Faster window resizing)

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

;v1.0 To do list:
; settings picker
; Color Picker
; LOG of minter count/growth.
; Get QORA/Founders?
; Fix when not minting.
; SEARCH (Edit>Find: looks for all groups, names, etc.)
; LTC BTC balance/address
; Export / Generate Report
; LOTS More!

;Known Issues/Bug Reports:

; Listed Trades do not always appear in Qortal UI?
; Flickering redraw when moving
; Minimize requires move/reize

;qombo globals
global SelectedTabID := 1
global SelectedTrades := 1
global AccountListView := ""
global JoinedListView := ""
global MintersListView := ""
global TradesListView := ""
global GroupsListView := ""
global NamesListView := ""
global PeersListView := ""
global QORAListView := ""
global LookupListView := ""
global SettingsListView := ""

global oMyGUI := ""
global TrayIcon := systemroot "\system32\imageres.dll"
global SettingsFile := {}
global QSettingsFilename := A_WorkingDir "\qombosettings.json"
global OutputStatus := "Welcome to qombo v" VersionNumber
;checkbox globals
global GetMinterNames := 0
global MinterTotals := ""
SetTitleMatchMode, RegEx

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
LoadWindow()
OnMessage(0x0047, "ResizeControls")
SetTimer, Active_Refresh, 5000
CheckForUpdates(1)
return
;END:	default run commands

;BEGIN: GUI Defs
class MyGui {
	Width := "550"
	Height := "450"
	
	__New()
	{
		Gui, MyWindow:New, , qombo
		Gui, MyWindow:+Resize
		
		Menu, FileSubmenu, Add, &Reload qombo, Reload_Clicked
		Menu, FileSubmenu, Add, E&xit qombo, Exit_Clicked
		Menu, qomboMenu, Add, &File, :FileSubmenu
		Menu, QortalSubmenu, Add, Start Qortal &Core, QStart_Clicked
		Menu, QortalSubmenu, Add, Start Qortal &UI, UIStart_Clicked
		Menu, QortalSubmenu, Add, &Open Settings/DB Folder, OpenFolder_Clicked
		Menu, QortalSubmenu, Add, Open Qortal Settings &List, OpenList_Clicked
		Menu, qomboMenu, Add, &Qortal, :QortalSubmenu
        Menu, TradeSubmenu, Add, QORT For Sale, ForSale_Clicked
        Menu, TradeSubmenu, Add, Sold QORT (LTC), LTCSold_Clicked
        Menu, TradeSubmenu, Add, Sold QORT (BTC), BTCSold_Clicked
        Menu, qomboMenu, Add, &Trade Portal, :TradeSubmenu
		Menu, HelpSubmenu, Add, qortal &Discord Server, Discord_Clicked
		Menu, HelpSubmenu, Add, Check for &Updates, Updates_Clicked
		Menu, HelpSubmenu, Add, &About qombo, About_Clicked
		Menu, qomboMenu, Add, &Help, :HelpSubmenu
		Gui, Menu, qomboMenu
		Menu, TradeSubmenu, Check, QORT For Sale
		
		col1_x := 5
		col2_x := 420
		col3_x := 480
		row_y := 5
		tabw := 542
		tabh := 420
		
		Gui, Add, StatusBar
		SB_SetParts(200, 200)
		SB_SetText(OutputStatus, 1)
		SB_SetText("`tBlock Height:               ", 2)
		SB_SetText("`tPeers:      ", 3)
		
		Gui, MyWindow:Add, Tab3, x%col1_x% y%row_y% h%tabh% w%tabw% vSelectedTabID gTab_Changed AltSubmit, Account||Minters|Trades|Groups|Names|Peers|Lookup|Settings|
		
		Gui, Tab
		; main window outside tabs
		
		Gui, Tab, Account
		Gui, MyWindow:Add, ListView, vAccountListView Grid h115 w517 -Hdr, | |
		Gui, MyWindow:Add, ListView, vJoinedListView Grid h238 w517, ID|Public|Members|Joined Groups|Last Message|Last Sender|Owner|Description|Owner Address| |
		Gui, MyWindow:Add, Button, gAccount_Clicked, Get Data
		
		Gui, Tab, Minters
		Gui, MyWindow:Add, ListView, vMintersListView Grid h360 w517, Level|Blocks|Name|Address|Sponsor|Sponsor Address|
		Gui, MyWindow:Add, Button, gMinters_Clicked, Get Data
		Gui, MyWindow:Add, CheckBox, x+m yp+4 vGetMinterNames gMinterNames_Clicked, Get Names?
		Gui, MyWindow:Add, Edit, r1 vMinterTotals w362 x+m yp-4 ReadOnly, Press  -Get Data-  to retrieve online Minters
		GuiControl, Disable, Edit1

		Gui Tab, Trades
		Gui, MyWindow:Add, ListView, vTradesListView Grid h360 w517, QORT Amount|Total Cost|Coin|(Cost/Qort)|Time Ago|Timestamp|Seller Name|Seller Address
        Gui, MyWindow:Add, Button, gTrades_Clicked, Get Data
		Gui, MyWindow:Add, Text, x+m yp+4, Press to retrieve Trades

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

RefreshTab(tabid) {
    StatusBarGetText, bartext
	WinGetPos, , , winW, winH, qombo v*
	lwinH := winH
	offset := 0
	if (winW < 476) {
		lwinH := lwinH-20
		offset := 21
	}
	ControlMove, SysTabControl321, , , winW-28, winH-110
    switch tabid {
        case "1":
        {
            ControlMove, SysListView321, , , winW-60, ((lwinH-200)/2)-73
	        ControlMove, SysListView322, , ((lwinH)/2)-63+offset, winW-60, ((lwinH-200)/2)+81
            ControlMove, Button1, , winH-75
        }
        case "2":
        {
            ControlMove, SysListView323, , , winW-60, lwinH-185
            ControlMove, Button2, , winH-75
	        ControlMove, Button3, , winH-72
            ControlMove, Edit1, , winH-75, winW-253
        }
        case "3":
        {
            ControlMove, SysListView324, , , winW-60, lwinH-185
            ControlMove, Button4, , winH-75
            ControlMove, Static1, , winH-72
        }
        case "4":
        {
            ControlMove, SysListView325, , , winW-60, lwinH-185
            ControlMove, Button5, , winH-75
            ControlMove, Static2, , winH-72
        }
        case "5":
        {
            ControlMove, SysListView326, , , winW-60, lwinH-185
            ControlMove, Button6, , winH-75
            ControlMove, Static3, , winH-72
        }
        case "6":
        {
            ControlMove, SysListView327, , , winW-60, lwinH-185
            ControlMove, Button7, , winH-75
            ControlMove, Static4, , winH-72
        }
        case "7":
        {
            ControlMove, SysListView328, , , winW-60, lwinH-185
            ControlMove, Button8, , winH-75
            ControlMove, Button9, winW-119, winH-75
            ControlMove, Static5, , winH-72
            ControlMove, Edit2, , winH-75, winW-363
        }
        case "8":
        {
            ControlMove, SysListView329, , , winW-60, lwinH-185
            ControlMove, Button10, , winH-75
            ControlMove, Button11, , winH-75
            ControlMove, Button12, , winH-75
        }
    }
	sbdiv := (winW-180)/3
	if (sbdiv < 150) {
		sbdiv := 150
	}
	WinSet, Redraw
    return
}

LoadWindow() {
	if !(FileExist(QSettingsFilename)) {
		return
	}
	rawsettings := ""
	FileRead, rawsettings, %A_WorkingDir%\qombosettings.json
	qsettings := JSON.parse(rawsettings)
	WinMove, qombo v*, , qsettings.win.X, qsettings.win.Y, qsettings.win.W, qsettings.win.H
	return
}

SaveWindow() {
	if (FileExist(QSettingsFilename)) {
		FileRead, rawsettings, %A_WorkingDir%\qombosettings.json
		qsettings := JSON.parse(rawsettings)
		if !(qsettings.HasKey(win)) {
			FileDelete, %A_WorkingDir%\qombosettings.json
			qsettings := {}
			qsettings.win := {}
		}
	}
	else {
	qsettings := {}
	qsettings.win := {}
	}
	WinGetPos, winX, winY, winW, winH, qombo v*
	qsettings.win.X := winX
	qsettings.win.Y := winY
	qsettings.win.W := winW
	qsettings.win.H := winH
	newsettings := JSON.stringify(qsettings)
	FileDelete, %A_WorkingDir%\qombosettings.json
	FileAppend, %newsettings%, %A_WorkingDir%\qombosettings.json
	return
}

ResizeControls() {
    Gui, Submit, NoHide
    RefreshTab(SelectedTabID)
	SaveWindow()
    return
}

Tab_Changed:
{
    ResizeControls()
    return
}

;Hotkeys
#IfWinActive qombo v*
^c::CopySelected()
#IfWinActive

Active_Refresh:
{
	ActiveRefresh()
	return
}

ActiveRefresh()
{
	Process, Exist, Qortal.exe
	qortalpid := ErrorLevel
	if (qortalpid) {
		Gui, MyWindow:Default
		nodestatus := JSON.parse(GetAPICall("http://localhost:12391/admin/status/", ""))
		SB_SetText("`tBlock Height: " nodestatus.height, 2)
		SB_SetText("`tPeers: " nodestatus.numberOfConnections, 3)
	}
	else {
		Gui, MyWindow:Default
		SB_SetText("`tBlock Height: Disconnected" nodestatus.height, 2)
		SB_SetText("`tPeers: Disconnected" nodestatus.numberOfConnections, 3)
	}
	return
}

CopySelected()
{
	Gui, Submit, NoHide
    switch SelectedTabID
	{
		case "1": {
			ControlGet, lvd1, List, Selected, SysListView321, qombo v*
			ControlGet, lvd2, List, Selected, SysListView322, qombo v*
			listviewdata := lvd1 "`n" lvd2
		}
		case "2": ControlGet, listviewdata, List, Selected, SysListView323, qombo v*
		case "3": ControlGet, listviewdata, List, Selected, SysListView324, qombo v*
		case "4": ControlGet, listviewdata, List, Selected, SysListView325, qombo v*
		case "5": ControlGet, listviewdata, List, Selected, SysListView326, qombo v*
		case "6": ControlGet, listviewdata, List, Selected, SysListView327, qombo v*
		case "7": ControlGet, listviewdata, List, Selected, SysListView328, qombo v*
		case "8": ControlGet, listviewdata, List, Selected, SysListView329, qombo v*
		case "9": ControlGet, listviewdata, List, Selected, SysListView3210, qombo v*
	}
	Clipboard := listviewdata
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
}

MyWindowGuiClose:
{
    ExitApp
}

Discord_Clicked: ;menu
{
	MsgBox, 4, Qortal Discord Server, Go to the Official Qortal Discord server now?
	IfMsgBox Yes
		Run, % "https://discord.com/invite/zZq6ev47S6"
	return
}

About_Clicked: ;menu
{
	MsgBox, , About qombo v%VersionNumber%, qombo v%VersionNumber% by QuickMythril`n`nA QORTAL blockchain explorer.`n(requires API enabled)
	return
}

Updates_Clicked:
{
	CheckForUpdates(0)
	return
}

CheckForUpdates(startup) {
	gitinfo := JSON.parse(GetAPICall("https://api.github.com/repos/QuickMythril/qombo/releases/latest", ""))
	if (gitinfo.tag_name == "v" VersionNumber) {
		if !(startup) {
			SB_SetText("No updates available.")
		}
		return
	}
	MsgBox, 4, qombo Update Available, % "Update Available: " gitinfo.name "`nInstalled Version: v" VersionNumber "`n`nNew Features:`n" gitinfo.body "`n`nUpdate now?"
	IfMsgBox No
		return
	IfMsgBox Yes
	{
		newfile := gitinfo.assets[1].name
		if (A_IsCompiled) {
			fileurl := gitinfo.assets[1].browser_download_url
		}
		else {
			fileurl := "https://raw.githubusercontent.com/QuickMythril/qombo/main/qombo" gitinfo.tag_name ".ahk"
			newfile := SubStr(newfile, 1, 11) "ahk"
		}
		UrlDownloadToFile, %fileurl%, %A_WorkingDir%\%newfile%
		Run, %newfile%
		ExitApp
		return
	}
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

GetAPICall(urltocall, data) {
	Process, Exist, Qortal.exe
	qortalpid := ErrorLevel
	if !(qortalpid) {
		if InStr(urltocall, "localhost") {
			SB_SetText("Core is not running.")
			return
		}
	}
    if (data) {
        urltocall := urltocall data
    }
	WR := ComObjCreate("Msxml2.XMLHTTP")
	Try {
		WR.Open("GET", urltocall, false)
		WR.SetRequestHeader("Pragma", "no-cache")
		WR.SetRequestHeader("Cache-Control", "no-cache, no-store")
		WR.SetRequestHeader("If-Modified-Since", "Sat, 1 Jan 2000 00:00:00 GMT")
		WR.Send()
		data := WR.ResponseText
	}
	return data
}

GetBlockHeight() {
	return GetAPICall("http://localhost:12391/blocks/height", 0)
}

GetMembers(id) {
	memberdata := JSON.parse(GetAPICall("http://localhost:12391/groups/members/", id "?limit=1&offset=1"))
	return memberdata.memberCount
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
	mintinginfo := GetAPICall("http://localhost:12391/admin/mintingaccounts/", 0)
	for k, v in JSON.parse(mintinginfo)[1]
	{
		if (k == "recipientAccount") {
			myaddress := v
		}
		else if (k == "mintingAccount") {
			mysponsor := v
		}
	}
	sponsorname := GetAPICall("http://localhost:12391/names/address/", mysponsor)
	for k, v in JSON.parse(sponsorname)[1]
	{
		if (k == "name") {
			mysponsorname := v
		}
	}

	nameinfo := GetAPICall("http://localhost:12391/names/address/", myaddress)
	for k, v in JSON.parse(nameinfo)[1]
	{
		if (k == "name") {
			myname := v
		}
	}
	
	userinfo := GetAPICall("http://localhost:12391/addresses/", myaddress)
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
	if !(mysponsor == myaddress) {
		LV_Add("", "Sponsor Name", mysponsorname)
		LV_Add("", "Sponsor Address", mysponsor)
	}
	LV_Add("", "QORT Balance", GetAPICall("http://localhost:12391/addresses/balance/", myaddress))
	LV_ModifyCol()
	
	Gui, ListView, JoinedListView
	LV_Delete()
	
	mychatinfo := JSON.parse(GetAPICall("http://localhost:12391/chat/active/", myaddress))
	mygroupinfo := JSON.parse(GetAPICall("http://localhost:12391/groups/member/", myaddress))
	for k, v in mychatinfo.groups {
		if (v.groupId == "0") {
			LV_Add("", "0", "", "", "Qortal General Chat", HowLongAgo(v.timestamp), v.senderName, "", "", "", v.timestamp)
		}
		for kk, vv in mygroupinfo {
			membercount := GetMembers(v.groupId)
			if (v.groupId == vv.groupId) {
				rawownername := GetAPICall("http://localhost:12391/names/address/", vv.owner)
				if (JSON.parse(rawownername)[1].name == "") {
					groupownername := "(unregistered)"
				}
				else {
					groupownername := JSON.parse(rawownername)[1].name
				}
				Gui, ListView, JoinedListView
				lastmessage := "(none)"
				if (v.timestamp) {
					lastmessage := HowLongAgo(v.timestamp)
				}
				LV_Add("", v.groupId, vv.isOpen, membercount, v.groupName, lastmessage, v.senderName, groupownername, vv.description, vv.owner, v.timestamp)
			}
		}
	}
	for k, v in mychatinfo.direct {
		LV_Add("", "", "", "", "(direct message)", HowLongAgo(v.timestamp), v.senderName, v.name, "", "", v.timestamp)
	}
	Gui, ListView, JoinedListView
	LV_ModifyCol()
	LV_ModifyCol(10, 0)
	LV_ModifyCol(10, "SortDesc")
	SB_SetText("Account info loaded.")
	return
}

Minters_Clicked:
{
	ParseMinters()
	return
}

MinterNames_Clicked: ;checkbox, minters tab
{
	GetMinterNames := !GetMinterNames
	oMyGUI.Update()
	return
}

ParseMinters() {
	Gui, MyWindow:Default
	SB_SetText("Please wait a moment...")
	rawminters := GetAPICall("http://localhost:12391/addresses/online", 0)
	minterlvs := [0,0,0,0,0,0,0,0,0,0,0]
	Gui, ListView, MintersListView
	LV_Delete()
	if !(rawminters) {
		SB_SetText(LV_GetCount() "No Minters found.  Try again later.")
	}
	for k, v in JSON.parse(rawminters)
	{
		if (GetMinterNames) {
			membernameinfo := JSON.parse(GetAPICall("http://localhost:12391/names/address/", v.recipientAddress))
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
		
		memberinfo := JSON.parse(rawmemberinfo := GetAPICall("http://localhost:12391/addresses/", v.recipientAddress))
		totalblocks := (memberinfo.blocksMinted + memberinfo.blocksMintedAdjustment)
		if (v.recipientAddress == v.minterAddress) {
			sponsorname := "(none)"
			sponsoraddr := "(none)"
		}
		else {
			if (GetMinterNames) {
				sponsornameinfo := JSON.parse(rawsponsorname := GetAPICall("http://localhost:12391/names/address/", v.minterAddress))
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
	LV_ModifyCol(2, "Sort")
	SB_SetText(LV_GetCount() " Minters online.")
	minterreport := LV_GetCount() " Minters: Lv0=" minterlvs[1] ", Lv1=" minterlvs[2] ", Lv2=" minterlvs[3] ", Lv3=" minterlvs[4] ", Lv4=" minterlvs[5] ", Lv5=" minterlvs[6] ", Lv6=" minterlvs[7]
	GuiControl, Text, MinterTotals, % minterreport
	return
}

Trades_Clicked:
{
    Menu, TradeSubmenu, Uncheck, QORT For Sale
    Menu, TradeSubmenu, Uncheck, Sold QORT (LTC)
    Menu, TradeSubmenu, Uncheck, Sold QORT (BTC)
    SB_SetText("Please wait a moment...")
    switch SelectedTrades
    {
        case 1:
        {
            Menu, TradeSubmenu, Check, QORT For Sale
            url := "http://127.0.0.1:12391/crosschain/tradeoffers?limit=0&reverse=true"
            ParseTrades(url, "forsale")
            SB_SetText(LV_GetCount() " Open Trade Orders found.")
        }
        case 2:
        {
            Menu, TradeSubmenu, Check, Sold QORT (LTC)
            url := "http://127.0.0.1:12391/crosschain/trades?foreignBlockchain=LITECOIN&limit=0&reverse=true"
            ParseTrades(url, "sold")
            SB_SetText(LV_GetCount() " completed LTC Trades found.")
        }
        case 3:
        {
            Menu, TradeSubmenu, Check, Sold QORT (BTC)
            url := "http://127.0.0.1:12391/crosschain/trades?foreignBlockchain=BITCOIN&limit=0&reverse=true"
            ParseTrades(url, "sold")
            SB_SetText(LV_GetCount() " completed BTC Trades found.")
        }
    }
	return
}

ForSale_Clicked:
{
    SelectedTrades := 1
    Menu, TradeSubmenu, Check, QORT For Sale
    Menu, TradeSubmenu, Uncheck, Sold QORT (LTC)
    Menu, TradeSubmenu, Uncheck, Sold QORT (BTC)
    SB_SetText("Please wait a moment...")
    url := "http://127.0.0.1:12391/crosschain/tradeoffers?limit=0&reverse=true"
    ParseTrades(url, "forsale")
    SB_SetText(LV_GetCount() " Open Trade Orders found.")
    return
}
LTCSold_Clicked:
{
    SelectedTrades := 2
    Menu, TradeSubmenu, Check, Sold QORT (LTC)
    Menu, TradeSubmenu, Uncheck, QORT For Sale
    Menu, TradeSubmenu, Uncheck, Sold QORT (BTC)
    SB_SetText("Please wait a moment...")
    url := "http://127.0.0.1:12391/crosschain/trades?foreignBlockchain=LITECOIN&limit=0&reverse=true"
    ParseTrades(url, "sold")
    SB_SetText(LV_GetCount() " completed LTC Trades found.")
    return
}
BTCSold_Clicked:
{
    SelectedTrades := 3
    Menu, TradeSubmenu, Check, Sold QORT (BTC)
    Menu, TradeSubmenu, Uncheck, QORT For Sale
    Menu, TradeSubmenu, Uncheck, Sold QORT (LTC)
    SB_SetText("Please wait a moment...")
    url := "http://127.0.0.1:12391/crosschain/trades?foreignBlockchain=BITCOIN&limit=0&reverse=true"
    ParseTrades(url, "sold")
    SB_SetText(LV_GetCount() " completed BTC Trades found.")
    return
}

ParseTrades(url, trades) {
	Gui, MyWindow:Default
	Gui, ListView, TradesListView
    LV_ModifyCol(5, "NoSort")
	LV_Delete()
    rawtrades := GetAPICall(url, 0)
    if (trades == "forsale") {
        for k, v in JSON.parse(rawtrades)
        {
            switch v.foreignBlockChain
            {
                case "BITCOIN": cointype := "BTC"
                case "LITECOIN": cointype := "LTC"
            }
            nameinfo := GetAPICall("http://localhost:12391/names/address/", v.qortalCreator)
            Sleep 0
			sellername := "(unregistered)"
	        for kk, vv in JSON.parse(nameinfo)[1]
	        {
		        if (kk == "name") {
					sellername := vv
				}
			}
			qortcost := Format("{:.8f}", v.expectedBitcoin/v.qortAmount)
            LV_Add("", v.qortAmount, v.expectedBitcoin, cointype, qortcost, HowLongAgo(v.creationTimestamp), v.creationTimestamp, sellername, v.qortalCreator)
        }
        LV_ModifyCol()
    }
    else if (trades == "sold") {
        for k, v in JSON.parse(rawtrades)
        {
			qortcost := Format("{:.8f}", v.btcAmount/v.qortAmount)
            LV_Add("", v.qortAmount, v.btcAmount, "", qortcost, HowLongAgo(v.tradeTimestamp), v.tradeTimestamp, "", "")
        }
        LV_ModifyCol()
        LV_ModifyCol(3, 0)
        LV_ModifyCol(7, 0)
        LV_ModifyCol(8, 0)
    }
	LV_ModifyCol(1, "Float")
	LV_ModifyCol(2, "Float")
	LV_ModifyCol(4, "Float")
    LV_ModifyCol(6, "Float")
    LV_ModifyCol(6, "SortDesc")
	GuiControl, Text, Static1, % LV_GetCount() " Trades"
	return
}

HowLongAgo(timestamp)
{
    timestamp := Floor(timestamp/1000)
    DllCall("GetSystemTimeAsFileTime", int64p,t)
    timestampnow:=t//10000000-11644473600
    howlongsec := timestampnow-Timestamp
    howlongmin := Floor(howlongsec/60)
    howlongsec := Mod(howlongsec, 60)
    howlonghour := Floor(howlongmin/60)
    howlongmin := Mod(howlongmin, 60)
    howlongday := Floor(howlonghour/24)
    howlonghour := Mod(howlonghour, 24)
    timestring := ""
    if (howlongday) {
        timestring := timestring howlongday "d, "
    }
    if (howlonghour) {
        timestring := timestring howlonghour "h, "
    }
    if (howlongmin) {
        timestring := timestring howlongmin "m, "
    }
    if (howlongsec) {
        timestring := timestring howlongsec "s"
    }
	else {
		timestring := SubStr(timestring, 1, -2)
	}
    return timestring
}

Groups_Clicked:
{
	ParseGroups()
	return
}

ParseGroups() {
	Gui, MyWindow:Default
	SB_SetText("Please wait a moment...")
	rawgroups := GetAPICall("http://localhost:12391/groups?limit=0", 0)
	Gui, ListView, GroupsListView
	LV_Delete()
	for k, v in JSON.parse(rawgroups)
	{
		membercount := GetMembers(v.groupId)
		rawownername := GetAPICall("http://localhost:12391/names/address/", v.owner)
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
	GuiControl, Text, Static2, % LV_GetCount() " Groups"
	SB_SetText(LV_GetCount() " Groups registered.")
	return
}

Names_Clicked:
{
	ParseNames()
	return
}

ParseNames() {
	Gui, MyWindow:Default
	SB_SetText("Please wait a moment...")
	rawnames := GetAPICall("http://localhost:12391/names?limit=0", 0)
	Gui, ListView, NamesListView
	LV_Delete()
	for k, v in JSON.parse(rawnames)
	{
		LV_Add("", v.name, v.owner)
	}
	LV_ModifyCol()
	GuiControl, Text, Static3, % LV_GetCount() " Names"
	SB_SetText(LV_GetCount() " Names registered.")
	return
}

Peers_Clicked:
{
	ParsePeers()
	return
}

ParsePeers() {
	Gui, MyWindow:Default
	SB_SetText("Please wait a moment...")
	rawpeers := GetAPICall("http://localhost:12391/peers", 0)
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
	GuiControl, Text, Static4, % LV_GetCount() " Peers"
	SB_SetText(LV_GetCount() " Peers connected.")
	return
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
	rawnames := GetAPICall("http://localhost:12391/names?limit=0", 0)
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
	nameinfo := GetAPICall("http://localhost:12391/names/address/", addr)
	for k, v in JSON.parse(nameinfo)[1]
	{
		if (k == "name") {
			name := v
		}
	}
	LV_Add("", "Name", name)
	userinfo := GetAPICall("http://localhost:12391/addresses/", addr)
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
	LV_Add("", "QORT Balance", GetAPICall("http://localhost:12391/addresses/balance/", addr))
	rewardshares := JSON.parse(GetAPICall("http://localhost:12391/addresses/rewardshares?involving=", addr))
	if (rewardshares.Count()) {
		for k, v in rewardshares
		{	
			if !(v.recipient == v.mintingAccount) {
				if (v.recipient == addr) {
					sponsor := v.mintingAccount
					sponsorname := GetAPICall("http://localhost:12391/names/address/", sponsor)
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
					sponseename := GetAPICall("http://localhost:12391/names/address/", sponsee)
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
	groupinfo := JSON.parse(GetAPICall("http://localhost:12391/groups/member/", addr))
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

LookupGroup(id) {
	Gui, MyWindow:Default
	SB_SetText("Please wait a moment...")
	rawgroup := GetAPICall("http://localhost:12391/groups/", id)
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
	
	rawownername := GetAPICall("http://localhost:12391/names/address/", owneraddress)
	if (JSON.parse(rawownername)[1].name == "") {
		ownername := "(unregistered)"
	}
	else {
		ownername := JSON.parse(rawownername)[1].name
	}
	LV_Add("", "Owner Name", ownername)
	LV_Add("", "Owner Address", owneraddress)
	
	rawmembers := GetAPICall("http://localhost:12391/groups/members/", id)
	members := JSON.parse(rawmembers).membercount
	LV_Add("", "Members", members)
	for k, v in JSON.parse(rawmembers).members
	{
		for kk, vv in v {
			if (kk == "member") {
				rawmembername := GetAPICall("http://localhost:12391/names/address/", vv)
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