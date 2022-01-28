#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <customguns>

#define WEAPON "weapon_fists"

#define REFIRE 0.35
#define RANGE 50.0
#define DAMAGE 10.0
#define PUSH_SCALE 100.0

public void CG_OnPrimaryAttack(int client, int weapon)
{

	char sWeapon[32];
	GetEntityClassname(weapon, sWeapon, sizeof(sWeapon));
	if(StrEqual(sWeapon, WEAPON))
	{
		CG_SetPlayerAnimation(client, PLAYER_ATTACK1);
		CG_PlayActivity(weapon, ACT_VM_HITCENTER);
		CG_Cooldown(weapon, REFIRE);

		float pos[3], angles[3], endPos[3];
		CG_GetShootPosition(client, pos);
		GetClientEyeAngles(client, angles);

		GetAngleVectors(angles, endPos, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(endPos, RANGE);
		AddVectors(pos, endPos, endPos);

		TR_TraceHullFilter(pos, endPos, view_as<float>({-10.0, -10.0, -10.0}), view_as<float>({10.0, 10.0, 10.0}), MASK_SHOT_HULL, TraceEntityFilter, client);

		float punchAngle[3];

		punchAngle[0] = GetRandomFloat( 1.0, 2.0 );
		punchAngle[1] = GetRandomFloat( -2.0, -1.0 );
		Tools_ViewPunch(client, punchAngle);
		
		if(TR_DidHit())
		{
			EmitGameSoundToAll("Weapon_Crowbar.Melee_Hit", weapon);
			
			int entityHit = TR_GetEntityIndex();
			if(entityHit > 0 && (!IsPlayer(entityHit) || GetClientTeam(entityHit) != GetClientTeam(client)) )
			{
				char classname[32];
				GetEntityClassname(entityHit, classname, sizeof(classname));

				if(StrContains(classname, "npc_") == 0)
				{

				}
				else if(GetEntityMoveType(entityHit) == MOVETYPE_VPHYSICS)
				{
					float force[3];
					GetAngleVectors(angles, force, NULL_VECTOR, NULL_VECTOR);

					ScaleVector(force, PUSH_SCALE);
					TeleportEntity(entityHit, NULL_VECTOR, NULL_VECTOR, force);

					if(GetEntityMoveType(entityHit) == MOVETYPE_VPHYSICS)
					{
						SetEntPropVector(entityHit, Prop_Data, "m_vecAbsVelocity", NULL_VECTOR); //trampoline fix
					}
				}
				SDKHooks_TakeDamage(entityHit, client, client, DAMAGE, DMG_CLUB);
			}

			// Do additional trace for impact effects
			float impactEndPos[3];
			GetAngleVectors(angles, impactEndPos, NULL_VECTOR, NULL_VECTOR);

			ScaleVector(impactEndPos, 50.0);
			TR_GetEndPosition(endPos);
			AddVectors(impactEndPos, endPos, impactEndPos);

			TR_TraceRayFilter(endPos, impactEndPos, MASK_SHOT_HULL, RayType_EndPoint, TraceEntityFilter, client);
			if(TR_DidHit())
			{
				UTIL_ImpactTrace(pos, DMG_CLUB);
			}
		}
		else
		{
			EmitGameSoundToAll("Weapon_Crowbar.Single", weapon);
		}
	}
}

public bool TraceEntityFilter(int entity, int mask, any data)
{
	if (entity == data) return false;
	return true;
}