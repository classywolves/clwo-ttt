/*
 * Base CS:GO plugin requirements.
 */
#include <sourcemod>
#include <sdktools>
#include <cstrike>

/*
 * Custom include files.
 */
#include <colorvariables>
#include <generics>

enum model {
  WPN_PROP,
  WPN_MDL,
  WPN_CHANCE
}

char models[][][] = {
  { "weapon_awp", "models/weapons/w_snip_awp_dropped.mdl", "0.05" },
  { "weapon_ak47", "models/weapons/w_rif_ak47_dropped.mdl", "0.2" }
}

int totalPositions = 0;
float positions[1024][3];

Handle mapPoints;

public OnPluginStart()
{
  RegisterCmds();
  HookEvents();
  InitDBs();
  InitPrecache();
  OnMapStart();

  LoadTranslations("common.phrases");
  
  PrintToServer("[INF] Loaded succcessfully");
}

public void RegisterCmds() {
  RegConsoleCmd("sm_spawngun", Command_SpawnGun, "Spawn a gun!");
  RegConsoleCmd("sm_spawnguns", Command_SpawnGuns, "Spawn all guns!");
}

public void HookEvents() {
  HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
}

public void InitDBs() {
}

public void InitPrecache() {
  for (int i = 0; i < sizeof(models); i++) {
    PrecacheModel(models[i][WPN_MDL], true);
    AddFileToDownloadsTable(models[i][WPN_MDL]);
  }
}

public void OnMapStart() {
  char map[255], path[PLATFORM_MAX_PATH];

  GetCurrentMap(map, sizeof(map));
  BuildPath(Path_SM, path, sizeof(path), "configs/lootpos/%s.txt", map);

  mapPoints.Close();
  mapPoints = OpenFile(path, "a+");

  LoadPoints();
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
  SpawnGuns();
}

public Action Command_SpawnGun(int client, int args) {
  Player player = Player(client);

  if (!player.Access("senator", true)) {
    return Plugin_Handled;
  }

  char name[128], mode[128];
  float pos[3];

  player.Pos(pos);

  GetCmdArg(1, name, sizeof(name));
  GetCmdArg(2, mode, sizeof(mode));

  SpawnGun(name, mode, pos);

  // name - "prop_physics" / "prop_physics_override"  
  // mode - "models/props_junk/watermelon01.mdl" / "models/weapons/w_rif_ak47_dropped.mdl"

  return Plugin_Handled;
}

public Action Command_SpawnGuns(int client, int args) {
  SpawnGuns();
}

public Action Command_AddLoc(int client, int args) {
  Player player = Player(client);

  char map[255];
  float pos[3];

  GetCurrentMap(map, sizeof(map));
  player.Pos(pos);

  AddLoc(map, pos);
}

public void LoadPoints() {
  char line[512];
  totalPositions = 0;

  while(!IsEndOfFile(mapPoints) && ReadFileLine(mapPoints, line, sizeof(line))) {
    char floatValues[128][3];
    ExplodeString(line, ";", floatValues, 3, 128);

    positions[totalPositions][0] = StringToFloat(floatValues[0]);
    positions[totalPositions][1] = StringToFloat(floatValues[1]);
    positions[totalPositions][2] = StringToFloat(floatValues[2]);

    totalPositions++;
  }

  totalPositions--;
}

public void SpawnGuns() {
  int total = 100;
  for (int i = 0; i < sizeof(models); i++) {
    float chance = StringToFloat(models[i][WPN_CHANCE]);

    for (int j = 0; j < chance * total; j++) {
      float pos[3];
      GetPos(pos);

      SpawnGun(models[i][WPN_PROP], models[i][WPN_MDL], pos);
    }
  }
}

public Action SpawnGun(char[] entityName, char[] entityMode, float[3] pos) {
  float angle[3];
  angle[1] = GetRandomFloat(0.0, 360.0);

  int entIndex = CreateEntityByName(entityName);
  SetEntityModel(entIndex, entityMode);
  DispatchSpawn(entIndex);
  ActivateEntity(entIndex);
  TeleportEntity(entIndex, pos, angle, NULL_VECTOR);
}

public void GetPos(float[3] pos) {
  int item = GetRandomInt(0, totalPositions - 1);

  pos[0] = positions[item][0];
  pos[1] = positions[item][1];
  pos[2] = positions[item][2];
}

public void AddLoc(char[] map, float pos[3]) {
  positions[totalPositions][0] = pos[0];
  positions[totalPositions][1] = pos[1];
  positions[totalPositions][2] = pos[2];

  totalPositions++;

  char line[512];
  Format(line, sizeof(line), "%f;%f;%f", pos[0], pos[1], pos[2]);

  WriteFileLine(mapPoints, line);
} 