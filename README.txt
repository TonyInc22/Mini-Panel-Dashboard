TONY MINI PANEL CYBER CONSOLE v0.5

CHANGES
- Increased the uptime value font.
- Simplified CPU to usage, CPU temperature, and package power.
- Core Max remains mapped in HWiNFO but is no longer displayed, so ValueRaw indices do not shift.
- Renamed MEMORY header to RAM.
- Replaced total-memory body value with available memory.
- Added the MEMORY footer label and moved the RAM bar above it.
- Replaced the storage temperature dial with drive usage KPIs.
- Added drive slots for C:, D:, E:, and F:. Missing D-F drives are hidden.
- Rebuilt network as separate download and upload Mbps KPIs.
- Removed Interface: Best and the ambiguous network bars.

HWiNFO MAP - UNCHANGED
ValueRaw0 = Total CPU Usage
ValueRaw1 = CPU Package
ValueRaw2 = Core Max (still mapped, not displayed)
ValueRaw3 = CPU Package Power
ValueRaw4 = Drive Temperature (still mapped, not displayed)
ValueRaw5 = GPU Temperature
ValueRaw6 = GPU Core Load

DRIVE LETTERS
The storage panel currently supports C:, D:, E:, and F:.

To use a different letter, change both occurrences for that slot:
- Drive=D:
- Text=D:

For example, to replace F: with G:, change Drive=F: to Drive=G:
in MeasureFUsed and MeasureFTotal, then change Text=F: to Text=G:
in MeterDriveFLabel.

INSTALL
1. Unload the previous skin.
2. Extract the ZIP.
3. Copy TonyMiniPanel_CyberConsole_v05 into Documents\Rainmeter\Skins\
4. Refresh all in Rainmeter.
5. Load TonyMiniPanel_CyberConsole.ini.
