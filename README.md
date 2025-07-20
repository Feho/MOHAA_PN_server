# MoHAA -=[PN]=- Server

## Mods ideas

- mohdm4 : Search and Destroy
- m4l0 : push mod ? stages ?
- Proximity mines
- Bleeding system (if you get shot, you bleed and lose health over time)
- Voting system for the next map (between 2 maps)
- A lot of gold boxes in the church (mohdm2)

### Limited Ammunition & Resupply Zones
*   **What it is:** Players spawn with a realistic combat load (e.g., 3-4 clips for their primary weapon) instead of maximum ammo. To get more, they must go to designated, static "Ammo Crate" locations on the map. This can be implemented with scripting that creates invisible "trigger zones."
*   **Why it helps players stay:** **Strategic Depth.** This one change transforms the game. It curbs mindless spamming and makes every bullet count. It creates new map objectives (controlling ammo points), encourages teamwork (covering a teammate who is resupplying), and makes scavenging weapons from fallen enemies a viable, desperate tactic.

### Mid-Match "High-Value Target" (HVT) Event
*   **What it is:** A server-side event that triggers automatically once per match. The server identifies the top-scoring player on each team and announces them as the HVT. Killing the enemy's HVT awards a significant point bonus (e.g., +5 or +10 points) to the team.
*   **Why it helps players stay:** **Dynamic Objectives.** It breaks up the monotony of TDM and creates a temporary, player-driven objective. Teams will shift their focus to either protect their own HVT or hunt down the enemy's, leading to dramatic and memorable moments.

### Simple, Session-Based Stat Tracking
*   **What it is:** A lightweight system that shows players their stats (Kills, Deaths, K/D Ratio, Objective Score) at the end of a map or via a command (`!stats`). Crucially, these stats should reset every map or every session.
*   **Why it keeps players:** It provides immediate feedback and a sense of accomplishment without creating a "grind" culture. Avoiding permanent global leaderboards prevents stat-padding and encourages players to focus on team objectives over protecting their overall K/D ratio.

### Dynamic Environment

* Des obstacles barrent la route. Certains sont destructibles.
* Des joueurs construisent des barricades.
* Un trigger au sol qui affiche au joueur "Press [USE] to block the passage".
* ✅ Les portes peuvent être verrouillées.

### Non-Lethal Injury System
*   **What it is:** A script that applies temporary, minor debuffs when a player takes significant damage but survives.
    *   **Leg Hit:** A high-damage shot to the legs could cause a brief (5-10 second) limp, slightly reducing movement speed.
    *   **Arm Hit:** A shot to the arms could temporarily increase weapon sway.
    *   **Shell Shock:** Being very close to a grenade explosion (without dying) could cause a brief vision blur and muffled audio.
    These effects would be temporary and could be removed instantly by a Medic's bandage.
*   **Why it keeps players:** It adds consequence to getting shot, making players value cover and tactical positioning even more. It avoids being overly punishing by keeping the effects short-lived, but they are significant enough to impact the outcome of a firefight. This also massively increases the value of a Medic, making them a cornerstone of any successful team.

### Sabotage Side-Objectives
*   **What it is:** On certain maps, key strategic points are designated as sabotage targets. These are not about winning the round directly but about crippling the enemy team.
    *   **Ammo Depot:** A designated ammo cache can be rigged with an explosive (long plant time). If it detonates, the enemy's main resupply point is destroyed for 2-3 minutes, forcing them to conserve ammo.
*   **Why it keeps players:** It provides a compelling gameplay loop for players who prefer stealth over direct confrontation. A single, successful saboteur can cause chaos and significantly impact the enemy's ability to coordinate, creating a huge advantage for their team. It adds a layer of high-stakes spy thriller to the match.