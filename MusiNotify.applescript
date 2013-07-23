global DispArt, DispAlb, NumOfNot, RemoveOnQuit, sid, iid, x, y, NPSP, NPIT, thanked, preffile, spotgroups, Itungroups, CurrentAppVersion

try
	CheckSystemVersion() -- Check to make sure that the user is running OSX 10.8
	set preffile to "com.BenB116.MusiNotify.plist"
	set CurrentAppVersion to "4.4.1"
	
	UpdateCheck()
	
	if not CheckPrefFile() then FirstPrefSetup() -- If the preference fle doesn't exist, then make one and do a first-run setup
	
	InitialSetup() -- Set up variables
end try

repeat
	delay 0.2
	try
		ReadPrefs() -- Read preference values
		tell application "System Events" to set applist to (name of every process whose background only = false) -- See which apps are running
		if applist contains "Spotify" then
			CheckSpotify() -- Check if the song has changed
		else
			if RemoveOnQuit = "1" then -- If app isn't running and RemoveOnQuit is set to 1 then...
				repeat with a in spotgroups
					RemoveSpotify(a) -- Remove notifications
				end repeat
				set spotgroups to {} -- Clear
			end if
		end if
		if applist contains "iTunes" then
			CheckiTunes() -- Check if the song has changed
		else
			if RemoveOnQuit = "1" then -- If app isn't running and RemoveOnQuit is set to 1 then...
				repeat with b in Itungroups
					RemoveiTunes(b) -- Remove notifications
				end repeat
				set Itungroups to {} -- Clear
			end if
		end if
	end try
end repeat

on CheckSystemVersion()
	try
		set vers to (do shell script "sw_vers -productVersion")
		set pte to (do shell script "echo " & vers & " | cut -d '.' -f 1-2")
		if pte is not equal to "10.8" then
			display dialog "Sorry. This app requires OSX 10.8+" buttons ("OK") with icon (path to resource "applet.icns")
			try
				set the_pid to (do shell script "ps ax | grep " & (quoted form of (POSIX path of (path to me))) & " | grep -v grep | awk '{print $1}'")
				if the_pid is not "" then do shell script ("kill -9 " & the_pid)
			end try
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
				if exists file prefFilePath then
					return true
				else
					return false
				end if
			end tell
			exit repeat
		end repeat
	on error msg
		display dialog "CheckPrefFile - " & msg with title "Error - MusiNotify" with icon (path to resource "applet.icns")
		return
	end try
end CheckPrefFile

on UpdateCheck()
	try
		set CurrentAppVersion to do shell script "defaults read " & preffile & " 'AppVersion'"
		set currentpath to do shell script "dirname " & (POSIX path of "/Applications/MusiNotify.app")
		set currentpath to currentpath & "/"
		set raw to (do shell script "curl benbern.dyndns.info/MusiNotify/Version.txt")
		set LatestVersion to first paragraph of raw
		
		if LatestVersion ­ CurrentAppVersion then
			set Featlist to ""
			try
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
					do shell script "cd ~/Library; curl -O https://raw.github.com/benb116/MusiNotify/master/MusiNotify.app.zip; unzip MusiNotify.app.zip"
					do shell script "cp -rf ~/Library/MusiNotify.app " & currentpath
					try
						do shell script "rm ~/Library/MusiNotify.app.zip; rm -rf ~/Library/__MACOSX; rm -rf ~/Library/MusiNotify.app"
					end try
					do shell script "defaults write " & preffile & " 'AppVersion' '" & LatestVersion & "'"
					display dialog "Update complete. Restart MusiNotify for the changes to take effect." buttons ("Restart") default button 1 with icon (path to resource "applet.icns") with title "MusiNotify - Update"
					
					set the_pid to (do shell script "ps ax | grep " & currentpath & "MusiNotify.app | grep -v grep | awk '{print $1}'")
					if the_pid is not "" then do shell script ("kill -9 " & the_pid & "; open " & (currentpath & "/MusiNotify.app"))
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

on FirstPrefSetup()
	try
		do shell script "touch ~/Library/Preferences/" & preffile
		
		-- Set initial settings
		do shell script "defaults write " & preffile & " 'login' '0'"
		set ans to button returned of (display dialog "Would you like to set this app as a login item?" buttons {"No", "Yes"} default button 2 with title "MusiNotify" with icon (path to resource "applet.icns"))
		if ans = "Yes" then
			do shell script "defaults write " & preffile & " 'login' '1'"
			set mypath to (POSIX path of (path to me))
			tell application "System Events" to make login item at end with properties {path:mypath, kind:application}
		end if
		do shell script "defaults write " & preffile & " 'DispArt' '1'"
		do shell script "defaults write " & preffile & " 'DispAlb' '0'"
		do shell script "defaults write " & preffile & " 'NumOfNot' '3'"
		do shell script "defaults write " & preffile & " 'RemoveOnQuit' '1'"
		do shell script "defaults write " & preffile & " 'AppVersion' '" & CurrentAppVersion & "'"
		
		-- Install the preference script
		try
			set prefreso to (POSIX path of (path to me) & "Contents/Resources/MusiNotify-Preferences.scpt")
			do shell script "cp " & prefreso & " ~/Library/Scripts/"
		end try
		try
			do shell script quoted form of ((POSIX path of (path to me)) & "Contents/Resources/MusiNotify - iTunes.app/Contents/MacOS/MusiNotify - iTunes")
		end try
		try
			do shell script quoted form of ((POSIX path of (path to me)) & "Contents/Resources/MusiNotify - Spotify.app/Contents/MacOS/MusiNotify - Spotify")
		end try
	on error msg
		display dialog "FirstPrefSetup - " & msg with title "Error - MusiNotify" with icon (path to resource "applet.icns")
		return
	end try
end FirstPrefSetup

on InitialSetup()
	try
		do shell script "defaults write " & preffile & " 'loginPath' '" & (POSIX path of (path to me)) & "'"
	end try
	try
		set sid to ""
		set iid to ""
		set x to 0
		set y to 0
		set spotgroups to {}
		set Itungroups to {}
		set NPIT to (POSIX path of (path to me)) & "/Contents/Resources/MusiNotify - iTunes.app/Contents/MacOS/MusiNotify - iTunes"
		set NPSP to (POSIX path of (path to me)) & "/Contents/Resources/MusiNotify - Spotify.app/Contents/MacOS/MusiNotify - Spotify"
	on error msg
		display dialog "InitialSetup - " & msg with title "Error - MusiNotify" with icon (path to resource "applet.icns")
		return
	end try
end InitialSetup

on ReadPrefs()
	try
		set DispArt to (do shell script "defaults read " & preffile & " 'DispArt'")
		set DispAlb to (do shell script "defaults read " & preffile & " 'DispAlb'")
		set NumOfNot to (do shell script "defaults read " & preffile & " 'NumOfNot'")
		set RemoveOnQuit to (do shell script "defaults read " & preffile & " 'RemoveOnQuit'")
	on error msg
		display dialog "ReadPrefs - " & msg with title "Error - MusiNotify" with icon (path to resource "applet.icns")
		return
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
				RemoveSpotify((item a of spotgroups))
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
	on error msg
		display dialog "SpotDet - " & msg with title "Error - MusiNotify" with icon (path to resource "applet.icns")
		return
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
				set iid to tid
			end try
		end if
	end try
end CheckiTunes

on ItunDet()
	try
		-- Same as SpotDet(), converted to iTunes
		if (count of Itungroups) = NumOfNot as integer then
			set y to last item of Itungroups
			try
				set Itungroups to (items 1 thru -2 of Itungroups)
			on error
				set Itungroups to {}
			end try
			log y
		else if (count of Itungroups) < NumOfNot as integer then
			repeat
				set y to y + 1
				if Itungroups does not contain y then exit repeat
			end repeat
		else if (count of Itungroups) > NumOfNot as integer then
			repeat with b from NumOfNot + 1 to (count of Itungroups)
				log b
				RemoveiTunes((item b of Itungroups))
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
		log Itungroups
		return (first item of Itungroups) as integer
	on error msg
		display dialog "iTunDet - " & msg with title "Error - MusiNotify" with icon (path to resource "applet.icns")
		return
	end try
end ItunDet

on RemoveSpotify(a)
	try
		if (count of spotgroups) ­ 0 then
			do shell script quoted form of NPSP & " -remove SP" & a
		end if
	on error msg
		display dialog "RemoveSpotify - " & msg with title "Error - MusiNotify" with icon (path to resource "applet.icns")
		return
	end try
end RemoveSpotify

on RemoveiTunes(b)
	try
		if (count of Itungroups) ­ 0 then
			do shell script quoted form of NPIT & " -remove IT" & b
		end if
	on error msg
		display dialog "RemoveiTunes - " & msg with title "Error - MusiNotify" with icon (path to resource "applet.icns")
		return
	end try
end RemoveiTunes