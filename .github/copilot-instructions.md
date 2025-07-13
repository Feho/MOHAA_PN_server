# MOHAA PN Server - Copilot Instructions

## Project Overview

This is a Medal of Honor: Allied Assault (MOHAA) dedicated server running with custom mods. The server uses OpenMoHAA engine enhancements and supports various gameplay modifications through .scr scripting.

## Core Commands

### Server Management
- **Start server**: `.\omohaaded.exe +set dedicated 2 +set sv_maxclients 16 +set net_port 12203 +exec server.cfg +set developer 2 +set logfile 2`
- **Quick start**: Run `"run dedicated server.bat"` (includes auto-restart on crash)
- **Config reload**: Modify `main/server.cfg` and restart server

### Development Workflow
- **Script testing**: Place .scr files in `main/global/` or `main/maps/` and reload map
- **Mod packaging**: Create .pk3 files (ZIP format) containing scripts and assets

## Architecture

### Core Components
- **OpenMoHAA Engine**: Enhanced MOHAA server executable (`omohaaded.exe`)
- **Game DLLs**: `gamex86.dll`, `cgamex86.dll`, `ffx86.dll` for core game logic
- **Asset System**: .pk3 packages for maps, scripts, models, sounds
- **Script Engine**: .scr file execution for custom game logic

### Directory Structure
```
main/
├── *.pk3              # Game asset packages
├── server.cfg         # Server configuration
├── global/            # Global scripts (all maps)
│   ├── feho/         # Custom mods scripts
│   └── *.scr         # Utility scripts (strings, fog, etc.)
├── maps/             # Map-specific scripts
├── squadmaker_config/ # Squad system configuration
└── disabled_mods/    # Inactive mod files
```

### Key Systems
- **Squad System**: Automated team management via squadmaker mod
- **Bot Management**: OpenMoHAA bots with configurable population (sv_maxbots, sv_minPlayers)
- **Realism Mode**: Enhanced gameplay with modified damage/health mechanics
- **Custom Scripts**: Fog effects, grenade alerts, voice commands, utilities

## Scripting Guidelines

### MOHAA Script (.scr) Syntax
- **Threading**: Use `thread function_name` for concurrent execution
- **Variables**: Prefix with scope (`local.`, `level.`, `game.`, `parm.`)
- **Entity References**: Use `$world`, `$player`, entity targeting
- **Control Flow**: C-like syntax with `if`, `while`, `for` loops
- **File Structure**: `function_name:` blocks terminated with `end`

### Script Organization
- **Global utilities**: Place in `main/global/` for cross-map availability
- **Map-specific**: Use `main/maps/mapname.scr` for map logic
- **Mod namespacing**: Use subdirectories like `main/global/feho/`
- **Error handling**: Check for NIL values and entity validity

### Example Script Pattern
```scr
// global/example_mod.scr
main:
    thread initialize_mod
end

initialize_mod:
    if (level.mod_initialized == 1)
    {
        end
    }

    level.mod_initialized = 1
    // Mod initialization code
end
```

## Configuration Standards

### Server Settings
- Use `seta` for persistent CVars, `set` for runtime-only
- Prefix custom CVars with mod name (e.g., `sqdmk_`, `support_`)
- Document configuration changes in `main/changelog.txt`

### Map Rotation
- Edit `sv_maplist` in `server.cfg` for map sequence
- Include mix of DM (deathmatch), objective, and campaign maps
- Format: `"map1 map2 dm/deathmatch1 obj/objective1"`

### Mod Management
- Active mods: Place .pk3 files in `main/`
- Disabled mods: Move to `main/disabled_mods/`
- Load order: Alphabetical by filename (prefix with z_ for priority)

## Development Best Practices

### Script Development
- Test scripts on development server before production deployment
- Use descriptive variable names with scope prefixes
- Implement proper cleanup in `remove` or entity death handlers
- Validate entity existence before manipulation
- The `docs/` directory contains documentation on the scripting language and game internals.

### Version Control
- Track changes in `main/changelog.txt` with date and author
- Document breaking changes and compatibility notes
- Maintain backup of working configurations before major changes

### Performance Considerations
- Limit excessive `wait` loops in scripts
- Use efficient entity targeting methods
- Monitor server performance with `sv_fps` and console output
- Consider impact of concurrent threads on server load

## Common Issues

### Script Debugging
- Check console logs for syntax errors and runtime exceptions
- Use `iprintln` and `println` for debug output
- Verify file paths and script execution order
- Test entity references and variable scoping

### Server Stability
- Monitor memory usage with complex mods
- Implement proper thread cleanup
- Avoid infinite loops without wait statements
- Test with realistic player loads

## External Dependencies

- **OpenMoHAA**: Enhanced server engine with additional features
- **Custom Assets**: Sounds, models, textures packaged in .pk3 files