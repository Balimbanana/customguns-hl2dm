#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <customguns>

#define WEAPON "weapon_healer"
#define REFIRE 0.55
#define RANGE 40.0
#define DAMAGE 10.0
#define PUSH_SCALE 30.0

float additionalTime[MAXPLAYERS+1];
float nextEnergy[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "Weapon_Healer",
	author = "Master(D)",
	description = "CustomGuns Weapon_Healer Extension",
	version = "00.00.01",
	url = ""
};

public void CG_OnHolster(int client, int weapon, int switchingTo)
{
	char sWeapon[32];
	GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));
	
	if(StrEqual(sWeapon, WEAPON))
	{
		additionalTime[client] = 0.0;
		nextEnergy[client] = 0.0;
	}
	return;
}

public void CG_OnPrimaryAttack(int client, int weapon)
{
	char sWeapon[32];
	GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));
	if(StrEqual(sWeapon, WEAPON))
	{
		//Declare:
		int Random = GetRandomInt(2, 5);
		vmSeq(client, Random, REFIRE)
		CG_SetPlayerAnimation(client, PLAYER_ATTACK1);
		//CG_PlayActivity(weapon, ACT_VM_SECONDARYATTACK);
		
		if(additionalTime[client] <= 0.025)
		{
			additionalTime[client] = 0.025;
		}

		additionalTime[client] += additionalTime[client]*1.2;
		if(additionalTime[client] >= 0.5)
		{
			additionalTime[client] = 0.5;
		}
		
		CG_Cooldown(weapon, REFIRE + additionalTime[client]);
		
		float pos[3], angles[3], endPos[3];
		CG_GetShootPosition(client, pos);
		GetClientEyeAngles(client, angles);
		GetAngleVectors(angles, endPos, NULL_VECTOR, NULL_VECTOR);

		ScaleVector(endPos, RANGE);
		AddVectors(pos, endPos, endPos);
		
		TR_TraceHullFilter(pos, endPos, view_as<float>({-10.0, -10.0, -10.0}), view_as<float>({10.0, 10.0, 10.0}), MASK_SHOT_HULL, TraceEntityFilter, client);
		
		if(TR_DidHit())
		{
			int entityHit = TR_GetEntityIndex();
			if(entityHit > 0)
			{
				//if(entityHit <= GetMaxClients() && IsClientConnected(entityHit) && IsClientInGame(entityHit))
				if ((HasEntProp(entityHit, Prop_Data, "m_iMaxHealth")) && (HasEntProp(entityHit, Prop_Data, "m_iHealth")))
				{
					if (GetEntProp(entityHit, Prop_Data, "m_iTeamNum") == GetEntProp(client, Prop_Data, "m_iTeamNum"))
					{
						char szClassname[32];
						GetEntityClassname(entityHit, szClassname, sizeof(szClassname));
						if ((StrContains(szClassname, "npc_", false) != -1) || (StrEqual(szClassname, "player", false)))
						{
							//Decalre:
							int MaxHealth = GetEntProp(entityHit, Prop_Data, "m_iMaxHealth");
							int Health = GetEntProp(entityHit, Prop_Data, "m_iHealth");
							
							//Check:
							if(MaxHealth != Health)
							{
								//MaxCheck:
								if(Health + 15 > MaxHealth)
								{
									//Set Prop:
									SetEntProp(entityHit, Prop_Data, "m_iHealth", MaxHealth);
								}
								//Override:
								else
								{
									//Set Prop:
									SetEntProp(entityHit, Prop_Data, "m_iHealth", (Health + 15));
								}
								
								EmitGameSoundToAll("HealthKit.Touch", weapon);
							}
						}
					}
				}
			}
		}
	}
	return;
}

public void CG_OnSecondaryAttack(int client, int weapon)
{
	char sWeapon[32];
	GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));
	if(StrEqual(sWeapon, WEAPON))
	{
		if(additionalTime[client] <= 0.025)
		{
			additionalTime[client] = 0.025;
		}

		additionalTime[client] += additionalTime[client]*1.2;

		if(additionalTime[client] >= 0.5)
		{
			additionalTime[client] = 0.5;
		}

		CG_Cooldown(weapon, REFIRE + additionalTime[client]);

		//EmitGameSoundToAll("Weapon_Healer.Special1", weapon);	}
}

public void CG_ItemPostFrame(int client, int weapon)
{
	char sWeapon[32];
	GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));	

	if(StrEqual(sWeapon, WEAPON))
	{
		if(!(GetClientButtons(client) & IN_ATTACK) && GetGameTime() >= nextEnergy[client])
		{
			additionalTime[client] *= 0.5;
			nextEnergy[client] = GetGameTime() + 0.25;
		}
	}
}

public bool TraceEntityFilter(int entity, int mask, any data)
{
	if (entity == data) return false;
	return true;
}