#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <ttt>
#include <ttt_helpers>
#include <player_methodmap>

#define upgrade_id 3

// We also need an array to hold players upgrade levels
int upgrade_levels[MAXPLAYERS + 1];

public void OnPluginStart() {
	// For every client we need to grab their current upgrade level.
	// Populate might not have run yet, but that is fine since that means we
	// are not late loading anyway.
	LoopValidClients(client) OnClientPutInServer(client);
}


// When a client is put in the server, we want to automatically grab their
// upgrade level.
public void OnClientPutInServer(int client) {
	update_upgrade_level(client);
}

// When the player disconnects from the server, we want to reset their upgrade_level
// back to zero.
public void OnClientDisconnect(int client) {
	upgrade_levels[client] = 0;
}

// We also want to update their skill level when it changes via the .populate()
// function on the player methodmap
public void OnUpgradeChanged(int client, int upgrade) {
	if (upgrade == upgrade_id) update_upgrade_level(client);
}

public void update_upgrade_level(int client) {
	Player player = Player(client);
	upgrade_levels[player.id] = player.has_upgrade(upgrade_id);
}

public Action Dissolve_Timer(Handle timer, DataPack Data) {
	Player client_player = Player(Data.ReadCell());
	int ragdoll_ent = Data.ReadCell();
	Effect_DissolveEntity(ragdoll_ent, DISSOLVE_ELECTRICAL,-1);
	CloseHandle(Data);
	SetEntProp(ragdoll_ent, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID|FSOLID_TRIGGER); 
	SetEntProp(ragdoll_ent, Prop_Data, "m_nSolidType", SOLID_VPHYSICS); 
	SetEntProp(ragdoll_ent, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);  
	client_player.armour += 15;
	CPrintToChat(client_player.id, "Necrophilia!  Gained armour.");
}

public Action TTT_OnBodyChecked(int client, int[] iRagdollC)
{
	if (!TTT_IsClientValid(client)) return Plugin_Continue;

	Player client_player = Player(client);

	if (client_player.armour < 100 && upgrade_levels[client] > 0 && !StrEqual(iRagdollC[Weaponused], "Necrophilia", false)) {
		Format(iRagdollC[Weaponused], MAX_NAME_LENGTH, "Necrophilia");
		DataPack Data = CreateDataPack();
		Data.WriteCell(client);
		Data.WriteCell(iRagdollC[Ent]);
		Data.Reset();
		CreateTimer(2.0, Dissolve_Timer, Data);
	}


	return Plugin_Continue;
}