# HUD index reservations

OpenMoHAA supports 256 HUD elements, so valid indices are `0` through `255`.
Values above 255 wrap on the normal protocol and must not be used.

The active shared and per-player systems reserve these ranges:

| Indices | Owner | Elements |
| --- | --- | --- |
| 119 | Global notification | Animated notification text |
| 120-123 | Kill banner | Panel, title, victim, accent |
| 124 | Hitmarker | Per-player hit confirmation |
| 125-127 | XP toast | Two text-only award lines and total |
| 150-156 | Squads | Per-player squad list |
| 160-162 | HVT | Shared event status |
| 165-186 | Leaderboard | Spectator-only table |
| 230-231 | Radio | Per-player objective status |
| 240-248 | Tickets | Shared ticket bars and messages |
| 250-255 | KOTH | Shared bar plus per-player status |

The 119-127 block was verified unused by other repository scripts before issue
#13 assigned it. Map scripts also use isolated indices such as 187, 200,
214-218, 220, 223, and 245-247; check this table and audit map-local HUD commands
before adding another global system.
