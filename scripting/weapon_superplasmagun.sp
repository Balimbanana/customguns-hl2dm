#include <sourcemod>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <customguns>

#define FIRE_FORCE 7500.0
#define MASS_SCALE 80.00.0
#define DELETE_AFTER 3.0

#define CLASSNAME "weapon_superplasmagun"

#define AMMO_COST_PRIMARY 1
#define AMMO_MAX 24
#define COOLDOWN_PRIMARY 3.5
#define PRIMARY_BULLET_DAMAGE 700.0

int LightSprite = -1;
int GlowSprite = -1;

float LastFiredWeapon[MAXPLAYERS + 1] = {0.0,...};
float LastCharged[MAXPLAYERS + 1] = {0.0,...};
int BoltOwner[2047] = {-1,...};
int BoltLight[2047] = -1;
int BoltProp[2047] = -1;

//Plugin Info:
public Plugin myinfo =
{
	name = "Weapon_Laser",
	author = "Master(D)",
	description = "CustomGuns Weapon_Laser Extension",
	version = "00.00.01",
	url = ""
};

public void OnPluginStart()
{

}

public void OnMapStart()
{
	//Loop:
	for(int Entity = MaxClients + 1; Entity < 2047; Entity++)
	{

		BoltOwner[Entity] = -1;
		BoltLight[Entity] = -1;
		BoltProp[Entity] = -1;
	}
	LightSprite = PrecacheModel("sprites/combineball_trail_black_1.vmt", true);
	//LightSprite = PrecacheModel("materials/sprites/laserbeam.vmt", true);
	GlowSprite = PrecacheModel("materials/sprites/blueglow2.vmt", true);
	PrecacheSound("weapons/laser/holster.wav");
	PrecacheSound("weapons/laser/dep.wav");
	PrecacheSound("weapons/laser/reload.wav");
}

//Public Void OnClientPutInServer(int Client)
public void OnClientPostAdminCheck(int Client)
{
	LastFiredWeapon[Client] = 0.0;
	LastCharged[Client] = 0.0;
}

public void CG_OnHolster(int client, int weapon, int switchingTo)
{
	char ClassName[32];
	GetEntityClassname(weapon, ClassName, sizeof(ClassName));

	if(StrEqual(ClassName, CLASSNAME))
	{
		EmitGameSoundToAll("Weapon_Laser.Holster", weapon);
	}
}

public void CG_OnWeaponEquipt(int client, int weapon, int Sucess)
{
	char ClassName2[32];
	GetEntityClassname(weapon, ClassName2, sizeof(ClassName2));

	if(StrEqual(ClassName2, CLASSNAME))
	{
		EmitGameSoundToAll("Weapon_Laser.DeHolster", weapon);
	}
}

//Think:
public void OnGameFrame()
{

	//Loop:
	for(int Entity = MaxClients + 1; Entity < 2047; Entity++)
	{

		if(IsValidEdict(Entity))
		{

			char cls[32];
			GetEntityClassname(Entity, cls, sizeof(cls));

			if(StrEqual(cls, "Super_PlamaBlast"))
			{
				//Declare:
				float Origin[3];

				//Initulize:
				GetEntPropVector(Entity, Prop_Data, "m_vecOrigin", Origin);

				//Declare:
				float Angels[3];

				//Initulize:
				GetEntPropVector(Entity, Prop_Data, "m_angRotation", Angels);

				//Temp Ent:
				TE_SetupEnergySplash(Origin, Angels, true);

				//Show To Client:
				TE_SendToAll();

				//Declare:
				float Velocity[3];

				//Initulize:
				GetEntPropVector(Entity, Prop_Data, "m_vecVelocity", Velocity);

				//Check to see if Laser Bolt has stopped Moving:
				if(Velocity[0] == 0.0 || Velocity[1] == 0.0 || Velocity[2] == 0.0)
				{

					//Is Valid:
					if(!IsValidEdict(Entity))
					{

						//Print:
						//PrintToServer("Invalid Laser Bolt");
						
						//Return:
						return;
					}

					//Remove:
					RemoveEdict(Entity);
				}
			}
		}
	}
}

public void CG_OnPrimaryAttack(int client, int weapon)
{
	char cls[32];
	GetEntityClassname(weapon, cls, sizeof(cls));

	if(StrEqual(cls, CLASSNAME))
	{
		if(getWeaponAmmo(client) > 0)
		{
		
			FireLaser(client, 0.200);
			CG_PlaySecondaryAttack(weapon);

			CG_SetNextPrimaryAttack(weapon, GetGameTime() + COOLDOWN_PRIMARY);

			setWeaponAmmo(client, (getWeaponAmmo(client) - AMMO_COST_PRIMARY), CLASSNAME);
			//CG_RemovePlayerAmmo(client, weapon, AMMO_COST_PRIMARY);

			EmitGameSoundToAll("Weapon_Laser.Single", weapon);
			LastFiredWeapon[client] = GetGameTime();
		}
	}
}

public void FireLaser(int client, float forceScale)
{
	CG_SetPlayerAnimation(client, PLAYER_ATTACK1);

	int ent = CreateEntityByName("grenade_ar2");
	//int ent = CreateEntityByName("prop_combine_ball");
	//int ent = CreateEntityByName("prop_physics_override");
	
	//SetEntityModel(ent, "models/items/ar2_grenade.mdl");

	//Dispatch:
	DispatchKeyValue(ent, "model", "models/effects/combineball.mdl");

	DispatchSpawn(ent);

	//Set Prop ClassName
	SetEntPropString(ent, Prop_Data, "m_iClassname", "Super_PlamaBlast");

	SetEntityGravity(ent, 0.005);

	CreateTimer(DELETE_AFTER, explode, EntIndexToEntRef(ent), TIMER_FLAG_NO_MAPCHANGE);

	float ang[3], pos[3], fwd[3], force[3];

	GetClientEyeAngles(client, ang);
	GetClientEyePosition(client, pos);

	GetAngleVectors(ang, fwd, NULL_VECTOR, NULL_VECTOR);

	ScaleVector(fwd, FIRE_FORCE * forceScale);
	force = fwd;

	CG_GetShootPosition(client, pos, 12.0, 6.0, -3.0);

	TeleportEntity(ent, pos, ang, force);

	float viewPunch[3];

	//int ent2 = CreateEntityByName("prop_combine_ball");
	int ent2 = CreateEntityByName("prop_physics_override");
	
	SetEntityModel(ent2, "models/effects/combineball.mdl");

	TeleportEntity(ent2, pos, ang, NULL_VECTOR);

	//Send:
	SetEntPropFloat(ent2, Prop_Send, "m_flModelScale", 2.0);
		
	//Set String:
	SetVariantString("!activator");

	//Accept:
	AcceptEntityInput(ent2, "SetParent", ent, ent2, 0);

	CreateTimer(DELETE_AFTER, explode, EntIndexToEntRef(ent2), TIMER_FLAG_NO_MAPCHANGE);

	BoltLight[ent] = CreateCustomLight(ent, 1, 250, 250, 255, 1.7, "200", "120", "8", "1", "null");

	CreateTimer(DELETE_AFTER, explode, EntIndexToEntRef(BoltLight[ent]), TIMER_FLAG_NO_MAPCHANGE);

	int Color[4] = {60, 20, 215, 255};

	TE_SetupBeamFollow(ent, LightSprite, GlowSprite, 0.8, 7.0, 1.5, 165, Color);

	//Show To All Clients:
	TE_SendToAll();

	Color = {200, 220, 215, 255};
	
	TE_SetupBeamFollow(ent, LightSprite, GlowSprite, 0.4, 2.5, 0.25, 165, Color);

	//Show To All Clients:
	TE_SendToAll();

	TE_SetupBeamFollow(ent, LightSprite, GlowSprite, 0.4, 7.5, 1.25, 245, Color);

	//Show To All Clients:
	TE_SendToAll();

	viewPunch[0] = GetRandomFloat( -9.5, 9.2 );
	viewPunch[1] = GetRandomFloat( -9.5, 7.5 );

	pos[2] += 10.0;

	//TE Setup:
	TE_SetupDynamicLight(pos, 200, 220, 255, 8, 65.0, 0.4, 50.0);

	//Send:
	TE_SendToAll();

	//Set Ent Color:
	SetEntityRenderColor(ent, 200, 20, 215, 10);

	Tools_ViewPunch(client, viewPunch);

	// Register a muzzleflash for the AI
	SetEntPropFloat(client, Prop_Data, "m_flFlashTime", GetGameTime() + 0.5);

	SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
	SetEntPropEnt(ent, Prop_Data, "m_hThrower", client);
	BoltOwner[ent] = client;
}

public Action explode(Handle timer, any data){
	if(IsValidEntity(data)){
		AcceptEntityInput(data, "Kill");
	}
}

// remove players from Vehicles before they are destroyed or the server will crash!
public OnEntityDestroyed(int Entity)
{
	//Check:
	if(IsValidEdict(Entity))
	{
		char cls[32];
		GetEntityClassname(Entity, cls, sizeof(cls));

		if(StrEqual(cls, "Super_PlamaBlast"))
		{

			//Effect:
			CreateHitSurfaceEffect(Entity);
		}
	}
}

public void CreateHitSurfaceEffect(int Entity)
{

	//Is Valid:
	if(!IsValidEdict(Entity))
	{

		//Print:
		//PrintToServer("Invalid Laser Bolt");

		//Return:
		return;
	}
	
	int client = BoltOwner[Entity];
	//int client = GetEntPropEnt(ent, Prop_Data, "m_hThrower");
	//int client = GetEntPropEnt(Entity, Prop_Data, "m_hOwnerEntity");

	//Check:
	if(client <= 0)
	{

		//Print:
		PrintToServer("Laser Bolt but no Client");

		//Return:
		return;
	}

	float Origin[3], Angels[3];

	GetEntPropVector(Entity, Prop_Data, "m_vecOrigin", Origin);
		
	GetEntPropVector(Entity, Prop_Data, "m_angRotation", Angels);

	//TE Setup:
	TE_SetupDynamicLight(Origin, 200, 220, 215, 8, 255.0, 0.4, 50.0);

	//Send:
	TE_SendToAll();

	physExplosion(Origin, 255.0, true);

	//Temp Ent:
	TE_SetupSparks(Origin, Angels, 5, 5);

	//Send:
	TE_SendToAll();

	int ent = CreateEntityByName("prop_combine_ball");
	DispatchSpawn(ent);

	TeleportEntity(ent, Origin, Angels, NULL_VECTOR);
	
	//Accept:
	AcceptEntityInput(ent, "explode");

	//Check:
	if(IsValidEdict(BoltLight[Entity]))
	{

		//Accept:
		AcceptEntityInput(BoltLight[Entity], "Kill");

		//Initialize:
		BoltLight[Entity] = -1;
	}

	//Check:
	if(IsValidEdict(BoltProp[Entity]))
	{

		//Accept:
		AcceptEntityInput(BoltProp[Entity], "Kill");

		//Initialize:
		BoltLight[Entity] = -1;
	}

	//Declare:
	int Effect = CreateEnvAr2Explosion(Entity, "null", "sprites/plasmaember.vmt");

	CreateTimer(1.0, explode, EntIndexToEntRef(Effect), TIMER_FLAG_NO_MAPCHANGE);
	
	//Emit Sound:
	EmitAmbientSound("ambient/explosions/explode_5.wav", Origin, SNDLEVEL_RAIDSIREN);

	//Declare:
	float Angles[3] = {0.0,...};
	float Offset[3] = {0.0, 0.0, 2.0};

	//Create Fire Effect!
	Effect = CreateInfoParticleSystemOther(Entity, "null", "citadel_shockwave", 1.0, Offset, Angles);

	//Accept:
	AcceptEntityInput(Effect, "ClearParent", Entity);

	CG_RadiusDamage(client, client, PRIMARY_BULLET_DAMAGE, DMG_SHOCK, 0, Origin, 300.0, client);
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
//CreateCustomLight(0, 1, 255, 255, 255, 0.5, "640", "80", "3", "0", "null")
public int CreateCustomLight(int Ent, int IsOn, int Red, int Green, int Blue, float Offset, const char[] Distance, const char[] SpotLightRadius, const char[] Brightness, const char[] Style, const char[] Attachment)
{

	//Declare:
	float EntOrigin[3];

	//Initulize:
	GetEntPropVector(Ent, Prop_Data, "m_vecOrigin", EntOrigin);

	//Edit Position:
	EntOrigin[2] += Offset;

	//Initulize::
	int Light = CreateEntityByName("light_dynamic");

	//Is Valid:
	if(IsValidEdict(Light))
	{

		//Declare:
		char LightColor[32];

		//Format:
		Format(LightColor, sizeof(LightColor), "%i %i %i", Red, Green, Blue);

		//Dispatch:
		DispatchKeyValue(Light, "_light", LightColor);

		DispatchKeyValue(Light, "distance", Distance);

		DispatchKeyValue(Light, "spotlight_radius", SpotLightRadius);

		DispatchKeyValue(Light, "brightness", Brightness);

		DispatchKeyValue(Light, "style", Style);

		//Declare:
		char SpawnOrg[50];

		//Format:
		Format(SpawnOrg, sizeof(SpawnOrg), "%f %f %f", EntOrigin[0], EntOrigin[1], EntOrigin[2]);

		//Dispatch:
		DispatchKeyValue(Light, "origin", SpawnOrg);

		//Spawn:
		DispatchSpawn(Light);

		//Activate
		ActivateEntity(Light);

		//Set String:
		SetVariantString("!activator");

		//Accept:
		AcceptEntityInput(Light, "SetParent", Ent, Light, 0);

		//Custom Attachment point!
		if(!StrEqual(Attachment, "null"))
		{

			//Attach:
			SetVariantString(Attachment);

			//Accept:
			AcceptEntityInput(Light, "SetParentAttachment", Light , Light, 0);
		}

		SetEntPropEnt(Light, Prop_Data, "m_hOwnerEntity", Ent);

		//Return:
		return Light;
	}

	//Return:
	return -1;
}

public int CreateEnvAr2Explosion(int Ent, char[] Attachment, char[] Material)
{

	//Declare:
	int Ar2Explosion = CreateEntityByName("env_ar2explosion");

	//Check:
	if(IsValidEdict(Ar2Explosion) && IsValidEdict(Ent))
	{

		//Accept:
		DispatchKeyValue(Ar2Explosion, "Material", Material);

		//Set Owner
		SetEntPropEnt(Ar2Explosion, Prop_Send, "m_hOwnerEntity", Ent);

		//Spawn
		DispatchSpawn(Ar2Explosion);

		//Declare:
		float Position[3];

		//Initulize:
		GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", Position);

		//Teleport:
		TeleportEntity(Ar2Explosion, Position, NULL_VECTOR, NULL_VECTOR);

		//Set String:
		SetVariantString("!activator");

		//Accept:
		AcceptEntityInput(Ar2Explosion, "SetParent", Ent, Ar2Explosion, 0);

		//Check:
		if(!StrEqual(Attachment, "null"))
		{

			//Attach:
			SetVariantString(Attachment);

			//Accept:
			AcceptEntityInput(Ar2Explosion, "SetParentAttachment", Ar2Explosion, Ar2Explosion, 0);
		}

		//Accept:
		AcceptEntityInput(Ar2Explosion, "explode");

		//Return:
		return Ar2Explosion;
	}

	//Return:
	return -1;
}

// Thanks to V0gelz Edited By Master(D)
stock int CreateEnvShooter(int Ent, char[] Attachment, float Angles[3], float iGibs,float Delay, float GibAngles[3], float Velocity, float Variance, float Giblife, char[] ModelType)
{

	//Declare:
	int Shooter = CreateEntityByName("env_shooter");

	//Check:
	if(IsValidEdict(Shooter) && IsValidEdict(Ent))
	{

		// Gib Direction (Pitch Yaw Roll) - The direction the gibs will fly. 
		DispatchKeyValueVector(Shooter, "angles", Angles);

		// Number of Gibs - Total number of gibs to shoot each time it's activated
		DispatchKeyValueFloat(Shooter, "m_iGibs", iGibs);

		// Delay between shots - Delay (in seconds) between shooting each gib. If 0, all gibs shoot at once.
		DispatchKeyValueFloat(Shooter, "delay", Delay);

		// <angles> Gib Angles (Pitch Yaw Roll) - The orientation of the spawned gibs. 
		DispatchKeyValueVector(Shooter, "gibangles", GibAngles);

		// Gib Velocity - Speed of the fired gibs. 
		DispatchKeyValueFloat(Shooter, "m_flVelocity", Velocity);

		// Course Variance - How much variance in the direction gibs are fired. 
		DispatchKeyValueFloat(Shooter, "m_flVariance", Variance);

		// Gib Life - Time in seconds for gibs to live +/- 5%. 
		DispatchKeyValueFloat(Shooter, "m_flGibLife", Giblife);
		
		// <choices> Used to set a non-standard rendering mode on this entity. See also 'FX Amount' and 'FX Color'. 
		DispatchKeyValue(Shooter, "rendermode", "5");

		// Model - Thing to shoot out. Can be a .mdl (model) or a .vmt (material/sprite). 
		DispatchKeyValue(Shooter, "shootmodel", ModelType);

		// <choices> Material Sound
		DispatchKeyValue(Shooter, "shootsounds", "-1"); // No sound

		// <choices> Simulate, no idea what it realy does tbh...
		// could find out but to lazy and not worth it...
		//DispatchKeyValue(Shooter, "simulation", "1");

		SetVariantString("spawnflags 4");
		AcceptEntityInput(Shooter, "AddOutput");

		//Activate:
		ActivateEntity(Shooter);

		//Declare:
		float Position[3];

		//Initulize:
		GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", Position);

		//Teleport:
		TeleportEntity(Shooter, Position, NULL_VECTOR, NULL_VECTOR);

		//Set String:
		SetVariantString("!activator");

		//Accept:
		AcceptEntityInput(Shooter, "SetParent", Ent, Shooter, 0);

		//Check:
		if(!StrEqual(Attachment, "null"))
		{

			//Attach:
			SetVariantString(Attachment);

			//Accept:
			AcceptEntityInput(Shooter, "SetParentAttachment", Shooter, Shooter, 0);
		}

		//Input:
		AcceptEntityInput(Shooter, "Shoot", Ent);

		//Return:
		return Shooter;
	}

	//Return:
	return -1;
}

public int CreateInfoParticleSystemOther(int Ent, char[] Attachment, char[] Model, float Time, float Offset[3], float Angles[3])
{

	//Declare:
	int Particle = CreateEntityByName("info_particle_system");

	//Check:
	if(IsValidEdict(Particle) && IsValidEdict(Ent))
	{

		//Dispatch:
		DispatchKeyValue(Particle, "effect_name", Model);

		//Spawn
		DispatchSpawn(Particle);

		//Activate:
		ActivateEntity(Particle);

		//Accept:
		AcceptEntityInput(Particle, "Start");

		//Declare:
		float Position[3];

		//Initulize:
		GetEntPropVector(Ent, Prop_Send, "m_vecOrigin", Position);

		//Do Math:
		Position[0] += Offset[0];
		Position[1] += Offset[1];
		Position[2] += Offset[2];

		//Teleport:
		TeleportEntity(Particle, Position, Angles, NULL_VECTOR);

		//Set String:
		SetVariantString("!activator");

		//Accept:
		AcceptEntityInput(Particle, "SetParent", Ent, Particle, 0);

		//Check:
		if(!StrEqual(Attachment, "null"))
		{

			//Attach:
			SetVariantString(Attachment);

			//Accept:
			AcceptEntityInput(Particle, "SetParentAttachment", Particle, Particle, 0);
		}

		//Check:
		if(Time > 0.0)
		{

			//Timer:
			CreateTimer(0.1, explode, EntIndexToEntRef(Particle), TIMER_FLAG_NO_MAPCHANGE);
		}

		//Accept:
		AcceptEntityInput(Particle, "EmitBlood", Ent);

		//Return:
		return Particle;
	}

	//Return:
	return -1;
}
