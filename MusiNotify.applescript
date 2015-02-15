global DispArt, DispAlb, NumOfNot, RemoveOnQuit, sid, iid, x, y, Notif, thanked, preffile, spotgroups, Itungroups, CurrentAppVersion, spotinotify, itunotify

try
	CheckSystemVersion() -- Check to make sure that the user is running OS X 10.8
	set preffile to "com.BenB116.MusiNotify.plist"
	set CurrentAppVersion to "4.7.1"
end try
try
	if not CheckPrefFile() then FirstPrefSetup() -- If the preference fle doesn't exist, then make one and do a first-run setup
	InitialSetup() -- Set up variables
end try

repeat -- Main Loop
	ReadPrefs() -- Read preference value
	
	try
		delay 0.5
		tell application "System Events"
			set applist to (name of every process) -- See which apps are running
		end tell
	end try
	if applist contains "Spotify" or applist contains "iTunes" then
		if applist contains "Spotify" and spotinotify = "1" then -- If Spotify is running and notifications are enabled...
			CheckSpotify() -- Check if the song has changed
		else
			if applist does not contain "Spotify" and RemoveOnQuit = "1" and (count of spotgroups) is not equal to 0 then -- If app isn't running, RemoveOnQuit is set to 1, and there are notifications in the sidebar then...
				repeat with a in spotgroups
					do shell script quoted form of Notif & " -remove SP" & a -- Remove notifications
				end repeat
				set spotgroups to {} -- Clear the list
				do shell script "defaults write " & preffile & " 'SpotifyCurrentGroups' ''" -- Clear the list in the preffile
				set sid to "" -- Reset
				do shell script "defaults write " & preffile & " 'SpotLast' '" & sid & "'" -- Reset
			end if
		end if
		if applist contains "iTunes" and itunotify = "1" then -- If iTunes is running and notifications are enabled...
			CheckiTunes() -- Check if the song has changed
		else
			if applist does not contain "iTunes" and RemoveOnQuit = "1" and (count of Itungroups) is not equal to 0 then -- If app isn't running, RemoveOnQuit is set to 1, and there are notifications in the sidebar then...
				repeat with b in Itungroups
					do shell script quoted form of Notif & " -remove IT" & b -- Remove notifications
				end repeat
				set Itungroups to {} -- Clear the list
				do shell script "defaults write " & preffile & " 'iTunesCurrentGroups' ''" -- Clear the list in the preffile
				set iid to "" -- Reset
				do shell script "defaults write " & preffile & " 'iTuLast' '" & iid & "'" -- Reset
			end if
		end if
	else -- If neither app is running...
		delay 2 -- Larger delay to reduce CPU usage
	end if
end repeat

on CheckSystemVersion()
	try
		set vers to (do shell script "sw_vers -productVersion | cut -d '.' -f 2") as number -- Get Version of OS X
		if vers is less than 8 then -- If user is not running 10.8 or 10.9...
			display dialog "Sorry. This app requires OSX 10.8+" buttons ("OK") with icon (path to resource "applet.icns") -- Display explanation
			KillMusiNotify() -- Quit
		end if
	on error msg
		display dialog "CheckSystemVersion - " & msg with title "Error - MusiNotify" with icon (path to resource "applet.icns")
		return
	end try
end CheckSystemVersion

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
		do shell script "defaults write " & preffile & " 'SpotiNotify' '1' | defaults write " & preffile & " 'iTuNotify' '1' | defaults write " & preffile & " 'DispArt' '1' | defaults write " & preffile & " 'DispAlb' '0' | defaults write " & preffile & " 'NumOfNot' '3' | defaults write " & preffile & " 'RemoveOnQuit' '1' | defaults write " & preffile & " 'AutoUpdate' '1'"
		
		set ans to button returned of (display dialog Â
			"Would you like to set this app as a login item?" buttons {"No", "Yes"} default button 2 Â
			with title "MusiNotify" with icon (path to resource "applet.icns")) -- Ask whether to set a login item
		if ans = "Yes" then
			set mypath to (POSIX path of (path to me))
			tell application "System Events" to make login item at end with properties {path:mypath} -- Add to login items
		end if
		
		try
			iTunes11dot1() -- Check if running iTunes 11.1
		end try
		
		try
			set prefreso to quoted form of (POSIX path of (path to me) & "Contents/Resources/MusiNotify Preferences.scpt")
			do shell script "cp " & prefreso & " ~/Library/Scripts/" -- Install the preference script
		end try
		
		display dialog Â
			"You're all set! Play a song in iTunes or Spotify to test it out." buttons {"Awesome!"} default button 1 Â
			with title "MusiNotify" with icon (path to resource "applet.icns") Â
			giving up after 5 -- Finish message
		
	on error msg
		display dialog "FirstPrefSetup - " & msg with title "Error - MusiNotify" with icon (path to resource "applet.icns")
		KillMusiNotify()
	end try
end FirstPrefSetup

on InitialSetup()
	try
		-- Define variables
		set x to 0
		set y to 0
		set Notif to (POSIX path of (path to me)) & "Contents/Resources/terminal-notifier.app/Contents/MacOS/terminal-notifier"
		set sid to ""
		set iid to ""
		set rawlines to paragraphs of (do shell script "defaults read " & preffile)
		repeat with lin in rawlines
			if lin contains "AutoUpdate" then set autoupdatepref to (characters 17 thru -2 of lin) as text
			if lin contains "SpotLast" then
				try
					set sid to (characters 17 thru -3 of lin) as text
				on error
					set sid to ""
				end try
			end if
			if lin contains "iTunLast" then
				try
					set iid to (characters 16 thru -2 of lin) as text
				on error
					set iid to ""
				end try
			end if
		end repeat
		try
			do shell script "defaults write " & preffile & " 'CurrentAppVersion' '" & CurrentAppVersion & "'"
			if autoupdatepref = "1" then -- If auto-updating is enabled
				do shell script "open " & POSIX path of (path to me) & quoted form of ("Contents/Resources/MusiNotify Updater.app") -- Run Update Checker
			end if
		end try
		
		try
			set previousspotgroups to do shell script "defaults read " & preffile & " 'SpotifyCurrentGroups'" -- Read previous groups from preffile
			set newgrop to paragraphs -2 thru 2 of previousspotgroups as list
			set spotgroups to {}
			repeat with t in newgrop
				set newraw to do shell script "echo " & t & " | cut -d ',' -f 1"
				set end of spotgroups to (newraw as integer)
			end repeat
			set spotgroups to (items 1 thru -2 of spotgroups) -- Format groups and add to list
		on error
			set spotgroups to {}
		end try
		try
			set previousitungroups to do shell script "defaults read " & preffile & " 'iTunesCurrentGroups'" -- Read previous groups from preffile
			set newgrop to paragraphs 2 thru -2 of previousitungroups as list
			set Itungroups to {}
			repeat with t in newgrop
				set newraw to do shell script "echo " & t & " | cut -d ',' -f 1"
				set end of Itungroups to (newraw as integer)
			end repeat
			set Itungroups to (items 2 thru -1 of Itungroups) -- Format groups and add to list
		on error
			set Itungroups to {}
		end try
		
		try
			iTunes11dot1() -- Check for iTunes 11.1
		end try
	on error msg
		display dialog "InitialSetup - " & msg with title "Error - MusiNotify" with icon (path to resource "applet.icns")
		KillMusiNotify()
	end try
end InitialSetup

on ReadPrefs()
	try
		-- Read current preference values from preffile
		set rawlines to paragraphs of (do shell script "defaults read " & preffile)
		repeat with lin in rawlines
			if lin contains "spotinotify" then set spotinotify to (characters 19 thru -2 of lin) as text
			if lin contains "itunotify" then set itunotify to (characters 17 thru -2 of lin) as text
			if lin contains "numofnot" then set NumOfNot to (characters 16 thru -2 of lin) as text
			if lin contains "removeonquit" then set RemoveOnQuit to (characters 20 thru -2 of lin) as text
			if lin contains "dispart" then set DispArt to (characters 15 thru -2 of lin) as text
			if lin contains "dispalb" then set DispAlb to (characters 15 thru -2 of lin) as text
		end repeat
	on error msg
		try
			display dialog Â
				Â
					"It looks like something's wrong with your preference file. Click \"Reset\" to reset it." buttons {"Quit", "Reset Preferences"} default button 2 Â
				with title "Error - MusiNotify" with icon (path to resource "applet.icns")
			if button returned of result is "Reset Preferences" then
				try
					do shell script "rm ~/Library/Preferences/" & preffile
				end try
				FirstPrefSetup()
			else
				KillMusiNotify()
			end if
		on error
			display dialog "ReadPrefs - " & msg with title "Error - MusiNotify" with icon (path to resource "applet.icns")
			KillMusiNotify()
		end try
	end try
end ReadPrefs

on CheckSpotify()
	try
		tell application "/Applications/Spotify.app"
			with timeout of 1 second
				-- Get Track info
				set strk to name of current track
				set tart to artist of current track
				set talb to album of current track
				set tid to id of current track
			end timeout
		end tell
		if talb does not contain "http" and talb does not contain "spotify:" then -- If the track is not an ad...
			if tid is not equal to sid then -- If track has changed...
				try
					-- Format artist and album					
					set sart to " "
					if DispArt = "1" and tart is not equal to "" then set sart to "By " & tart
					set salb to " "
					if DispAlb = "1" and talb is not equal to "" then set salb to "On " & talb
					
					set theID to SpotDet() -- Get the ID
					set xid to "-group SP" & theID as text
					
					do shell script quoted form of Notif & Â
						" -title " & (quoted form of strk) & Â
						" -subtitle " & (quoted form of sart) & Â
						" -message " & (quoted form of salb) & Â
						" -sender 'com.Spotify.client' " & xid & Â
						" -activate com.Spotify.client" -- Display the notification
					
					if NumOfNot = "0" then -- If the user does not want notifications in the sidebar...
						try
							repeat with a in spotgroups
								do shell script quoted form of Notif & " -sender 'com.spotify.client' -remove SP" & a -- Remove previous notifications
							end repeat
							set spotgroups to {} -- Clear list
						end try
						do shell script quoted form of Notif & " -sender 'com.spotify.client' -remove SP0" -- Remove last notification
					end if
					log spotgroups
					set Formspotgroups to ""
					repeat with z in spotgroups
						set Formspotgroups to Formspotgroups & ((z as text) & ", ")
					end repeat
					do shell script "defaults write " & preffile & " 'SpotifyCurrentGroups' '(" & Formspotgroups & ")' | defaults write " & preffile & " 'SpotLast' '" & tid & "'" -- Remove records
					set sid to tid
				end try
			end if
		end if
	end try
end CheckSpotify

on SpotDet()
	try
		if NumOfNot = "0" then -- If the user does not want notifications in the sidebar...
			return 0
		else
			if (count of spotgroups) = NumOfNot as integer then -- If sidebar is "full"
				set x to last item of spotgroups -- Use the oldest group
				try
					set spotgroups to (items 1 thru -2 of spotgroups)
				on error
					set spotgroups to {}
				end try
			else if (count of spotgroups) < NumOfNot as integer then -- If sidebar is not "full"
				repeat
					set x to x + 1
					if spotgroups does not contain x then exit repeat -- make a new group
				end repeat
			else if (count of spotgroups) > NumOfNot as integer then -- If sidebar is "over-filled"
				repeat with a from NumOfNot + 1 to (count of spotgroups)
					do shell script Notif & " -sender 'com.spotify.client' -remove SP" & (item a of spotgroups) -- Remove extra notifications
				end repeat
				set spotgroups to (items 1 thru NumOfNot of spotgroups)
				set x to last item of spotgroups -- Use the oldest group
				try
					set spotgroups to (items 1 thru -2 of spotgroups)
				on error
					set spotgroups to {}
				end try
			end if
			set beginning of spotgroups to x -- Update group list
			
			return (first item of spotgroups) as integer
		end if
	on error msg
		display dialog "SpotDet - " & msg with title "Error - MusiNotify" with icon (path to resource "applet.icns")
		KillMusiNotify()
	end try
end SpotDet

on CheckiTunes()
	try
		with timeout of 1 second
			tell application "iTunes"
				-- Get Track info
				set itrk to name of current track
				set tart to artist of current track
				set talb to album of current track
				set tid to persistent ID of current track
			end tell
		end timeout
		if tid is not equal to iid then -- If track has changed...
			try
				-- Format artist and album
				set iart to " "
				if DispArt = "1" and tart is not equal to "" then set iart to "By " & tart
				set ialb to " "
				if DispAlb = "1" and talb is not equal to "" then set ialb to "On " & talb
				
				set theID to ItunDet() -- Get the ID
				set yid to "-group IT" & theID as text
				
				do shell script quoted form of Notif & Â
					" -title " & (quoted form of itrk) & Â
					" -subtitle " & (quoted form of iart) & Â
					" -message " & (quoted form of ialb) & Â
					" -sender 'com.apple.iTunes' " & yid & Â
					" -activate com.apple.iTunes" -- Display the notification
				
				if NumOfNot = "0" then -- If the user does not want notifications in the sidebar...
					try
						repeat with b in Itungroups
							do shell script quoted form of Notif & " -sender 'com.apple.iTunes' -remove IT" & b -- Remove previous notifications
						end repeat
						set Itungroups to {} -- Clear list
					end try
					do shell script quoted form of Notif & " -sender 'com.apple.iTunes' -remove IT0" -- Remove last notification
				end if
				
				set Formitungroups to ""
				repeat with z in Itungroups
					set Formitungroups to Formitungroups & ((z as text) & ", ")
				end repeat
				do shell script "defaults write com.benb116.musinotify.plist 'iTunesCurrentGroups' '(" & Formitungroups & ")' | defaults write " & preffile & " 'iTunLast' '" & tid & "'" -- Remove records
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
					do shell script quoted form of Notif & " -sender 'com.apple.iTunes' -remove IT" & (item b of Itungroups)
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
			
			return (first item of Itungroups) as integer
		end if
	on error msg
		display dialog "iTunDet - " & msg with title "Error - MusiNotify" with icon (path to resource "applet.icns")
		KillMusiNotify()
	end try
end ItunDet

on KillMusiNotify()
	try -- Kill MusiNotify
		tell application "System Events"
			set theID to (unix id of processes whose name is "MusiNotify") -- Find process ID
			do shell script "kill -9 " & theID -- Kill
		end tell
	end try
end KillMusiNotify

on iTunes11dot1()
	try -- Check current iTunes version
		try
			set asked to (do shell script "defaults read " & preffile & " '11.1_Ask'") -- Has the user been asked before?
		on error
			set asked to "0"
		end try
		if asked is not equal to "1" then
			set currentiTunesversion to (do shell script "defaults read /Applications/iTunes.app/Contents/Info.plist 'CFBundleShortVersionString'") -- Determine current iTunes version
			set currentiTunesversion to (characters 1 thru 4 of currentiTunesversion) as string
			log (currentiTunesversion)
			if (currentiTunesversion as number) is greater than or equal to 11.1 then -- Version 11.1 and up have built-in notifications
				set iTuneschoice to button returned of (display dialog Â
					"Hi there, it looks like you're using a version of iTunes has notifications built in, so you don't NEED to use MusiNotify. However, MusiNotify allows for more customization and control over your notifications." & return & return & Â
					"Would you like to use MusiNotify for iTunes?" buttons {"Don't use MusiNotify for iTunes", "Use MusiNotify for iTunes"} default button 2 Â
					with title "MusiNotify" with icon (path to resource "applet.icns")) -- Display message
				if iTuneschoice = "Don't use MusiNotify for iTunes" then
					do shell script "defaults write " & preffile & " 'iTuNotify' '0'" -- Record choice
				end if
				do shell script "defaults write " & preffile & " '11.1_Ask' '1'" -- Record that the user was asked
			end if
		end if
	end try
end iTunes11dot1