# Map Voting System Testing Guide

## Testing Scenarios

### Basic Functionality Tests

1. **Normal Voting Flow**
   - Start server with timelimit > 0 
   - Wait for voting to trigger at 60 seconds remaining
   - Test both vote options ('1' and '2')
   - Verify results are announced and nextmap is set

2. **Vote Prevention**
   - Try voting twice with same player
   - Verify "already voted" message appears
   - Confirm only first vote counts

3. **Edge Cases**
   - Test with empty sv_maplist (should disable voting)
   - Test with only 1 map in list (should disable voting)
   - Test with timelimit = 0 (should skip voting)

### Map Selection Logic Tests

4. **Rotation Order**
   ```
   sv_maplist: "map1 map2 map3"
   current: map2
   Expected: Option 1 = map3, Option 2 = random(map1)
   ```

5. **Wrap Around**
   ```
   sv_maplist: "map1 map2 map3"  
   current: map3
   Expected: Option 1 = map1, Option 2 = random(map2)
   ```

6. **Unknown Current Map**
   ```
   sv_maplist: "map1 map2 map3"
   current: unknown_map
   Expected: Option 1 = map2, Option 2 = random(map1, map3)
   ```

### User Interface Tests

7. **Vote Commands**
   - Type '1' -> should record vote for option 1
   - Type '2' -> should record vote for option 2
   - Type 'vote' -> should show current vote status
   - Type 'mapvote' -> should show current vote status

8. **Announcements**
   - Vote start announcement with options
   - Periodic reminders every 20 seconds
   - Final results with vote counts
   - Winner announcement and nextmap setting

### Results Handling Tests

9. **Clear Winner**
   - Option 1: 3 votes, Option 2: 1 vote
   - Expected: Option 1 wins, nextmap set

10. **Tie Vote**
    - Option 1: 2 votes, Option 2: 2 votes
    - Expected: Default to Option 1, appropriate message

11. **No Votes**
    - Option 1: 0 votes, Option 2: 0 votes
    - Expected: Default rotation, no nextmap override

## Console Commands for Testing

```
// Enable debug mode (edit script to uncomment println statements)
// Set test configuration
seta timelimit "2"  // 2 minute rounds for faster testing
seta sv_maplist "dm/mohdm1 dm/mohdm2 dm/mohdm3 obj/obj_team1"
map dm/mohdm1

// Force reload scripts (if needed)
restart

// Check current configuration
cvarlist sv_maplist
cvarlist timelimit
cvarlist mapname
cvarlist nextmap
```

## Expected Log Output

When working correctly, you should see:
1. Script initialization (if debug enabled)
2. Vote trigger at 60 seconds
3. Vote announcements in chat
4. Vote recordings when players type '1' or '2'
5. Final results and nextmap setting

## Troubleshooting

### Common Issues:
- **No voting triggers**: Check timelimit > 0 and sufficient maps
- **Vote commands ignored**: Ensure player hasn't voted already
- **No results**: Check that round actually ends and timer reaches limit
- **Wrong map selected**: Verify sv_maplist parsing and option logic

### Debug Steps:
1. Uncomment println statements in script for console output
2. Check server console for script errors
3. Verify event subscription is working
4. Test map parsing logic manually with test script

## Performance Notes

- System uses minimal resources (2-second timer checks)
- Voting only active for ~60 seconds per round
- No persistent storage required
- Automatic cleanup after each round