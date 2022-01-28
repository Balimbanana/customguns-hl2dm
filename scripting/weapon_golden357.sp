#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <customguns>

#define CLASSNAME "weapon_golden357"
#define GAUSS_BEAM_SPRITE "sprites/laserbeam.vmt"

int sprite;

//Plugin Info:
public Plugin myinfo =
{
	name = "Weapon_Golden357",
	author = "Master(D)",
	description = "CustomGuns Weapon_Golden357 Extension",
	version = "00.00.15",
	url = ""
};

public OnConfigsExecuted()
{
	sprite = PrecacheModel(GAUSS_BEAM_SPRITE);
}

public void CG_OnPrimaryAttack(int client, int weapon)
{
	char cls[32];
	GetEntityClassname(weapon, cls, sizeof(cls));

	if(StrEqual(cls, CLASSNAME))
	{
		if(getWeaponAmmo(client) > 0)
		{
			FireGolden357(client, weapon);
			CG_PlayPrimaryAttack(weapon);
		}
	}
}

public void FireGolden357(int client, int weapon)
{
	CG_SetPlayerAnimation(client, PLAYER_ATTACK1);

	float ang[3], pos[3], endPos[3], traceNormal[3];

	GetClientEyeAngles(client, ang);

	CG_GetShootPosition(client, pos, 12.0, 6.0, -3.0);

	pos[2] += 10.0;

	// Register a muzzleflash for the AI
	SetEntPropFloat(client, Prop_Data, "m_flFlashTime", GetGameTime() + 0.5);

	TR_TraceRayFilter(pos, ang, MASK_SHOT, RayType_Infinite, TraceEntityFilter, client);
	TR_GetEndPosition(endPos);
	TR_GetPlaneNormal(null, traceNormal);
	//int entityHit = TR_GetEntityIndex();

	//TE Setup:
	TE_SetupDynamicLight(pos, 200, 200, 15, 8, 65.0, 0.4, 50.0);

	//Send:
	TE_SendToAll();

	//Temp Ent:
	TE_SetupEnergySplash(endPos, traceNormal, true);

	//Show To Client:
	TE_SendToAll();

	//TE Setup:
	TE_SetupDynamicLight(endPos, 200, 200, 15, 8, 35.0, 0.4, 50.0);

	//Send:
	TE_SendToAll();

	physExplosion(endPos, 20.0, true);
	
	DrawBeam(pos, endPos, 1.6, weapon);
}

void DrawBeam(const float startPos[3], const float endPos[3], float width, int startEntity = -1){
	//UTIL_Tracer( startPos, endPos, 0, TRACER_DONT_USE_ATTACHMENT, 6500.0, false, "GaussTracer" );
	int beam = CreateEntityByName("beam");
	if(beam != -1){

		if(startEntity != -1){
			Beam_PointEntInit(beam, endPos, startEntity);
			SetEntPropFloat(beam, Prop_Data, "m_fWidth", width / 4.0);
			SetEntPropFloat(beam, Prop_Data, "m_fEndWidth", width);
		} else {
			Beam_PointPointInit(beam, startPos, endPos);
			SetEntPropFloat(beam, Prop_Data, "m_fWidth", width);
			SetEntPropFloat(beam, Prop_Data, "m_fEndWidth", width / 4.0);
		}
		
		SetEntityRenderColor(beam, 255, 145 +GetRandomInt(-16, 16), 0, 255);
		DispatchKeyValue(beam, "model", GAUSS_BEAM_SPRITE);
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
		if(beam != -1){
			if(startEntity != -1){
				Beam_PointEntInit(beam, endPos, startEntity);
			} else {
				Beam_PointPointInit(beam, startPos, endPos);
			}
			
			SetEntPropFloat(beam, Prop_Data, "m_fAmplitude", 1.6 * i);
			
			SetEntPropFloat(beam, Prop_Data, "m_fWidth", width/2.0 + i);
			SetEntPropFloat(beam, Prop_Data, "m_fEndWidth", 0.1);
			
			SetEntityRenderColor(beam, 255, 255, 150 + GetRandomInt(0, 64));
			DispatchKeyValue(beam, "model", GAUSS_BEAM_SPRITE);
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

public bool TraceEntityFilter(int entity, int mask, any data){
	if (entity == data)
		return false;
	return true;
}
