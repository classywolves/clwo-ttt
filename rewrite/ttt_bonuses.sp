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
#include <sourcecomms>
#include <generics>

public OnPluginStart()
{
  RegisterCmds();
  HookEvents();
  InitDBs();

  LoadTranslations("common.phrases");
  
  PrintToServer("[BNS] Loaded succcessfully");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
  CreateNative("AddPlayerSpeed", Native_AddPlayerSpeed);
  return APLRes_Success;
}

public void RegisterCmds() {
}

public void HookEvents() {
}

public void InitDBs() {
}

public void TTT_OnRoundStart() {
  GiveBonuses();
}

public void GiveBonuses() {
  LoopAliveClients(client) {
    Player player = Player(client);

    if (player.TraitorKills && player.Traitor) {
      // This person killed a traitor last round!
      GiveBonus(player);

      // Reset traitor kills.
      player.TraitorKills = 0;
    }
  }
}

public void GiveBonus(Player player) {
  player.Msg("You've killed ${blue}%i {yellow}traitors in the past rounds.", player.TraitorKills);
  player.AddHealth(4 * player.TraitorKills);
  player.AddSpeed(0.05 * player.TraitorKills);
}

public int Native_AddPlayerSpeed(Handle plugin, int numParams) {
  Player player = Player(GetNativeCell(1));
  float speed = view_as<float>(GetNativeCell(2));

  player._AddSpeed(speed);
}