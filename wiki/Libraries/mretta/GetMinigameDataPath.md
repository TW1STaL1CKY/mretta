```lua
mretta.GetMinigameDataPath( )
```

**Realm:** Client

<br>

## Description
Gets the current minigame's folder path within your data folder.<br>
<br><br>

## Returns
1. **[string](https://wiki.facepunch.com/gmod/string)**<br>
&ensp;&ensp;The folder path relative to "data/".
<br>

## Examples
If your minigame's folder inside "gamemodes" is called "mretta_example":

```lua
print(mretta.GetMinigameDataPath())
```

`mretta/mretta_example/`