// Forlix FloodCheck
// http://forlix.org/, df@forlix.org
//
// Copyright (c) 2008-2013 Dominik Friedrichs

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION          "1.73-B"
#define PLUGIN_VERSION_CVAR     "forlix_floodcheck_version"

#define VOICE_LOOPBACK_MSG      "Voice loopback not allowed!\nYou have been muted."

#define MALFORMED_NAME_MSG      "Malformed player name (control chars, zero length, ...)"
#define MALFORMED_MESSAGE_MSG   "Malformed message (control chars, zero length, ...)"

#define FLOOD_HARD_MSG          "Temporary ban for %s (Hard-flooding)"
#define FLOOD_NAME_MSG          "Temporary ban for %s (Name-flooding)"
#define FLOOD_CONNECT_MSG       "Too quick successive connection attempts, try again in %s"

#define LOG_MSG_LOOPBACK_MUTE   "[Forlix_FloodCheck] %N muted for voice loopback"

#define NAME_STR_EMPTY          "empty"
#define REASON_STR_EMPTY        "Empty reason"

#define HARD_TRACK              16
#define CONNECT_TRACK           16

#define MAX_NAME_LEN            32
#define MAX_MSG_LEN             128
#define MAX_IPPORT_LEN          32
#define MAX_STEAMID_LEN         32

#define REASON_TRUNCATE_LEN     63
// can be max MAX_MSG_LEN-2
// the game now truncates to 63 but only clientside

public Plugin myinfo = 
{
	name = "Forlix FloodCheck", 
	author = "Forlix(Dominik Friedrichs) (Playa Edit)", 
	description = "General purpose Flood and Exploit Protection", 
	version = PLUGIN_VERSION, 
	url = "FunForBattle"
}

float chat_interval;
int chat_num;

float hard_interval;
int hard_num, hard_ban_time;

float name_interval;
int name_num, name_ban_time;

float connect_interval;
int connect_num, connect_ban_time;

int exclude_chat_triggers, mute_voice_loopback;

#include "ff_convars.sp"
#include "ff_markcheats.sp"
#include "ff_events.sp"
#include "ff_chatflood.sp"
#include "ff_hardflood.sp"
#include "ff_nameflood.sp"
#include "ff_connectflood.sp"
#include "ff_voiceloopback.sp"
#include "ff_toolfuncs.sp"