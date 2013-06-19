
global DispArt, DispAlb, NumOfNot, RemoveOnQuit, snme, inme, x, y, NPSP, NPIT, thanked, preffile, spotgroups, Itungroups

try
	CheckSystemVersion() -- Check to make sure that the user is running OSX 10.8
	set preffile to "com.BenB116.MusiNotify.plist"
	
	if not CheckPrefFile() then FirstPrefSetup() -- If the preference fle doesn't exist, then make one and do a first-run setup
	
	InitialSetup() -- Set up variables
end try
log "Checking..."
repeat
	delay 0.2
	try
		ReadPrefs() -- Read preference values
		tell application "System Events" to set applist to (name of every process whose background only = false) -- See which apps are running
		if applist contains "Spotify" then
			CheckSpotify() -- Check if the song has changed
		else
			if RemoveOnQuit = "1" then
				repeat with a in spotgroups
					RemoveSpotify(a) -- Remove notifications
				end repeat
				set spotgroups to {}
			end if
		end if
		if applist contains "iTunes" then
			CheckiTunes() -- Check if the song has changed
		else
			if RemoveOnQuit = "1" then
				repeat with b in Itungroups
					RemoveiTunes(b) -- Remove notifications
				end repeat
				set Itungroups to {}
			end if
		end if
	end try
end repeat

on CheckSystemVersion()
	set vers to (do shell script "sw_vers -productVersion")
	set pte to (do shell script "echo " & vers & " | cut -d '.' -f 1-2")
	if pte is not equal to "10.8" then
		display dialog "Sorry. This app requires OSX 10.8+" buttons ("OK")
		try
			set the_pid to (do shell script "ps ax | grep " & (quoted form of (POSIX path of (path to me))) & " | grep -v grep | awk '{print $1}'")
			if the_pid is not "" then do shell script ("kill -9 " & the_pid)
		end try
	end if
end CheckSystemVersion

on CheckPrefFile()
	try
		set prefFilePath to "~/Library/Preferences/" & preffile
		repeat
			try
				tell application "/System/Library/CoreServices/System Events.app"
					if exists file prefFilePath then
						return true
					else
						return false
					end if
				end tell
				exit repeat
			on error
				log "Trying for system events"
			end try
		end repeat
	end try
end CheckPrefFile

on FirstPrefSetup()
	try
		do shell script "touch ~/Library/Preferences/com.BenB116.MusiNotify.plist"
		-- Set initial settings
		do shell script "defaults write " & preffile & " 'login' '0'"
		set ans to button returned of (display dialog "Would you like to set this app as a login item?" buttons {"No", "Yes"} default button 2 with title "MusiNotify")
		if ans = "Yes" then
			do shell script "defaults write " & preffile & " 'login' '1'"
			AddToLogin((POSIX path of (path to me)))
		end if
		do shell script "defaults write " & preffile & " 'DispArt' '1'"
		do shell script "defaults write " & preffile & " 'DispAlb' '0'"
		do shell script "defaults write " & preffile & " 'NumOfNot' '3'"
		do shell script "defaults write " & preffile & " 'RemoveOnQuit' '1'"
		do shell script "defaults write " & preffile & " 'AppVersion' '4.3'"
		
		-- Install the preference script
		try
			set prefreso to (POSIX path of (path to me) & "Contents/Resources/MusiNotify-Preferences.scpt")
			do shell script "cp " & prefreso & " ~/Library/Scripts/"
		end try
	end try
end FirstPrefSetup

on AddToLogin(apppath)
	tell application "System Events" to make login item at end with properties {path:apppath, kind:application}
end AddToLogin

on InitialSetup()
	try
		do shell script "defaults write " & preffile & " 'loginPath' '" & (POSIX path of (path to me)) & "'"
	end try
	try
		set snme to ""
		set inme to ""
		set x to 0
		set y to 0
		set spotgroups to {}
		set Itungroups to {}
		set NPIT to (POSIX path of (path to me)) & "Contents/Resources/MusiNotify - iTunes.app/Contents/MacOS/MusiNotify - iTunes"
		set NPSP to (POSIX path of (path to me)) & "Contents/Resources/MusiNotify - Spotify.app/Contents/MacOS/MusiNotify - Spotify"
	end try
end InitialSetup

on ReadPrefs()
	set DispArt to (do shell script "defaults read " & preffile & " 'DispArt'")
	set DispAlb to (do shell script "defaults read " & preffile & " 'DispAlb'")
	set NumOfNot to (do shell script "defaults read " & preffile & " 'NumOfNot'")
	set RemoveOnQuit to (do shell script "defaults read " & preffile & " 'RemoveOnQuit'")
end ReadPrefs

on CheckSpotify()
	try
		tell application "Spotify"
			-- Get Track info
			set strk to name of current track
			set tart to artist of current track
			set talb to album of current track
		end tell
		if talb does not contain "http" and talb does not contain "spotify:" then -- If the track is not an ad...
			set thanked to false
			if strk is not equal to snme then -- If track has changed...
				try
					set sart to " "
					if DispArt = "1" and tart is not equal to "" then set sart to "By " & tart
					set salb to " "
					if DispAlb = "1" and talb is not equal to "" then set salb to "On " & talb
					
					set theid to SpotDet()
					set xid to "-group SP" & theid as text
					
					log "Notification - " & strk
					do shell script quoted form of NPSP & " -title " & (quoted form of strk) & " -subtitle " & (quoted form of sart) & " -message " & (quoted form of salb) & " " & xid & " -execute 'open /Applications/Spotify.app'" -- Display the notification
					log "Checking…"
					set snme to strk
				end try
			end if
			
		else
			try
				if thanked is false then
					do shell script quoted form of NPSP & " -title " & (quoted form of "Thanks for using MusiNotify!") & " -subtitle " & (quoted form of "You're awesome!") & " -message \"\" -group TH"
					set thanked to true
					do shell script quoted form of NPSP & " -remove TH"
				end if
			end try
		end if
		
	end try
end CheckSpotify

on SpotDet()
	log spotgroups
	if (count of spotgroups) = NumOfNot as integer then
		set x to last item of spotgroups
		try
			set spotgroups to (items 1 thru -2 of spotgroups)
		on error
			set spotgroups to {}
		end try
		log x
	else if (count of spotgroups) < NumOfNot as integer then
		repeat
			set x to x + 1
			if spotgroups does not contain x then exit repeat
		end repeat
	else if (count of spotgroups) > NumOfNot as integer then
		repeat with a from NumOfNot + 1 to (count of spotgroups)
			log a
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
	log spotgroups
	return (first item of spotgroups) as integer
end SpotDet

on CheckiTunes()
	try
		tell application "iTunes"
			-- Get Track info
			set itrk to name of current track
			set tart to artist of current track
			set talb to album of current track
		end tell
		
		if itrk is not equal to inme then -- If track has changed...
			try
				set iart to " "
				if DispArt = "1" and tart is not equal to "" then set iart to "By " & tart
				set ialb to " "
				if DispAlb = "1" and talb is not equal to "" then set ialb to "On " & talb
				
				set theid to ItunDet()
				set yid to "-group IT" & theid as text
				
				do shell script quoted form of NPIT & " -title " & (quoted form of itrk) & " -subtitle " & (quoted form of iart) & " -message " & (quoted form of ialb) & " " & yid & " -execute 'open /Applications/iTunes.app'" -- Display the notification
				set inme to itrk
			end try
		end if
	end try
end CheckiTunes

on ItunDet()
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
			Removeitunify((item b of Itungroups))
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
end ItunDet

on RemoveSpotify(a)
	if (count of spotgroups) ≠ 0 then
		do shell script quoted form of NPSP & " -remove SP" & a
	end if
end RemoveSpotify

on RemoveiTunes(b)
	if (count of Itungroups) ≠ 0 then
		do shell script quoted form of NPIT & " -remove IT" & b
	end if
end RemoveiTunes