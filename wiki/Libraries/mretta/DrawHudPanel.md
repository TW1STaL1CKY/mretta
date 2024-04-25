```lua
mretta.DrawHudPanel( number x, number y, number width, number height, number linePosition, function drawFunc )
```

**Realm:** Client

<br>

## Description
Draws a Mretta themed base HUD panel for you to draw into. Requires a 2D drawing context.<br>
<br><br>

## Arguments
1. **[number](https://wiki.facepunch.com/gmod/number) x**<br>
&ensp;&ensp;The X position of the panel.
2. **[number](https://wiki.facepunch.com/gmod/number) y**<br>
&ensp;&ensp;The Y position of the panel.
3. **[number](https://wiki.facepunch.com/gmod/number) width**<br>
&ensp;&ensp;The width of the panel.
4. **[number](https://wiki.facepunch.com/gmod/number) height**<br>
&ensp;&ensp;The height of the panel.
5. **[number](https://wiki.facepunch.com/gmod/number) linePosition**<br>
&ensp;&ensp;A MRETTAHUD_LINE enum determining where the style line for the panel should be drawn.
6. **[function](https://wiki.facepunch.com/gmod/function) drawFunc**<br>
&ensp;&ensp;The function defining what will be drawn inside this panel. The XY position 0,0 in this function will be the top-left padded corner of the panel. Anything that attempts to be drawn outside the panel will be clipped.
<br>

## Examples
This will draw a Mretta themed HUD panel containing "Hello world".

```lua
hook.Add("HUDPaint", "test", function()
    mretta.DrawHudPanel(400, 400, 200, 100, MRETTAHUD_LINE_LEFT, function()
        surface.SetFont(mretta.FontLarge)
        surface.SetTextColor(color_white)
        surface.SetTextPos(0, 0)
        surface.DrawText("Hello world")
    end)
end)
```

![Example result](https://github.com/TW1STaL1CKY/mretta/blob/develop/wiki/uploads/DrawHudPanel_example.png?raw=true)