#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <zombiereloaded>
#include <cstrike>

bool g_bBreak = false;
bool g_bNextRound = false;
int g_iTime = -1;

public Plugin myinfo =
{
	name = "[ZR] Break Time",
	author = "koen", // Inspiration from zaCade's plugin on unloze
	description = "",
	version = "",
	url = "https://github.com/notkoen"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_break", cmd_break, ADMFLAG_UNBAN, "Start break time during events");
	RegAdminCmd("sm_endbreak", cmd_endbreak, ADMFLAG_UNBAN, "Force break time to end");
	HookEvent("round_start", Event_RoundStart);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, TakeDamage);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, TakeDamage);
}

public Action TakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (g_bBreak)
		return Plugin_Handled;

	return Plugin_Continue;
}

public Action cmd_endbreak(int client, int args)
{
	if (!g_bBreak)
	{
		CPrintToChat(client, " \x04[Break Time] \x01It is currently not break time!");
		return Plugin_Handled;
	}

	PrintCenterTextAll("Admin <font color='#00FF00'>%N</font> has ended the break early!\nRestarting game in 5 seconds!", client);
	g_bBreak = false;
	CS_TerminateRound(5.0, CSRoundEnd_GameStart, true);
	return Plugin_Handled;
}

public Action cmd_break(int client, int args)
{
	if (args < 1)
	{
		CPrintToChat(client, " \x04[Break Time] \x01Usage: sm_break <time in seconds>");
		return Plugin_Handled;
	}

	if (g_bBreak)
	{
		PrintToChat(client, " \x04[Break Time] \x01Break time is enabled already!");
		return Plugin_Handled;
	}

	int time = GetCmdArgInt(1);
	if (time == 0)
	{
		CPrintToChat(client, " \x04[Break Time] \x01Error, invalid time input");
		return Plugin_Handled;
	}

	if (time < 30)
	{
		CPrintToChat(client, " \x04[Break Time] \x01Minimum time for break is 30 seconds.");
		return Plugin_Handled;
	}

	char outp[8];
	int min, sec;
	min = time / 60;
	sec = time % 60;
	Format(outp, sizeof(outp), "%d:%s%d", min, sec < 10 ? "0" : "", sec);

	PrintCenterTextAll("We will be taking a break next round for <font color='#00FF00'>%s</font>minutes", outp);
	g_bNextRound = true;
	g_iTime = time;
	return Plugin_Handled;
}

public void Event_RoundStart(Handle ev, const char[] name, bool broadcast)
{
	if (!g_bNextRound)
		return;

	g_bNextRound = false;
	g_bBreak = true;
	CreateTimer(1.0, countdown, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action countdown(Handle timer)
{
	if (g_iTime >= 0 && g_bBreak)
	{
		char outp[8];
		int min, sec;
		min = g_iTime / 60;
		sec = g_iTime % 60;
		Format(outp, sizeof(outp), "%d:%s%d", min, sec < 10 ? "0" : "", sec);

		if (g_iTime < 10)
			PrintCenterTextAll("Break time - <font color='#FF0000'>%s</font>", outp);
		else if (g_iTime < 30)
			PrintCenterTextAll("Break time - <font color='#FFFF00'>%s</font>", outp);
		else
			PrintCenterTextAll("Break time - <font color='#00FF00'>%s</font>", outp);

		g_iTime--;
		return Plugin_Continue;
	}

	PrintCenterTextAll("Break time ending! Restarting round in <font color='#00FF00'>5 seconds...</font>");
	g_bBreak = false;
	CS_TerminateRound(5.0, CSRoundEnd_GameStart, true);
	return Plugin_Stop;
}

public Action ZR_OnClientInfect(int &client, int &attacker, bool &motherInfect, bool &respawnOverride, bool &respawn)
{
	if (g_bBreak)
		return Plugin_Handled;

	return Plugin_Continue;
}