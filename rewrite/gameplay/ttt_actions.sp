/*
 * Base CS:GO plugin requirements.
 */
#include <sourcemod>
#include <sdktools>
#include <cstrike>

/*
 * Custom include files.
 */
#include <ttt>
#include <colorvariables>
#include <generics>
#include <dynamic>

/*
 * Custom methodmaps.
 */
#include <player_methodmap>

public OnPluginStart()
{
  PreCache();
  HookEvents();
  
  LoadTranslations("common.phrases");

  PrintToServer("[BLM] Loaded succcessfully");
}

public void HookEvents() {
  HookEvent("player_death", OnPlayerDeath);
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
  int client = GetClientOfUserId(GetEventInt(event, "userid"));
  int attackerClient = GetClientOfUserId(GetEventInt(event, "attacker"));

  Player victim = Player(client)
  Player attacker = Player(attackerClient)

  if (attacker.Traitor) {
    ClearTimer(bloodLustTimers[attacker.Client]);
    
    BloodLustReset(attacker.Client);
    bloodLustTimers[attacker.Client] = CreateTimer(bloodLustStartTime, BloodLustStart, attacker.Client);
  }
  else
  {
    ClearTimer(bloodLustTimers[attacker.Client]);
  }
  
  ClearTimer(bloodLustTimers[victim.Client]);

  return Plugin_Continue;
}