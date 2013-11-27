BenB116's MusiNotify
======

This is a plugin for Mac OS X 10.8 and up. It displays notifications using two versions of [Terminal-Notifier](https://github.com/alloy/terminal-notifier) whenever the current track changes in iTunes or Spotify. The notification shows the name of the track and, optionally, the artist and album.

Mac OS X 10.8 or higher is required.

[Download Here](https://github.com/benb116/MusiNotify/blob/master/MusiNotify.app.zip?raw=true)

###How does it work?
MusiNotify continually checks to see if either iTunes or Spotify is running. If either is, MusiNotify will get the name, artist, album, and id of the current track. If the id changes, MusiNotify will display a notification with the app's icon. Pretty simple!

So why does the app have almost 400 LOC? 

1.	It has a fully-automated update system
2.	It has a total of seven different user preferences
3.	It has a .plist file to keep track of the preferences
3.	It keeps track of notification ID's, which is a complex task when the number of notifications in the sidebar has virtually no limit and can change at a moment's notice
4.	It adds and removes specific notifications to maintain the user's desired settings
4.	It does all this for iTunes and Spotify

###Current Features
* Optionally display the artist and/or album
* Change the number of notifications visible in the sidebar (the default is three)
* Optionally clear notifications from the sidebar when iTunes or Spotify is quit.
* Will not display notifications for audio ads in Spotify

###Tell me about how MusiNotify works for you
Let me know if there is a bug, a feature request, or if the darn thing just doesn't work.


![image](http://f.cl.ly/items/0A2P2O0W3L053n1I3x0L/Spot%20Art.png)
<br>
Spotify Notification

![image](http://f.cl.ly/items/0x3P2W1K2U3Z0q3k083s/Spot%20all.png)
<br>
Spotify Notification with Album

![image](http://f.cl.ly/items/1Z3z3l3V3u3J450V1e06/iTunes.png)
<br>
iTunes Notification with Album

![image](http://f.cl.ly/items/1S2w2U0y0X383Z342J37/Sidebar.png)
<br>
Sidebar with notifications from iTunes and Spotify