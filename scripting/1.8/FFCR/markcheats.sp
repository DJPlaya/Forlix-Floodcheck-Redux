// Forlix FloodCheck
// http://forlix.org/, df@forlix.org
//
// Copyright (c) 2008-2013 Dominik Friedrichs

static char addcheat_cmds[][] = 
{
	// these known dangerous commands will be marked as cheat
	// most of these cause a server to lag or crash in certain circumstances
	"dbghist_addline", 
	"dbghist_dump", 
	"dump_entity_sizes", 
	"dump_globals", 
	"dump_panels", 
	"dump_terrain", 
	"dumpcountedstrings", 
	"dumpentityfactories", 
	"dumpeventqueue", 
	"dumpgamestringtable", 
	"editdemo", 
	"groundlist", 
	"listmodels", 
	"map_showspawnpoints", 
	"mem_dump", 
	"mp_dump_timers", 
	"npc_ammo_deplete", 
	"npc_heal", 
	"npc_speakall", 
	"npc_thinknow", 
	"physics_budget", 
	"physics_debug_entity", 
	"physics_highlight_active", 
	"physics_report_active", 
	"physics_select", 
	"report_entities", 
	"report_simthinklist", 
	"report_soundpatch", 
	"report_touchlinks", 
	"rr_reloadresponsesystems", 
	"scene_flush", 
	"soundlist", 
	"soundscape_flush", 
	"sv_findsoundname", 
	"sv_soundemitter_filecheck", 
	"sv_soundemitter_flush", 
	"sv_soundscape_printdebuginfo", 
	"wc_update_entity"
};

void MarkCheats()
{
	for (int iCount = 0; iCount < sizeof(addcheat_cmds); iCount++)
		SetCheatFlag(addcheat_cmds[iCount]);
}

static bool SetCheatFlag(const char[] cCvar)
{
	int iFlags = GetCommandFlags(cCvar);
	if (iFlags == INVALID_FCVAR_FLAGS)
		return false;
		
	SetCommandFlags(cCvar, iFlags | FCVAR_CHEAT);
	return true;
} 