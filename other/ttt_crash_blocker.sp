/*
 * Base CS:GO plugin requirements.
 */
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <smlib>

/*
 * Custom include files.
 */
#include <colorlib>
#include <generics>

int deadPlayers[MAXPLAYERS];
int numDeadPlayers = 0;

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
  RegConsoleCmd("sm_logbodies", Command_LogBodies, "Logs position of all dead bodies");
  RegConsoleCmd("sm_killbodies", Command_KillBodies, "Kills all dead bodies");
}

public void HookEvents() {
  HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
  HookEvent("player_death", OnPlayerDeath, EventHookMode_PostNoCopy);
}

public void HookClient(int client) {
  SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
  for (int i = 0; i < sizeof(deadPlayers); i++) {
    deadPlayers[i] = 0;
  }

  numDeadPlayers = 0;
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
  int client = GetClientOfUserId(event.GetInt("userid"));
  deadPlayers[numDeadPlayers] = client;
  numDeadPlayers++;

  return Plugin_Continue;
}

public void InitDBs() {
}

public void InitPrecache() {
}

public void OnMapStart() {
}

public Action Command_LogBodies(int client, int args) {
  int entities[MAXPLAYERS];
  float ragdollPositions[MAXPLAYERS][3];
  int ragdolls = GetRagdollPositions(entities, ragdollPositions);

  for (int i = 0; i < ragdolls; i++) {
    PrintToServer("entity %i | pos %f;%f;%f", entities[i], ragdollPositions[i][0], ragdollPositions[i][1], ragdollPositions[i][2])
  }

  return Plugin_Handled;
}

public Action Command_KillBodies(int client, int args) {
  int entities[MAXPLAYERS];
  float ragdollPositions[MAXPLAYERS][3];
  int ragdolls = GetRagdollPositions(entities, ragdollPositions);

  for (int i = 0; i < ragdolls; i++) {
    PrintToServer("entity %i | pos %f;%f;%f", entities[i], ragdollPositions[i][0], ragdollPositions[i][1], ragdollPositions[i][2])
    DestroyBody(entities[i]);
  }

  return Plugin_Handled;
}

public bool GetRagdollPosition(int entity, float[3] pos) {
  if (IsValidEntity(entity)) {
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
    return true;
  }

  return false;
}

public int GetRagdollPositions(int entities[MAXPLAYERS], float ragdollPositions[MAXPLAYERS][3]) {
  int ragdolls = 0;
  for (int i = 0; i < sizeof(deadPlayers); i++) {
    if (deadPlayers[i] != 0) {
      // This person has died and probably has a ragdoll.
      int[] ragdoll = new int[Ragdolls];

      TTT_GetClientRagdoll(deadPlayers[i], ragdoll);

      if (GetRagdollPosition(ragdoll[Ent], ragdollPositions[ragdolls])) {
        entities[ragdolls] = ragdoll[Ent];
        ragdolls++;
      }
    }
  }

  return ragdolls;
}

public void DestroyBody(int entity) {
  Entity_Kill(entity);
}

public Action OnTraceAttack(int victimClient, int &attackerClient, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup) {
  if (victim.Health > damage) {
    return Plugin_Continue;
  }

  float playerPos[3];
  GetClientEyePosition(victimClient, playerPos);

  // The player dies from this attack.  We should check if any dead / fake bodies are near them.
  int entities[MAXPLAYERS];
  float ragdollPositions[MAXPLAYERS][3];
  int ragdolls = GetRagdollPositions(entities, ragdollPositions);

  for (int i = 0; i < ragdolls; i++) {
    float distance = GetVectorDistance(ragdollPositions[i], playerPos, true);

    if (distance < 22500.0) {
      DestroyBody(entities[i]);
      return Plugin_Handled;
    }
  }

  return Plugin_Continue;
}
