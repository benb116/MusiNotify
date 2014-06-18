global preffile, spotinotify, itunotify, isloginitem, dispart, dispalb, numofnot, removeonquit, autoupdate
set preffile to "com.BenB116.MusiNotify.plist"

set rawlines to paragraphs of (do shell script "defaults read " & preffile)
repeat with lin in rawlines
	if lin contains "spotinotify" then set spotinotify to (characters 19 thru -2 of lin) as text
	if lin contains "itunotify" then set itunotify to (characters 17 thru -2 of lin) as text
	if lin contains "numofnot" then set numofnot to (characters 16 thru -2 of lin) as text
	if lin contains "removeonquit" then set removeonquit to (characters 20 thru -2 of lin) as text
	if lin contains "dispart" then set dispart to (characters 15 thru -2 of lin) as text
	if lin contains "dispalb" then set dispalb to (characters 15 thru -2 of lin) as text
	if lin contains "autoUpdate" then set autoupdate to (characters 18 thru -2 of lin) as text
end repeat
tell application "System Events" to set listoflogin to (name of every login item) as list

if listoflogin does not contain "MusiNotify" then set isloginitem to "Add "
if listoflogin contains "MusiNotify" then set isloginitem to "Remove "
if spotinotify = "1" then set isSpotEnab to "Disable "
if spotinotify = "0" then set isSpotEnab to "Enable "
if itunotify = "1" then set isiTunEnab to "Disable "
if itunotify = "0" then set isiTunEnab to "Enable "
if dispart = "1" then set isart to "Don't "
if dispart = "0" then set isart to ""
if dispalb = "1" then set isalb to "Don't "
if dispalb = "0" then set isalb to ""
if removeonquit = "1" then set isclearquit to "Don't "
if removeonquit = "0" then set isclearquit to ""
if autoupdate = "1" then set isautoupdate to "Don't "
if autoupdate = "0" then set isautoupdate to ""

try
	set q1 to (choose from list {isiTunEnab & "iTunes Notifications", isSpotEnab & "Spotify Notifications", isloginitem & "Login Item", isart & "Display Artist Name", isalb & "Display Album Name", "Number of Notifications in Sidebar", isclearquit & "Clear Notifications on Quit", isautoupdate & "Auto-Update"} Â
		with prompt "Which preferences would you like to change?" with title "MusiNotify Preferences" with multiple selections allowed)
end try

try
	repeat with pref in q1
		if pref contains "iTunes Notifications" then EnDisiTunes()
		if pref contains "Spotify Notifications" then EnDisSpotify()
		if pref contains "Login Item" then loginitem()
		if pref contains "Display Artist Name" then changedispart()
		if pref contains "Display Album Name" then changedispalb()
		if pref contains "Number of Notifications in Sidebar" then changenumofnot()
		if pref contains "Clear Notifications on Quit" then changeremoveonquit()
		if pref contains "Auto-Update" then changeautoupdate()
	end repeat
	display dialog "Success!"
on error msg
	display dialog "Error: " & msg
end try
on changepref(pref, num)
	do shell script "defaults write " & preffile & " '" & pref & "' '" & num & "'"
end changepref

on EnDisiTunes()
	if itunotify = "1" then changepref("iTuNotify", "0")
	if itunotify = "0" then changepref("iTuNotify", "1")
end EnDisiTunes

on EnDisSpotify()
	if spotinotify = "1" then changepref("SpotiNotify", "0")
	if spotinotify = "0" then changepref("SpotiNotify", "1")
end EnDisSpotify

on loginitem()
	if isloginitem = "Add " then
		set linez to paragraphs of (do shell script "ps -ax | grep 'MusiNotify.app'")
		repeat with lin in linez
			if lin contains "MusiNotify.app/Contents" then exit repeat
		end repeat
		set currentpath to ((do shell script "echo " & lin & " | cut -d ' ' -f 4 | cut -d '.' -f 1") & ".app")
		tell application "System Events" to make login item at end with properties {path:currentpath}
	else
		tell application "System Events" to delete login item "MusiNotify"
	end if
end loginitem

on changedispart()
	if dispart = "0" then changepref("DispArt", "1")
	if dispart = "1" then changepref("DispArt", "0")
end changedispart

on changedispalb()
	if dispalb = "0" then changepref("DispAlb", "1")
	if dispalb = "1" then changepref("DispAlb", "0")
end changedispalb

on changenumofnot()
	repeat
		set q5 to (display dialog Â
			"MusiNotify currently displays " & numofnot & " notifications in the sidebar." & return & return & Â
			"How many notifications would you like displayed in the sidebar? (Enter a number ³ 0)" default answer "" & numofnot & Â
			"" with title "MusiNotify Preferences" default button 2)
		try
			set newnum to text returned of q5 as integer
			if newnum < 0 then error
			exit repeat
		end try
	end repeat
	set newnum to newnum as text
	changepref("NumOfNot", newnum)
end changenumofnot

on changeremoveonquit()
	if removeonquit = "0" then changepref("RemoveOnQuit", "1")
	if removeonquit = "1" then changepref("RemoveOnQuit", "0")
end changeremoveonquit

on changeautoupdate()
	if autoupdate = "0" then changepref("AutoUpdate", "1")
	if autoupdate = "1" then changepref("AutoUpdate", "0")
end changeautoupdate