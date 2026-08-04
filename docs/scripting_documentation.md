# Scripting Documentation

## Medal of Honor: Allied Assault - Server-Side Scripting Guide

Welcome, developer, to the world of Medal of Honor: Allied Assault server-side scripting! This guide aims to provide you with the foundational knowledge and practical examples needed to create custom game logic, features, and full-blown modifications for MOHAA. We'll be drawing extensively from the provided "xyz_Airborne_Mod" and "zz_admin-Pro_1.22_modif" script examples.

### 1. Introduction to MOHAA Scripting

MOHAA's game logic is primarily controlled by `.scr` files. These are text-based scripts written in a C-like language (often informally referred to as "MOHAA Script," GSQ, or similar to QuakeC). These scripts run on the server and dictate how game objects behave, how game rules are enforced, and how custom features are implemented.

*   **Server-Side Execution:** All `.scr` logic runs on the server. Client-side effects (like HUD changes) are typically achieved by the server sending commands to the client via `stufftext`.
*   **Event-Driven and Threaded:** Scripts often react to game events (player spawn, trigger activation) and can run multiple logic sequences (threads) concurrently.
*   **Entity-Based:** The game world is composed of entities (players, objects, triggers, etc.), and scripts primarily manipulate these entities and their properties.

### 2. Setting Up Your Mod

1.  **File Structure:**
    *   Mods are packaged in `.pk3` files (which are essentially ZIP archives).
    *   Scripts usually reside in `global/` or `maps/` directories within the `.pk3`.
        *   `global/`: For scripts intended to be accessible from any map or game mode.
        *   `maps/mapname.scr`: For map-specific logic that runs automatically when `mapname` loads.
        *   Custom subdirectories (e.g., `global/<mod_name>/`) are common for organization.
3.  **Loading Scripts:**
    *   Map-specific scripts (`maps/mapname.scr`) are loaded automatically.
    *   Global scripts can be loaded from `mapname.scr` or other scripts using `exec`, `thread`, or `waitthread`.

    ```scr
    // Example: in maps/dm/mohdm1.scr
    main:
        exec global/global/AIR_Control.scr::init // Initialize the Airborne mod
        // ... other map specific logic
    end
    ```

### 3. Scripting Language Basics (.scr)

#### 3.1. Syntax and Structure

*   **Comments:**
    *   `// Single-line comment`
    *   `/* Multi-line comment */`
*   **Statements:** Often end with a newline, though semicolons are sometimes seen (less common and often not strictly required as in C).
*   **Code Blocks:** Defined by `thread_name:` and `end`, or within control structures like `if` and `while`.
*   **Case Sensitivity:** Variable names and keywords are generally case-insensitive, but it's good practice to be consistent (e.g., lowercase for keywords, specific prefixes for variables). Function/thread names *are* case-sensitive when called.

#### 3.2. Variables

*   **Declaration:** Variables are implicitly typed. Their scope is determined by prefixes:
    *   `local.variable_name`: Local to the current thread/function.
        ```scr
        my_thread local.my_arg:
            local.temp_var = 10
            local.another_var = "hello"
            local.origin_vector = (100 200 50)
            // ...
        end
        ```
    *   `self.variable_name`: Belongs to the current entity executing the script (e.g., a player, a trigger). Persists as long as the entity exists.
        ```scr
        // Inside a player script or a trigger's setthread
        self.health_regen_active = 1
        self.last_damage_time = level.time
        ```
    *   `level.variable_name`: Global to the current map load. Accessible from any script. Used for game state, shared data, etc.
        ```scr
        // In AIR_Control.scr
        level.AIR["realism"] = 1 // Using an array as a namespace
        level.AIR_mapscript = "dm/mohdm1"
        ```
    *   `game.variable_name`: Legacy persistent game state. It is intended to cross map loads, but dedicated servers can lose it when the game module is unloaded and reloaded. Do not rely on `game.*` for rotation-wide state.
    *   `session.variable_name`: OpenMoHAA process-lifetime state. It survives map changes and map restarts, including transitions that unload and reload `game.so`, and is accessible from every server-side script.
        ```scr
        if (session.rounds_played == NIL)
        {
            session.rounds_played = 0
        }

        session.rounds_played++
        session.last_map = getcvar "mapname"
        session.map_wins["allies"] = 3
        ```
        Use `session.*` for compact rotation-wide state such as counters, map history, team wins, or one-time initialization flags. Values are cleared when the server process exits or the service is restarted; they are not written to configuration files. NIL, strings, integers, floats, characters, vectors, and arrays containing those types are supported. Entity/listener references and cyclic arrays are not persisted; the server logs a warning and skips an unsupported root variable during a map transition. Keep session data reasonably small because the namespace is serialized during game-module reloads and currently has no explicit payload-size limit.

        `session.*` is an OpenMoHAA extension. It requires a recent OpenMoHAA `game.so`; original MOHAA binaries and older OpenMoHAA game modules do not recognize this namespace.
*   **Entity References:**
    *   `$<targetname>`: Refers to an entity by its `targetname` (e.g., `$player`, `$world`, `$my_trigger_targetname`).
    *   `$player[index]`: Access a specific player (1-indexed).
    *   `self`: Refers to the entity executing the current script block.
    *   `parm.other`: In trigger scripts, often refers to the activator (e.g., the player who used a `trigger_use`).

#### 3.3. Data Types (Implicit)

*   **Numbers:** Integers and floating-point numbers (e.g., `10`, `0.5`, `-100.25`).
*   **Strings:** Enclosed in double quotes (e.g., `"Hello, World!"`, `"models/weapons/colt45.tik"`).
*   **Vectors:** 3D coordinates or color RGB values, enclosed in parentheses (e.g., `(100 200 50)`, `(1.0 0.5 0.0)` for orange).
*   **Booleans:** Typically represented by `1` (true) and `0` or `NIL` (false).
*   **NIL:** Represents "nothing" or an uninitialized/non-existent value. Essential for checks: `if (local.my_var == NIL)`.
*   **Entity References:** As described above.
*   **Arrays:** See section 3.7.

#### 3.4. Operators

*   **Arithmetic:** `+`, `-`, `*`, `/`, `%` (modulo).
*   **Comparison:** `==`, `!=`, `<`, `>`, `<=`, `>=`.
*   **Logical:** `&&` (AND), `||` (OR), `!` (NOT). Note: MOHAA script sometimes uses `and` / `or` keywords.
*   **Assignment:** `=`.
*   **String Concatenation:** `+`.

#### 3.5. Control Flow

*   **`if / else / elseif`:**
    ```scr
    if (local.score > 100)
    {
        println "Victory!"
    }
    else if (local.score > 50)
    {
        println "Getting close!"
    }
    else
    {
        println "Keep trying."
    }
    ```
*   **`while` loop:**
    ```scr
    local.count = 0
    while(local.count < 10)
    {
        println "Count: " + local.count
        local.count++
        waitframe // IMPORTANT to prevent server freeze
    }
    ```
*   **`for` loop:**
    ```scr
    for (local.i = 1; local.i <= $player.size; local.i++)
    {
        $player[local.i] iprint "Hello player " + local.i
    }
    ```
*   **`switch` statement:**
    ```scr
    switch(local.weapon_choice)
    {
        case "rifle":
            // give rifle
            break
        case "smg":
            // give smg
            break
        default:
            println "Unknown weapon."
            break
    }
    ```
*   **`goto_label local.variable:` / `goto label`:** Used for jumping to labels, but can make code hard to follow. Generally, prefer structured loops and conditionals.

#### 3.5.1. Waiting

*   **`wait <seconds>` / `waitframe`:** Suspend the current thread for a fixed time. `waitframe` yields for a single frame and is what keeps a `while` loop from freezing the server.
*   **`<entity> waittill <name>`:** Suspend until the entity signals `<name>` (e.g. `self waittill trigger`, `level waittill spawn`). **This waits forever if the signal never comes** — a thread blocked here is stuck for the rest of the map.
*   **`<entity> waittill_timeout <seconds> <name>`:** The same wait, but it always resumes: either the signal arrives, or the timeout expires. Prefer this whenever the signal is not strictly guaranteed.
*   **`<entity> waittill_any <name1> <name2> ...`** and **`<entity> waittill_any_timeout <seconds> <name1> ...`:** Resume on whichever of several signals arrives first.

```scr
local.door waittill_timeout 10 opened
```

Note that the timeout forms do **not** tell you *why* they resumed. If that matters, check
some state afterwards to distinguish "the signal arrived" from "we timed out":

```scr
local.bot waittill_timeout 30 bot_move_done
local.status = local.bot bot_commandstatus local.id   // still "running" == timed out
```

There is also a race worth knowing about: a signal fired *before* your thread reaches the
`waittill` is lost, because the engine's wake does nothing when no thread is registered
yet. Where a signal can fire early, check the relevant state first and only wait if the
work is still pending — with nothing that yields between the check and the wait.

#### 3.6. Functions and Threads

*   **Defining a Thread/Function:**
    ```scr
    // A thread that does something
    my_cool_thread local.param1 local.some_other_param:
        println "Executing my_cool_thread with: " + local.param1 + ", " + local.some_other_param
        // ... logic ...
    end // Ends execution for this thread

    // A function that returns a value
    calculate_sum local.val1 local.val2:
        local.result = local.val1 + local.val2
    end local.result // Returns local.result
    ```
*   **Calling Threads/Functions:**
    *   `exec path/to/script.scr::thread_name param1 param2`: Executes the script synchronously. The calling script waits for `exec` to finish if it's in the same file, or if the called script has `wait` commands. No direct return value assignment.
    *   `thread path/to/script.scr::thread_name param1 param2`: Executes the script asynchronously (in a new thread). The calling script continues immediately.
    *   `local.return_val = waitthread path/to/script.scr::func_name param1 param2`: Executes synchronously and assigns the returned value to `local.return_val`.

    *Example from `AIR_clipping_lib.scr`*:
    ```scr
    // Calling a function from strings.scr and assigning its return value
    level.AIR_mapscript = waitexec global/strings.scr::to_lower (getcvar "mapname")
    // Calling a thread within the same file
    waitthread enable_clips
    ```
    *Note: `waitexec` is similar to `waitthread` but usually implies the called script might have significant `wait` commands itself.*

#### 3.7. Arrays

MOHAA script uses a flexible array system.

*   **Declaration:**
    ```scr
    local.my_array = makeArray
        "string_element"
        123
        (10 20 30) // a vector
        $player // an entity reference
    endArray

    // Multi-dimensional (jagged arrays are possible)
    local.multi_dim_array = makeArray
        ( "row1_col1" "row1_col2" )
        ( "row2_col1" 1000 (0 0 0) )
    endArray
    ```
*   **Accessing Elements:** 1-indexed.
    ```scr
    local.first_val = local.my_array[1] // "string_element"
    local.vector_x = local.my_array[3][1] // 10 (X-component of the vector)

    local.second_row_third_col = local.multi_dim_array[2][3] // (0 0 0)
    ```
*   **Size:** `local.my_array.size` returns the number of top-level elements.
*   **String-Indexed Arrays (Associative Arrays / Dictionaries):**
    MOHAA script can also use string keys for arrays, effectively creating associative arrays.
    ```scr
    level.AIR["setting_name"] = "value"
    level.AIR["another_setting"] = 1

    // To iterate (if keys are somewhat predictable or stored elsewhere):
    // This usually requires knowing the keys or having them in another array.
    ```

### 4. Core MOHAA Modding Concepts

#### 4.1. Entities

Everything in the game world is an entity.

*   **Players:**
    *   `$player`: Often refers to the "current" player in some contexts (like single-player or if script is run by player event). In multiplayer, it's an array of all connected players.
    *   `$player[local.i]`: Access player by index (1 to `$player.size`).
    *   Common properties: `.origin`, `.angles`, `.health`, `.dmteam`, `.viewangles`, `.name`, `.entnum`.
    *   Common commands:
        *   `$player[local.i] iprint "Message"`: Prints a message to that player's screen.
        *   `$player[local.i] stufftext "set r_fastsky 1"`: Sends a console command to the player.
        *   `$player[local.i] playsound "sound_alias"`
        *   `$player[local.i] hurt local.damage_amount`
        *   `$player[local.i] give "models/weapons/colt45.tik"`
        *   `$player[local.i] tele local.destination_origin`
        *   `$player[local.i] bind self.seat[local.f]`
        *   `$player[local.i] unbind`
*   **World Entity:** `$world`
    *   Controls global map properties.
    *   Example: `$world farplane_color (0.0 0.0 0.0)`.
*   **Scripted Entities:**
    *   `script_model`: Visible model that can be scripted.
        *   `spawn script_model model "path/to/model.tik"`
        *   Properties: `.origin`, `.angles`, `.model`, `.scale`.
        *   Commands: `hide`, `show`, `solid`, `notsolid`, `remove`.
    *   `script_origin`: Invisible point in space, useful as a marker, helper, or for binding other entities.
        *   `spawn script_origin origin (x y z)`
    *   `trigger_use`: Activated when a player presses the "use" key while looking at it and in range.
        *   `spawn trigger_use targetname "my_usable_trigger"`
        *   `self waittill trigger`
        *   `parm.other` is the player who used it.
    *   `trigger_multiple`: Activated when an entity touches it.
        *   `spawn trigger_multiple`
        *   `self waittill trigger`
        *   `parm.other` is the entity that touched it.
    *   `func_beam`: Creates a beam effect.
        *   Properties: `.origin`, `endpoint`, `alpha`, `endAlpha`, `scale`, `color`.
*   **Entity Manipulation:**
    *   `spawn <classname_or_tik_path> <key1> <value1> <key2> <value2> ...`: The fundamental command for creating new entities.
        *   `local.mg = spawn statweapons/mg42_gun.tik`
        *   `local.spotstart = spawn func_beam`
    *   `<entity> hide` / `<entity> show`
    *   `<entity> solid` / `<entity> notsolid` (controls collision)
    *   `<entity> remove`: Marks for removal at end of frame.
    *   `<entity> delete`: Stronger removal, might be immediate or end of frame.
    *   `<entity> immediateremove`: Removes instantly (use with caution).
    *   `<entity> <property> <value>`: Setting a property, e.g., `local.my_object.origin = (10 20 30)`.
    *   `<entity> setsize (min_x min_y min_z) (max_x max_y max_z)`: Sets the bounding box.
    *   `<entity> glue <other_entity>`: Attaches an entity to another, so it moves with it.
    *   `<entity> bind <other_entity>`: Similar to glue, often used for players to vehicles/seats.
    *   `<entity> attach <other_entity> "tag_name" ...`: Attaches to a specific tag (bone) on a model.
    *   `<entity> setthread path/to/script.scr::thread_name`: Assigns a script thread to an entity, usually for triggers.

#### 4.2. Time and Waiting

*   `wait <seconds>`: Pauses the current thread for the specified duration.
    ```scr
    println "Waiting for 5 seconds..."
    wait 5
    println "Done waiting."
    ```
*   `waitframe`: Pauses the current thread until the next server frame. **Crucial in loops to prevent server lock-ups.**
    ```scr
    while(1)
    {
        // do something every frame
        waitframe
    }
    ```
*   `level.time`: A global variable holding the current map time in seconds.

#### 4.3. CVARs (Console Variables)

CVARs store game settings and states.
*   `getcvar "<cvar_name>"`: Returns the string value of a CVAR.
    ```scr
    local.mapname = getcvar "mapname"
    local.gravity_value = float (getcvar "sv_gravity") // Convert to float if needed
    ```
*   `setcvar "<cvar_name>" "<value>"`: Sets the value of a CVAR.
    ```scr
    setcvar "g_allowvote" "0"
    ```
*   **Server vs. Client CVARs:** Some CVARs are server-side (`sv_`), some are game-logic related (`g_`), and some are client-side (`r_`, `cl_`). Server scripts primarily deal with `sv_` and `g_` CVARs. To change client CVARs, you typically use `stufftext`.

#### 4.4. HUD (Heads-Up Display)

Scripts can draw custom elements on the player's HUD using `huddraw_` commands.

*   **Structure:**
    *   Each HUD element is identified by an `index` (0-255).
    *   You set properties for an index, then draw it.
*   **Common Commands:**
    *   `huddraw_font <index> <fontname>` (e.g., `facfont-20`, `verdana-14`)
    *   `huddraw_align <index> <horizontal_align> <vertical_align>` (e.g., `left top`, `center center`, `right bottom`)
    *   `huddraw_rect <index> <x> <y> <width> <height>` (position and optional size for text or shader box)
    *   `huddraw_string <index> "<text>"`
    *   `huddraw_color <index> <r> <g> <b>` (0.0-1.0 for each component)
    *   `huddraw_alpha <index> <alpha>` (0.0 transparent to 1.0 opaque)
    *   `huddraw_shader <index> "path/to/shader_or_image.tga"` (for drawing images/boxes)
*   **Clearing:** To remove a HUD element, set its alpha to 0: `huddraw_alpha <index> 0.0`.

```scr
huddraw_font 122 "facfont-20"
huddraw_align 122 "left" "bottom"
huddraw_rect 122 5 -15 100 100
huddraw_string 122 ("AIRborne Mod " + level.AIR["version"])
huddraw_color 122 0.400 0.400 1.000
huddraw_alpha 122 1.000
```

#### 4.5. Sound

*   **`playsound <sound_alias_or_path>`:** Plays a sound at the entity's origin.
*   **`loopsound <sound_alias_or_path>`:** Loops a sound at the entity's origin.
*   **`stoploopsound`:** Stops a looping sound on an entity.
*   **`ScriptMaster`:** Used for aliasing sounds and setting their properties (volume, min/max distance, channel). This is crucial for managing sounds effectively, especially for custom sounds not defined in the game's default sound alias files.
    *   *Example*:
        ```scr
        local.master = spawn ScriptMaster
        local.master aliascache air_exp1 sound/weapons/explo/Explo_Bazooka1.wav soundparms 0.6 0.1 0.8 0.4 200 1100 "local" loaded maps "m dm moh obj train "
        // ... other aliases ...
        ```
        *   `soundparms <volume> <volume_randomness> <pitch> <pitch_randomness> <min_dist> <max_dist> [channel] [loaded|streamed] [maps "maplist"]`

#### 4.6. Vectors and Angles

*   **Vectors:** `(X Y Z)` for positions, velocities, directions.
*   **Angles:** `(PITCH YAW ROLL)` for entity orientation. Pitch is up/down, Yaw is left/right, Roll is tilt.
*   **Common Functions:**
    *   `angles_toforward <angles_vector>`: Returns a unit vector pointing forward.
    *   `angles_toleft <angles_vector>`: Returns a unit vector pointing left.
    *   `angles_toup <angles_vector>`: Returns a unit vector pointing up.
    *   `vector_toangles <direction_vector>`: Returns (PITCH YAW 0) angles for that direction.
    *   `vector_length <vector>`: Magnitude of the vector.
    *   `vector_normalize <vector>`: Returns a unit vector in the same direction.
    *   `vector_dot <vec1> <vec2>`: Dot product.
    *   `vector_cross <vec1> <vec2>`: Cross product.
    *   `vector_within <origin1> <origin2> <distance>`: Checks if `origin2` is within `distance` of `origin1`.

### 5. Advanced Scripting Techniques

#### 5.1. Libraries and Modularity

Breaking your mod into multiple script files makes it manageable.
*   **Utility Scripts:** Create scripts for common tasks (e.g., `strings.scr` for string manipulation, `maths.scr` for math functions).
*   **Main Library Files:** Group related functionalities (e.g., `modname_features_.scr` for mod features).

#### 5.2. State Management

Keeping track of the game's or an entity's state is crucial.
*   **`level.` variables:** For global game states (e.g., `level.modname_loaded`).
*   **`self.` variables:** For entity-specific states (e.g., `self.seats_taken`).
*   **`session.` variables:** For compact state that must survive map changes but should reset when the server process restarts (e.g., rotation counters or per-team map wins).

### 6. Debugging and Troubleshooting

*   **`println "<message>"`:** Prints a message to the server console. Essential for tracing variable values and script flow.
*   **`developer 1`:** Server CVAR that enables more verbose console output, including script errors.
*   **Common Errors:**
    *   **NIL references:** Trying to access a property of an entity that doesn't exist or a variable that hasn't been initialized. Always check `if (my_entity != NIL)`.
    *   **Incorrect parameter count:** Calling a function/thread with the wrong number of arguments.
    *   **Infinite loops:** A `while(1)` loop without a `waitframe` or `wait` inside will freeze the server.
    *   **"SZ_GetSpace: overflow without FSB_ALLOWOVERFLOW"**: This common MOHAA server crash often happens when too much data is being sent to clients (e.g., too many `iprint` messages in rapid succession, too many entities being updated frequently, or very complex HUDs). Be mindful of network traffic.
    *   **Typographical errors:** Scripting language is generally forgiving, but typos in entity targetnames, variable names, or function calls will cause issues.
*   **Isolate Issues:** If a complex script isn't working, comment out sections to pinpoint the problematic code.
*   **Read the Console:** The server console is your best friend for debugging.

### 7. Best Practices

*   **Modularity:** Break down complex features into smaller, manageable scripts and functions. Use libraries.
*   **Clear Naming:** Use descriptive names for variables, functions, and entities.
*   **Comments:** Explain complex logic or non-obvious code.
*   **NIL Checks:** Always check if an entity or variable is `NIL` before using it, especially for entities that might be removed or players who might disconnect.
    ```scr
    if (self.target_player != NIL && isAlive self.target_player)
    {
        // Proceed
    }
    ```
*   **Avoid `goto`:** It makes code harder to read and debug.
*   **`waitframe` in Loops:** Always include a `waitframe` or `wait` in `while(1)` loops.
*   **Entity Management:** Remove entities that are no longer needed (`remove`, `delete`) to prevent hitting engine limits and save server resources.
*   **Optimization:**
    *   Avoid overly complex calculations in tight loops that run every frame for many entities.
    *   Minimize `stufftext` commands, especially those sent frequently to all players.
*   **Use `level.` for Globals:** Store mod-wide settings and states in `level.` variables, often namespaced (e.g., `level.MyMod_Settings["feature_enabled"] = 1`).
*   **Error Handling (Basic):**
    ```scr
    if (local.required_entity == NIL)
    {
        println "ERROR: Required entity not found for MyFeature!"
        end // Stop this thread
    }
    ```

### 8. Conclusion

MOHAA scripting offers a powerful way to customize the game. By understanding the core concepts of entities, threads, variables, and control flow, and by studying existing mods, you can create a wide array of new gameplay experiences. Remember to start simple, test frequently, and use the server console for debugging. Good luck, and happy modding!
