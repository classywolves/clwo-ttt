#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>

#include <ttt>
#include <ttt_helpers>
#include <player_methodmap>

#define upgrade_id 7

float last_time[MAXPLAYERS + 1];
int used_time[MAXPLAYERS + 1];
bool going_forward[MAXPLAYERS + 1];

public void OnPluginStart() {
	// Prepare the sound file for use.
	AddFileToDownloadsTable("sound/ttt_clwo/ttt_binoculars_activate.mp3");

	// Account for late loading
	LoopValidClients(client) OnClientPutInServer(client);
	HookEvent("round_end", OnRoundEnd, EventHookMode_Post);
}

public void OnClientPutInServer(int client)
{
	//SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost) ;
}

public void OnConfigsExecuted() {

}

public Action OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) {
	if (!going_forward[client] && buttons & IN_USE) {
		float current_time = GetGameTime();

		going_forward[client] = true;

		PrintToConsole(client, "pressed 'use_key' current %f last %f", current_time, last_time[client]);
		
		if (last_time[client] > current_time - 0.5) {
			if (!IsPlayerAlive(client)) return Plugin_Handled;

			// Double press!
			Player player = Player(client);
			if (!player.has_upgrade(upgrade_id)) return Plugin_Handled;

			int cooldown_time = used_time[client] + RoundFloat(120.0 / player.has_upgrade(upgrade_id))
			if (GetTime() < cooldown_time) {
				CPrintToChat(client, "{purple}[TTT] {red}Sprint is on cooldown for another %d seconds.", -(GetTime() - cooldown_time));
				return Plugin_Handled;
			}

			used_time[client] = GetTime();

			// They have the skill points.
			CPrintToChat(client, "{purple}[TTT] {yellow}Sprint has been activated.");

			for (float i = 0.0; i < 0.5; i += 0.01) {
				DataPack pack;
				CreateDataTimer(i, SpeedIncrease, pack);
				pack.WriteCell(GetClientSerial(client));
				pack.WriteFloat(i);
			}
			CreateTimer(3.0, RevokeSpeed, GetClientSerial(client));
		}

		last_time[client] = current_time;
	} else if (going_forward[client] && !(buttons & IN_USE)) {
		going_forward[client] = false;
	}

	return Plugin_Continue;
}

public Action OnRoundEnd(Handle event, const char[] name, bool dontBroadcast) {
	for (int i = 0; i < 64; i++) {
		used_time[i] = 0;
	}
}

public Action SpeedIncrease(Handle timer, Handle pack)
{
	ResetPack(pack);
	int client = GetClientFromSerial(ReadPackCell(pack));
	if (!client) return Plugin_Stop;

	float speed = ReadPackFloat(pack);
 
	SetClientSpeed(client, 1.0 + speed);

	return Plugin_Stop;
}

public Action RevokeSpeed(Handle timer, any serial)
{
	int client = GetClientFromSerial(serial);
	if (!client) return Plugin_Stop;
 
	SetClientSpeed(client, 1.0);

	return Plugin_Stop;
}

public SetClientSpeed(int client, float speed) 
{ 
	SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", speed) 
}  