// Forlix FloodCheck
// http://forlix.org/, df@forlix.org
//
// Copyright (c) 2008-2013 Dominik Friedrichs

//- Includes -//

#include <sdktools>


//- Natives -//

// SourceBans++
native void SBPP_BanPlayer(int iAdmin, int iTarget, int iTime, const char[] sReason);
native void SBPP_ReportPlayer(int iReporter, int iTarget, const char[] sReason);

// Sourcebans 2.X
native void SBBanPlayer(client, target, time, char[] reason);
native void SB_ReportPlayer(int client, int target, const char[] reason);


//- Defines -//

#define PLUGIN_VERSION "0.1" // TODO: No versioning till the first stable Release

#define VOICE_LOOPBACK_MSG "Voice loopback not allowed!\nYou have been muted."

#define MALFORMED_NAME_MSG "Malformed player name (control chars, zero length, ...)"
#define MALFORMED_MESSAGE_MSG "Malformed message (control chars, zero length, ...)"

#define FLOOD_HARD_MSG "Temporary ban for %s (Hard-flooding)"
#define FLOOD_NAME_MSG "Temporary ban for %s (Name-flooding)"
#define FLOOD_CONNECT_MSG "Too quick successive connection attempts, try again in %s"

#define LOG_MSG_LOOPBACK_MUTE "[Forlix_FloodCheck] %N muted for voice loopback"

#define NAME_STR_EMPTY "empty"
#define REASON_STR_EMPTY "Empty reason"

#define HARD_TRACK 16
#define CONNECT_TRACK 16

#define MAX_NAME_LEN 32
#define MAX_MSG_LEN 128
#define MAX_IPPORT_LEN 32
#define MAX_STEAMID_LEN 32

#define REASON_TRUNCATE_LEN 63 // can be max MAX_MSG_LEN-2 // the game now truncates to 63 but only clientside


//- Global Variables -//

bool g_bSourceBans, g_bSourceBansPP;

//- ConVars -//

//- Misc -//
bool g_bExcludeChatTriggers, g_bMuteVoiceLoopback;
//- Chat -//
float g_fChatInterval;
int g_iChatNum;
//- Hard Flood -//
float g_fHardInterval;
int g_iHardNum, g_iHardBanTime;
//- Namecheck -//
float g_fNameInterval;
int g_iNameNum, g_iNameBanTime;
//- Connect Check -//
float g_fConnectInterval;
int g_iConnectNum, g_iConnectBanTime;


public Plugin myinfo = 
{
	name = "Forlix FloodCheck Redux", 
	author = "Playa (Formerly Dominik Friedrichs)", 
	description = "An Universal Anti Spam, Flood and Exploit Solution compactible with most Source Engine Games", 
	version = PLUGIN_VERSION, 
	url = "FunForBattle"
}


//- FFC Modules -// Note that the ordering of these Includes is important

//- ConVars -//
#include "FFC/ff_convars.sp"
#include "FFC/ff_markcheats.sp"
#include "FFC/ff_events.sp"
//- Chat -//
#include "FFC/ff_chatflood.sp"
//- Hard Flood -//
#include "FFC/ff_hardflood.sp"
//- Namecheck -//
#include "FFC/ff_nameflood.sp"
//- Connect Check -//
#include "FFC/ff_connectflood.sp"
//- Voice Loopback -//
#include "FFC/ff_voiceloopback.sp"
#include "FFC/ff_toolfuncs.sp"


//////////////////

static bool late_load;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, err_max)
{
	CreateNative("IsClientFlooding", Native_IsClientFlooding);
	
	late_load = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	RegPluginLibrary("forlix_floodcheck");
	
	// chat and radio flood checking
	RegConsoleCmd("say", FloodCheckChat);
	RegConsoleCmd("say_team", FloodCheckChat);
	
	HookEvent("player_connect", Event_PlayerConnect, EventHookMode_Pre);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	HookEvent("player_changename", Event_PlayerChangename, EventHookMode_Pre);
	
	// game-specific setup
	char gamedir[16];
	GetGameFolderName(gamedir, sizeof(gamedir));
	
	if(StrEqual(gamedir, "cstrike")) // counter-strike: source
		SetupChatDetection_cstrike();
		
	else if(StrEqual(gamedir, "dod")) // day of defeat: source
		SetupChatDetection_dod();
		
	else if(StrEqual(gamedir, "tf")) // team fortress 2
		SetupChatDetection_tf();
		
	else // all other games
		SetupChatDetection_misc();
		
	SetupConVars();
	MarkCheats();
	
	FloodCheckConnect_PluginStart();
	
	if(late_load)
		Query_VoiceLoopback_All();
		
	late_load = false;
}

public void OnPluginEnd()
{
	FloodCheckConnect_PluginEnd();
}

public void OnAllPluginsLoaded()
{
	if (FindPluginByFile("sbpp_main.smx"))
		g_bSourceBansPP = true;
		
	else if (FindPluginByFile("sourcebans.smx"))
		g_bSourceBans = true;
		
	else // Rare but possible, someone unloaded SB and we would still think its active :O
	{
		g_bSourceBansPP = false;
		g_bSourceBans = false;
	}
	
	if(g_bSourceBansPP && g_bSourceBans)
		LogError("[Warning] Sourcebans++ and Sourcebans 2.X are installed at the same Time! This can Result in Problems, FFC will only use SB++ for now");
}

public bool OnClientConnect(client, char[] rejectmsg, maxlen)
{
	if(!IsClientNameAllowed(client))
	{
		strcopy(rejectmsg, maxlen, MALFORMED_NAME_MSG);
		return false;
	}
	
	return true;
}

public OnClientSettingsChanged(client)
{
	if(!IsClientInGame(client) || IsFakeClient(client))
		return;
		
	Query_VoiceLoopback(client);
	
	if(!IsClientNameAllowed(client))
		KickClient(client, MALFORMED_NAME_MSG);
		
	// make sure client cant hardflood us with settingschanged
	FloodCheckHard(client);
	return;
}

public OnClientConnected(client)
{
	//- Chat -//
	FloodCheckChat_Connect(client);
	//- Hard Flood -//
	FloodCheckHard_Connect(client);
	//- Namecheck -//
	FloodCheckName_Connect(client);
	
	return;
}

public Action OnClientCommand(client, args)
{
	FloodCheckHard(client);
	return Plugin_Continue;
}