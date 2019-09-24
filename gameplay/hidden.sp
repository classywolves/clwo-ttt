#pragma semicolon 1

//Base CS:GO Plugin Requirements
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

//Custom includes
#include <ttt>
#include <gamemodes>
#include <chat-processor>
#include <ttt_messages>
#include <ttt_targeting>    
#include <generics>
#include <colorvariables>
#include <smlib/math>

Handle gha_HiddenGravityTimers[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
Handle gha_HiddenDustTimers[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };

bool gba_WantsHidden[MAXPLAYERS + 1] = { false, ... }; 
bool gba_Hidden[MAXPLAYERS + 1] = { false, ... };

bool gb_HiddenRoundNR = false;
bool gb_HiddenRound = false;

int gia_ErrorTimeout[MAXPLAYERS + 1];
int gia_ClientKnife[MAXPLAYERS + 1] = { 0, ... };
int gia_LastPounceTime[MAXPLAYERS + 1] = { 0, ... };
int gia_LastPounceError[MAXPLAYERS + 1] = { 0, ... };

int gi_HiddenCountdown = 10;
int gi_HowManyWantHidden = 0;

ConVar cv_MPTeammatesAreEnemies;
ConVar cv_MPDropKnife;
ConVar cv_CustomGMNR;

ConVar cv_HiddenSpeed = null;
ConVar cv_HiddenGravity = null;
ConVar cv_HiddenHealth = null;
ConVar cv_HiddenHealthCT = null;
ConVar cv_HiddenDustTime = null;
ConVar cv_HiddenDustSize = null;
ConVar cv_HiddenDustSpeed = null;
ConVar cv_HiddenPouncePower = null;
ConVar cv_HiddenPounceAngle = null;


public void OnPluginStart()
{
    PrintToChatAll("[HID] Loaded successfully");
    
    LoopValidClients(i)
    {
        HookActions(i);
    }

    cv_MPTeammatesAreEnemies = FindConVar("mp_teammates_are_enemies");
    cv_MPDropKnife = FindConVar("mp_drop_knife_enable");
    cv_CustomGMNR = FindConVar("cv_CustomGMNR");

    cv_HiddenSpeed = CreateConVar("cv_HiddenSpeed", "1.1", "Speed of the Hidden", FCVAR_NOTIFY, true, 1.0, true, 10.0);
    cv_HiddenGravity = CreateConVar("cv_HiddenGravity", "0.9", "Gravity of the Hidden", FCVAR_NOTIFY, true, 0.1, true, 1.0);
    cv_HiddenHealth = CreateConVar("cv_HiddenHealth", "100", "Health of the Hidden", FCVAR_NOTIFY, true, 25.0, true, 100.0);
    cv_HiddenHealthCT = CreateConVar("cv_HiddenHealthCT", "100", "Health of the CT side", FCVAR_NOTIFY, true, 100.0, true, 500.0);
    cv_HiddenDustTime = CreateConVar("cv_HiddenDustTime", "4", "How many seconds between each dust particle is created", FCVAR_NOTIFY, true, 0.0, true, 600.0);
    cv_HiddenDustSize = CreateConVar("cv_HiddenDustSize", "20", "How big is the dust particle", FCVAR_NOTIFY, true, 0.0, true, 1000.0);
    cv_HiddenDustSpeed = CreateConVar("cv_HiddenDustSpeed", "0", "How fast is the dust particle", FCVAR_NOTIFY, true, 0.0, true, 1000.0);
    cv_HiddenPouncePower = CreateConVar("cv_HiddenPouncePower", "700.0", "Power of the Hidden pounce", FCVAR_NOTIFY, true, 450.0, true, 1000.0);
    cv_HiddenPounceAngle = CreateConVar("cv_HiddenPounceAngle", "35.0", "Angle forced upwards of pounce", FCVAR_NOTIFY, true, 20.0, true, 50.0);

    RegConsoleCmd("say", Command_Say);

    RegAdminCmd("sm_reloadhidden", Command_ReloadHidden, ADMFLAG_GENERIC, "Reload Hidden Plugin");
    RegAdminCmd("sm_hidden", Command_Hidden, ADMFLAG_VOTE, "Begin Hidden Gamemode");
    RegAdminCmd("sm_cancelhidden", Command_CancelHidden, ADMFLAG_VOTE, "Cancel Hidden Gamemode");
    RegAdminCmd("sm_chs", Command_CHS, ADMFLAG_ROOT, "Change Hidden Speed");
    RegAdminCmd("sm_chg", Command_CHG, ADMFLAG_ROOT, "Change Hidden Gravity");
    RegAdminCmd("sm_chh", Command_CHH, ADMFLAG_ROOT, "Change Hidden Health");
    RegAdminCmd("sm_chhct", Command_CHHCT, ADMFLAG_ROOT, "Change Hidden CT Health");
}

public Action Command_Say(int client, int args)
{
    char text[192], command[64];
	GetCmdArgString(text, sizeof(text));
	GetCmdArg(0, command, sizeof(command));

	int startidx = 0;
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}

	if (strcmp(text[startidx], "hidden", false) == 0)
	{
        if(gb_HiddenRoundNR)
        {
            PrintToChat(client, "[HID] Hidden has already been voted for");
            return Plugin_Continue;
        }
        if(gb_HiddenRound)
        {
            PrintToChat(client, "[HID] Hidden has already started");
            return Plugin_Continue;
        }
        if(gba_WantsHidden[client])
        {
            PrintToChat(client, "[HID] You already voted for hidden");
            return Plugin_Continue;
        }
        if(cv_CustomGMNR.BoolValue)
        {
            PrintToChat(client, "[TDM] A custom gamemode has already been voted for");
            return Plugin_Continue;
        }
        int total = 0;
        int votesNeeded = 0;
        LoopValidClients(i)
        {  
            total++;
        }
        votesNeeded = total - total/3;
        gba_WantsHidden[client] = true;
        gi_HowManyWantHidden++;
        WantsToPlay(client, "Hidden", gi_HowManyWantHidden, votesNeeded);
        if(gi_HowManyWantHidden >= votesNeeded)
        {
            CPrintToChatAll("[HID] Next round will be Hidden");
            LoopValidClients(i)
            {
                gba_WantsHidden[i] = false;
                gi_HowManyWantHidden = 0;
            }
            cv_CustomGMNR.SetBool(true, false, true);
            gb_HiddenRoundNR = true;
            return Plugin_Continue;
        }
        return Plugin_Continue;
    }
    else 
    {
        return Plugin_Continue;
    }
}

public Action Command_ReloadHidden(int client, int args)
{
    char buffer[256];
    ServerCommandEx(buffer, sizeof(buffer), "sm plugins reload clwo/gameplay/hidden");
    PrintToConsole(client, "%s", buffer);
    return Plugin_Handled;
}

public Action Command_Hidden(int client, int args)
{
    if(gb_HiddenRoundNR)
    {
        CPrintToChat(client, "[HID] Hidden Round has already been started!");
        return Plugin_Handled;
    }
    else
    {
        CPrintToChatAll("[HID] Next round will be Hidden");
        gb_HiddenRoundNR = true;
        cv_CustomGMNR.SetBool(true, false, true);
        return Plugin_Handled;
    }
}

public Action Command_CancelHidden(int client, int args)
{
    if(gb_HiddenRoundNR)
    {
        gb_HiddenRoundNR = false;
        CPrintToChatAll("[HID] Hidden cancelled");
        cv_CustomGMNR.SetBool(false, false, true);
    }
    return Plugin_Handled;
}

public Action Command_CHS(int client, int args)
{
    if(args < 1)
    {
        CPrintToChat(client, "[HID] cv_HiddenSpeed = %f", cv_HiddenSpeed.FloatValue);
        CPrintToChat(client, TTT_USAGE ... "sm_chs [speed]");
        return Plugin_Handled;
    }

    char buffer[256];
    GetCmdArg(1, buffer, sizeof(buffer));

    cv_HiddenSpeed.SetFloat(StringToFloat(buffer), false, true);
    return Plugin_Handled;
}

public Action Command_CHG(int client, int args)
{
    if(args < 1)
    {
        CPrintToChat(client, "[HID] cv_HiddenGravity = %f", cv_HiddenGravity.FloatValue);
        CPrintToChat(client, TTT_USAGE ... "sm_chg [gravity]");
        return Plugin_Handled;
    }

    char buffer[256];
    GetCmdArg(1, buffer, sizeof(buffer));

    cv_HiddenGravity.SetFloat(StringToFloat(buffer), false, true);
    return Plugin_Handled;
}

public Action Command_CHH(int client, int args)
{
    if(args < 1)
    {
        CPrintToChat(client, "[HID] cv_HiddenHealth = %i", cv_HiddenHealth.IntValue);
        CPrintToChat(client, TTT_USAGE ... "sm_chh [health]");
        return Plugin_Handled;
    }

    char buffer[256];
    GetCmdArg(1, buffer, sizeof(buffer));

    cv_HiddenHealth.SetInt(StringToInt(buffer), false, true);
    return Plugin_Handled;
}

public Action Command_CHHCT(int client, int args)
{
    if(args < 1)
    {
        CPrintToChat(client, "[HID] cv_HiddenHealthCT = %i", cv_HiddenHealthCT.IntValue);
        CPrintToChat(client, TTT_USAGE ... "sm_chhct [health]");
        return Plugin_Handled;
    }

    char buffer[256];
    GetCmdArg(1, buffer, sizeof(buffer));

    cv_HiddenHealthCT.SetInt(StringToInt(buffer), false, true);
    return Plugin_Handled;
}

public void HiddenPerformPounce(int client, int time)
{
    if (time - gia_LastPounceTime[client] > 3)
    {
        bool valid_jump = true;        
        float ClientAbsOrigin[3];
        float ClientEyeAngles[3];
        float Velocity[3];

        GetClientAbsOrigin(client, ClientAbsOrigin);
        GetClientEyeAngles(client, ClientEyeAngles);
        float EyeAngleZero = ClientEyeAngles[0];
        float ClientOriginTwo = ClientAbsOrigin[2];

        if(EyeAngleZero >= 30.0 && EyeAngleZero <= 90.0)
        {
            valid_jump = false;
        }

        ClientEyeAngles[0] = ClientEyeAngles[0] - cv_HiddenPounceAngle.FloatValue;

        if(ClientEyeAngles[0] <= -90.0)
        {
            ClientEyeAngles[0] = EyeAngleZero;
        }

        GetAngleVectors(ClientEyeAngles, Velocity, NULL_VECTOR, NULL_VECTOR);
        ScaleVector(Velocity, cv_HiddenPouncePower.FloatValue);

        ClientAbsOrigin[2] += 10;
        ClientEyeAngles[0] = EyeAngleZero;

        if(valid_jump)
        {
            TE_SetupDust(ClientAbsOrigin, NULL_VECTOR, 100.0, 0.0);
            TE_SendToAll(0.0);
            ClientAbsOrigin[2] = ClientOriginTwo;
            ClientEyeAngles[0] = EyeAngleZero; 
            TeleportEntity(client, ClientAbsOrigin, ClientEyeAngles, Velocity);
            gia_LastPounceTime[client] = GetTime();
        }
    }
    else 
    {    
        if(time - gia_LastPounceError[client] > 1)
        {
            gia_LastPounceError[client] = time;
            CPrintToChat(client, "[HID] You cannot pounce so often");
        }
    }
}

public void TTT_OnRoundStart(int innocents, int traitors, int detectives)
{
    gi_HiddenCountdown = 10;

    if(gb_HiddenRoundNR)
    {
        HiddenPanel();
        HookDMG();
        CreateTimer(1.0, Timer_HiddenCountdown, 1, TIMER_REPEAT);
    }
}

public void TTT_OnRoundEnd(int winner, Handle array)
{
    if(gb_HiddenRound)
    {
        EndHidden();
    }
}

public void BeginHidden()
{
    cv_MPTeammatesAreEnemies.SetBool(false, true, true);
    cv_MPDropKnife.SetBool(false, true, true);

    HiddenPanel();
    
    gb_HiddenRoundNR = false;
    gb_HiddenRound = true;

    SetUpTeams(4);
    SetHealth(cv_HiddenHealthCT.IntValue, cv_HiddenHealth.IntValue);
    SetSpeed(TTT_TEAM_TRAITOR, cv_HiddenSpeed.FloatValue);
    SetGravity(TTT_TEAM_TRAITOR, cv_HiddenGravity.FloatValue);
    CreateHiddenTimers();

    LoopAliveClients(i)
    {
        if(TTT_GetClientRole(i) == TTT_TEAM_TRAITOR)
        {
            gba_Hidden[i] = true;
        }
    }

    UnHookDMG();
    CPrintToChatAll("[HID] Hidden has started!");
}

public Action Timer_HiddenCountdown(Handle timer, int pass)
{
    if(gi_HiddenCountdown == 0)
    {
        UnHookDMG();
        BeginHidden();
        ClearTimer(timer);
        gb_HiddenRoundNR = false;
        cv_CustomGMNR.SetBool(false, false, true);
        return Plugin_Stop;
    }

    PrintCenterTextAll("Hidden Starting in: %i", gi_HiddenCountdown);
    CPrintToChatAll("[HID] Hidden starting in: %i", gi_HiddenCountdown);    
    gi_HiddenCountdown--;
    return Plugin_Continue;
}

public void HiddenPanel()
{
    Panel panel = new Panel();
    panel.SetTitle("HIDDEN");
    panel.DrawItem("", ITEMDRAW_SPACER);
    panel.DrawText("This is the Hidden gamemode");
    panel.DrawItem("", ITEMDRAW_SPACER);
    panel.DrawText("Some players are invisible and the rest are not, the invisible players ");
    panel.DrawText("If they right click with their knife they pounce with a 3 second delay");
    panel.DrawText("Everyone else is Detective and had to find the Traitors");
    panel.DrawItem("", ITEMDRAW_SPACER);
    panel.CurrentKey = GetMaxPageItems(panel.Style);
    panel.DrawItem("Exit", ITEMDRAW_CONTROL);

    LoopValidClients(i)
    {
        panel.Send(i, HandlerDoNothing, 30);
    }

    delete panel;    
}

public void EndHidden()  
{
    LoopValidClients(i)
    {
        SetEntPropFloat(i, Prop_Send, "m_flLaggedMovementValue", 1.0);
        SetEntityGravity(i, 1.0);
        ClearHiddenTimers(i);
        gba_Hidden[i] = false;
    }
    cv_MPTeammatesAreEnemies.SetBool(true, true, true);
    cv_MPDropKnife.SetBool(true, true, true);
    gb_HiddenRoundNR = false;
    gb_HiddenRound = false;
}

public void HookActions(int client)
{   
    SDKHook(client, SDKHook_SetTransmit, Hook_HiddenSetTransmit);
    SDKHook(client, SDKHook_WeaponSwitchPost, Hook_HiddenOnWeaponSwitchPost);
    SDKHook(client, SDKHook_WeaponCanUse, Hook_HiddenWeaponCanUse);
}

public void HookDMG()
{
    LoopValidClients(i)
    {
        SDKHook(i, SDKHook_OnTakeDamage, Hidden_TakeDMG);
    }
}

public void UnhookActions(int client)
{
    SDKUnhook(client, SDKHook_SetTransmit, Hook_HiddenSetTransmit);
    SDKUnhook(client, SDKHook_WeaponSwitchPost, Hook_HiddenOnWeaponSwitchPost);
    SDKUnhook(client, SDKHook_WeaponCanUse, Hook_HiddenWeaponCanUse);
    ClearHiddenTimers(client);
}

public void UnHookDMG()
{
    LoopValidClients(i)
    {
        SDKUnhook(i, SDKHook_OnTakeDamage, Hidden_TakeDMG);
    }
}

public Action Hidden_TakeDMG(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, 
                            int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if(gb_HiddenRoundNR && damagetype != DMG_FALL)
    {
        damage = 0.0;
        return Plugin_Changed;
    }
    else
    {
        return Plugin_Continue;
    }
}

public Action Hook_HiddenSetTransmit(int entity, int client)
{
    if(gba_Hidden[entity] && IsValidClient(entity) && !gba_Hidden[client] && client != entity && IsPlayerAlive(client) && gb_HiddenRound)
    {
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

public Action Hook_HiddenOnWeaponSwitchPost(int client, int weapon)
{
    char weaponName[256];
    GetClientWeapon(client, weaponName, sizeof(weaponName));

    if(StrContains(weaponName, "knife", false) != -1)
    {
        gia_ClientKnife[client] = weapon;
    }

    if(!gba_Hidden[client])
    {
        return Plugin_Continue;
    }

    SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", cv_HiddenSpeed.FloatValue);

    if(!IsValidEntity(gia_ClientKnife[client]) || gia_ClientKnife[client] == 0)
    {
        SDKHooks_DropWeapon(client, weapon);
        RemoveEntity(weapon);
        return Plugin_Continue;
    }

    if(!CanHiddenUse(weaponName))
    {
        CPrintToChat(client, "[HID] You can only use certain items as Hidden");
        SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", gia_ClientKnife[client]);
    }

    return Plugin_Continue;
}

public Action Hook_HiddenWeaponCanUse(int client, int weapon)
{
    char weaponName[256];
    GetClientWeapon(client, weaponName, sizeof(weaponName));

    if(!gba_Hidden[client])
    {
        return Plugin_Continue;
    }

    if(!CanHiddenUse(weaponName) && gb_HiddenRound)
    {
        CPrintToChat(client, "[HID] You can only use certain items as Hidden");
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    int time = GetTime();
    char weaponName[256];
    GetClientWeapon(client, weaponName, sizeof(weaponName));
    if (buttons & IN_ATTACK || buttons & IN_ATTACK2)
    {
        if(!CanHiddenUse(weaponName) && gb_HiddenRound)
        {
            if (gba_Hidden[client]) 
            {
                if (ErrorTimeout(client, 2)) 
                {
                    CPrintToChat(client, "[HID] You cannot shoot as Hidden");
                }
                buttons &= ~IN_ATTACK;
                buttons &= ~IN_ATTACK2;
            }
        }
    }
    if (gb_HiddenRound && gba_Hidden[client] && buttons & IN_ATTACK2 && StrContains(weaponName, "knife", false) != -1)
    {
        HiddenPerformPounce(client, time);
    }

    return Plugin_Continue;
}

public void CreateHiddenTimers()
{
    LoopValidClients(i)
    {
        if(TTT_GetClientRole(i) == TTT_TEAM_TRAITOR)
        {
            gha_HiddenGravityTimers[i] = CreateTimer(0.1, HiddenGravityTimer, i, TIMER_REPEAT);
            gha_HiddenDustTimers[i] = CreateTimer(cv_HiddenDustTime.FloatValue, HiddenDustTimer, i, TIMER_REPEAT);
        }   
    }   
}

public Action HiddenGravityTimer(Handle timer, int client)
{
    if(gba_Hidden[client] && gb_HiddenRound)
    {
        SetEntityGravity(client, cv_HiddenGravity.FloatValue);
    }
}

public Action HiddenDustTimer(Handle timer, int client)
{
    if(gba_Hidden[client] && gb_HiddenRound && TTT_GetClientRole(client) == TTT_TEAM_TRAITOR && IsPlayerAlive(client))
    {
        float ClientAbsOrigin[3];

        GetClientAbsOrigin(client, ClientAbsOrigin);
        ClientAbsOrigin[2] += 10.0;

        TE_SetupDust(ClientAbsOrigin, NULL_VECTOR, cv_HiddenDustSize.FloatValue, cv_HiddenDustSpeed.FloatValue);
        TE_SendToAll(0.0);
    }
}

public void OnClientPutInServer(int client)
{
    gba_Hidden[client] = false;
    HookActions(client);
}

public void OnClientDisconnect(int client)
{
    gba_Hidden[client] = false;
    if(gba_WantsHidden[client])
    {
        gba_WantsHidden[client] = false;
        gi_HowManyWantHidden--;
    }
    SDKUnhook(client, SDKHook_OnTakeDamage, Hidden_TakeDMG);
    UnhookActions(client);
}

public bool CanHiddenUse(char[] weaponName)
{
    if(StrContains(weaponName, "knife", false) != -1 || 
    StrContains(weaponName, "healthshot", false) != -1 || 
    StrContains(weaponName, "fists", false) != -1 || 
    StrContains(weaponName, "bump", false) != -1 || 
    StrContains(weaponName, "breach", false) != -1 ||
    StrContains(weaponName, "taser", false) != -1)
    {
        return true;
    }

    return false;
}

public void ClearHiddenTimers(int client)
{
    if(gha_HiddenDustTimers[client] != INVALID_HANDLE)
    {
        ClearTimer(gha_HiddenDustTimers[client]);
        PrintToConsoleAll("[HID] %N's dust timer cleared", client);
    }
    if(gha_HiddenGravityTimers[client] != INVALID_HANDLE)
    {
        ClearTimer(gha_HiddenGravityTimers[client]);
        PrintToConsoleAll("[HID] %N's dust timer cleared", client);
    }
}

public bool ErrorTimeout(int client, int timeout)
{
    int currentTime = GetTime();
    if (currentTime - gia_ErrorTimeout[client] < timeout)
    {
        return true;
    }

    gia_ErrorTimeout[client] = currentTime;
    return false;
}