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

// BaseComm
native bool BaseComm_IsClientMuted(int client);
native bool BaseComm_SetClientMute(int client, bool muteState);
//native bool BaseComm_IsClientGagged(int client); TODO
//native bool BaseComm_SetClientGag(int client, bool gagState); TODO

// SourceComms
enum bType // Punishments Types
{
	bNot = 0,  // Player chat or voice is not blocked
	bSess,  // ... blocked for player session (until reconnect)
	bTime,  // ... blocked for some time
	bPerm // ... permanently blocked
}

native bType SourceComms_GetClientMuteType(int client);
native bool SourceComms_SetClientMute(int client, bool muteState, int muteLength = -1, bool saveToDB = false, const char[] reason = "Muted through natives");
// native bType SourceComms_GetClientGagType(int client); TODO
// native bool SourceComms_SetClientGag(int client, bool gagState, int gagLength = -1, bool saveToDB = false, const char[] reason = "Gagged through natives"); TODO

// SB-MaterialAdmin

#define MA_BAN_STEAM 1
#define MA_BAN_IP 2
native bool MAOffBanPlayer(int iClient, int iType, char[] sSteamID, char[] sIp, char[] sName, int iTime, char[] sReason); // Local/Offline Ban
native bool MABanPlayer(int iClient, int iTarget, int iType, int iTime, char[] sReason);
//native bool MASetClientMuteType(int iClient, int iTarget, char[] sReason, int iType, int iTime = 0); TODO
//native bool MAOffSetClientMuteType(int iClient, char[] sSteamID, char[] sIp, char[] sName, char[] sReason, int iType, int iTime = 0); TODO
//native int MAGetClientMuteType(int iClient); TODO


#define MA_LogAdmin 0
#define MA_LogConfig 1
#define MA_LogDateBase 2
#define MA_LogAction 3
native bool MALog(int iType, const char[] sLog, any ...); //TODO


//- Defines -//

#define PLUGIN_VERSION "0.1" // No versioning right now, we are on a rolling Release Cycle

#define VOICE_LOOPBACK_MSG "Voice loopback not allowed!\nYou have been muted."

#define MALFORMED_NAME_MSG "Malformed player name (control chars, zero length, ...)"
#define MALFORMED_MESSAGE_MSG "Malformed message (control chars, zero length, ...)"

#define FLOOD_HARD_MSG "Temporary ban for %s (Hard-flooding)"
#define FLOOD_NAME_MSG "Temporary ban for %s (Name-flooding)"
#define FLOOD_CONNECT_MSG "Too quick successive connection attempts, try again in %s"

#define LOG_MSG_LOOPBACK_MUTE "[Forlix FloodCheck Redux] %L muted for voice loopback"

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

static bool g_bLateLoad;
bool g_bSourceBans, g_bSourceBansPP, g_bBaseComm, g_bSourceComms, g_bSBMaterialAdmin;

//- ConVars -//
Handle g_hCVar_ExcludeChatTriggers, g_hCVar_MuteVoiceLoopback;
Handle g_hCVar_ChatInterval, g_hCVar_ChatNum;
Handle g_hCVar_HardInterval, g_hCVar_HardNum, g_hCVar_HardBanTime;
Handle g_hCVar_NameInterval, g_hCVar_NameNum, g_hCVar_NameBanTime;
Handle g_hCVar_ConnectInterval, g_hCVar_ConnectNum, g_hCVar_ConnectBanTime;

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


//- FFCR Modules -// Note that the ordering of these Includes is important

#include "FFCR/convars.sp" // ConVars
#include "FFCR/markcheats.sp" // Mark dangerous CMDs as Cheats
#include "FFCR/events.sp" // Events
#include "FFCR/chatflood.sp" // Chat
#include "FFCR/hardflood.sp" // Hard Flood
#include "FFCR/nameflood.sp" // Namecheck
#include "FFCR/connectflood.sp" // Connect Check
#include "FFCR/voiceloopback.sp" // Voice Loopback
#include "FFCR/stocks.sp" // Stocks


public Plugin myinfo = 
{
	name = "Forlix FloodCheck Redux", 
	author = "Playa (Formerly Dominik Friedrichs)", 
	description = "An Universal Anti Spam, Flood and Exploit Solution compactible with most Source Engine Games", 
	version = PLUGIN_VERSION, 
	url = "github.com/DJPlaya/Forlix-Floodcheck-Redux"
}

//- Plugin, Native Config Functions -//

public APLRes AskPluginLoad2(Handle myself, bool bLate, char[] error, err_max)
{
	//- SourceBans -//
	MarkNativeAsOptional("SBPP_BanPlayer");
	MarkNativeAsOptional("SBPP_ReportPlayer");
	MarkNativeAsOptional("SBBanPlayer");
	MarkNativeAsOptional("SB_ReportPlayer");
	//- BaseComm -//
	MarkNativeAsOptional("BaseComm_IsClientMuted");
	MarkNativeAsOptional("BaseComm_SetClientMute");
	//- SourceComms -//
	MarkNativeAsOptional("SourceComms_GetClientMuteType");
	MarkNativeAsOptional("SourceComms_SetClientMute");
	//- SB Material Admin -//
	MarkNativeAsOptional("MAOffBanPlayer");
	MarkNativeAsOptional("MABanPlayer");
	MarkNativeAsOptional("MALog");
	//TODO: Mark other Natives?
	
	CreateNative("IsClientFlooding", Native_IsClientFlooding);
	
	g_bLateLoad = bLate;
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	RegPluginLibrary("forlix_floodcheck_redux");
	
	// chat and radio flood checking
	RegConsoleCmd("say", FloodCheckChat);
	RegConsoleCmd("say_team", FloodCheckChat);
	
	HookEvent("player_connect", Event_PlayerConnect, EventHookMode_Pre);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	HookEvent("player_changename", Event_PlayerChangename, EventHookMode_Pre);
	
	// game-specific setup
	char gamedir[16];
	GetGameFolderName(gamedir, sizeof(gamedir));
	
	if (StrEqual(gamedir, "cstrike")) // counter-strike: source
		SetupChatDetection_cstrike();
		
	else if (StrEqual(gamedir, "dod")) // day of defeat: source
		SetupChatDetection_dod();
		
	else if (StrEqual(gamedir, "tf")) // team fortress 2
		SetupChatDetection_tf();
		
	else // all other games
		SetupChatDetection_misc();
		
	SetupConVars();
	MarkCheats();
	
	FloodCheckConnect_PluginStart();
	
	if (g_bLateLoad)
		Query_VoiceLoopback_All();
		
	g_bLateLoad = false;
}

public void OnPluginEnd()
{
	FloodCheckConnect_PluginEnd();
}

public void OnAllPluginsLoaded()
{
	//- Library Checks, SB -//
	if (LibraryExists("sourcebans++")) // SB++
		g_bSourceBansPP = true;
		
	else
		g_bSourceBansPP = false;
		
	if (LibraryExists("sourcebans")) // SB
		g_bSourceBans = true;
		
	else
		g_bSourceBans = false;
		
	if (LibraryExists("materialadmin")) // SB Material Admin
		g_bSBMaterialAdmin = true;
		
	else
		g_bSBMaterialAdmin = false;
		
	if (g_bSourceBansPP && g_bSourceBans)
		LogError("[Warning] Sourcebans++ and Sourcebans 2.X are installed at the same Time! This can Result in Problems, FFCR will use SB++ for now");
		
	else if (g_bSourceBansPP && g_bSBMaterialAdmin)
		LogError("[Warning] Sourcebans++ and SB Material Admin are installed at the same Time! This can Result in Problems, FFCR will use SB++ for now");
		
	else if (g_bSourceBans && g_bSBMaterialAdmin)
		LogError("[Warning] Sourcebans and SB Material Admin are installed at the same Time! This can Result in Problems, FFCR will use SB++ for now");
		
	//- Library Checks, Comms -// We could check if SBMaterialAdmin is installed here cause it also has the Mute Natives implemented, but it should run fine along with SourceComms
	if (LibraryExists("basecomm")) // BaseComm
		g_bBaseComm = true;
		
	else
		g_bBaseComm = false;
		
	if (LibraryExists("sourcecomms++")) // SourceComms
	{
		g_bSourceComms = true;
		
		if(LibraryExists("sourcecomms"))
			LogError("[Warning] SourceComms++ and SourceComms are installed at the same Time! This can Result in Problems.");
	}
	
	else
	{
		if (LibraryExists("sourcecomms"))
			g_bSourceComms = true;
			
		else
			g_bSourceComms = false;
	}
}

public void OnLibraryAdded(const char[] cName)
{ // Ordered by Occurrence for Efficiency
	if (strcmp(cName, "sourcebans++", false))
			g_bSourceBans = true;
			
	else if (strcmp(cName, "sourcecomms++", false) || strcmp(cName, "sourcecomms", false))
			g_bSourceComms = true;
			
	else if (LibraryExists("materialadmin")) // SB Material Admin
		g_bSBMaterialAdmin = true;
			
	else if (strcmp(cName, "basecomm", false))
			g_bBaseComm = true;
			
	else if (strcmp(cName, "sourcebans", false))
			g_bSourceBansPP = true;
}

public void OnLibraryRemoved(const char[] cName)
{ // Ordered by Occurrence for Efficiency
	if (strcmp(cName, "sourcebans++", false))
			g_bSourceBans = false;
			
	else if (strcmp(cName, "sourcecomms++", false) || strcmp(cName, "sourcecomms", false))
			g_bSourceComms = false;
			
	else if (LibraryExists("materialadmin")) // SB Material Admin
		g_bSBMaterialAdmin = false;
			
	else if (strcmp(cName, "basecomm", false))
			g_bBaseComm = false;
			
	else if (strcmp(cName, "sourcebans", false))
			g_bSourceBansPP = false;
}

public void OnConfigsExecuted()
{
	//Some games support disallowing voice_inputfromfile server side
	ConVar hCVar_VoiceFromFile = FindConVar("sv_allow_voice_from_file");
	if (hCVar_VoiceFromFile)
	{
		SetConVarBool(hCVar_VoiceFromFile, false);
		g_bMuteVoiceLoopback = false;
	}
}

public bool OnClientConnect(client, char[] rejectmsg, maxlen)
{
	if (!IsClientNameAllowed(client))
	{
		strcopy(rejectmsg, maxlen, MALFORMED_NAME_MSG);
		return false;
	}
	
	return true;
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

public OnClientSettingsChanged(client)
{
	if (!IsClientInGame(client) || IsFakeClient(client))
		return;
		
	Query_VoiceLoopback(client);
	
	if (!IsClientNameAllowed(client))
		KickClient(client, MALFORMED_NAME_MSG);
		
	// make sure client cant hardflood us with settingschanged
	FloodCheckHard(client);
	return;
}

public Action OnClientCommand(client, args)
{
	FloodCheckHard(client);
	return Plugin_Continue;
} 