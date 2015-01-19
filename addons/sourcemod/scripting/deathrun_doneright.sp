#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <csgocolors>

#define TEAM_T 2
#define TEAM_CT 3
#define PLUGIN_VERSION "1.0"

new Handle:deathrundr_version = INVALID_HANDLE;
new Handle:deathrundr_enable = INVALID_HANDLE;
new Handle:deathrundr_check_maps = INVALID_HANDLE;
new Handle:deathrundr_rounds_as_t = INVALID_HANDLE;
new Handle:deathrundr_block_radio = INVALID_HANDLE;
new Handle:deathrundr_enable_queue = INVALID_HANDLE;
new Handle:deathrundr_needed_players = INVALID_HANDLE;

new Handle:TQueue = INVALID_HANDLE;

new RoundSinceT[MAXPLAYERS+1];

public Plugin:myinfo =
{
    name = "Deathrun Done Right",
    author = "The1Speck",
    description = "A more complete and flexible solution for CS:S/CS:GO deathrun servers",
    version = PLUGIN_VERSION,
    url = "http://www.tangoworldwide.net"
}

public OnPluginStart()
{
	AddCommandListener(BlockRadio, "coverme");
	AddCommandListener(BlockRadio, "takepoint");
	AddCommandListener(BlockRadio, "holdpos");
	AddCommandListener(BlockRadio, "regroup");
	AddCommandListener(BlockRadio, "followme");
	AddCommandListener(BlockRadio, "takingfire");
	AddCommandListener(BlockRadio, "go");
	AddCommandListener(BlockRadio, "fallback");
	AddCommandListener(BlockRadio, "sticktog");
	AddCommandListener(BlockRadio, "getinpos");
	AddCommandListener(BlockRadio, "stormfront");
	AddCommandListener(BlockRadio, "report");
	AddCommandListener(BlockRadio, "roger");
	AddCommandListener(BlockRadio, "enemyspot");
	AddCommandListener(BlockRadio, "needbackup");
	AddCommandListener(BlockRadio, "sectorclear");
	AddCommandListener(BlockRadio, "inposition");
	AddCommandListener(BlockRadio, "reportingin");
	AddCommandListener(BlockRadio, "getout");
	AddCommandListener(BlockRadio, "negative");
	AddCommandListener(BlockRadio, "enemydown");
	AddCommandListener(Cmd_JoinTeam, "jointeam");
	
	deathrundr_version = CreateConVar("deathrundr_version", PLUGIN_VERSION, "Deathrun Done Right version; not changeable", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	deathrundr_enable = CreateConVar("deathrundr_enable", "1", "Enable or disable the Deathrun Done Right; 0 - disabled, 1 - enabled", 0, true, 0.0, true, 1.0);
	deathrundr_check_maps = CreateConVar("deathrundr_check_maps", "1", "Enable or disable the checking of whether or not the map is deathrun. 0 disabled, 1 - enabled.", 0, true, 0.0, true, 1.0);
	deathrundr_rounds_as_t = CreateConVar("deathrundr_rounds_as_t", "1", "How many consecutive rounds can you play as T?", 0, true, 1.0);
	deathrundr_block_radio = CreateConVar("deathrundr_block_radio", "1", "Should radio commands be blocked?", 0, true, 0.0, true, 1.0);
	deathrundr_enable_queue = CreateConVar("deathrundr_enable_queue", "1", "Enable or disable the T-queue implementation. 0 disabled, 1 - enabled.", 0, true, 0.0, true, 1.0);
	deathrundr_needed_players = CreateConVar("deathrundr_needed_players", "3", "Set how many players are needed to enable autoswitching", 0, true, 1.0);
	
	HookEvent("round_end", Event_RoundEnd);
	
	RegConsoleCmd("sm_last", Cmd_Last);
	if(GetConVarBool(deathrundr_enable_queue))
	{
		RegAdminCmd("sm_queueadmin", Cmd_QueueAdmin, ADMFLAG_GENERIC);
		RegConsoleCmd("sm_queue", Cmd_Queue);
		TQueue = CreateArray();
	}
	
	SetConVarString(deathrundr_version, PLUGIN_VERSION);
	AutoExecConfig(true, "deathrun_doneright");
}

public Action:Cmd_Last(client, args)
{
	ReplyToCommand(client, "%d", RoundSinceT[client]);
}

OpenQueueClientMenu(client)
{
	new Handle:menu = CreateMenu(Menu_ViewQueue);
	SetMenuTitle(menu, "Terrorist Queue");
	new queueSize = GetArraySize(TQueue);
	for(new i = 0; i < queueSize; i++)
	{
		new String:info[10], String:display[MAX_NAME_LENGTH];
		Format(info, sizeof(info), "%i", GetArrayCell(TQueue, i));
		Format(display, sizeof(display), "%N", GetArrayCell(TQueue, i));
		AddMenuItem(menu, info, display, ITEMDRAW_DISABLED);
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public Menu_ViewQueue(Handle:menu, MenuAction:action, param1, param2)
{
}

public Menu_ClientChoose(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		if(StrEqual(info, "view"))
			OpenQueueClientMenu(param1);
		else if(StrEqual(info, "join"))
		{
			if(GetClientTeam(param1) == TEAM_T)
			{
				CPrintToChat(param1, "{NORMAL}[{BLUE}Deathrun{NORMAL}] You are already Terrorist, don't be greedy!");
				return;
			}
			if(FindValueInArray(TQueue, param1) == -1)
			{
				PushArrayCell(TQueue, param1);
				CPrintToChat(param1, "{NORMAL}[{BLUE}Deathrun{NORMAL}] You have been added to the Terrorist Queue!");
			} else {
				CPrintToChat(param1, "{NORMAL}[{BLUE}Deathrun{NORMAL}] You are already in the Queue!");
			}			
		}
	}
}

public Action:Cmd_Queue(client, args)
{
	new Handle:menu = CreateMenu(Menu_ClientChoose);
	SetMenuTitle(menu, "Queue Menu");
	AddMenuItem(menu, "view", "View The Queue");
	AddMenuItem(menu, "join", "Join The Queue");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public Action:Cmd_QueueAdmin(client, args)
{
}

public OnConfigsExecuted()
{
	if(GetConVarBool(deathrundr_enable) && GetConVarBool(deathrundr_check_maps))
	{
		//Credit to bobbobagan
		decl String:mapname[128];
		GetCurrentMap(mapname, sizeof(mapname));
  
		if (strncmp(mapname, "dr_", 3, false) == 0 || (strncmp(mapname, "deathrun_", 9, false) == 0) || (strncmp(mapname, "dtka_", 5, false) == 0))
		{
			LogMessage("Deathrun map detected. Enabling Deathrun Done Right.");
			SetConVarInt(deathrundr_enable, 1);
		}
		else
		{
			LogMessage("Current map is not a deathrun map. Disabling Deathrun Done Right.");
			SetConVarInt(deathrundr_enable, 0);
		}
	}
}

public OnMapStart()
{
	if(GetConVarBool(deathrundr_enable))
		ServerCommand("mp_autoteambalance 0; mp_limitteams 0; mp_warmuptime 0");
}

public OnClientPostAdminCheck(client)
{
	RoundSinceT[client] = 0;
}

public OnClientDisconnect(client)
{
	RoundSinceT[client] = 0;
	if(GetConVarBool(deathrundr_enable_queue) && FindValueInArray(TQueue, client) != -1)
	{
		RemoveFromArray(TQueue, FindValueInArray(TQueue, client));
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new CurrentPlayers = GetTeamClientCount(TEAM_CT) + GetTeamClientCount(TEAM_T);
	if(GetConVarBool(deathrundr_enable) && CurrentPlayers >= GetConVarInt(deathrundr_needed_players))
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			RoundSinceT[i]++;
		}
		
		new nT = -1, oT = -1; //New Terrorist, Old Terrorist
		if(GetConVarBool(deathrundr_enable_queue) && GetArraySize(TQueue) != 0)
		{
			//If Queue is implemented and has people in it..
			nT = (GetArrayCell(TQueue, 0));
			RemoveFromArray(TQueue, 0);
		} else {
			//Lets just do it randomly
			if(GetTeamClientCount(TEAM_CT) > 0)
			{
				do
				{
					nT = GetRandomInt(1, MaxClients);
				}
				while(!IsClientInGame(nT) || GetClientTeam(nT) != TEAM_CT);
			}
		}
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && GetClientTeam(i) == TEAM_T)
				oT = i;
		}
		
		if(nT != -1 && nT != 0 && oT != -1)
		{
			CS_SwitchTeam(nT, TEAM_T);
			RoundSinceT[nT] = 0;
			if(oT != -1)
				CS_SwitchTeam(oT, TEAM_CT);
		}
	}
}

public Action:BlockRadio(client, const String:command[], args)
{	
	//Credit to bobbobagan
    if (GetConVarBool(deathrundr_enable) && (GetConVarBool(deathrundr_block_radio)))
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action:Cmd_JoinTeam(client, const String:command[], args)
{
	new CurrentPlayers = GetTeamClientCount(TEAM_CT) + GetTeamClientCount(TEAM_T);
	if(GetConVarBool(deathrundr_enable) && CurrentPlayers >= GetConVarInt(deathrundr_needed_players) && GetTeamClientCount(TEAM_T) == 1)
	{
		new String:arg[32];
		GetCmdArg(1, arg, sizeof(arg));
	
		if(StringToInt(arg) == TEAM_T)
		{
			PrintHintText(client, "You cannot join T manually!");
			UTIL_TeamMenu(client);
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

//Credit to databomb's CTBan Plugin
UTIL_TeamMenu(client)
{
	new clients[1];
	new Handle:bf;
	clients[0] = client;
	bf = StartMessage("VGUIMenu", clients, 1);
	
	if (GetUserMessageType() == UM_Protobuf)
	{
		PbSetString(bf, "name", "team");
		PbSetBool(bf, "show", true);
	}
	else
	{
		BfWriteString(bf, "team"); // panel name
		BfWriteByte(bf, 1); // bShow
		BfWriteByte(bf, 0); // count
	}
	
	EndMessage();

}