#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <customguns>

//Definitions:
#define CLASSNAME "weapon_pulsemg"
#define PULSEMG_BEAM_SPRITE "sprites/laserbeam.vmt"
#define COOLDOWN_PRIMARY 0.12
#define PULSEMG_DAMAGE_PERBULLET 3.2
#define AMMO_COST_PRIMARY 1
#define KNOCKBACK_SCALE 1.0

//Misc:
int sprite;

bool teamplay;

//Plugin Info:
public Plugin myinfo =
{
	name = "Weapon_PulseMG",
	author = "Master(D)",
	description = "CustomGuns Weapon_PulseMG Extension",
	version = "00.00.05",
	url = ""
};

public OnConfigsExecuted()
{
	sprite = PrecacheModel(PULSEMG_BEAM_SPRITE);
}

public void OnMapStart()
{
	teamplay = GetConVarBool(FindConVar("mp_teamplay"));
}

public void CG_OnPrimaryAttack(int client, int weapon)
{
	char cls[32];
	GetEntityClassname(weapon, cls, sizeof(cls));

	if(StrEqual(cls, CLASSNAME))
	{
		int Ammo = getWeaponAmmo(client);

		//Check:
		if(Ammo - AMMO_COST_PRIMARY >= 0)
		{
				//CG_RemovePlayerAmmo(client, weapon, AMMO_COST_PRIMARY);
				setWeaponAmmo(client, (Ammo - AMMO_COST_PRIMARY), CLASSNAME);
				CG_SetNextPrimaryAttack(weapon, GetGameTime() + COOLDOWN_PRIMARY);
				FirePulseMg(client, weapon);
				CG_PlayPrimaryAttack(weapon);
				EmitGameSoundToAll("Weapon_Ar2.Single", weapon);
		}
	}
}

public void FirePulseMg(int client, int weapon)
{
	CG_SetPlayerAnimation(client, PLAYER_ATTACK1);

	float ang[3], pos[3], endPos[3], traceNormal[3];

	GetClientEyeAngles(client, ang);

	CG_GetShootPosition(client, pos, 24.0, 6.0, -12.0);

	pos[2] += 10.0;

	// Register a muzzleflash for the AI
	SetEntPropFloat(client, Prop_Data, "m_flFlashTime", GetGameTime() + 0.5);

	TR_TraceRayFilter(pos, ang, MASK_SHOT, RayType_Infinite, TraceEntityFilter, client);
	TR_GetEndPosition(endPos);
	TR_GetPlaneNormal(null, traceNormal);
	//int entityHit = TR_GetEntityIndex();

	//TE Setup:
	TE_SetupDynamicLight(pos, 100, 100, 255, 8, 35.0, 0.4, 50.0);

	//Send:
	TE_SendToAll();

	//Temp Ent:
	TE_SetupEnergySplash(endPos, traceNormal, true);

	//Show To Client:
	TE_SendToAll();

	//TE Setup:
	TE_SetupDynamicLight(endPos, 100, 100, 255, 8, 65.0, 0.4, 50.0);

	//Send:
	TE_SendToAll();

	physExplosion(endPos, 20.0, true);
	
	int entityHit = TR_GetEntityIndex();
	
	if(entityHit > 0)
	{
	 	if(entityHit <= MaxClients && IsClientConnected(entityHit) && IsClientInGame(entityHit))
		{
			if(!teamplay || GetClientTeam(entityHit) != GetClientTeam(client))
			{
			
				//Declare:
				float KnockBack[3];
			
				//Create Knock Back:
				CalculateKnockBack(client, entityHit, PULSEMG_DAMAGE_PERBULLET, KnockBack);
		
				SDKHooks_TakeDamage(entityHit, client, client, PULSEMG_DAMAGE_PERBULLET, DMG_SHOCK, weapon, KnockBack, endPos);
			}
		}
		else
		{
			CG_RadiusDamage(client, client, PULSEMG_DAMAGE_PERBULLET, DMG_SHOCK, weapon, endPos, 20.0, client);
		}
	}
	
	//Override:
	else
	{
		CG_RadiusDamage(client, client, PULSEMG_DAMAGE_PERBULLET, DMG_SHOCK, weapon, endPos, 20.0, client);
	}

	float viewPunch[3];
	viewPunch[0] = GetRandomFloat( -0.5, -0.2 );
	viewPunch[1] = GetRandomFloat( -0.5,  0.5 );
	Tools_ViewPunch(client, viewPunch);

	DrawBeam(pos, endPos, 1.6, weapon);

	UTIL_ImpactTrace(endPos, DMG_SHOCK, "ImpactGauss");

	// Register a muzzleflash for the AI
	SetEntPropFloat(client, Prop_Data, "m_flFlashTime", GetGameTime() + 0.5);
}

public void DrawBeam(const float startPos[3], const float endPos[3], float width, int startEntity){

	int beam = CreateEntityByName("beam");
	if(beam != -1)
	{
		if(startEntity != -1)
		{
			Beam_PointEntInit(beam, endPos, startEntity);
			SetEntPropFloat(beam, Prop_Data, "m_fWidth", width / 4.0);
			SetEntPropFloat(beam, Prop_Data, "m_fEndWidth", width);
		}
		else
		{
			Beam_PointPointInit(beam, startPos, endPos);
			SetEntPropFloat(beam, Prop_Data, "m_fWidth", width);
			SetEntPropFloat(beam, Prop_Data, "m_fEndWidth", width / 4.0);
		}
		
		SetEntityRenderColor(beam, 145 + GetRandomInt(-16, 16), 145 + GetRandomInt(-16, 16), 255, 255);
		DispatchKeyValue(beam, "model", PULSEMG_BEAM_SPRITE);
		SetEntProp(beam, Prop_Data, "m_nModelIndex", sprite);
			
		SetVariantString("OnUser1 !self:kill::0.1:-1")
		AcceptEntityInput(beam, "addoutput");
		AcceptEntityInput(beam, "FireUser1");
		
		DispatchSpawn(beam);
		ActivateEntity(beam);
	}
	
	//Draw electric bolts along shaft
	for ( int i = 0; i < 3; i++ )
	{
		beam = CreateEntityByName("beam");
		if(beam != -1)
		{
			if(startEntity != -1)
			{
				Beam_PointEntInit(beam, endPos, startEntity);
			} else {
				Beam_PointPointInit(beam, startPos, endPos);
			}
			
			SetEntPropFloat(beam, Prop_Data, "m_fAmplitude", 1.6 * i);
			
			SetEntPropFloat(beam, Prop_Data, "m_fWidth", width/2.0 + i);
			SetEntPropFloat(beam, Prop_Data, "m_fEndWidth", 0.1);

			SetEntityRenderColor(beam, 130 + GetRandomInt(0, 64), 130 + GetRandomInt(0, 64), 225);
			DispatchKeyValue(beam, "model", PULSEMG_BEAM_SPRITE);
			SetEntProp(beam, Prop_Data, "m_nModelIndex", sprite);
				
			SetVariantString("OnUser1 !self:kill::0.1:-1")
			AcceptEntityInput(beam, "addoutput");
			AcceptEntityInput(beam, "FireUser1");
			
			DispatchSpawn(beam);
			ActivateEntity(beam);
		}
	}
}

//
// CBeam stuff
//
//

enum 
{
	BEAM_POINTS = 0,
	BEAM_ENTPOINT,
	BEAM_ENTS,
	BEAM_HOSE,
	BEAM_SPLINE,
	BEAM_LASER,
	NUM_BEAM_TYPES
};

void Beam_PointEntInit(int beam, const float start[3], int endEntity)
{
	SetEntProp(beam, Prop_Send, "m_nBeamType", BEAM_ENTPOINT);
	SetEntProp(beam, Prop_Send, "m_nNumBeamEnts", 2);
	SetEntPropVector(beam, Prop_Send, "m_vecOrigin", start);
	
	//SetEndEntity
	int offset = FindDataMapInfo(beam, "m_hAttachEntity");
	SetEntDataEnt2(beam, offset+4, endEntity);
	
	SetEntPropEnt(beam, Prop_Data, "m_hEndEntity", endEntity);
	
	//SetEndAttachment
	offset = FindDataMapInfo(beam, "m_nAttachIndex");
	SetEntData(beam, offset+4, 1);
} 

void Beam_PointPointInit(int beam, const float start[3], const float end[3])
{
	SetEntProp(beam, Prop_Send, "m_nBeamType", BEAM_POINTS);
	SetEntProp(beam, Prop_Send, "m_nNumBeamEnts", 2);
	TeleportEntity(beam, start, NULL_VECTOR, NULL_VECTOR);
	SetEntPropVector(beam, Prop_Send, "m_vecEndPos", end);
}
/**
 * Sets up a Dynamic Light effect
 *
 * @param vecOrigin        Position of the Dynamic Light
 * @param r            r color value
 * @param g            g color value
 * @param b            b color value
 * @param iExponent        ?
 * @param fTime            Duration
 * @param fDecay        Decay of dynamic light
 * @noreturn
 */
public void TE_SetupDynamicLight(float Origin[3], int R, int G, int B, int Exponent, float Radius , float Time, float Decay)
{

    TE_Start("Dynamic Light");
    TE_WriteVector("m_vecOrigin", Origin);
    TE_WriteNum("r",R);
    TE_WriteNum("g",G);
    TE_WriteNum("b",B);
    TE_WriteNum("exponent", Exponent);
    TE_WriteFloat("m_fRadius", Radius);
    TE_WriteFloat("m_fTime", Time);
    TE_WriteFloat("m_fDecay", Decay);
}

public bool TraceEntityFilter(int entity, int mask, any data)
{
	if (entity == data)
		return false;
	return true;
}

public void CalculateKnockBack(int Client, int attacker, float damage, float Push[3])
{

	//Delare:
  	decl Float:EyeAngles[3];

	//Initialize:
	GetClientEyeAngles(Client, EyeAngles);

	Push[0] = ((damage - damage - damage, Cosine(DegToRad(EyeAngles[1]))));
	Push[1] = ((damage - damage - damage, Sine(DegToRad(EyeAngles[1]))));
	Push[2] = ((-50.0, Sine(DegToRad(EyeAngles[0]))));
	
	//Multiply
	ScaleVector(Push, KNOCKBACK_SCALE);
}
