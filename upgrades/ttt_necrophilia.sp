#include <sdkhooks>

#include <ttt_helpers>
#include <halflife>

#define upgrade_id 3

public Action Dissolve_Timer(Handle timer, DataPack Data) {
	Player client_player = Player(Data.ReadCell());
	int ragdoll_ent = Data.ReadCell();
	CloseHandle(Data);

	Effect_DissolveEntity(ragdoll_ent, DISSOLVE_ELECTRICAL,-1);
	
	SetEntProp(ragdoll_ent, Prop_Send, "m_usSolidFlags", FSOLID_NOT_SOLID|FSOLID_TRIGGER); 
	SetEntProp(ragdoll_ent, Prop_Data, "m_nSolidType", SOLID_VPHYSICS); 
	SetEntProp(ragdoll_ent, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);  


	int random_armour = GetRandomInt(80, 120) / GetClientCount(true);
	client_player.armour += random_armour;

	CPrintToChat(client_player.id, "Necrophilia!  Gained %d armour!", random_armour);
}

public Action TTT_OnBodyChecked(int client, int[] iRagdollC)
{
	if (!TTT_IsClientValid(client)) return Plugin_Continue;

	Player client_player = Player(client);

	if (client_player.armour < 100 && client_player.has_upgrade(upgrade_id) > 0 && !StrEqual(iRagdollC[Weaponused], "Necrophilia", false)
		&& iRagdollC[Found]) {

		Format(iRagdollC[Weaponused], MAX_NAME_LENGTH, "Necrophilia");

		DataPack Data = CreateDataPack();
		Data.WriteCell(client);
		Data.WriteCell(iRagdollC[Ent]);
		Data.Reset();

		CreateTimer(2.0, Dissolve_Timer, Data);
	}

	return Plugin_Continue;
}