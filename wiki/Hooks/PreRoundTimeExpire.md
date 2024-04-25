**Realm:** Server

<br>

## Description
Called when the round timer has reached zero. **Your minigame will need to decide what happens.**<br>
<br><br>

## Returns
1. **[boolean](https://wiki.facepunch.com/gmod/boolean)**<br>
&ensp;&ensp;If `true`, the round will end.<br>
&ensp;&ensp;If `false`, the round will go into overtime. After this, the round needs to be manually ended using rounds.CompleteRound, or preferrably rounds.CompleteRoundIfOvertime.
2. **[string](https://wiki.facepunch.com/gmod/string)**<br>
&ensp;&ensp;When the first argument is `true`, this will be the reason for the round ending that is displayed to clients.