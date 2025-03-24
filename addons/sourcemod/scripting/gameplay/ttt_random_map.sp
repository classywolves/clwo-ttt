#pragma semicolon 1

#include <sourcemod>

public OnPluginStart() {
    ChangeToRandomMap();
}

public void ChangeToRandomMap()
{
    ArrayList maps = new ArrayList(256, 0);
    char mapPath[PLATFORM_MAX_PATH], line[256], map[256];

    BuildPath(Path_SM, mapPath, sizeof(mapPath), "configs/starting_maps.txt");
    File file = OpenFile(mapPath, "r");

    while (!file.EndOfFile() && file.ReadLine(line, sizeof(line)))
    {
        if (line[0] == '/' && line[1] == '/') continue;
        maps.PushString(line);
    }

    int random = GetRandomInt(0, maps.Length - 1);

    maps.GetString(random, map, sizeof(map));
}