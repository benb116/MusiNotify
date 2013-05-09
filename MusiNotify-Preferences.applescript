global preffile
set preffile to "com.BenB116.MusiNotify.plist"

set q1 to (choose from list {"Login Item", "Display Artist Name", "Display Album Name", "Number of Notifications in Sidebar", "Clear Notifications on Quit"} with prompt "Which preferences would you like to change?" with title "MusiNotify Preferences" with multiple selections allowed)

if q1 contains "Login Item" then loginitem()
if q1 contains "Display Artist Name" then DispArt()
if q1 contains "Display Album Name" then DispAlb()
if q1 contains "Number of Notifications in Sidebar" then NumOfNot()
if q1 contains "Clear Notifications on Quit" then RemoveOnQuit()

display dialog "Preferences saved" buttons ("OK") default button 1 with title "MusiNotify Preferences"

on changepref(pref, num)
	do shell script "defaults write " & preffile & " '" & pref & "' '" & num & "'"
end changepref

on loginitem()
	set logit to (do shell script "defaults read " & preffile & " 'login'")
	if logit = "1" then set loginenabled to "is"
	if logit = "0" then set loginenabled to "is not"
	set q2 to (display dialog "MusiNotify currently " & loginenabled & " a login item.

Would you like MusiNotify to start on login?" with title "MusiNotify Preferences" buttons {"Cancel", "Yes", "No"})
	if button returned of q2 is "Yes" and logit = "0" then
		set apppath to (do shell script "defaults read " & preffile & " 'loginPath'")
		tell application "System Events" to make login item at end with properties {path:apppath, kind:application}
		changepref("login", "1")
	else if button returned of q2 is "No" and logit = "1" then
		tell application "System Events" to delete login item "MusiNotify"
		changepref("login", "0")
	end if
end loginitem

on DispArt()
	set Art to (do shell script "defaults read " & preffile & " 'DispArt'")
	if Art = "1" then set artenabled to "displays"
	if Art = "0" then set artenabled to "does not display"
	set q3 to (display dialog "MusiNotify currently " & artenabled & " the artist in notifications.

Would you like MusiNotify to display the artist?" with title "MusiNotify Preferences" buttons {"Cancel", "Yes", "No"})
	if button returned of q3 is "Yes" and Art = "0" then
		changepref("DispArt", "1")
	else if button returned of q3 is "No" and Art = "1" then
		changepref("DispArt", "0")
	end if
end DispArt

on DispAlb()
	set Alb to (do shell script "defaults read " & preffile & " 'DispAlb'")
	if Alb = "1" then set Albenabled to "displays"
	if Alb = "0" then set Albenabled to "does not display"
	set q4 to (display dialog "MusiNotify currently " & Albenabled & " the album in notifications.

Would you like MusiNotify to display the album?" with title "MusiNotify Preferences" buttons {"Cancel", "Yes", "No"})
	if button returned of q4 is "Yes" and Alb = "0" then
		changepref("DispAlb", "1")
	else if button returned of q4 is "No" and Alb = "1" then
		changepref("DispAlb", "0")
	end if
end DispAlb

on NumOfNot()
	set NumNot to (do shell script "defaults read " & preffile & " 'NumOfNot'") as string
	repeat
		set q5 to text returned of (display dialog "MusiNotify currently displays " & NumNot & " notifications in the sidebar." & return & return & "How many notifications would you like displayed in the sidebar?" default answer "" & NumNot & "" with title "MusiNotify Preferences")
		try
			set newnum to q5 as number
			exit repeat
		end try
	end repeat
	set newnum to newnum as text
	changepref("NumOfNot", newnum)
end NumOfNot

on RemoveOnQuit()
	set removeon to (do shell script "defaults read " & preffile & " 'RemoveOnQuit'") as string
	if removeon = "1" then set RemoveEnabled to "removes"
	if removeon = "0" then set RemoveEnabled to "does not remove"
	set q6 to button returned of (display dialog "MusiNotify currently " & RemoveEnabled & " notifications in the sidebar when iTunes or Spotify quit." & return & return & "Would you like the notifications to be cleared after quitting?" buttons {"Cancel", "Yes", "No"} with title "MusiNotify Preferences")
	if q6 is "Yes" and removeon = "0" then
		changepref("RemoveOnQuit", "1")
	else if q6 is "No" and removeon = "1" then
		changepref("RemoveOnQuit", "0")
	end if
end RemoveOnQuit