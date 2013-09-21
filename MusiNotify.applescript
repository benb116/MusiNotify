global DispArt, DispAlb, NumOfNot, RemoveOnQuit, sid, iid, x, y, NPSP, NPIT, thanked, preffile, spotgroups, Itungroups, CurrentAppVersion, spotinotify, itunotify

try
	CheckSystemVersion() -- Check to make sure that the user is running OS X 10.8
	set preffile to "com.BenB116.MusiNotify.plist"
	set CurrentAppVersion to "4.4.7"
	
	UpdateCheck() -- Check for updates
end try
try
	if not CheckPrefFile() then FirstPrefSetup() -- If the preference fle doesn't exist, then make one and do a first-run setup
	
	InitialSetup() -- Set up variables
end try

repeat -- Main Loop
	delay 2
	try
		ReadPrefs() -- Read preference values
		tell application "System Events" to set applist to (name of every process whose background only = false) -- See which apps are running
		if applist contains "Spotify" and spotinotify = "1" then
			CheckSpotify() -- Check if the song has changed
		else
			if RemoveOnQuit = "1" and (count of spotgroups) is not equal to 0 then -- If app isn't running and RemoveOnQuit is set to 1 then...
				repeat with a in spotgroups
					do shell script quoted form of NPSP & " -remove SP" & a -- Remove notifications
				end repeat
				set spotgroups to {} -- Clear
				do shell script "defaults write com.BenB116.MusiNotify.plist 'SpotifyCurrentGroups' ''"
			end if
			set sid to ""
		end if
		if applist contains "iTunes" and itunotify = "1" then
			CheckiTunes() -- Check if the song has changed
		else
			if RemoveOnQuit = "1" and (count of Itungroups) is not equal to 0 then -- If app isn't running and RemoveOnQuit is set to 1 then...
				repeat with b in Itungroups
					do shell script quoted form of NPIT & " -remove IT" & b -- Remove notifications
				end repeat
				set Itungroups to {} -- Clear
				do shell script "defaults write com.BenB116.MusiNotify.plist 'iTunesCurrentGroups' ''"
			end if
			set iid to ""
		end if
	end try
end repeat

on CheckSystemVersion()
	try
		set vers to (do shell script "sw_vers -productVersion") -- Get Version of OS X
		set pte to (do shell script "echo " & vers & " | cut -d '.' -f 1-2")
		if pte is not equal to "10.8" then
			display dialog "Sorry. This app requires OSX 10.8+" buttons ("OK") with icon (path to resource "applet.icns")
			KillMusiNotify()
		end if
	on error msg
		display dialog "CheckSystemVersion - " & msg with title "Error - MusiNotify" with icon (path to resource "applet.icns")
		return
	end try
end CheckSystemVersion

on UpdateCheck()
	try
		set raw to (do shell script "curl http://raw.github.com/benb116/MusiNotify/master/Version.txt")
		set LatestVersion to first paragraph of raw -- Get latest version
		
		if LatestVersion is not equal to CurrentAppVersion then
			set Featlist to ""
			try -- Get new feature list
				set NewFeats to paragraphs 2 thru -1 of raw
				repeat with feat in NewFeats
					set Featlist to Featlist & feat & return
				end repeat
			on error
				set Featlist to ""
			end try
			
			set UpdateQ to button returned of (display dialog "MusiNotify " & LatestVersion & " is available for update." & return & return & Featlist with title "MusiNotify - Update" buttons {"Don't Update", "Update"} default button 2 with icon (path to resource "applet.icns"))
			if UpdateQ = "Update" then
				try
					do shell script "cd ~/Library; curl -O https://raw.github.com/benb116/MusiNotify/master/MusiNotify.app.zip; unzip MusiNotify.app.zip" -- Download new app and unzip
					set currentpath to do shell script "dirname " & (POSIX path of "/Applications/MusiNotify.app")
					set currentpath to currentpath & "/"
					do shell script "cp -rf ~/Library/MusiNotify.app " & currentpath -- Replace the old app
					do shell script "cp -f " & currentpath & "Contents/Resources/MusiNotify Preferences.scpt ~/Library/Scripts/MusiNotify Preferences.scpt"
					try
						do shell script "rm ~/Library/MusiNotify.app.zip; rm -rf ~/Library/__MACOSX; rm -rf ~/Library/MusiNotify.app" -- Get rid of extra files
					end try
					display dialog "Update complete. Restart MusiNotify for the changes to take effect." buttons ("Restart") default button 1 with icon (path to resource "applet.icns") with title "MusiNotify - Update"
					
					set the_pid to (do shell script "ps ax | grep " & currentpath & "MusiNotify.app | grep -v grep | awk '{print $1}'")
					if the_pid is not "" then do shell script ("kill -9 " & the_pid & "; open " & (currentpath & "/MusiNotify.app")) -- Restart
				on error
					try
						do shell script "rm ~/Library/MusiNotify.app.zip"
					end try
					try
						do shell script "rm -rf ~/Library/__MACOSX"
					end try
					try
						do shell script "rm -rf ~/Library/MusiNotify.app"
					end try
				end try
			end if
		end if
	on error
		display dialog "UpdateCheck - " & msg with title "Error - MusiNotify" with icon (path to resource "applet.icns")
	end try
end UpdateCheck

on CheckPrefFile()
	try
		set prefFilePath to "~/Library/Preferences/" & preffile
		repeat
			tell application "System Events"
				if exists file prefFilePath then -- Does the pref file exist?
					return true
				else
					return false
				end if
			end tell
			exit repeat
		end repeat
	on error msg
		display dialog "CheckPrefFile - " & msg with title "Error - MusiNotify" with icon (path to resource "applet.icns")
		KillMusiNotify()
	end try
end CheckPrefFile

on FirstPrefSetup()
	try
		do shell script "touch ~/Library/Preferences/" & preffile -- Make the pref file
		
		-- Set initial settings
		do shell script "defaults write " & preffile & " 'SpotiNotify' '1'"
		do shell script "defaults write " & preffile & " 'iTuNotify' '1'"
		
		try -- Check current iTunes version
			set currentiTunesversion to (do shell script "defaults read /Applications/iTunes.app/Contents/Info.plist 'CFBundleShortVersionString'")
			if currentiTunesversion contains "11.1" then -- Version 11.1 has built-in notifications
				set iTuneschoice to button returned of (display dialog Â
					"Hi there, it looks like you're using iTunes 11.1. " & return & return & Â
					"This version of iTunes has notifications built in, so you don't NEED to use MusiNotify. However, MusiNotify is much more customizable and (in the opinion of the developer) better." & return & return & Â
					"Would you like to use MusiNotify for iTunes?" buttons {"Don't use MusiNotify for iTunes", "Use MusiNotify for iTunes"} default button 2)
				if iTuneschoice = "Don't use MusiNotify for iTunes" then
					do shell script "defaults write " & preffile & " 'iTuNotify' '0'"
				end if
			end if
		end try
		
		do shell script "defaults write " & preffile & " 'login' '0'"
		set ans to button returned of (display dialog "Would you like to set this app as a login item?" buttons {"No", "Yes"} default button 2 with title "MusiNotify" with icon (path to resource "applet.icns"))
		if ans = "Yes" then
			do shell script "defaults write " & preffile & " 'login' '1'"
			set mypath to (POSIX path of (path to me))
			tell application "System Events" to make login item at end with properties {path:mypath, kind:application} -- Add to login items
		end if
		do shell script "defaults write " & preffile & " 'DispArt' '1'"
		do shell script "defaults write " & preffile & " 'DispAlb' '0'"
		do shell script "defaults write " & preffile & " 'NumOfNot' '3'"
		do shell script "defaults write " & preffile & " 'RemoveOnQuit' '1'"
		try
			set prefreso to (POSIX path of (path to me) & "Contents/Resources/MusiNotify Preferences.scpt")
			do shell script "cp " & prefreso & " ~/Library/Scripts/" -- Install the preference script
		end try
		-- Run the notifiers to reset their icons
		try
			do shell script quoted form of ((POSIX path of (path to me)) & "Contents/Resources/MusiNotify - iTunes.app/Contents/MacOS/MusiNotify - iTunes")
		end try
		try
			do shell script quoted form of ((POSIX path of (path to me)) & "Contents/Resources/MusiNotify - Spotify.app/Contents/MacOS/MusiNotify - Spotify")
		end try
	on error msg
		display dialog "FirstPrefSetup - " & msg with title "Error - MusiNotify" with icon (path to resource "applet.icns")
		KillMusiNotify()
	end try
end FirstPrefSetup

on InitialSetup()
	try
		do shell script "defaults write " & preffile & " 'loginPath' '" & (POSIX path of (path to me)) & "'" -- Update login path
	end try
	try
		set sid to ""
		set iid to ""
		set x to 0
		set y to 0
		
		try
			set previousspotgroups to do shell script "defaults read " & preffile & " 'SpotifyCurrentGroups'" -- Read Previous Notifications
			set newgrop to paragraphs 2 thru -2 of previousspotgroups as list
			set spotgroups to {}
			repeat with t in newgrop
				set newraw to do shell script "echo '" & y & "' | cut -d ' ' -f 5 | cut -d ',' -f 1"
				set end of spotgroups to (newraw as integer)
			end repeat
		on error
			set spotgroups to {}
		end try
		
		try
			set previousitungroups to do shell script "defaults read " & preffile & " 'iTunesCurrentGroups'"
			set newgrop to paragraphs 2 thru -2 of previousitungroups as list
			set Itungroups to {}
			repeat with t in newgrop
				set newraw to do shell script "echo '" & y & "' | cut -d ' ' -f 5 | cut -d ',' -f 1"
				set end of Itungroups to (newraw as integer)
			end repeat
		on error
			set Itungroups to {}
		end try
		
		set NPIT to (POSIX path of (path to me)) & "Contents/Resources/MusiNotify - iTunes .app/Contents/MacOS/MusiNotify - iTunes"
		set NPSP to (POSIX path of (path to me)) & "/Contents/Resources/MusiNotify - Spotify.app/Contents/MacOS/MusiNotify - Spotify"
	on error msg
		display dialog "InitialSetup - " & msg with title "Error - MusiNotify" with icon (path to resource "applet.icns")
		KillMusiNotify()
	end try
end InitialSetup

on ReadPrefs()
	try
		set spotinotify to (do shell script "defaults read " & preffile & " 'SpotiNotify'")
		set itunotify to (do shell script "defaults read " & preffile & " 'iTuNotify'")
		set DispArt to (do shell script "defaults read " & preffile & " 'DispArt'")
		set DispAlb to (do shell script "defaults read " & preffile & " 'DispAlb'")
		set NumOfNot to (do shell script "defaults read " & preffile & " 'NumOfNot'")
		set RemoveOnQuit to (do shell script "defaults read " & preffile & " 'RemoveOnQuit'")
	on error msg
		display dialog "ReadPrefs - " & msg with title "Error - MusiNotify" with icon (path to resource "applet.icns")
		KillMusiNotify()
	end try
end ReadPrefs

on CheckSpotify()
	try
		tell application "Spotify"
			-- Get Track info
			set strk to name of current track
			set tart to artist of current track
			set talb to album of current track
			set tid to id of current track
		end tell
		if talb does not contain "http" and talb does not contain "spotify:" then -- If the track is not an ad...
			set thanked to false
			if tid is not equal to sid then -- If track has changed...
				try
					set sart to " "
					if DispArt = "1" and tart is not equal to "" then set sart to "By " & tart
					set salb to " "
					if DispAlb = "1" and talb is not equal to "" then set salb to "On " & talb
					
					set theid to SpotDet() -- Get the ID
					set xid to "-group SP" & theid as text
					
					do shell script quoted form of NPSP & " -title " & (quoted form of strk) & " -subtitle " & (quoted form of sart) & " -message " & (quoted form of salb) & " " & xid & " -execute 'open /Applications/Spotify.app'" -- Display the notification
					if NumOfNot = "0" then
						try
							repeat with a in spotgroups
								do shell script quoted form of NPSP & " -remove SP" & a -- Remove notifications
							end repeat
							set spotgroups to {} -- Clear
						end try
						do shell script quoted form of NPSP & " -remove SP0"
					end if
					
					set Formspotgroups to ""
					repeat with z in spotgroups
						set Formspotgroups to Formspotgroups & ((z as text) & ", ")
					end repeat
					do shell script "defaults write com.benb116.musinotify.plist 'SpotifyCurrentGroups' '(" & Formspotgroups & ")'" -- Record Current Groups
					
					set sid to tid
				end try
			end if
		else
			try
				if thanked is false then
					do shell script quoted form of NPSP & " -title " & (quoted form of "Thanks for using MusiNotify!") & " -subtitle " & (quoted form of "You're awesome!") & " -message \"\" -group TH -open " & quoted form of ("https://github.com/benb116/MusiNotify")
					set thanked to true
					do shell script quoted form of NPSP & " -remove TH"
				end if
			end try
		end if
	end try
end CheckSpotify

on SpotDet()
	try
		if NumOfNot = "0" then
			return 0
		else
			if (count of spotgroups) = NumOfNot as integer then -- If full
				set x to last item of spotgroups
				try
					set spotgroups to (items 1 thru -2 of spotgroups)
				on error
					set spotgroups to {}
				end try
			else if (count of spotgroups) < NumOfNot as integer then -- If not full
				repeat
					set x to x + 1
					if spotgroups does not contain x then exit repeat
				end repeat
			else if (count of spotgroups) > NumOfNot as integer then -- If over-filled
				repeat with a from NumOfNot + 1 to (count of spotgroups)
					do shell script quoted form of NPSP & " -remove SP" & (item a of spotgroups)
				end repeat
				set spotgroups to (items 1 thru NumOfNot of spotgroups)
				set x to last item of spotgroups
				try
					set spotgroups to (items 1 thru -2 of spotgroups)
				on error
					set spotgroups to {}
				end try
			end if
			set beginning of spotgroups to x
			
			return (first item of spotgroups) as integer
		end if
	on error msg
		display dialog "SpotDet - " & msg with title "Error - MusiNotify" with icon (path to resource "applet.icns")
		KillMusiNotify()
	end try
end SpotDet

on CheckiTunes()
	try
		tell application "iTunes"
			-- Get Track info
			set itrk to name of current track
			set tart to artist of current track
			set talb to album of current track
			set tid to id of current track
		end tell
		if tid is not equal to iid then -- If track has changed...
			try
				set iart to " "
				if DispArt = "1" and tart is not equal to "" then set iart to "By " & tart
				set ialb to " "
				if DispAlb = "1" and talb is not equal to "" then set ialb to "On " & talb
				
				set theid to ItunDet() -- Get the ID
				set yid to "-group IT" & theid as text
				
				do shell script quoted form of NPIT & " -title " & (quoted form of itrk) & " -subtitle " & (quoted form of iart) & " -message " & (quoted form of ialb) & " " & yid & " -execute 'open /Applications/iTunes.app'" -- Display the notification
				if NumOfNot = "0" then
					try
						repeat with b in Itungroups
							do shell script quoted form of NPIT & " -remove IT" & b -- Remove notifications
						end repeat
						set Itungroups to {} -- Clear
					end try
					do shell script quoted form of NPIT & " -remove IT0"
				end if
				
				set Formitungroups to ""
				repeat with z in Itungroups
					set Formitungroups to Formitungroups & ((z as text) & ", ")
				end repeat
				do shell script "defaults write com.benb116.musinotify.plist 'iTunesCurrentGroups' '(" & Formitungroups & ")'" -- Record Current Groups
				
				set iid to tid
			end try
		end if
	end try
end CheckiTunes

on ItunDet()
	try
		-- Same as SpotDet(), converted to iTunes
		if NumOfNot = "0" then
			return 0
		else
			if (count of Itungroups) = NumOfNot as integer then
				set y to last item of Itungroups
				try
					set Itungroups to (items 1 thru -2 of Itungroups)
				on error
					set Itungroups to {}
				end try
			else if (count of Itungroups) < NumOfNot as integer then
				repeat
					set y to y + 1
					if Itungroups does not contain y then exit repeat
				end repeat
			else if (count of Itungroups) > NumOfNot as integer then
				repeat with b from NumOfNot + 1 to (count of Itungroups)
					do shell script quoted form of NPIT & " -remove IT" & (item b of Itungroups)
				end repeat
				set Itungroups to (items 1 thru NumOfNot of Itungroups)
				set y to last item of Itungroups
				try
					set Itungroups to (items 1 thru -2 of Itungroups)
				on error
					set Itungroups to {}
				end try
			end if
			set beginning of Itungroups to y
			
			set Formitungroups to ""
			repeat with z in Itungroups
				set Formitungroups to Formitungroups & ((z as text) & ", ")
			end repeat
			do shell script "defaults write com.benb116.musinotify.plist 'iTunesCurrentGroups' '(" & Formitungroups & ")'"
			
			return (first item of Itungroups) as integer
		end if
	on error msg
		display dialog "iTunDet - " & msg with title "Error - MusiNotify" with icon (path to resource "applet.icns")
		KillMusiNotify()
	end try
end ItunDet

on KillMusiNotify()
	try -- Kill MusiNotify
		set the_pid to (do shell script "ps ax | grep " & (quoted form of (POSIX path of (path to me))) & " | grep -v grep | awk '{print $1}'")
		if the_pid is not "" then do shell script ("kill -9 " & the_pid)
	end try
end KillMusiNotify