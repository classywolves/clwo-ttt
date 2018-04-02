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
  { "weapon_ak47", "models/weapons/w_rif_ak47_dropped.mdl", "0.10" },
  { "weapon_aug", "models/weapons/w_rif_aug_dropped.mdl", "0.05" },
  { "weapon_awp", "models/weapons/w_snip_awp_dropped.mdl", "0.02" },
  { "weapon_bizon", "models/weapons/w_smg_bizon_dropped.mdl", "0.05" },
  { "weapon_deagle", "models/weapons/w_pist_deagle_dropped.mdl", "0.05" },
  { "weapon_elite", "models/weapons/w_pist_elite_dropped.mdl", "0.05" },
  { "weapon_famas", "models/weapons/w_rif_famas_dropped.mdl", "0.05" },
  { "weapon_fiveseven", "models/weapons/w_pist_fiveseven_dropped.mdl", "0.10" },
  { "weapon_flashbang", "models/weapons/w_eq_flashbang_dropped.mdl", "0.05" },
  { "weapon_g3sg1", "models/weapons/w_snip_g3sg1_dropped.mdl", "0.01" },
  { "weapon_galilar", "models/weapons/w_rif_galilar_dropped.mdl", "0.05" },
  { "weapon_hegrenade", "models/weapons/w_eq_fraggrenade_dropped.mdl", "0.05" },
  { "weapon_incgrenade", "models/weapons/w_eq_incendiarygrenade_dropped.mdl", "0.05" },
  { "weapon_m249", "models/weapons/w_mach_m249_dropped.mdl", "0.02" },
  { "weapon_m4a1", "models/weapons/w_rif_m4a1_dropped.mdl", "0.02" },
  { "weapon_m4a1_silencer", "models/weapons/w_rif_m4a1_s_dropped.mdl", "0.02" },
  { "weapon_mac10", "models/weapons/w_smg_mac10_dropped.mdl", "0.05" },
  { "weapon_mag7", "models/weapons/w_shot_mag7_dropped.mdl", "0.05" },
  { "weapon_mp7", "models/weapons/w_smg_mp7_dropped.mdl", "0.05" },
  { "weapon_mp9", "models/weapons/w_smg_mp9_dropped.mdl", "0.05" },
  { "weapon_negev", "models/weapons/w_mach_negev_dropped.mdl", "0.02" },
  { "weapon_nova", "models/weapons/w_shot_nova_dropped.mdl", "0.05" },
  { "weapon_p250", "models/weapons/w_pist_p250_dropped.mdl", "0.05" },
  { "weapon_p90", "models/weapons/w_smg_p90_dropped.mdl", "0.05" },
  { "weapon_sawedoff", "models/weapons/w_shot_sawedoff_dropped.mdl", "0.05" },
  { "weapon_scar20", "models/weapons/w_snip_scar20_dropped.mdl", "0.01" },
  { "weapon_sg556", "models/weapons/w_rif_sg556_dropped.mdl", "0.05" },
  { "weapon_ssg08", "models/weapons/w_snip_ssg08_dropped.mdl", "0.05" },
  { "weapon_smokegrenade", "models/weapons/w_eq_smokegrenade_dropped.mdl", "0.05" },
  { "weapon_tec9", "models/weapons/w_pist_tec9_dropped.mdl", "0.05" },
  { "weapon_ump45", "models/weapons/w_smg_ump45_dropped.mdl", "0.05" },
  { "weapon_xm1014", "models/weapons/w_shot_xm1014_dropped.mdl", "0.05" }
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

  if (mapPoints != INVALID_HANDLE) { mapPoints.Close(); }
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
  if (totalPositions) {
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