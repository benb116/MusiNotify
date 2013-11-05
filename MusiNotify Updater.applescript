set preffile to "com.BenB116.MusiNotify.plist"
try
	
	repeat
		try
			set CurrentAppVersion to (do shell script "defaults read " & preffile & " 'CurrentAppVersion'")
			exit repeat
		end try
	end repeat
	
	set raw to (do shell script "curl https://raw.github.com/benb116/MusiNotify/master/Version.txt")
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
		
		set UpdateQ to button returned of (display dialog "MusiNotify " & LatestVersion & " is available for update." & return & return & Featlist with title "MusiNotify - Update" buttons {"Don't Update", "Update"} default button 2)
		-- with icon (path to resource "applet.icns"))
		if UpdateQ = "Update" then
			try
				do shell script "cd ~/Library; curl -O https://raw.github.com/benb116/MusiNotify/master/MusiNotify.app.zip; unzip MusiNotify.app.zip" -- Download new app and unzip
				
				set linez to paragraphs of (do shell script "ps -ax | grep 'MusiNotify.app'")
				repeat with lin in linez
					if lin contains "MusiNotify.app/Contents" then exit repeat
				end repeat
				set currentpath to "/" & (do shell script "echo " & lin & " | cut -d '/' -f 2")
				set pid to (do shell script "echo " & lin & " | cut -d ' ' -f 1")
				
				do shell script "cp -rf ~/Library/MusiNotify.app " & currentpath -- Replace the old app
				
				do shell script "cp -f " & currentpath & "/MusiNotify.app/Contents/Resources/" & quoted form of ("MusiNotify Preferences.scpt") & " ~/Library/Scripts/" -- Copy the new preference file
				
				display dialog "Update complete. Restart MusiNotify for the changes to take effect." buttons ("OK") default button 1 with icon (path to resource "applet.icns") with title "MusiNotify - Update"
				
				try
					do shell script "rm ~/Library/MusiNotify.app.zip; rm -rf ~/Library/__MACOSX; rm -rf ~/Library/MusiNotify.app" -- Get rid of extra files
				end try
				
				do shell script "defaults write " & preffile & " 'CurrentAppVersion' '" & LatestVersion & "'"
				
				do shell script "kill -9 " & pid
				
				delay 1
				
				do shell script "open " & currentpath & "/MusiNotify.app"
				
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