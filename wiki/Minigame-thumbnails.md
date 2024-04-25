Each minigame can have a thumbnail seen by all players on the voting screen.

It's up to you what you put as your minigame's thumbnail! Ideally, you would want to put something that gives a preview of what the minigame is about, or the main feature of the minigame if possible.

----

### Requirements
The thumbnail needs to be named "thumb.jpg" in the root of your gamemode.

It **needs** to be:
- A JPG file
- 300x150 in dimensions (you can make it smaller but it will become stretched)
- Under 60KB in filesize

----

### Filesize tips
Here are some steps to get your thumbnail to the lowest filesize possible (using GIMP):
1. Select a quality level below 96, try going as low as possible before quality is visually affected
2. Untick all boxes that save extra data like Exif, color profile, and comments
3. Tick Optimize and Progressive (DON'T tick Arithmetic coding, things will break)
4. Set Subsampling to 4:2:0 Chroma Quartered
5. Set DCT method to Floating-Point
6. Save the file and run it through [TinyJPG](https://tinyjpg.com/)

----

### Example
![Minigame thumbnail example](https://github.com/TW1STaL1CKY/mretta/blob/develop/gamemodes/mretta_base/thumb.jpg?raw=true "This is an example of a minigame thumbnail. A 300x150 JPG at 17.9KB.")

----

### How do clients get the thumbnails anyway?
Clients store minigame thumbnails in their data folder. When the client joins the server, they send over which minigame thumbnails they already have saved, which prompts the server to send back the minigame thumbnails the client is missing one by one.

Update dates of the thumbnail files are checked too. This means if a minigame thumbnail is updated on the server, clients will receive the updated thumbnail automatically.

Clients are able to clear their thumbnails folder via the *mretta_thumbs_cleardata* command. Of course, they can also manually do it by removing the thumbnail files from their data folder.
<br>Once a client clears their thumbnail files, they will need to reconnect to the server in order to retrieve the thumbnails again.