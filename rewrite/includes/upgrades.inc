#if defined _upgrades_included
	#endinput
#endif
#define _upgrades_included

#define Upgrade_Invisibility 2

native int get_upgrade_points(int client_id, int upgrade_id);

public int Upgrade_GetPoints(int client, int upgrade) {
	return get_upgrade_points(client, upgrade);
}

public int Upgrade_Limit(int value, int min, int max) {
	if (value < min) return min;
	if (value > max) return max;
	return value;
}