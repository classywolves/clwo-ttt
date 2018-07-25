#include <sourcemod>

ArrayList maps;
int serial;

public OnPluginStart() {
  ChangeToRandomMap();
}

public void ChangeToRandomMap() {
  if (ReadMapList(maps, serial, "default", 0) == null || serial == -1) {
    LogMessage("Random Map failed to load a map list.");
    return;
  }

  char map[256];
  int random = GetRandomInt(0, maps.Length - 1);

  maps.GetString(random, map, sizeof(map));

  LogMessage("Changed map to %s", map);
  ServerCommand("sm_map %s", map);
}