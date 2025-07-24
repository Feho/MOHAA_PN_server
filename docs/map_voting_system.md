# Map Voting System Documentation

## Overview

The map voting system allows players to vote for the next map at the end of each round, giving them more control over the server experience.

## How It Works

### Trigger
- Voting begins automatically when 60 seconds remain in the round
- Only works in timed game modes (when `timelimit` > 0)

### Vote Options
1. **Option 1**: Next map in the rotation sequence (from `sv_maplist`)
2. **Option 2**: Random map from the available pool (excluding current map and Option 1)

### Voting Process
1. Server announces voting options via chat:
   ```
   ===================================
   MAP VOTE - Time remaining: 60 seconds
   Option 1: dm/mohdm3 (Type '1')
   Option 2: obj/obj_team1 (Type '2')
   ===================================
   ```

2. Players vote by typing `1` or `2` in public chat
3. Each player can only vote once per round
4. Votes are tallied when the round ends

### Results
- The map with more votes becomes the next map
- Tie votes or no votes default to the rotation order (Option 1)
- Server announces results and sets the `nextmap` cvar automatically

## Configuration

The system uses the existing `sv_maplist` configuration:
```
seta sv_maplist "m1l1 m1l2b dm/mohdm1 dm/mohdm2 m2l1 dm/mohdm3 obj/obj_team1"
```

## Files Modified/Added

- `main/global/feho/mapvote.scr` - Main voting system script
- `main/global/events.scr` - Updated to load the map voting system

## Dependencies

- Requires existing `global/strings.scr` for map list parsing
- Uses the OpenMoHAA event system for chat monitoring
- Integrates with standard MOHAA cvar system

## Edge Cases Handled

- **Small map pools**: Voting disabled if fewer than 2 maps available
- **No time limit**: System inactive in untimed game modes  
- **Player spam**: Each player limited to one vote per round
- **Disconnections**: Voting continues normally if players leave
- **Server restart**: System reinitializes automatically

## Troubleshooting

If voting doesn't work:
1. Check that `timelimit` is set to a value > 0
2. Verify `sv_maplist` contains multiple maps
3. Ensure the script is loaded via `events.scr`
4. Check console for any script errors

## Customization

To modify voting timing, edit the trigger condition in `monitor_round_timer`:
```scr
// Change 61/59 to different values (e.g., 121/119 for 2 minutes)
if (local.time_remaining <= 61 && local.time_remaining >= 59 && level.voting_active == 0)
```

To change vote commands, modify the text checking in `event_player_textMessage`:
```scr
// Add more vote options or different keywords
if (local.text == "1" || local.text == "next")
{
    // Vote for option 1
}
```