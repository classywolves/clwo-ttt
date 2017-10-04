#include <sdkhooks>
#include <ttt_helpers>
#include <halflife>

// Define a free upgrade_id to this plugin.
#define upgrade_id 3
// Define the maximum points allowed.
#define max_points 4
// Define the sound file location.
#define bury_sound "sound/ttt_necrophilia_bury.mp3"

/**
* A global forward from sourcemod, gets called after map load and all cvars initialised.
*/
public void OnConfigsExecuted()
{
	// Prepare the sound file for use.
	PrecacheSound(bury_sound);
	AddFileToDownloadsTable(bury_sound);
}

/**
* This is the callback for the timer which is created in TTT_OnBodyChecked().
* @param timer Handle to the timer.
* @param Data A DataPack object, containing client_id and ragdoll_ent.
* @return Nothing.
*/
public Action Dissolve_Timer(Handle timer, DataPack Data) {
	// Assign the values from the DataPack to variables.
	Player client_player = Player(Data.ReadCell());
	int ragdoll_ent = Data.ReadCell();
	CloseHandle(Data);

	if (client_player.has_upgrade(upgrade_id) == max_points) {
		// Allow entity to fall through the floor.
		SetEntProp(ragdoll_ent, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID|FSOLID_TRIGGER); 
		SetEntProp(ragdoll_ent, Prop_Data, "m_nSolidType", SOLID_VPHYSICS); 
		SetEntProp(ragdoll_ent, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);  
		// Begin the dissolve process for the ragdoll.
		Effect_DissolveEntity(ragdoll_ent, DISSOLVE_ELECTRICAL,-1);
		// Fetch the position of the ragdoll.
		float position[3];
		GetEntPropVector(ragdoll_ent, Prop_Send, "m_vecOrigin", position);
		// Play a sound for the dissolving effect
		EmitAmbientSound(bury_sound, position, ragdoll_ent, SNDLEVEL_CONVO);
	}

	// Calculate the random armour amount.
	int random_armour = (GetRandomInt(40, 60) * client_player.has_upgrade(upgrade_id)) / GetClientCount(true);
	// Limit maximum armour gained to 15 and set the armour.
	random_armour = (15 < random_armour) ? random_armour : 15
	client_player.armour += random_armour;

	CPrintToChat(client_player.id, "Necrophilia!  Gained %d armour!", random_armour);
}

/**
* A global forward from the TTT library, called when someone presses 'E' on a ragdoll.
* @param client The client id of the person which checked a body.
* @param iRagdollC An integer array, which is mapped to the Ragdolls enum.
* @return Plugin_Continue.
*/
public Action TTT_OnBodyChecked(int client, int[] iRagdollC)
{
	if (!TTT_IsClientValid(client)) return Plugin_Continue;

	Player client_player = Player(client);

	if (client_player.armour < 100 && (client_player.has_upgrade(upgrade_id) > 0 && client_player.has_upgrade(upgrade_id) <= max_points) && !StrEqual(iRagdollC[Weaponused], "Necrophilia", false)
		&& iRagdollC[Found]) {
		// Set the Weaponused state, used to prevent duplicate uses.
		Format(iRagdollC[Weaponused], MAX_NAME_LENGTH, "Necrophilia");
		// Write data to the DataPack.
		DataPack Data = CreateDataPack();
		Data.WriteCell(client);
		Data.WriteCell(iRagdollC[Ent]);
		Data.Reset();
		// Delay the time to harvest a body.
		CreateTimer(2.0, Dissolve_Timer, Data);
	}

	return Plugin_Continue;
}