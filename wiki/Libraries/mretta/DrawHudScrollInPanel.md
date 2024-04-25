```lua
mretta.DrawHudScrollInPanel( number x, number y, number width, number height, number timeStart, number timeEnd, function drawFunc )
```

**Realm:** Client

<br>

## Description
Draws a Mretta themed base HUD panel for you to draw into, which slides in and out of view for a defined time period. At this time, there is no option for changing the style line position. Requires a 2D drawing context.<br>
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
5. **[number](https://wiki.facepunch.com/gmod/number) timeStart**<br>
&ensp;&ensp;The time the panel will begin sliding in. Based on [RealTime](https://wiki.facepunch.com/gmod/Global.RealTime).
6. **[number](https://wiki.facepunch.com/gmod/number) timeEnd**<br>
&ensp;&ensp;The time the panel will begin sliding out. Based on [RealTime](https://wiki.facepunch.com/gmod/Global.RealTime).
7. **[function](https://wiki.facepunch.com/gmod/function) drawFunc**<br>
&ensp;&ensp;The function defining what will be drawn inside this panel. The XY position 0,0 in this function will be the top-left padded corner of the panel. Anything that attempts to be drawn outside the panel will be clipped.
<br>

## Examples
One second after execution, this will draw a Mretta themed HUD panel that slides into view, hold for 3 seconds, then slide out of view.

```lua
local stamp = RealTime() + 1

hook.Add("HUDPaint","test",function()
    mretta.DrawHudScrollInPanel(400, 400, 500, 100, stamp, stamp + 3, function()
        surface.SetFont(mretta.FontLarge)
        surface.SetTextColor(color_white)
        surface.SetTextPos(0, 0)
        surface.DrawText("Hello world in sliding form!")
    end)
end)
```

![Example result](https://github.com/TW1STaL1CKY/mretta/blob/develop/wiki/uploads/DrawHudScrollInPanel_example.gif?raw=true)