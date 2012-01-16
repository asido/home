/*
This source file is part of Rigs of Rods
Copyright 2005,2006,2007,2008,2009 Pierre-Michel Ricordel
Copyright 2007,2008,2009 Thomas Fischer

For more information, see http://www.rigsofrods.com/

Rigs of Rods is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License version 3, as
published by the Free Software Foundation.

Rigs of Rods is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Rigs of Rods.  If not, see <http://www.gnu.org/licenses/>.
*/
#include "RoRFrameListener.h"

#include "OgrePrerequisites.h"
#include "OgreTerrain.h"
#include "OgreTerrainQuadTreeNode.h"
#include "OgreTerrainMaterialGeneratorA.h"
#include "OgreTerrainPaging.h"


//#include "joystick.h"
#include "ProceduralManager.h"
#include "hdrlistener.h"
#include "softshadowlistener.h"
#include "ssaolistener.h"
#include "RigsOfRods.h"
#include "utils.h"
#include "ScopeLog.h"
#include "DepthOfFieldEffect.h"
#include "Lens.h"
#include "ChatSystem.h"
#include "GlowMaterialListener.h"
#include "MeshObject.h"

#include "CharacterFactory.h"
#include "BeamFactory.h"
#include "rormemory.h"
#include "PlayerColours.h"
#include "OverlayWrapper.h"
#include "ShadowManager.h"
#include "TruckHUD.h"
#include "DotSceneLoader.h"

#ifdef USE_MPLATFORM
#include "mplatform_fd.h"
#endif

#ifdef USE_LUA
# include "luasystem.h"
#endif

#ifdef USE_ANGELSCRIPT
#include "ScriptEngine.h"
#endif

#include "Road.h"
#include "road2.h"
#include "editor.h"
#include "water.h"
#include "WaterOld.h"
#include "Replay.h"

#ifdef USE_HYDRAX
# include "HydraxWater.h"
#endif

#include "dashboard.h"
#include "Heathaze.h"
#ifdef HAS_EDITOR
#include "truckeditor.h"
#endif
#include "network.h"
#include "NetworkStreamManager.h"
#include "engine.h"
#include "turboprop.h"
#include "screwprop.h"
#include "FlexAirfoil.h"

#ifdef USE_MYGUI
#include "gui_manager.h"
#include "gui_menu.h"
#include "gui_friction.h"
#include "gui_mp.h"
#include "SelectorWindow.h"
#include "LoadingWindow.h"
#endif //MYGUI

#include "mirrors.h"
#include "autopilot.h"
#include "ResourceBuffer.h"
#include "CacheSystem.h"

#ifdef USE_PAGED
# include "PagedGeometry.h"
# include "ImpostorPage.h"
# include "BatchPage.h"
#endif

#include "MovableText.h"
#include "IngameConsole.h"
#ifdef FEAT_TIMING
	#include "BeamStats.h"
#endif

#ifdef USE_PAGED
# include "TreeLoader2D.h"
# include "TreeLoader3D.h"
# include "GrassLoader.h"
#endif

#ifdef USE_MYGUI
#include "MapControl.h"
#include "MapTextureCreator.h"
#include "MapEntity.h"
#endif // MYGUI
#include <OgreFontManager.h>
#include "language.h"
#include "errorutils.h"
#include "DustManager.h"

#include <OgreHeaderPrefix.h>
#include <OgreRTShaderSystem.h>

#if OGRE_PLATFORM == OGRE_PLATFORM_WIN32
	#include <Windows.h>
# ifdef XFIRE
	// XFire support under windows only!
	#include "xfiregameclient.h"
# endif //XFIRE
#endif

// some gcc fixes
#if OGRE_PLATFORM == OGRE_PLATFORM_LINUX
#pragma GCC diagnostic ignored "-Wfloat-equal"
#endif //OGRE_PLATFORM_LINUX

#include "OISKeyboard.h"

#ifdef USE_OIS_G27
#include "win32/Win32LogitechLEDs.h"
#endif

//#include "OgreTerrainSceneManager.h" // = ILLEGAL to link to a plugin!

#include "writeTextToTexture.h"
#include "Console.h"

#if OGRE_PLATFORM == OGRE_PLATFORM_APPLE
//#include <CFUserNotification.h>
#endif

using namespace std;

bool disableRendering=false;

Camera *gCamera;

/// This class just pretends to provide prcedural page content to avoid page loading
class DummyPageProvider : public PageProvider
{
public:
	bool prepareProceduralPage(Page* page, PagedWorldSection* section) { return true; }
	bool loadProceduralPage(Page* page, PagedWorldSection* section) { return true; }
	bool unloadProceduralPage(Page* page, PagedWorldSection* section) { return true; }
	bool unprepareProceduralPage(Page* page, PagedWorldSection* section) { return true; }
};
DummyPageProvider mDummyPageProvider;

class disableRenderingListener : public RenderTargetListener
{
private:

public:
	void preRenderTargetUpdate(const RenderTargetEvent& evt)
	{
		if (disableRendering) mScene->setFindVisibleObjects(false);
	}
	void postRenderTargetUpdate(const RenderTargetEvent& evt)
	{
		mScene->setFindVisibleObjects(true);
	}

};

disableRenderingListener disableListener;

Material *terrainmaterial = 0;

char terrainoriginalmaterial[100];
bool shutdownall=false;



// static heightfinder
HeightFinder *RoRFrameListener::hfinder = 0;
RoRFrameListener *eflsingleton = 0;

//workaround for pagedgeometry
inline float getTerrainHeight(Ogre::Real x, Ogre::Real z, void *unused=0)
{
	if(!RoRFrameListener::hfinder)
		return 1;
	return RoRFrameListener::hfinder->getHeightAt(x, z);
}



void RoRFrameListener::startTimer()
{
	//LogManager::getSingleton().logMessage("LUA: startTimer()");
	raceStartTime = (int)rtime;
	if(ow)
	{
		ow->racing->show();
		ow->laptimes->show();
		ow->laptimems->show();
		ow->laptimemin->show();
	}
}

float RoRFrameListener::stopTimer()
{
	//LogManager::getSingleton().logMessage("LUA: stopTimer()");
	float time=rtime - raceStartTime;
	// let the display on
	if(ow)
	{
		char txt[255];
		sprintf(txt, "Last lap: %.2i'%.2i.%.2i", ((int)(time))/60,((int)(time))%60, ((int)(time*100.0))%100);
		ow->lasttime->setCaption(txt);
		//ow->racing->hide();
		ow->laptimes->hide();
		ow->laptimems->hide();
		ow->laptimemin->hide();
	}
	raceStartTime = -1;
	return time;
}

void RoRFrameListener::updateRacingGUI()
{
	if(!ow) return;
	// update raceing gui if required
	float time=rtime - raceStartTime;
	char txt[10];
	sprintf(txt, "%.2i", ((int)(time*100.0))%100);
	ow->laptimems->setCaption(txt);
	sprintf(txt, "%.2i", ((int)(time))%60);
	ow->laptimes->setCaption(txt);
	sprintf(txt, "%.2i'", ((int)(time))/60);
	ow->laptimemin->setCaption(txt);
}

void RoRFrameListener::updateIO(float dt)
{
	if (current_truck != -1 && trucks[current_truck] && trucks[current_truck]->driveable == TRUCK)
	{
#ifdef USE_OIS_G27
		//logitech G27 LEDs tachometer
		if (leds)
		{
			leds->play(trucks[current_truck]->engine->getRPM(),
				trucks[current_truck]->engine->getMaxRPM()*0.75,
				trucks[current_truck]->engine->getMaxRPM());
		}
#endif //OIS_G27

		// force feedback
		if (forcefeedback)
		{
			Vector3 udir=trucks[current_truck]->nodes[trucks[current_truck]->cameranodepos[0]].RelPosition-trucks[current_truck]->nodes[trucks[current_truck]->cameranodedir[0]].RelPosition;
			Vector3 uroll=trucks[current_truck]->nodes[trucks[current_truck]->cameranodepos[0]].RelPosition-trucks[current_truck]->nodes[trucks[current_truck]->cameranoderoll[0]].RelPosition;
			udir.normalise();
			uroll.normalise();
			forcefeedback->setForces(-trucks[current_truck]->ffforce.dotProduct(uroll)/10000.0,
				trucks[current_truck]->ffforce.dotProduct(udir)/10000.0,
				trucks[current_truck]->WheelSpeed,
				trucks[current_truck]->hydrodircommand,
				trucks[current_truck]->ffhydro);
		}
	}

}

void RoRFrameListener::updateGUI(float dt)
{
	if(!ow) return; // no gui, then skip this

	NETCHAT.update(dt);

	if (current_truck==-1) return;

	//update the truck info gui (also if not displayed!)
	ow->truckhud->update(dt, trucks[current_truck], mSceneMgr, mCamera, mWindow, mTruckInfoOn);

#ifdef FEAT_TIMING
	BES.updateGUI(dt, current_truck, trucks);
#endif

	if (pressure_pressed)
	{
		Real angle;
		angle=135.0-trucks[current_truck]->getPressure()*2.7;
		ow->pressuretexture->setTextureRotate(Degree(angle));
	}

	// racing gui
	if (raceStartTime > 0)
		updateRacingGUI();

	// update map
#ifdef USE_MYGUI
	if(bigMap)
	{
		for (int i=0; i<free_truck; i++)
		{
			if(!trucks[i]) continue;
			MapEntity *e = bigMap->getEntityByName("Truck"+StringConverter::toString(i));
			if(!e) continue;
			if (trucks[i]->state != RECYCLE && !interactivemap)
			{
				e->setState(trucks[i]->state);
				e->setVisibility(true);
				e->setPosition(trucks[i]->getPosition());
				e->setRotation(-Radian(trucks[i]->getHeadingDirectionAngle()));
			} else
			{
				e->setVisibility(false);
			}
		}
	}
#endif // MYGUI

	if (trucks[current_truck]->driveable == TRUCK)
	{
		//TRUCK
		if(!trucks[current_truck]->engine) return;

		//special case for the editor
		if (trucks[current_truck]->editorId>=0 && editor)
		{
			ow->editor_pos->setCaption("Position: X=" +
				StringConverter::toString(trucks[current_truck]->nodes[trucks[current_truck]->editorId].AbsPosition.x)+
				"  Y="+StringConverter::toString(trucks[current_truck]->nodes[trucks[current_truck]->editorId].AbsPosition.y)+
				"  Z="+StringConverter::toString(trucks[current_truck]->nodes[trucks[current_truck]->editorId].AbsPosition.z)
				);
			ow->editor_angles->setCaption("Angles: 0.0 " +
				StringConverter::toString(editor->pturn)+
				"  "+StringConverter::toString(editor->ppitch)
				);
			char type[256];
			sprintf(type, "Object: %s", editor->curtype);
			ow->editor_object->setCaption(type);
		}

		// gears
		int truck_getgear = trucks[current_truck]->engine->getGear();
		if (truck_getgear>0)
		{
			int numgears = trucks[current_truck]->engine->getNumGears();
			String gearstr = StringConverter::toString(truck_getgear) + "/" + StringConverter::toString(numgears);
			ow->guiGear->setCaption(gearstr);
			ow->guiGear3D->setCaption(gearstr);
		} else if (truck_getgear==0)
		{
			ow->guiGear->setCaption("N");
			ow->guiGear3D->setCaption("N");
		} else
		{
			ow->guiGear->setCaption("R");
			ow->guiGear3D->setCaption("R");
		}
		//autogears
		int cg = trucks[current_truck]->engine->getAutoShift();
		for (int i=0; i<5; i++)
		{
			if (i==cg)
			{
				if (i==1)
				{
					ow->guiAuto[i]->setColourTop(ColourValue(1.0, 0.2, 0.2, 1.0));
					ow->guiAuto[i]->setColourBottom(ColourValue(0.8, 0.1, 0.1, 1.0));
					ow->guiAuto3D[i]->setColourTop(ColourValue(1.0, 0.2, 0.2, 1.0));
					ow->guiAuto3D[i]->setColourBottom(ColourValue(0.8, 0.1, 0.1, 1.0));
				} else
				{
					ow->guiAuto[i]->setColourTop(ColourValue(1.0, 1.0, 1.0, 1.0));
					ow->guiAuto[i]->setColourBottom(ColourValue(0.8, 0.8, 0.8, 1.0));
					ow->guiAuto3D[i]->setColourTop(ColourValue(1.0, 1.0, 1.0, 1.0));
					ow->guiAuto3D[i]->setColourBottom(ColourValue(0.8, 0.8, 0.8, 1.0));
				}
			} else
			{
				if (i==1)
				{
					ow->guiAuto[i]->setColourTop(ColourValue(0.4, 0.05, 0.05, 1.0));
					ow->guiAuto[i]->setColourBottom(ColourValue(0.3, 0.02, 0.2, 1.0));
					ow->guiAuto3D[i]->setColourTop(ColourValue(0.4, 0.05, 0.05, 1.0));
					ow->guiAuto3D[i]->setColourBottom(ColourValue(0.3, 0.02, 0.2, 1.0));
				} else
				{
					ow->guiAuto[i]->setColourTop(ColourValue(0.4, 0.4, 0.4, 1.0));
					ow->guiAuto[i]->setColourBottom(ColourValue(0.3, 0.3, 0.3, 1.0));
					ow->guiAuto3D[i]->setColourTop(ColourValue(0.4, 0.4, 0.4, 1.0));
					ow->guiAuto3D[i]->setColourBottom(ColourValue(0.3, 0.3, 0.3, 1.0));
				}
			}

		}

		// pedals
		ow->guipedclutch->setTop(-0.05*trucks[current_truck]->engine->getClutch()-0.01);
		ow->guipedbrake->setTop(-0.05*(1.0-trucks[current_truck]->brake/trucks[current_truck]->brakeforce)-0.01);
		ow->guipedacc->setTop(-0.05*(1.0-trucks[current_truck]->engine->getAcc())-0.01);

		// speedo / calculate speed
		Real guiSpeedFactor = 7.0 * (140.0 / trucks[current_truck]->speedoMax);
		Real angle = 140 - fabs(trucks[current_truck]->WheelSpeed * guiSpeedFactor);
		if (angle < -140)
			angle = -140;
		ow->speedotexture->setTextureRotate(Degree(angle));

		// calculate tach stuff
		Real tachoFactor = 0.072;
		if(trucks[current_truck]->useMaxRPMforGUI)
			tachoFactor = 0.072 * (3500 / trucks[current_truck]->engine->getMaxRPM());
		angle=126.0-fabs(trucks[current_truck]->engine->getRPM() * tachoFactor);
		if (angle<-120.0) angle=-120.0;
		if (angle>121.0) angle=121.0;
		ow->tachotexture->setTextureRotate(Degree(angle));

		// roll
		Vector3 dir=trucks[current_truck]->nodes[trucks[current_truck]->cameranodepos[0]].RelPosition-trucks[current_truck]->nodes[trucks[current_truck]->cameranoderoll[0]].RelPosition;
		dir.normalise();
		//	roll_node->resetOrientation();
		angle=asin(dir.dotProduct(Vector3::UNIT_Y));
		if (angle<-1) angle=-1;
		if (angle>1) angle=1;
		//float jroll=angle*1.67;
		ow->rolltexture->setTextureRotate(Radian(angle));
		//	roll_node->roll(Radian(angle));

		// rollcorr
		if (trucks[current_truck]->free_active_shock && ow && ow->guiRoll && ow->rollcortexture)
		{
			//		rollcorr_node->resetOrientation();
			//		rollcorr_node->roll(Radian(-trucks[current_truck]->stabratio*5.0));
			ow->rollcortexture->setTextureRotate(Radian(-trucks[current_truck]->stabratio*10.0));
			if (trucks[current_truck]->stabcommand)
				ow->guiRoll->setMaterialName("tracks/rollmaskblink");
			else
				ow->guiRoll->setMaterialName("tracks/rollmask");
		}

		// pitch
		dir=trucks[current_truck]->nodes[trucks[current_truck]->cameranodepos[0]].RelPosition-trucks[current_truck]->nodes[trucks[current_truck]->cameranodedir[0]].RelPosition;
		dir.normalise();
		//	pitch_node->resetOrientation();
		angle=asin(dir.dotProduct(Vector3::UNIT_Y));
		if (angle<-1) angle=-1;
		if (angle>1) angle=1;
		ow->pitchtexture->setTextureRotate(Radian(angle));
		//	pitch_node->roll(Radian(angle));

		// turbo
		angle=40.0-trucks[current_truck]->engine->getTurboPSI()*3.34;
		ow->turbotexture->setTextureRotate(Degree(angle));

		// indicators
		ow->igno->setMaterialName(String("tracks/ign-")         + ((trucks[current_truck]->engine->contact)?"on":"off"));
		ow->batto->setMaterialName(String("tracks/batt-")       + ((trucks[current_truck]->engine->contact && !trucks[current_truck]->engine->running)?"on":"off"));
		ow->pbrakeo->setMaterialName(String("tracks/pbrake-")   + ((trucks[current_truck]->parkingbrake)?"on":"off"));
		ow->lockedo->setMaterialName(String("tracks/locked-")   + ((trucks[current_truck]->isLocked())?"on":"off"));
		ow->lopresso->setMaterialName(String("tracks/lopress-") + ((!trucks[current_truck]->canwork)?"on":"off"));
		ow->clutcho->setMaterialName(String("tracks/clutch-")   + ((fabs(trucks[current_truck]->engine->getTorque())>=trucks[current_truck]->engine->getClutchForce()*10.0f)?"on":"off"));
		ow->lightso->setMaterialName(String("tracks/lights-")   + ((trucks[current_truck]->lights)?"on":"off"));

		if (trucks[current_truck]->isTied())
		{
			if (fabs(trucks[current_truck]->commandkey[0].commandValue) > 0.000001f)
			{
				flipflop = !flipflop;
				if (flipflop)
					ow->securedo->setMaterialName("tracks/secured-on");
				else
					ow->securedo->setMaterialName("tracks/secured-off");
			} else
			{
				ow->securedo->setMaterialName("tracks/secured-on");
			}
		} else
		{
			ow->securedo->setMaterialName("tracks/secured-off");
		}

	} else if (ow && trucks[current_truck]->driveable == AIRPLANE)
	{
		//AIRPLANE GUI
		int ftp = trucks[current_truck]->free_aeroengine;

		//throttles
		ow->thro1->setTop(ow->thrtop+ow->thrheight*(1.0-trucks[current_truck]->aeroengines[0]->getThrotle())-1.0);
		if (ftp>1) ow->thro2->setTop(ow->thrtop+ow->thrheight*(1.0-trucks[current_truck]->aeroengines[1]->getThrotle())-1.0);
		if (ftp>2) ow->thro3->setTop(ow->thrtop+ow->thrheight*(1.0-trucks[current_truck]->aeroengines[2]->getThrotle())-1.0);
		if (ftp>3) ow->thro4->setTop(ow->thrtop+ow->thrheight*(1.0-trucks[current_truck]->aeroengines[3]->getThrotle())-1.0);

		//fire
		if (trucks[current_truck]->aeroengines[0]->isFailed()) ow->engfireo1->setMaterialName("tracks/engfire-on"); else ow->engfireo1->setMaterialName("tracks/engfire-off");
		if (ftp>1 && trucks[current_truck]->aeroengines[1]->isFailed()) ow->engfireo2->setMaterialName("tracks/engfire-on"); else ow->engfireo2->setMaterialName("tracks/engfire-off");
		if (ftp>2 && trucks[current_truck]->aeroengines[2]->isFailed()) ow->engfireo3->setMaterialName("tracks/engfire-on"); else ow->engfireo3->setMaterialName("tracks/engfire-off");
		if (ftp>3 && trucks[current_truck]->aeroengines[3]->isFailed()) ow->engfireo4->setMaterialName("tracks/engfire-on"); else ow->engfireo4->setMaterialName("tracks/engfire-off");

		//airspeed
		float angle=0.0;
		float ground_speed_kt=trucks[current_truck]->nodes[0].Velocity.length()*1.9438;

		//tropospheric model valid up to 11.000m (33.000ft)
		float altitude=trucks[current_truck]->nodes[0].AbsPosition.y;
		float sea_level_temperature=273.15+15.0; //in Kelvin
		float sea_level_pressure=101325; //in Pa
		float airtemperature=sea_level_temperature-altitude*0.0065; //in Kelvin
		float airpressure=sea_level_pressure*pow(1.0-0.0065*altitude/288.15, 5.24947); //in Pa
		float airdensity=airpressure*0.0000120896;//1.225 at sea level

		float kt = ground_speed_kt*sqrt(airdensity/1.225); //KIAS
		if (kt>23.0)
		{
			if (kt<50.0)
				angle=((kt-23.0)/1.111);
			else if (kt<100.0)
				angle=(24.0+(kt-50.0)/0.8621);
			else if(kt<300.0)
				angle=(82.0+(kt-100.0)/0.8065);
			else
				angle=329.0;
		}
		ow->airspeedtexture->setTextureRotate(Degree(-angle));

		// AOA
		angle=0;
		if (trucks[current_truck]->free_wing>4)
			angle=trucks[current_truck]->wings[4].fa->aoa;
		if (kt<10.0) angle=0;
		float absangle=angle;
		if (absangle<0) absangle=-absangle;
#ifdef USE_OPENAL
		if (ssm)
			ssm->modulate(current_truck, SS_MOD_AOA, absangle);
		if (absangle>18.0 && ssm)
			ssm->trigStart(current_truck, SS_TRIG_AOA);
		else
			ssm->trigStop(current_truck, SS_TRIG_AOA);
#endif // OPENAL
		if (angle>25.0) angle=25.0;
		if (angle<-25.0) angle=-25.0;
		ow->aoatexture->setTextureRotate(Degree(-angle*4.7+90.0));

		// altimeter
		angle=trucks[current_truck]->nodes[0].AbsPosition.y*1.1811;
		ow->altimetertexture->setTextureRotate(Degree(-angle));
		char altc[10];
		sprintf(altc, "%03u", (int)(trucks[current_truck]->nodes[0].AbsPosition.y/30.48));
		ow->alt_value_taoe->setCaption(altc);

		//adi
		//roll
		Vector3 rollv=trucks[current_truck]->nodes[trucks[current_truck]->cameranodepos[0]].RelPosition-trucks[current_truck]->nodes[trucks[current_truck]->cameranoderoll[0]].RelPosition;
		rollv.normalise();
		float rollangle=asin(rollv.dotProduct(Vector3::UNIT_Y));

		//pitch
		Vector3 dirv=trucks[current_truck]->nodes[trucks[current_truck]->cameranodepos[0]].RelPosition-trucks[current_truck]->nodes[trucks[current_truck]->cameranodedir[0]].RelPosition;
		dirv.normalise();
		float pitchangle=asin(dirv.dotProduct(Vector3::UNIT_Y));
		Vector3 upv=dirv.crossProduct(-rollv);
		if (upv.y<0) rollangle=3.14159-rollangle;
		ow->adibugstexture->setTextureRotate(Radian(-rollangle));
		ow->aditapetexture->setTextureVScroll(-pitchangle*0.25);
		ow->aditapetexture->setTextureRotate(Radian(-rollangle));

		//hsi
		Vector3 idir=trucks[current_truck]->nodes[trucks[current_truck]->cameranodepos[0]].RelPosition-trucks[current_truck]->nodes[trucks[current_truck]->cameranodedir[0]].RelPosition;
		//			idir.normalise();
		float dirangle=atan2(idir.dotProduct(Vector3::UNIT_X), idir.dotProduct(-Vector3::UNIT_Z));
		ow->hsirosetexture->setTextureRotate(Radian(dirangle));
		if (trucks[current_truck]->autopilot)
		{
			ow->hsibugtexture->setTextureRotate(Radian(dirangle)-Degree(trucks[current_truck]->autopilot->heading));
			float vdev=0;
			float hdev=0;
			trucks[current_truck]->autopilot->getRadioFix(localizers, free_localizer, &vdev, &hdev);
			if (hdev>15) hdev=15;
			if (hdev<-15) hdev=-15;
			ow->hsivtexture->setTextureUScroll(-hdev*0.02);
			if (vdev>15) vdev=15;
			if (vdev<-15) vdev=-15;
			ow->hsihtexture->setTextureVScroll(-vdev*0.02);
		}

		//vvi
		float vvi=trucks[current_truck]->nodes[0].Velocity.y*196.85;
		if (vvi<1000.0 && vvi>-1000.0) angle=vvi*0.047;
		if (vvi>1000.0 && vvi<6000.0) angle=47.0+(vvi-1000.0)*0.01175;
		if (vvi>6000.0) angle=105.75;
		if (vvi<-1000.0 && vvi>-6000.0) angle=-47.0+(vvi+1000.0)*0.01175;
		if (vvi<-6000.0) angle=-105.75;
		ow->vvitexture->setTextureRotate(Degree(-angle+90.0));

		//rpm
		float pcent=trucks[current_truck]->aeroengines[0]->getRPMpc();
		if (pcent<60.0) angle=-5.0+pcent*1.9167;
		else if (pcent<110.0) angle=110.0+(pcent-60.0)*4.075;
		else angle=314.0;
		ow->airrpm1texture->setTextureRotate(Degree(-angle));

		if (ftp>1) pcent=trucks[current_truck]->aeroengines[1]->getRPMpc(); else pcent=0;
		if (pcent<60.0) angle=-5.0+pcent*1.9167;
		else if (pcent<110.0) angle=110.0+(pcent-60.0)*4.075;
		else angle=314.0;
		ow->airrpm2texture->setTextureRotate(Degree(-angle));

		if (ftp>2) pcent=trucks[current_truck]->aeroengines[2]->getRPMpc(); else pcent=0;
		if (pcent<60.0) angle=-5.0+pcent*1.9167;
		else if (pcent<110.0) angle=110.0+(pcent-60.0)*4.075;
		else angle=314.0;
		ow->airrpm3texture->setTextureRotate(Degree(-angle));

		if (ftp>3) pcent=trucks[current_truck]->aeroengines[3]->getRPMpc(); else pcent=0;
		if (pcent<60.0) angle=-5.0+pcent*1.9167;
		else if (pcent<110.0) angle=110.0+(pcent-60.0)*4.075;
		else angle=314.0;
		ow->airrpm4texture->setTextureRotate(Degree(-angle));

		if (trucks[current_truck]->aeroengines[0]->getType() == AEROENGINE_TYPE_TURBOPROP)
		{
			Turboprop *tp=(Turboprop*)trucks[current_truck]->aeroengines[0];
			//pitch
			ow->airpitch1texture->setTextureRotate(Degree(-tp->pitch*2.0));
			//torque
			pcent=100.0*tp->indicated_torque/tp->max_torque;
			if (pcent<60.0) angle=-5.0+pcent*1.9167;
			else if (pcent<110.0) angle=110.0+(pcent-60.0)*4.075;
			else angle=314.0;
			ow->airtorque1texture->setTextureRotate(Degree(-angle));
		}

		if (ftp>1 && trucks[current_truck]->aeroengines[1]->getType()==AEROENGINE_TYPE_TURBOPROP)
		{
			Turboprop *tp=(Turboprop*)trucks[current_truck]->aeroengines[1];
			//pitch
			ow->airpitch2texture->setTextureRotate(Degree(-tp->pitch*2.0));
			//torque
			pcent=100.0*tp->indicated_torque/tp->max_torque;
			if (pcent<60.0) angle=-5.0+pcent*1.9167;
			else if (pcent<110.0) angle=110.0+(pcent-60.0)*4.075;
			else angle=314.0;
			ow->airtorque2texture->setTextureRotate(Degree(-angle));
		}

		if (ftp>2 && trucks[current_truck]->aeroengines[2]->getType()==AEROENGINE_TYPE_TURBOPROP)
		{
			Turboprop *tp=(Turboprop*)trucks[current_truck]->aeroengines[2];
			//pitch
			ow->airpitch3texture->setTextureRotate(Degree(-tp->pitch*2.0));
			//torque
			pcent=100.0*tp->indicated_torque/tp->max_torque;
			if (pcent<60.0) angle=-5.0+pcent*1.9167;
			else if (pcent<110.0) angle=110.0+(pcent-60.0)*4.075;
			else angle=314.0;
			ow->airtorque3texture->setTextureRotate(Degree(-angle));
		}

		if (ftp>3 && trucks[current_truck]->aeroengines[3]->getType()==AEROENGINE_TYPE_TURBOPROP)
		{
			Turboprop *tp=(Turboprop*)trucks[current_truck]->aeroengines[3];
			//pitch
			ow->airpitch4texture->setTextureRotate(Degree(-tp->pitch*2.0));
			//torque
			pcent=100.0*tp->indicated_torque/tp->max_torque;
			if (pcent<60.0) angle=-5.0+pcent*1.9167;
			else if (pcent<110.0) angle=110.0+(pcent-60.0)*4.075;
			else angle=314.0;
			ow->airtorque4texture->setTextureRotate(Degree(-angle));
		}

		//starters
		if (trucks[current_truck]->aeroengines[0]->getIgnition()) ow->engstarto1->setMaterialName("tracks/engstart-on"); else ow->engstarto1->setMaterialName("tracks/engstart-off");
		if (ftp>1 && trucks[current_truck]->aeroengines[1]->getIgnition()) ow->engstarto2->setMaterialName("tracks/engstart-on"); else ow->engstarto2->setMaterialName("tracks/engstart-off");
		if (ftp>2 && trucks[current_truck]->aeroengines[2]->getIgnition()) ow->engstarto3->setMaterialName("tracks/engstart-on"); else ow->engstarto3->setMaterialName("tracks/engstart-off");
		if (ftp>3 && trucks[current_truck]->aeroengines[3]->getIgnition()) ow->engstarto4->setMaterialName("tracks/engstart-on"); else ow->engstarto4->setMaterialName("tracks/engstart-off");
	} else if (trucks[current_truck]->driveable==BOAT)
	{
		//BOAT GUI
		int fsp = trucks[current_truck]->free_screwprop;
		//throtles
		ow->bthro1->setTop(ow->thrtop+ow->thrheight*(0.5-trucks[current_truck]->screwprops[0]->getThrotle()/2.0)-1.0);
		if (fsp>1)
			ow->bthro2->setTop(ow->thrtop+ow->thrheight*(0.5-trucks[current_truck]->screwprops[1]->getThrotle()/2.0)-1.0);

		//position
		Vector3 dir=trucks[current_truck]->nodes[trucks[current_truck]->cameranodepos[0]].RelPosition-trucks[current_truck]->nodes[trucks[current_truck]->cameranodedir[0]].RelPosition;
		dir.normalise();
		//moveBoatMapDot(trucks[current_truck]->position.x/mapsizex, trucks[current_truck]->position.z/mapsizez);
		//position

		char tmp[50]="";
		if(trucks[current_truck]->getLowestNode() != -1)
		{
			Vector3 pos = trucks[current_truck]->nodes[trucks[current_truck]->getLowestNode()].AbsPosition;
			float height =  pos.y - hfinder->getHeightAt(pos.x, pos.z);
			if(height>0.1 && height < 99.9)
			{
				sprintf(tmp, "%2.1f", height);
				ow->boat_depth_value_taoe->setCaption(tmp);
			} else
			{
				ow->boat_depth_value_taoe->setCaption("--.-");
			}
		}

		//waterspeed
		float angle=0.0;
		Vector3 hdir=trucks[current_truck]->nodes[trucks[current_truck]->cameranodepos[0]].RelPosition-trucks[current_truck]->nodes[trucks[current_truck]->cameranodedir[0]].RelPosition;
		hdir.normalise();
		float kt=hdir.dotProduct(trucks[current_truck]->nodes[trucks[current_truck]->cameranodepos[0]].Velocity)*1.9438;
		angle=kt*4.2;
		ow->boatspeedtexture->setTextureRotate(Degree(-angle));
		ow->boatsteertexture->setTextureRotate(Degree(trucks[current_truck]->screwprops[0]->getRudder() * 170));
	}
}

float RoRFrameListener::gravity = DEFAULT_GRAVITY;

void RoRFrameListener::setGravity(float value)
{
	if(!eflsingleton) return;
	// update the mass of all trucks
	gravity = value;
	for (int t=0; t<eflsingleton->free_truck; t++)
	{
		if(!eflsingleton->trucks[t]) continue;
		eflsingleton->trucks[t]->recalc_masses();
	}
}

// Constructor takes a RenderWindow because it uses that to determine input context
RoRFrameListener::RoRFrameListener(RenderWindow* win, Camera* cam, SceneManager* scm, Root* root, bool isEmbedded) :
	initialized(false),
	mCollisionTools(0),
	isEmbedded(isEmbedded),
	ow(0)
{
	for (int i=0; i<MAX_TRUCKS; i++) trucks[i]=0;

	pthread_mutex_init(&mutex_data, NULL);
	net_quality=0;
	net_quality_changed=false;

	thread_mode=THREAD_MONO;
	if (SETTINGS.getSetting("Threads")=="1 (Standard CPU)")thread_mode=THREAD_MONO;
	if (SETTINGS.getSetting("Threads")=="2 (Hyper-Threading or Dual core CPU)") thread_mode=THREAD_HT;
	if (SETTINGS.getSetting("Threads")=="3 (multi core CPU, one thread per beam)") thread_mode=THREAD_HT2;

	current_truck=-1;
#ifdef USE_LUA
	lua=0;
#endif // LUASCRIPT

	// we dont use overlays in embedded mode
	if(!isEmbedded)
		ow = new OverlayWrapper(win);

	benchmarking = !(SETTINGS.getSetting("Benchmark").empty());
	enablePosStor = (SETTINGS.getSetting("Position Storage")=="Yes");
	objectCounter=0;
	hdrListener=0;
	shaderSchemeMode=1;

	netPointToUID=-1;
	netcheckGUITimer=0;
	mDOF=0;
	mDOFDebug=false;
	mouseGrabForce=100000.0f;
	eflsingleton=this;
	forcefeedback=0;
#ifdef USE_OIS_G27
	leds=0;
#endif //OIS_G27

	if(SETTINGS.getSetting("Skidmarks") == "Yes")
		new SkidmarkManager();

#ifdef USE_MPLATFORM
	mplatform = new MPlatform_FD();
	if (mplatform) mplatform->connect();
#endif


#ifdef USE_ANGELSCRIPT
	new ScriptEngine(this, 0);
	exploreScripts();
#endif

	externalCameraMode=0;
	lastcameramode=0;
	gameStartTime = CACHE.getTimeStamp();
	loadedTerrain="none";
	creditsviewtime=5;
	terrainUID="";
	fogmode=-1;
	fogdensity=0;
	mtc=0;
	bigMap=0;
	envmap=0;
	debugCollisions=false;
	interactivemap=0;
	free_localizer=0;
	loading_state=NONE_LOADED;
	pressure_pressed=false;
	chatting=false;
	rtime=0;
	joyshiftlock=0;
	mScene=scm;
	persostart=Vector3(0,0,0);
	person=0;
	netChat=0;
	reload_pos=Vector3::ZERO;
	win->addListener(&disableListener);
	free_truck=0;
	//dirt=0;
	editorfd=0;
#ifdef HAS_EDITOR
	trucked=0;
#endif
	showcredits=0;
	current_truck=-1;
	w=0;
	mapsizex = 3000;
	mapsizez = 3000;
	hidegui=false;
	collisions=0;
	editor=0;
	mirror=0;
	dashboard=0;//new Dashboard(scm,win);

	mSceneMgr=scm;
#ifdef USE_OPENAL
	ssm=SoundScriptManager::getSingleton();
#endif //OPENAL
	mRoot=root;

	if(ow)
	{
		// setup direction arrow
		Entity *arrent = mSceneMgr->createEntity("dirArrowEntity", "arrow2.mesh");
	#if OGRE_VERSION<0x010602
		arrent->setNormaliseNormals(true);
	#endif //OGRE_VERSION
		// Add entity to the scene node
		dirArrowNode= new SceneNode(mSceneMgr);
		dirArrowNode->attachObject(arrent);
		dirArrowNode->setVisible(false);
		dirArrowNode->setScale(0.1, 0.1, 0.1);
		dirArrowNode->setPosition(Vector3(-0.6, +0.4, -1));
		dirArrowNode->setFixedYawAxis(true, Vector3::UNIT_Y);
		dirvisible = false;
		dirArrowPointed = Vector3::ZERO;
		ow->directionOverlay->add3D(dirArrowNode);
	}
	raceStartTime=-1;
	truck_preload_num=0;

	// setup input
	inputGrabMode=GRAB_ALL;
	switchMouseButtons=false;
#if OGRE_PLATFORM == OGRE_PLATFORM_APPLE
	// on apple, switch by default
	switchMouseButtons=true;
#endif
	if(SETTINGS.getSetting("Switch Mouse Buttons") == "Yes")
		switchMouseButtons=true;
	else if(SETTINGS.getSetting("Switch Mouse Buttons") == "No")
		switchMouseButtons=false;

	mouseGrabState=0; // 0 = not grabbed
	if(SETTINGS.getSetting("Input Grab") == "All")
		inputGrabMode = GRAB_ALL;
	else if(SETTINGS.getSetting("Input Grab") == "Dynamically")
		inputGrabMode = GRAB_DYNAMICALLY;
	else if(SETTINGS.getSetting("Input Grab") == "None")
		inputGrabMode = GRAB_NONE;

	// start input engine
	size_t hWnd = 0;
	win->getCustomAttribute("WINDOW", &hWnd);


	if(!benchmarking && !isEmbedded)
		INPUTENGINE.setup(hWnd, true, true, inputGrabMode);
#ifdef USE_MYGUI
	// init GUI
	new GUIManager(root, scm, win);
	LoadingWindow::getInstance();
	SelectorWindow::getInstance();
	// create main menu :D
	new GUI_MainMenu(this);
	new GUI_Friction();
#endif //MYGUI

#ifdef USE_ANGELSCRIPT
#ifdef USE_MYGUI
	Console::getInstance();
#endif// MYGUI
#endif

	// setup particle manager
	new DustManager(mSceneMgr);

	CACHE.startup(scm);

	if(SETTINGS.getSetting("regen-cache-only") != "")
	{
		CACHE.startup(scm, true);
		String str = _L("Cache regeneration done.\n");
		if(CACHE.newFiles > 0) str += StringConverter::toString(CACHE.newFiles) + " new files\n";
		if(CACHE.changedFiles > 0) str += StringConverter::toString(CACHE.changedFiles) + " changed files\n";
		if(CACHE.deletedFiles > 0) str += StringConverter::toString(CACHE.deletedFiles) + " deleted files\n";
		if(CACHE.newFiles + CACHE.changedFiles + CACHE.deletedFiles == 0) str += "no changes";
		str += _L("\n(These stats can be imprecise)");
		showError(_L("Cache regeneration done"), str.c_str());
		exit(0);
	}



	screenWidth=win->getWidth();
	screenHeight=win->getHeight();
	mouseX=screenWidth-20;
	mouseY=screenHeight-20;
	isnodegrabbed=false;

	mRotateSpeed = 100;
	mMoveSpeed = 50;

	windowResized(win);
	Ogre::WindowEventUtilities::addWindowEventListener(win, this);


	debugCollisions = (SETTINGS.getSetting("Debug Collisions") == "Yes");

    xfire_enabled = (SETTINGS.getSetting("XFire") == "Yes");

	externalCameraMode = (SETTINGS.getSetting("External Camera Mode") == "Static")? 1 : 0;

#ifndef XFIRE
	xfire_enabled = false;
#endif



	// get lights mode
	flaresMode = 0; //None
	if(SETTINGS.getSetting("Lights") == "None (fastest)")
		flaresMode = 0;
	else if(SETTINGS.getSetting("Lights") == "No light sources")
		flaresMode = 1;
	else if(SETTINGS.getSetting("Lights") == "Only current vehicle, main lights")
		flaresMode = 2;
	else if(SETTINGS.getSetting("Lights") == "All vehicles, main lights")
		flaresMode = 3;
	else if(SETTINGS.getSetting("Lights") == "All vehicles, all lights")
		flaresMode = 4;


	// heathaze effect
	heathaze=0;
	if(SETTINGS.getSetting("HeatHaze") == "Yes")
	{
		heathaze=new HeatHaze(scm, win,cam);
		heathaze->setEnable(true);
	}

	// no more force feedback
	// useforce=(SETTINGS.getSetting("Controler Force Feedback")=="Enable");
	// force feedback is ...back :)
	if (SETTINGS.getSetting("Force Feedback")=="Yes")
	{
		//check if a device has been detected
		if (INPUTENGINE.getForceFeedbackDevice())
		{
			//retrieve gain values
			float ogain=1.0;
			String tmpstring = SETTINGS.getSetting("Force Feedback Gain");
			if (tmpstring != String("")) ogain = atof(tmpstring.c_str())/100.0;

			float stressg=1.0;
			tmpstring = SETTINGS.getSetting("Force Feedback Stress");
			if (tmpstring != String("")) stressg = atof(tmpstring.c_str())/100.0;

			float centg=0.0;
			tmpstring = SETTINGS.getSetting("Force Feedback Centering");
			if (tmpstring != String("")) centg = atof(tmpstring.c_str())/100.0;

			float camg=0.0;
			tmpstring = SETTINGS.getSetting("Force Feedback Camera");
			if (tmpstring != String("")) camg = atof(tmpstring.c_str())/100.0;

			forcefeedback=new ForceFeedback(INPUTENGINE.getForceFeedbackDevice(), ogain, stressg, centg, camg);
		}
	}

#ifdef USE_OIS_G27
	if (SETTINGS.getSetting("Logitech LEDs")=="Yes")
	{
		leds = INPUTENGINE.getLogitechLEDsDevice();
	}
#endif //OIS_G27


	if(SETTINGS.getSetting("Screenshot Format")=="" || SETTINGS.getSetting("Screenshot Format")=="jpg (smaller, default)")
		strcpy(screenshotformat, "jpg");
	else if(SETTINGS.getSetting("Screenshot Format")=="png (bigger, no quality loss)")
		strcpy(screenshotformat, "png");
	else
		strncpy(screenshotformat, SETTINGS.getSetting("Screenshot Format").c_str(), 10);

	//Joystick
	/*
	float deadzone=0.1;
	String deadzone_string = SETTINGS.getSetting("Controler Deadzone");
	if (deadzone_string != String("")) {
		deadzone = atof(deadzone_string.c_str());
	}
	*/
	//joy=new BeamJoystick(mInputManager, deadzone, useforce, &cfg);
	//useforce=joy->hasForce();

	mCamera = cam;
	gCamera = cam;
	mWindow = win;
	mStatsOn = 0;
	mTruckInfoOn = false;
	mapMode=0;
	mTimeUntilNextToggle = 0;
	mSceneDetailIndex = 0;
	mMoveScale = 0.0f;
	mRotScale = 0.0f;
	camIdealPosition = Vector3::ZERO;
	lastPosition = Vector3::ZERO;
	//lastangle=0;
	camRotX=0;
	camRotY=Degree(12);
	camDist=20;
	clutch=0;
	camCollided=false;
	camPosColl=Vector3::ZERO;
	cameramode=0;
	road=0;

	objcounter=0;

	// load 3d line for mouse picking
	pickLine =  mSceneMgr->createManualObject("PickLineObject");
	pickLineNode = mSceneMgr->getRootSceneNode()->createChildSceneNode("PickLineNode");

	MaterialPtr pickLineMaterial = MaterialManager::getSingleton().create("PickLineMaterial",ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
	pickLineMaterial->setReceiveShadows(false);
	pickLineMaterial->getTechnique(0)->setLightingEnabled(true);
	pickLineMaterial->getTechnique(0)->getPass(0)->setDiffuse(0,0,1,0);
	pickLineMaterial->getTechnique(0)->getPass(0)->setAmbient(0,0,1);
	pickLineMaterial->getTechnique(0)->getPass(0)->setSelfIllumination(0,0,1);

	pickLine->begin("PickLineMaterial", Ogre::RenderOperation::OT_LINE_LIST);
	pickLine->position(0, 0, 0);
	pickLine->position(0, 0, 0);
	pickLine->end();
	pickLineNode->attachObject(pickLine);
	pickLineNode->setVisible(false);

	//network
	netmode=(SETTINGS.getSetting("Network enable")=="Yes");

	// check command line args
	String cmd = SETTINGS.getSetting("cmdline CMD");
	String cmdAction = "";
	String cmdServerIP = "";
	String modName = "";
	long cmdServerPort = 0;
	Vector3 spawnLocation = Vector3::ZERO;
	if(cmd != "")
	{
		Ogre::vector<String>::type str = StringUtil::split(cmd, "/");
		// process args now
		for(Ogre::vector<String>::type::iterator it = str.begin(); it!=str.end(); it++)
		{
			String argstr = *it;
			Ogre::vector<String>::type args = StringUtil::split(argstr, ":");
			if(args.size()<2) continue;
			if(args[0] == "action" && args.size() == 2) cmdAction = args[1];
			if(args[0] == "serverpass" && args.size() == 2) SETTINGS.setSetting("Server password", args[1]);
			if(args[0] == "modname" && args.size() == 2) modName = args[1];
			if(args[0] == "ipport" && args.size() == 3)
			{
				cmdServerIP = args[1];
				cmdServerPort = StringConverter::parseLong(args[2]);
			}
			if(args[0] == "loc" && args.size() == 4)
			{
				spawnLocation = Vector3(StringConverter::parseInt(args[1]), StringConverter::parseInt(args[2]), StringConverter::parseInt(args[3]));
				SETTINGS.setSetting("net spawn location", Ogre::StringConverter::toString(spawnLocation));
			}
		}
	}

	if(cmdAction == "regencache") SETTINGS.setSetting("regen-cache-only", "True");
	if(cmdAction == "installmod")
	{
		// use modname!
	}


	// check if we enable netmode based on cmdline
	if(!netmode && cmdAction == "joinserver")
		netmode = true;
	net=0;

	// preselected map or truck?
	String preselected_map = SETTINGS.getSetting("Preselected Map");
	String preselected_truck = SETTINGS.getSetting("Preselected Truck");
	String preselected_truckConfig = SETTINGS.getSetting("Preselected TruckConfig");
	bool enterTruck = (SETTINGS.getSetting("Enter Preselected Truck") == "Yes");

	if(preselected_map != "") LogManager::getSingleton().logMessage("Preselected Map: " + (preselected_map));
	if(preselected_truck != "") LogManager::getSingleton().logMessage("Preselected Truck: " + (preselected_truck));
	if(preselected_truckConfig != "") LogManager::getSingleton().logMessage("Preselected Truck Config: " + (preselected_truckConfig));

	//LogManager::getSingleton().logMessage("huette debug 1");

	// initiate player colours
	new PlayerColours();

	// hide console when not in netmode
	NETCHAT.setMode(this, NETCHAT_LEFT_SMALL, false);

	// you always need that, even if you are not using the network
	new NetworkStreamManager();

	// new factory for characters, net is INVALID, will be set later
	new CharacterFactory(cam, 0, collisions, hfinder, w, bigMap, mSceneMgr);
	new ChatSystemFactory(0);

	// notice: all factories must be available before starting the network!
#ifdef USE_SOCKETW
	if(netmode)
	{
		// cmdline overrides config
		std::string sname = SETTINGS.getSetting("Server name").c_str();
		if(cmdAction == "joinserver" && !cmdServerIP.empty())
			sname = cmdServerIP;

		long sport = StringConverter::parseLong(SETTINGS.getSetting("Server port"));
		if(cmdAction == "joinserver" && cmdServerPort)
			sport = cmdServerPort;

		if (sport==0)
		{
			showError(_L("A network error occured"), _L("Bad server port"));
			exit(123);
			return;
		}
		LogManager::getSingleton().logMessage("trying to join server '" + String(sname) + "' on port " + StringConverter::toString(sport) + "'...");

#ifdef USE_MYGUI
		LoadingWindow::get()->setAutotrack(_L("Trying to connect to server ..."));
#endif // USE_MYGUI
		// important note: all new network code is written in order to allow also the old network protocol to further exist.
		// at some point you need to decide with what type of server you communicate below and choose the correct class

		net = new Network(trucks, sname, sport, this);

		bool connres = net->connect();
#ifdef USE_MYGUI
		LoadingWindow::get()->hide();

#ifdef USE_SOCKETW
		new GUI_Multiplayer(net, cam);
		GUI_Multiplayer::getSingleton().update();
#endif //USE_SOCKETW

#endif //USE_MYGUI
		if(!connres)
		{
			LogManager::getSingleton().logMessage("connection failed. server down?");
			showError(_L("Unable to connect to server"), _L("Unable to connect to the server. It is certainly down or you have network problems."));
			//fatal
			exit(1);
		}
		char *terrn = net->getTerrainName();
		if(terrn && !strcmp(terrn, "any"))
			// so show the terrain selection
			preselected_map = "";
		else
			preselected_map = String(terrn);

		// show chat in MP
		NETCHAT.setMode(this, NETCHAT_LEFT_SMALL, true);

		// create person _AFTER_ network, important
		int colourNum = 0;
		if(net->getLocalUserData()) colourNum = net->getLocalUserData()->colournum;
		person = (Character *)CharacterFactory::getSingleton().createLocal(colourNum);

		// network chat stuff
		netChat = ChatSystemFactory::getSingleton().createLocal(colourNum);

	} else
#endif //SOCKETW
	{
		// no network
		person = (Character *)CharacterFactory::getSingleton().createLocal(-1);
	}

	person->setVisible(false);

	// load guy
	int source=-1;
#ifdef USE_SOCKETW
	if(net)
		source = net->getUserID();
#endif //SOCKETW

	// new beam factory
	new BeamFactory(this, trucks, mSceneMgr, mSceneMgr->getRootSceneNode(), mWindow, net, &mapsizex, &mapsizez, collisions, hfinder, w, mCamera, mirror);


	// setup a benchmark if required
	if(setupBenchmark())
		return;

	// now continue to load everything...
	if(preselected_map != "")
	{
		if(!CACHE.checkResourceLoaded(preselected_map))
		{
			LogManager::getSingleton().logMessage("Terrain not found: " + preselected_map);
			showError(_L("Terrain loading error"), _L("Terrain not found: ") + preselected_map);
			exit(123);
		}

		// set the terrain cache entry
		loaded_terrain = CACHE.getResourceInfo(preselected_map);

		loadTerrain(preselected_map);
		//miniature map stuff
		//char ppname[1024];
		//sprintf(ppname, "%s-mini.png", preselected_map);
		//MaterialPtr tmat=(MaterialPtr)(MaterialManager::getSingleton().getByName("tracks/Map"));

		//search if mini picture exists
		//FileInfoListPtr files= ResourceGroupManager::getSingleton().findResourceFileInfo(ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME`, ppname);
		//if ( && !files->empty())
		//{
		//	tmat->getTechnique(0)->getPass(0)->getTextureUnitState(0)->setTextureName(ppname);
		//}
		//else
		//{
		//	tmat->getTechnique(0)->getPass(0)->getTextureUnitState(0)->setTextureName("unknown.png");
		//}

		//load preselected truck
		if(preselected_truck != "")
		{
			loading_state=TERRAIN_LOADED;
			std::vector<String> *tconfig = 0;
			if(!preselected_truckConfig.empty())
			{
				std::vector<String> tconfig2;
				if(!preselected_truckConfig.empty())
					tconfig2.push_back(preselected_truckConfig);
				tconfig = &tconfig2;
			}
			initTrucks(true, preselected_truck.c_str(), "", tconfig, enterTruck);

		} else {
			// no trucks loaded?
			if (truck_preload_num == 0 && !netmode)
			{
#ifdef USE_MYGUI
				// show truck selector
				SelectorWindow::get()->setEnableCancel(false);
				if(w)
				{
					hideMap();
					SelectorWindow::get()->show(SelectorWindow::LT_NetworkWithBoat);
				}
				else
				{
					hideMap();
					SelectorWindow::get()->show(SelectorWindow::LT_Network);
				}
#endif // MYGUI
			} else {
				// init no trucks, as there were found some
				initTrucks(false, preselected_map);
			}
		}
	} else
	{
#ifdef USE_MYGUI
		// show terrain selector
		hideMap();
		//LogManager::getSingleton().logMessage("huette debug 3");
		SelectorWindow::get()->show(SelectorWindow::LT_Terrain);
		SelectorWindow::get()->setEnableCancel(false);
#endif // MYGUI
	}

	// show character
	person->setVisible(true);


	initialized=true;
}

RoRFrameListener::~RoRFrameListener()
{
#ifdef USE_MYGUI
	LoadingWindow::FreeInstance();
	SelectorWindow::FreeInstance();
#endif //MYGUI

//	if (joy) delete (joy);
#ifdef USE_PAGED
	for(std::vector<paged_geometry_t>::iterator it=pagedGeometry.begin(); it!=pagedGeometry.end(); it++)
	{
		if(it->geom)
		{
			delete(it->geom);
			it->geom=0;
		}
		if(it->loader)
		{
			delete((TreeLoader2D *)it->loader);
			it->loader=0;
		}
	}
#endif
#ifdef USE_SOCKETW
	if (net) delete (net);
#endif //SOCKETW
	//we should destroy OIS here
	//we could also try to destroy SoundScriptManager, but we don't care!
	#ifdef USE_MPLATFORM
	if (mplatform)
	{
		if (mplatform->disconnect()) delete(mplatform);
	}
	#endif

}

void RoRFrameListener::exploreScripts()
{
#if USE_ANGELSCRIPT
	FileInfoListPtr files= ResourceGroupManager::getSingleton().findResourceFileInfo("Scripts", "*.rs", false);
	for (FileInfoList::iterator iterFiles = files->begin(); iterFiles!= files->end(); ++iterFiles)
	{
		ScriptEngine::getSingleton().loadScript(iterFiles->filename);
	}
#endif //USE_ANGELSCRIPT
}

void RoRFrameListener::loadNetTerrain(char *preselected_map)
{
	// load preselected map
	char mapname[1024];
	sprintf(mapname, "%s.terrn", preselected_map);
	loadTerrain(mapname);
	//miniature map stuff
	MaterialPtr tmat=(MaterialPtr)(MaterialManager::getSingleton().getByName("tracks/Map"));
	//search if mini picture exists
	char ppname[1024];
	sprintf(ppname, "%s-mini.dds", preselected_map);
	String group="";
	if(group == "")
	{
		sprintf(ppname, "%s-mini.png", preselected_map);
		try
		{
			group = ResourceGroupManager::getSingleton().findGroupContainingResource(ppname);
		}catch(...)
		{
		}
	}
	if(group == "")
		return;
	FileInfoListPtr files= ResourceGroupManager::getSingleton().findResourceFileInfo(group, ppname);
	if (!files->empty())
	{
		tmat->getTechnique(0)->getPass(0)->getTextureUnitState(0)->setTextureName(ppname);
	}
	else
	{
		tmat->getTechnique(0)->getPass(0)->getTextureUnitState(0)->setTextureName("unknown.dds");
	}
}


int RoRFrameListener::setupBenchmark()
{
	String benchmark = SETTINGS.getSetting("Benchmark");
	if(benchmark.empty()) return 0;

	if(benchmark == "simple")
	{
		// very simple benchmark: a simple truck driving
		benchmarking=true;
#ifdef USE_MYGUI
		LoadingWindow::get()->hide();
#endif //MYGUI

		// load a simple terrain
		loadTerrain("simple.terrn");

		// get truck name to test
		int trucknums = 6;
		if(!SETTINGS.getSetting("BenchmarkTrucks").empty())
			trucknums = StringConverter::parseInt(SETTINGS.getSetting("BenchmarkTrucks"));
		String truckname = SETTINGS.getSetting("Preselected Truck");
		if(truckname.empty())
		{
			showError(_L("please specify truck to benchmark"), _L("Benchmark truck not specified"));
			exit(1);
		}

		// load trucks
		float radius = 10;
		for(int i=0;i<trucknums;i++)
		{
			Vector3 pos = Vector3(500,0,250+3.5f*i);
			Ogre::Quaternion dir = Ogre::Quaternion::ZERO;
			Beam *truck = BeamFactory::getSingleton().createLocal(pos, dir, truckname);
			truck->reset();
			radius = truck->getMinimalCameraRadius() * 3.5f;
			setCurrentTruck(truck->trucknum);
		}

		// activate them all
		for(int i=0;i<trucknums;i++)
			trucks[i]->activate();

		// setup the camera
		cameramode=CAMERA_EXT;
		camRotX = Degree(-120);
		camDist = radius;

		// start the simulation
		loading_state=ALL_LOADED;

		// modify the gui
		if(ow)
		{
			ow->truckhud->show(false);
			ow->showDashboardOverlays(false,0);
			ow->showDebugOverlay(1);
		}
		startTimer();

		// return 1 to skip the normal loading
		return 1;
	} else
	{
		// unkown benchmark
		showError(_L("Benchmark loading error"), _L("Benchmark not known: ") + benchmark);
		exit(1);
	}
	return 0;
}

void RoRFrameListener::getMeshInformation(Mesh* mesh,size_t &vertex_count,Vector3* &vertices,
											  size_t &index_count, unsigned* &indices,
											  const Vector3 &position,
											  const Quaternion &orient,const Vector3 &scale)
{
	vertex_count = index_count = 0;

	bool added_shared = false;
	size_t current_offset = vertex_count;
	size_t shared_offset = vertex_count;
	size_t next_offset = vertex_count;
	size_t index_offset = index_count;
	size_t prev_vert = vertex_count;
	size_t prev_ind = index_count;

	// Calculate how many vertices and indices we're going to need
	for(int i = 0;i < mesh->getNumSubMeshes();i++)
	{
		SubMesh* submesh = mesh->getSubMesh(i);

		// We only need to add the shared vertices once
		if(submesh->useSharedVertices)
		{
			if(!added_shared)
			{
				VertexData* vertex_data = mesh->sharedVertexData;
				vertex_count += vertex_data->vertexCount;
				added_shared = true;
			}
		}
		else
		{
			VertexData* vertex_data = submesh->vertexData;
			vertex_count += vertex_data->vertexCount;
		}

		// Add the indices
		Ogre::IndexData* index_data = submesh->indexData;
		index_count += index_data->indexCount;
	}

	// Allocate space for the vertices and indices
	vertices = new Vector3[vertex_count];
	indices = new unsigned[index_count];

	added_shared = false;

	// Run through the submeshes again, adding the data into the arrays
	for(int i = 0;i < mesh->getNumSubMeshes();i++)
	{
		SubMesh* submesh = mesh->getSubMesh(i);

		Ogre::VertexData* vertex_data = submesh->useSharedVertices ? mesh->sharedVertexData : submesh->vertexData;
		if((!submesh->useSharedVertices)||(submesh->useSharedVertices && !added_shared))
		{
			if(submesh->useSharedVertices)
			{
				added_shared = true;
				shared_offset = current_offset;
			}

			const Ogre::VertexElement* posElem = vertex_data->vertexDeclaration->findElementBySemantic(Ogre::VES_POSITION);
			Ogre::HardwareVertexBufferSharedPtr vbuf = vertex_data->vertexBufferBinding->getBuffer(posElem->getSource());
			unsigned char* vertex = static_cast<unsigned char*>(vbuf->lock(Ogre::HardwareBuffer::HBL_READ_ONLY));
			Ogre::Real* pReal;

			for(size_t j = 0; j < vertex_data->vertexCount; ++j, vertex += vbuf->getVertexSize())
			{
				posElem->baseVertexPointerToElement(vertex, &pReal);

				Vector3 pt;

				pt.x = (*pReal++);
				pt.y = (*pReal++);
				pt.z = (*pReal++);

				pt = (orient * (pt * scale)) + position;

				vertices[current_offset + j].x = pt.x;
				vertices[current_offset + j].y = pt.y;
				vertices[current_offset + j].z = pt.z;
			}
			vbuf->unlock();
			next_offset += vertex_data->vertexCount;
		}

		Ogre::IndexData* index_data = submesh->indexData;

		size_t numTris = index_data->indexCount / 3;
		unsigned short* pShort = 0;
		unsigned int* pInt = 0;
		Ogre::HardwareIndexBufferSharedPtr ibuf = index_data->indexBuffer;
		bool use32bitindexes = (ibuf->getType() == Ogre::HardwareIndexBuffer::IT_32BIT);
		if (use32bitindexes) pInt = static_cast<unsigned int*>(ibuf->lock(Ogre::HardwareBuffer::HBL_READ_ONLY));
		else pShort = static_cast<unsigned short*>(ibuf->lock(Ogre::HardwareBuffer::HBL_READ_ONLY));

		for(size_t k = 0; k < numTris; ++k)
		{
			size_t offset = (submesh->useSharedVertices)?shared_offset:current_offset;

			unsigned int vindex = use32bitindexes? *pInt++ : *pShort++;
			indices[index_offset + 0] = vindex + offset;
			vindex = use32bitindexes? *pInt++ : *pShort++;
			indices[index_offset + 1] = vindex + offset;
			vindex = use32bitindexes? *pInt++ : *pShort++;
			indices[index_offset + 2] = vindex + offset;

			index_offset += 3;
		}
		ibuf->unlock();
		current_offset = next_offset;
	}
}

String RoRFrameListener::saveTerrainMesh()
{
	LogManager::getSingleton().logMessage("saving Terrain Mesh to file...");
	ManualObject* mMan = mSceneMgr->createManualObject("Terrain");
	mMan->estimateIndexCount(mapsizex*mapsizez*3);
	mMan->estimateVertexCount(mapsizex*mapsizez*7);
	//mMan->setDynamic(false);
	mMan->begin("TerrainMaterial",RenderOperation::OT_TRIANGLE_LIST);
	int i = 0;
	int step = (mapsizex / 256);
	if(step == 0) step = 1;
	step *= 3;
	LogManager::getSingleton().logMessage("saving with steps: " + StringConverter::toString(step));
	for(int x = 1;x<mapsizex;x+=step)
	{
		for(int z = 1;z<mapsizez;z+=step)
		{
			mMan->index(i);
			mMan->position(Vector3(x-step, hfinder->getHeightAt(x-step, z-step), z-step));
			mMan->position(Vector3(x  , hfinder->getHeightAt(x, z)    , z));
			mMan->position(Vector3(x-step, hfinder->getHeightAt(x-step, z)  , z));
			i++;

			mMan->index(i);
			mMan->position(Vector3(x-step, hfinder->getHeightAt(x-step, z-step), z-step));
			mMan->position(Vector3(x  , hfinder->getHeightAt(x, z-step)  , z-step));
			mMan->position(Vector3(x  , hfinder->getHeightAt(x, z)    , z));
			i++;
		}
		LogManager::getSingleton().logMessage("x: " + StringConverter::toString(x));
	}
	mMan->end();
	Ogre::MeshPtr mMeshPtr = mMan->convertToMesh("TerrainMesh");
	Ogre::Mesh* mMesh = mMeshPtr.getPointer();
	Ogre::MeshSerializer* mMeshSeri = new Ogre::MeshSerializer();
	//String mfilename = mFolder + "/" + mFolder + ".mesh";
	String mfilename = loadedTerrain + ".mesh";
	LogManager::getSingleton().logMessage("saved Terrain Mesh to file:" + mfilename);
	mMeshSeri->exportMesh(mMesh, mfilename);
	mSceneMgr->destroyManualObject(mMan);
	delete mMesh;
	delete mMeshSeri;
	return mfilename;
}

void RoRFrameListener::unloadObject(const char* instancename)
{
	if(loadedObjects.find(std::string(instancename)) == loadedObjects.end())
	{
		LogManager::getSingleton().logMessage("unable to unload object: " + std::string(instancename));
		return;
	}

	// TODO: proper unloading with unloading of the collision things

	Ogre::SceneNode *node = loadedObjects[std::string(instancename)];
	node->detachAllObjects();
	node->setVisible(false);
}

void RoRFrameListener::loadObject(const char* name, float px, float py, float pz, float rx, float ry, float rz, SceneNode * bakeNode, const char* instancename, bool enable_collisions, int luahandler, const char *type, bool uniquifyMaterial)
{
	ScopeLog log("object_"+String(name));
	if(type && !strcmp(type, "grid"))
	{
		// some fast grid object hacks :)
		for(int x=0;x<500;x+=50)
			for(int z=0;z<500;z+=50)
				loadObject(name, px+x, py, pz+z, rx, ry, rz, bakeNode, 0, enable_collisions, luahandler, 0);
		return;
	}

	// nice idea, but too many random hits
	//if(abs(rx+1) < 0.001) rx = Math::RangeRandom(0, 360);
	//if(abs(ry+1) < 0.001) ry = Math::RangeRandom(0, 360);
	//if(abs(rz+1) < 0.001) rz = Math::RangeRandom(0, 360);

	if(strnlen(name, 250)==0)
		return;

	//FILE *fd;
	char fname[1024];
	char oname[1024];
	char mesh[1024];
	char line[1024];
	float scx, scy, scz;
	float lx, hx, ly, hy, lz, hz;
	float srx, sry, srz;
	float drx, dry, drz;
	float fcx, fcy, fcz;
	bool forcecam=false;
	char collmesh[1024];
	Quaternion rotation;
	bool ismovable=false;

	int event_filter = EVENT_ALL;
	rotation=Quaternion(Degree(rx), Vector3::UNIT_X)*Quaternion(Degree(ry), Vector3::UNIT_Y)*Quaternion(Degree(rz), Vector3::UNIT_Z);

	// try to load with UID first!
	String odefgroup = "";
	String odefname = "";
	bool odefFound = false;
	if(terrainUID != "" && !CACHE.stringHasUID(name))
	{
		sprintf(fname,"%s-%s.odef", terrainUID.c_str(), name);
		odefname = String(fname);
		bool exists = ResourceGroupManager::getSingleton().resourceExistsInAnyGroup(odefname);
		if(exists)
		{
			odefgroup = ResourceGroupManager::getSingleton().findGroupContainingResource(odefname);
			odefFound = true;
		}
	}

	if(!odefFound)
	{
		sprintf(fname,"%s.odef", name);
		odefname = String(fname);
		bool exists = ResourceGroupManager::getSingleton().resourceExistsInAnyGroup(odefname);
		if(exists)
		{
			odefgroup = ResourceGroupManager::getSingleton().findGroupContainingResource(odefname);
			odefFound = true;
		}
	}

	//if(!CACHE.checkResourceLoaded(odefname, odefgroup))
	if(!odefFound)
	{
		LogManager::getSingleton().logMessage("Error while loading Terrain: could not find required .odef file: " + odefname + ". Ignoring entry.");
		return;
	}

	DataStreamPtr ds=ResourceGroupManager::getSingleton().openResource(odefname, odefgroup);

	ds->readLine(mesh, 1023);
	if(String(mesh) == "LOD")
	{
		// LOD line is obsolete
		ds->readLine(mesh, 1023);
	}

	//scale
	ds->readLine(line, 1023);
	sscanf(line, "%f, %f, %f",&scx,&scy,&scz);
	sprintf(oname,"object%i(%s)", objcounter,name);
	objcounter++;
	

	SceneNode *tenode = mSceneMgr->getRootSceneNode()->createChildSceneNode();
	MeshObject *mo = new MeshObject(mScene, mesh, oname, tenode);
	//mo->setQueryFlags(OBJECTS_MASK);
	//tenode->attachObject(te);
	tenode->setScale(scx,scy,scz);
	tenode->setPosition(px,py,pz);
	tenode->rotate(rotation);
	tenode->pitch(Degree(-90));
	tenode->setVisible(true);

	// register in map
	loadedObjects[std::string(instancename)] = tenode;


	if(uniquifyMaterial && instancename)
	{
		for(unsigned int i = 0; i < mo->getEntity()->getNumSubEntities(); i++)
		{
			SubEntity *se = mo->getEntity()->getSubEntity(i);
			String matname = se->getMaterialName();
			String newmatname = matname + "/" + String(instancename);
			//LogManager::getSingleton().logMessage("subentity " + StringConverter::toString(i) + ": "+ matname + " -> " + newmatname);
			se->getMaterial()->clone(newmatname);
			se->setMaterialName(newmatname);
		}
	}

	String meshGroup = ResourceGroupManager::getSingleton().findGroupContainingResource(mesh);
	MeshPtr mainMesh = mo->getMesh();

	//collision box(es)
	bool virt=false;
	bool rotating=false;
	bool classic_ref=true;
	// everything is of concrete by default
	ground_model_t *gm = collisions->getGroundModelByString("concrete");
	bool generateLod=false;
	char eventname[256];
	eventname[0]=0;
	bool lodmode=false;
	while (!ds->eof())
	{
		size_t ll=ds->readLine(line, 1023);
		char* ptline=line;
		if (ll==0 || line[0]=='/' || line[0]==';') continue;
		//trim line
		while (*ptline==' ' || *ptline=='\t') ptline++;

		if (!strcmp("end",ptline)) break;
		if (!strcmp("movable", ptline)) {ismovable=true;continue;};
		if (!strcmp("localizer-h", ptline))
		{
			localizers[free_localizer].position=Vector3(px,py,pz);
			localizers[free_localizer].rotation=rotation;
			localizers[free_localizer].type=LOCALIZER_HORIZONTAL;
			free_localizer++;
			continue;
		}
		if (!strcmp("localizer-v", ptline))
		{
			localizers[free_localizer].position=Vector3(px,py,pz);
			localizers[free_localizer].rotation=rotation;
			localizers[free_localizer].type=LOCALIZER_VERTICAL;
			free_localizer++;
			continue;
		}
		if (!strcmp("localizer-ndb", ptline))
		{
			localizers[free_localizer].position=Vector3(px,py,pz);
			localizers[free_localizer].rotation=rotation;
			localizers[free_localizer].type=LOCALIZER_NDB;
			free_localizer++;
			continue;
		}
		if (!strcmp("localizer-vor", ptline))
		{
			localizers[free_localizer].position=Vector3(px,py,pz);
			localizers[free_localizer].rotation=rotation;
			localizers[free_localizer].type=LOCALIZER_VOR;
			free_localizer++;
			continue;
		}
		if (!strcmp("standard", ptline)) {classic_ref=false;tenode->pitch(Degree(90));continue;};
		if (!strcmp("beginbox", ptline) || !strcmp("beginmesh", ptline))
		{
			drx=dry=drz=0.0;
			rotating=false;
			virt=false;
			forcecam=false;
			event_filter=EVENT_NONE;
			eventname[0]=0;
			collmesh[0]=0;
			gm = collisions->getGroundModelByString("concrete");
			continue;
		};
		if (!strncmp("boxcoords", ptline, 9))
		{
			sscanf(ptline, "boxcoords %f, %f, %f, %f, %f, %f",&lx,&hx,&ly,&hy,&lz, &hz);
			continue;
		}
		if (!strncmp("mesh", ptline, 4))
		{
			sscanf(ptline, "mesh %s",collmesh);
			continue;
		}
		if (!strncmp("rotate", ptline, 6))
		{
			sscanf(ptline, "rotate %f, %f, %f",&srx, &sry, &srz);
			rotating=true;
			continue;
		}
		if (!strncmp("forcecamera", ptline, 11))
		{
			sscanf(ptline, "forcecamera %f, %f, %f",&fcx, &fcy, &fcz);
			forcecam=true;
			continue;
		}
		if (!strncmp("direction", ptline, 9))
		{
			sscanf(ptline, "direction %f, %f, %f",&drx, &dry, &drz);
			continue;
		}
		if (!strncmp("frictionconfig", ptline, 14) && strlen(ptline) > 15)
		{
			// load a custom friction config
			collisions->loadGroundModelsConfigFile(String(ptline + 15));
			continue;
		}
		if (!strncmp("stdfriction", ptline, 11) || !strncmp("usefriction", ptline, 11) && strlen(ptline) > 12)
		{
			String modelName = String(ptline + 12);
			gm = collisions->getGroundModelByString(modelName);
			continue;
		}
		if (!strcmp("virtual", ptline)) {virt=true;continue;};
		if (!strncmp("event", ptline, 5))
		{
			char ts[256];
			ts[0]=0;
			sscanf(ptline, "event %s %s",eventname, ts);
			if(!strncmp(ts, "avatar", 6))
				event_filter=EVENT_AVATAR;
			else if(!strncmp(ts, "truck", 5))
				event_filter=EVENT_TRUCK;
			else if(!strncmp(ts, "airplane", 8))
				event_filter=EVENT_AIRPLANE;
			else if(!strncmp(ts, "delete", 8))
				event_filter=EVENT_DELETE;
			continue;
		}
		//resp=sscanf(ptline, "%f, %f, %f, %f, %f, %f, %f, %f, %f, %c",&lx,&hx,&ly, &hy,&lz, &hz, &srx, &sry, &srz,&type);
		if (!strcmp("endbox", ptline))
		{
			if (enable_collisions) collisions->addCollisionBox(tenode, rotating, virt,px,py,pz,rx,ry,rz,lx,hx,ly,hy,lz,hz,srx,sry,srz,eventname, instancename, forcecam, Vector3(fcx, fcy, fcz), scx, scy, scz, drx, dry, drz, event_filter, luahandler);
			continue;
		}
		if (!strcmp("endmesh", ptline))
		{
			// check if this is an event box:
			if((SETTINGS.getSetting("Debug Event Boxes") == "Yes") && virt && event_filter != EVENT_NONE)
			{
				// load mesh, find bounds, add collision box, discard mesh
				Entity *ent = mSceneMgr->createEntity(collmesh);
				AxisAlignedBox bounds = ent->getBoundingBox();

				Vector3 min = bounds.getMinimum();
				Vector3 max = bounds.getMaximum();
				
				// add event box
				collisions->addCollisionBox(tenode, rotating, virt, px,py,pz,rx,ry,rz,min.x,max.x,min.y,max.y,min.z,max.z,srx,sry,srz,eventname, instancename, forcecam, Vector3(fcx, fcy, fcz), scx, scy, scz, drx, dry, drz, event_filter, luahandler);

				if(debugCollisions)
				{
					ent->setMaterialName("tracks/transred");
					SceneNode *colbakenode=mSceneMgr->getRootSceneNode()->createChildSceneNode();
					colbakenode->attachObject(ent);
					colbakenode->setPosition(Vector3(px,py,pz));
					colbakenode->setOrientation(tenode->getOrientation());
					colbakenode->showBoundingBox(true);
				} else
				{
					mSceneMgr->destroyEntity(ent);
				}
				

				

			}
			// normal, non virtual collision box
			Entity *ent = mSceneMgr->createEntity(collmesh);
			ent->setMaterialName("tracks/transred");

			size_t vertex_count,index_count;
			Vector3* vertices;
			unsigned* indices;

			getMeshInformation(ent->getMesh().getPointer(),vertex_count,vertices,index_count,indices, Vector3(px,py,pz), tenode->getOrientation(), Vector3(scx, scy, scz));

			//LogManager::getSingleton().logMessage(LML_NORMAL,"Vertices in mesh: %u",vertex_count);
			//LogManager::getSingleton().logMessage(LML_NORMAL,"Triangles in mesh: %u",index_count / 3);
			for (int i=0; i<(int)index_count/3; i++)
			{
				if (enable_collisions) collisions->addCollisionTri(vertices[indices[i*3]], vertices[indices[i*3+1]], vertices[indices[i*3+2]], gm);
			}

			delete[] vertices;
			delete[] indices;
			if(!debugCollisions)
			{
				mSceneMgr->destroyEntity(ent);
			} else
			{
				SceneNode *colbakenode=mSceneMgr->getRootSceneNode()->createChildSceneNode();
				colbakenode->attachObject(ent);
				colbakenode->setPosition(Vector3(px,py,pz));
				colbakenode->setOrientation(tenode->getOrientation());
			}

			continue;
		}
		if (!strncmp("setMeshMaterial", ptline, 15))
		{
			char mat[255]="";
			sscanf(ptline, "setMeshMaterial %s", mat);
			if(mo->getEntity() && strnlen(mat,250)>0)
			{
				mo->getEntity()->setMaterialName(String(mat));
				// load it
				//MaterialManager::getSingleton().load(String(mat), ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
			}
			continue;
		}
		if (!strncmp("playanimation", ptline, 13))
		{
			char animname[255]="";
			float speedfactorMin = 0, speedfactorMax = 0;
			sscanf(ptline, "playanimation %f, %f, %s", &speedfactorMin, &speedfactorMax, animname);
			if(tenode && mo->getEntity() && strnlen(animname,250)>0)
			{
				AnimationStateSet *s = mo->getEntity()->getAllAnimationStates();
				if(!s->hasAnimationState(String(animname)))
				{
					LogManager::getSingleton().logMessage("ODEF: animation '" + String(animname) + "' for mesh: '" + String(mesh) + "' in odef file '" + String(name) + ".odef' not found!");
					continue;
				}
				animated_object_t ao;
				ao.node = tenode;
				ao.ent = mo->getEntity();
				ao.speedfactor = speedfactorMin;
				if(speedfactorMin != speedfactorMax)
					ao.speedfactor = Math::RangeRandom(speedfactorMin, speedfactorMax);
				ao.anim = 0;
				try
				{
					ao.anim = mo->getEntity()->getAnimationState(String(animname));
				} catch (...)
				{
					ao.anim = 0;
				}
				if(!ao.anim)
				{
					LogManager::getSingleton().logMessage("ODEF: animation '" + String(animname) + "' for mesh: '" + String(mesh) + "' in odef file '" + String(name) + ".odef' not found!");
					continue;
				}
				ao.anim->setEnabled(true);
				animatedObjects.push_back(ao);
			}
			continue;
		}
		if (!strncmp("drawTextOnMeshTexture", ptline, 21))
		{
			if(!mo->getEntity())
				continue;
			String matName = mo->getEntity()->getSubEntity(0)->getMaterialName();
			MaterialPtr m = MaterialManager::getSingleton().getByName(matName);
			if(m.getPointer() == 0)
			{
				LogManager::getSingleton().logMessage("ODEF: problem with drawTextOnMeshTexture command: mesh material not found: "+String(fname)+" : "+String(ptline));
				continue;
			}
			String texName = m->getTechnique(0)->getPass(0)->getTextureUnitState(0)->getTextureName();
			Texture* background = (Texture *)TextureManager::getSingleton().getByName(texName).getPointer();
			if(!background)
			{
				LogManager::getSingleton().logMessage("ODEF: problem with drawTextOnMeshTexture command: mesh texture not found: "+String(fname)+" : "+String(ptline));
				continue;
			}

			static int textureNumber = 0;
			textureNumber++;
			char tmpTextName[255]="", tmpMatName[255]="";
			sprintf(tmpTextName, "TextOnTexture_%d_Texture", textureNumber);
			sprintf(tmpMatName, "TextOnTexture_%d_Material", textureNumber);			// Make sure the texture is not WRITE_ONLY, we need to read the buffer to do the blending with the font (get the alpha for example)
			TexturePtr texture = TextureManager::getSingleton().createManual(tmpTextName, ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME, TEX_TYPE_2D, (Ogre::uint)background->getWidth(), (Ogre::uint)background->getHeight(), MIP_UNLIMITED , PF_X8R8G8B8, Ogre::TU_STATIC|Ogre::TU_AUTOMIPMAP, new ResourceBuffer());
			if(texture.getPointer() == 0)
			{
				LogManager::getSingleton().logMessage("ODEF: problem with drawTextOnMeshTexture command: could not create texture: "+String(fname)+" : "+String(ptline));
				continue;
			}

			float x=0, y=0, w=0, h=0;
			float a=0, r=0, g=0, b=0;
			char fontname[255]="";
			char text[255]="";
			char option='l';
			int res = sscanf(ptline, "drawTextOnMeshTexture %f, %f, %f, %f, %f, %f, %f, %f, %c, %s %s", &x, &y, &w, &h, &r, &g, &b, &a, &option, fontname, text);
			if(res < 11)
			{
				LogManager::getSingleton().logMessage("ODEF: problem with drawTextOnMeshTexture command: "+String(fname)+" : "+String(ptline));
				continue;
			}

			// cehck if we got a template argument
			if(!strncmp(text, "{{argument1}}", 13))
				strncpy(text, instancename, 250);

			// replace '_' with ' '
			char *text_pointer = text;
			while (*text_pointer!=0) {if (*text_pointer=='_') *text_pointer=' ';text_pointer++;};

			Font* font = (Font *)FontManager::getSingleton().getByName(String(fontname)).getPointer();
			if(!font)
			{
				LogManager::getSingleton().logMessage("ODEF: problem with drawTextOnMeshTexture command: font not found: "+String(fname)+" : "+String(ptline));
				continue;
			}


			//Draw the background to the new texture
			texture->getBuffer()->blit(background->getBuffer());

			x = background->getWidth() * x;
			y = background->getHeight() * y;
			w = background->getWidth() * w;
			h = background->getHeight() * h;

			Image::Box box = Image::Box((size_t)x, (size_t)y, (size_t)(x+w), (size_t)(y+h));
			WriteToTexture(String(text), texture, box, font, ColourValue(r, g, b, a), option);

			// we can save it to disc for debug purposes:
			//SaveImage(texture, "test.png");

			m->clone(tmpMatName);
			MaterialPtr mNew = MaterialManager::getSingleton().getByName(tmpMatName);
			mNew->getTechnique(0)->getPass(0)->getTextureUnitState(0)->setTextureName(tmpTextName);

			mo->getEntity()->setMaterialName(String(tmpMatName));
			continue;
		}

		LogManager::getSingleton().logMessage("ODEF: unknown command in "+String(fname)+" : "+String(ptline));
	}

	//add icons if type is set
#ifdef USE_MYGUI
	String typestr = "";
	if(type && bigMap)
	{
		typestr = String(type);
		// hack for raceways
		if (!strcmp(name, "chp-checkpoint"))
			typestr = "checkpoint";
		if (!strcmp(name, "chp-start"))
			typestr = "racestart";
		if (!strncmp(name, "road", 4))
			typestr = "road";

		if(typestr != String("") && typestr != String("road") && typestr != String("sign"))
		{
			MapEntity *e = bigMap->createMapEntity(typestr);
			if(e)
			{
				e->setVisibility(true);
				e->setPosition(px, pz);
				e->setRotation(ry);

				if(String(name) != String(""))
					e->setDescription(String(instancename));
			}
		}
	}
#endif // MYGUI
}

void RoRFrameListener::repairTruck(char* inst, char* box)
{
	//find the right truck (the one in the box)
	int t;
	int rtruck=-1;
	for (t=0; t<free_truck; t++)
	{
		if(!trucks[t]) continue;
		if (collisions->isInside(trucks[t]->nodes[0].AbsPosition, inst, box))
		{
			//we found one
			if (rtruck==-1) rtruck=t;
			else rtruck=-2; //too much trucks!
		}
	}
	if (rtruck>=0)
	{
		//take a position reference
#ifdef USE_OPENAL
		if(ssm) ssm->trigOnce(rtruck, SS_TRIG_REPAIR);
#endif //OPENAL
		Vector3 ipos=trucks[rtruck]->nodes[0].AbsPosition;
		trucks[rtruck]->reset();
		trucks[rtruck]->resetPosition(ipos.x, ipos.z, false);
		trucks[rtruck]->updateVisual();
	}
}

void RoRFrameListener::removeTruck(char* inst, char* box)
{
	//find the right truck (the one in the box)
	int t;
	int rtruck=-1;
	for (t=0; t<free_truck; t++)
	{
		if(!trucks[t]) continue;
		if (collisions->isInside(trucks[t]->nodes[0].AbsPosition, inst, box))
		{
			//we found one
			if (rtruck==-1) rtruck=t;
			else rtruck=-2; //too much trucks!
		}
	}
	if (rtruck>=0)
	{
		// remove it
		removeTruck(rtruck);
	}
}


bool RoRFrameListener::benchmarkStep(float dt)
{
	// accelerate the truck a bit
	//if(current_truck != -1 && trucks[current_truck] && trucks[current_truck]->engine)
	for (int i=0; i<free_truck; i++)
	{
		if(!trucks[i]) continue;
		trucks[i]->engine->autoSetAcc(0.5f);

	}

#if 0
	if(rtime > 10.0f && rtime < 15.0f)
		trucks[current_truck]->brake = 1;

	// toggle parking brake around 20 and 25 sec
	if(fabs(20.0f - rtime) < 0.1f)
		trucks[current_truck]->parkingbrake=1;

	if(fabs(22.0f - rtime) < 0.1f)
		trucks[current_truck]->parkingbrake=0;
#endif //0

	// end the benchmark after some time
	if(rtime > 30.0f)
	{
		Vector3 pos = trucks[current_truck]->nodes[0].AbsPosition;
		LogManager::getSingleton().logMessage("Benchmark final Position: " + StringConverter::toString(pos));

		String finalpos_str = SETTINGS.getSetting("BenchmarkFinalPosition");
		String finalpos_error_str = SETTINGS.getSetting("BenchmarkFinalPositionError");
		if(!finalpos_str.empty() && !finalpos_error_str.empty())
		{
			// check if we are at the wished position
			Real finalpos_error = StringConverter::parseReal(finalpos_error_str);
			Vector3 finalPos = StringConverter::parseVector3(finalpos_str);
			LogManager::getSingleton().logMessage("Benchmark target Position: " + StringConverter::toString(finalPos));
			Real targetDistance = fabs(pos.distance(finalPos));
			LogManager::getSingleton().logMessage("Benchmark target distance: " + StringConverter::toString(targetDistance));
			LogManager::getSingleton().logMessage("Benchmark error allowance: " + StringConverter::toString(finalpos_error));

			if(targetDistance < finalpos_error)
			{
				LogManager::getSingleton().logMessage("Benchmark succeeding, inside of error radius");
				exit(0);
			} else
			{
				LogManager::getSingleton().logMessage("Benchmark failing, out of allowance error radius");
				exit(1);
			}
		} else
		{
			// exit gracefully
			exit(0);
		}
	}

	// rotate camera slowly
	//camRotX += Degree(-0.03f);

	// update timer
	updateRacingGUI();

	return true;
}

bool RoRFrameListener::updateEvents(float dt)
{
	if (dt==0.0f) return true;

	// when in benchmark mode, do not process user events, rather execute some hardcoded actions
	if(benchmarking)
		return benchmarkStep(dt);

	INPUTENGINE.updateKeyBounces(dt);
	if(!INPUTENGINE.getInputsChanged()) return true;

	bool dirty = false;
	//update joystick readings
	//	joy->UpdateInputState();

	//stick shift general uglyness
	/*
	// no more stickshift, commented out when upgrading to the inputengine
	if (loading_state==ALL_LOADED && current_truck!=-1 && trucks[current_truck]->driveable==TRUCK && trucks[current_truck]->engine->getAutoMode()==MANUAL)
	{
		int gb;
		gb=joy->updateStickShift(true, trucks[current_truck]->engine->getClutch());
		// TODO: FIXME
		//if (gb!=-1) trucks[current_truck]->engine->setGear(gb);
	}
	else joy->updateStickShift(false, 0.0);
	*/

	// update overlays if enabled
	if(ow) ow->update(dt);

#ifdef USE_MYGUI
	if(GUI_Friction::getSingleton().getVisible() && current_truck >= 0 && trucks[current_truck])
	{
		// friction GUI active
		ground_model_t *gm = trucks[current_truck]->getLastFuzzyGroundModel();
		if(gm)
			GUI_Friction::getSingleton().setActiveCol(gm);
	}
#endif // MYGUI

	if (NETCHAT.getVisible() && INPUTENGINE.getEventBoolValueBounce(EV_COMMON_ENTER_CHATMODE, 0.5f) && !chatting && !hidegui)
	{
		// enter chat mode
		INPUTENGINE.resetKeyLine();
		INPUTENGINE.setRecordInput(true);
		NETCHAT.setEnterText("", true, true);
		chatting=true;
	}

	if (NETCHAT.getVisible() && INPUTENGINE.getEventBoolValueBounce(EV_COMMON_SEND_CHAT, 0.5f) && chatting && !hidegui)
	{
		processConsoleInput();
		NETCHAT.setEnterText("", false);
		chatting=false;
		INPUTENGINE.setRecordInput(false);
		INPUTENGINE.resetKeyLine();
		mTimeUntilNextToggle = 0.5; // for enter/exit truck
		return true;
	}

	// no event handling during chatting!
	if(chatting)
		return true;

#ifdef USE_MYGUI
	if(INPUTENGINE.getEventBoolValueBounce(EV_COMMON_SHOW_MENU))
	{
		bool newvalue = !GUI_MainMenu::getSingleton().getVisible();
		GUI_MainMenu::getSingleton().setVisible(newvalue);
		GUI_Friction::getSingleton().setShaded(newvalue);
	}
#endif //MYGUI

	if(INPUTENGINE.getEventBoolValueBounce(EV_COMMON_QUIT_GAME))
	{
		{
			if(!showcredits)
				shutdown_pre();
			else
				shutdown_final();
		}
	}
#ifdef USE_MYGUI
	if(GUI_MainMenu::getSingleton().getVisible()) return true; // disable input events in menu mode
#endif // MYGUI



	if (INPUTENGINE.getEventBoolValueBounce(EV_DOF_TOGGLE, 0.5f) && mDOF)
	{
		bool enabled = !mDOF->getEnabled();
		if(!enabled && mDOFDebug)
		{
			// turn off debug if on
			mDOFDebug = false;
			mDOF->setDebugEnabled(mDOFDebug);
		}
		mDOF->setEnabled(enabled);
	}
	if (INPUTENGINE.getEventBoolValueBounce(EV_DOF_DEBUG, 0.5f) && mDOF)
	{
		mDOFDebug = !mDOFDebug;
		mDOF->setDebugEnabled(mDOFDebug);
	}
	
	if (INPUTENGINE.getEventBoolValueBounce(EV_TOGGLESHADERS, 0.5f))
	{
		if(shaderSchemeMode)
		{
			shaderSchemeMode=0;
			mCamera->getViewport()->setMaterialScheme(MaterialManager::DEFAULT_SCHEME_NAME);
			LogManager::getSingleton().logMessage("shaders disabled");
			if(ow) ow->flashMessage("shaders disabled");
		} else
		{
			shaderSchemeMode=1;
			mCamera->getViewport()->setMaterialScheme(RTShader::ShaderGenerator::DEFAULT_SCHEME_NAME);
			LogManager::getSingleton().logMessage("shaders enabled");
			if(ow) ow->flashMessage("shaders enabled");
		}
	}

	if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_SCREENSHOT_BIG, 0.5f))
	{
		// hide flash messages
		if(ow) ow->hideFlashMessage();

		int mNumScreenShots=0;
		String path = SETTINGS.getSetting("User Path");
		String tmp = path + String("screenshot_big_") + StringConverter::toString(++mNumScreenShots) + String(".") + String(screenshotformat);
		while(fileExists(tmp.c_str()))
			tmp = path + String("screenshot_big_") + StringConverter::toString(++mNumScreenShots) + String(".") + String(screenshotformat);

		tmp = String("screenshot_big_") + StringConverter::toString(++mNumScreenShots);

		hideGUI(true);

		gridScreenshots(mWindow, mCamera, 6, path, tmp, "."+String(screenshotformat), true);

		hideGUI(false);

		LogManager::getSingleton().logMessage("Wrote big screenshot : " + tmp);
		if(ow) ow->flashMessage(String("Wrote big screenshot : ") + tmp);

	} else if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_SCREENSHOT, 0.5f))
	{
		int mNumScreenShots=0;
		String tmp = SETTINGS.getSetting("User Path") + String("screenshot_") + StringConverter::toString(++mNumScreenShots) + String(".") + String(screenshotformat);
		while(fileExists(tmp.c_str()))
			tmp = SETTINGS.getSetting("User Path") + String("screenshot_") + StringConverter::toString(++mNumScreenShots) + String(".") + String(screenshotformat);

		LogManager::getSingleton().logMessage("Wrote screenshot : " + tmp);
		// hide any flash message
		if(ow) ow->hideFlashMessage();

		mWindow->update();

		mWindow->writeContentsToFile(tmp);
		char tmp1[255];
		String ssmsg = _L("wrote screenshot:");
		sprintf(tmp1, "%s %d", ssmsg.c_str(), mNumScreenShots);
		if(ow) ow->flashMessage(tmp1);
	}

	if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCKEDIT_RELOAD, 0.5f) && current_truck != -1 && trucks[current_truck])
	{
		if(current_truck + 1 >= MAX_TRUCKS)
		{
			if(ow) ow->flashMessage(String("unable to load new truck: limit reached. Please restart RoR"), 30);
			return true;
		}

		// store camera settings
		Radian camRotX_saved = camRotX;
		Radian camRotY_saved = camRotY;

		// store current trucks node positions
		Beam *beam = trucks[current_truck];
		Vector3 *nodeStorage = (Vector3 *)malloc(sizeof(Vector3) * beam->free_node + 10);

		// remove the old truck
		beam->state=RECYCLE;

		// load the same truck again
		Beam *newBeam = BeamFactory::getSingleton().createLocal(reload_pos, reload_dir, beam->realtruckfilename);

		// enter the new truck
		setCurrentTruck(newBeam->trucknum);

		// copy over the most basic info
		if(beam->free_node == newBeam->free_node)
		{
			for(int i=0;i<beam->free_node;i++)
			{
				// copy over nodes attributes if the amount of them didnt change
				newBeam->nodes[i].AbsPosition = beam->nodes[i].AbsPosition;
				newBeam->nodes[i].RelPosition = beam->nodes[i].RelPosition;
				newBeam->nodes[i].Velocity    = beam->nodes[i].Velocity;
				newBeam->nodes[i].Forces      = beam->nodes[i].Forces;
				newBeam->nodes[i].iPosition   = beam->nodes[i].iPosition;
				newBeam->nodes[i].smoothpos   = beam->nodes[i].smoothpos;
			}
		}

		// TODO:
		// * copy over the engine infomation
		// * commands status
		// * other minor stati

		// notice the user about the amount of possible reloads
		String msg = StringConverter::toString(newBeam->trucknum) + String(" of ") + StringConverter::toString(MAX_TRUCKS) + String(" possible reloads.");
		if(ow) ow->flashMessage(msg, 10.0f);

		// dislocate the old truck, so its out of sight
		beam->resetPosition(100000, 100000, false, 100000);
		// note: in some point in the future we would delete the truck here,
		// but since this function is buggy we dont do it yet.


		// restore camera position
		camRotX = camRotX_saved;
		camRotY = camRotY_saved;

		return true;
	}

	// special keys for the debug mode
	if(mDOF && mDOFDebug)
	{
		if(INPUTENGINE.getEventBoolValueBounce(EV_DOF_DEBUG_TOGGLE_FOCUS_MODE, 1.0f))
			mDOF->toggleFocusMode();

		// zoom
		if(INPUTENGINE.getEventBoolValue(EV_DOF_DEBUG_ZOOM_IN))
			mDOF->zoomView(-dt);
		else if(INPUTENGINE.getEventBoolValue(EV_DOF_DEBUG_ZOOM_OUT))
			mDOF->zoomView(dt);

		// aperture
		if(INPUTENGINE.getEventBoolValue(EV_DOF_DEBUG_APERTURE_MORE))
			mDOF->setAperture(-5*dt);
		else if(INPUTENGINE.getEventBoolValue(EV_DOF_DEBUG_APERTURE_LESS))
			mDOF->setAperture(5*dt);

		// focus
		const OIS::MouseState mstate = INPUTENGINE.getMouseState();
		Real offset = 0.05f * mstate.Z.rel;
		if(INPUTENGINE.getEventBoolValue(EV_DOF_DEBUG_FOCUS_IN))
			offset -= 120.0 * dt;
		else if(INPUTENGINE.getEventBoolValue(EV_DOF_DEBUG_FOCUS_OUT))
			offset += 120.0 * dt;
		mDOF->moveFocus(offset);

		// if in DOF debug, we wont process any other events
		return true;
	}
/* -- disabled for now ... why we should check for this if it does not call anything?
   -- enable this again when truckToolGUI is available again

	if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_SHOWTRUCKTOOL, 0.5f) && current_truck != -1)
	{
		//if(truckToolGUI)
		//	truckToolGUI->show();
	}
*/
	if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_RELOAD_ROADS, 0.5f))
	{
		if(proceduralManager)
		{
			//proceduralManager->deleteAllObjects();
			proceduralManager->updateAllObjects();
		}
	}

	if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_SAVE_TERRAIN, 0.5f))
	{
		if(ow) ow->flashMessage("saving terrain, please wait...");
		mWindow->update();
		String fn = saveTerrainMesh();
		if(ow) ow->flashMessage("terrain saved to file: " + fn);
	}

	// position storage
	if(enablePosStor && current_truck != -1)
	{
		int res = -10, slot=-1;
		if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_SAVE_POS1, 0.5f)) { slot=0; res = trucks[current_truck]->savePosition(slot); };
		if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_SAVE_POS2, 0.5f)) { slot=1; res = trucks[current_truck]->savePosition(slot); };
		if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_SAVE_POS3, 0.5f)) { slot=2; res = trucks[current_truck]->savePosition(slot); };
		if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_SAVE_POS4, 0.5f)) { slot=3; res = trucks[current_truck]->savePosition(slot); };
		if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_SAVE_POS5, 0.5f)) { slot=4; res = trucks[current_truck]->savePosition(slot); };
		if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_SAVE_POS6, 0.5f)) { slot=5; res = trucks[current_truck]->savePosition(slot); };
		if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_SAVE_POS7, 0.5f)) { slot=6; res = trucks[current_truck]->savePosition(slot); };
		if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_SAVE_POS8, 0.5f)) { slot=7; res = trucks[current_truck]->savePosition(slot); };
		if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_SAVE_POS9, 0.5f)) { slot=8; res = trucks[current_truck]->savePosition(slot); };
		if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_SAVE_POS10, 0.5f)) { slot=9; res = trucks[current_truck]->savePosition(slot); };
		if(slot != -1 && !res)
			if(ow) ow->flashMessage("Position saved under slot " + StringConverter::toString(slot+1), 3);
		else if(slot != -1 && res)
			if(ow) ow->flashMessage("Error while saving position saved under slot " + StringConverter::toString(slot+1)+" : "+StringConverter::toString(res), 3);

		if(res == -10)
		{
			if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_LOAD_POS1, 0.5f)) { slot=0; res = trucks[current_truck]->loadPosition(slot); };
			if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_LOAD_POS2, 0.5f)) { slot=1; res = trucks[current_truck]->loadPosition(slot); };
			if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_LOAD_POS3, 0.5f)) { slot=2; res = trucks[current_truck]->loadPosition(slot); };
			if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_LOAD_POS4, 0.5f)) { slot=3; res = trucks[current_truck]->loadPosition(slot); };
			if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_LOAD_POS5, 0.5f)) { slot=4; res = trucks[current_truck]->loadPosition(slot); };
			if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_LOAD_POS6, 0.5f)) { slot=5; res = trucks[current_truck]->loadPosition(slot); };
			if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_LOAD_POS7, 0.5f)) { slot=6; res = trucks[current_truck]->loadPosition(slot); };
			if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_LOAD_POS8, 0.5f)) { slot=7; res = trucks[current_truck]->loadPosition(slot); };
			if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_LOAD_POS9, 0.5f)) { slot=8; res = trucks[current_truck]->loadPosition(slot); };
			if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_LOAD_POS10, 0.5f)) { slot=9; res = trucks[current_truck]->loadPosition(slot); };
			if(slot != -1 && res==0)
				if(ow) ow->flashMessage("Loaded position from slot " + StringConverter::toString(slot+1), 3);
			else if(slot != -1 && res!=0)
				if(ow) ow->flashMessage("Could not load position from slot " + StringConverter::toString(slot+1) + "", 3);
		}
	}

	// camera FOV settings
	if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_FOV_LESS))
	{
		int fov = mCamera->getFOVy().valueDegrees();
		if(fov>10)
			fov -= 2;
		mCamera->setFOVy(Degree(fov));
		if(ow) ow->flashMessage(_L("FOV: ") + StringConverter::toString(fov));
	}

	if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_FOV_MORE))
	{
		int fov = mCamera->getFOVy().valueDegrees();
		if(fov<160)
			fov += 2;
		mCamera->setFOVy(Degree(fov));
		if(ow) ow->flashMessage(_L("FOV: ") + StringConverter::toString(fov));
	}

	// full screen/windowed screen switching
	if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_FULLSCREEN_TOGGLE, 2.0f))
	{
		static int org_width = -1, org_height = -1;
		int width = mWindow->getWidth();
		int height = mWindow->getHeight();
		if(org_width == -1)
			org_width = width;
		if(org_height == -1)
			org_height = height;
		bool mode = mWindow->isFullScreen();
		if(!mode)
		{
			mWindow->setFullscreen(true, org_width, org_height);
			LogManager::getSingleton().logMessage(" ** switched to fullscreen: "+StringConverter::toString(width)+"x"+StringConverter::toString(height));
		} else
		{
			mWindow->setFullscreen(false, 640, 480);
			mWindow->setFullscreen(false, org_width, org_height);
			LogManager::getSingleton().logMessage(" ** switched to windowed mode: ");
		}
	}

	if (INPUTENGINE.getEventBoolValueBounce(EV_CAMERA_FREE_MODE_FIX))
	{
		if(cameramode == CAMERA_FREE)
		{
			// change to fixed free camera: that is working like fixed cam
			cameramode = CAMERA_FREE_FIXED;
			LogManager::getSingleton().logMessage("switching to fixed free camera mode");
			if(ow) ow->flashMessage(_L("fixed free camera"));
		} else if(cameramode == CAMERA_FREE_FIXED)
		{
			cameramode = CAMERA_FREE;
			LogManager::getSingleton().logMessage("switching to free camera mode from fixed mode");
			if(ow) ow->flashMessage(_L("free camera"));
		}
	}

	if (INPUTENGINE.getEventBoolValueBounce(EV_CAMERA_FREE_MODE))
	{
		static int storedcameramode = -1;
		if(cameramode == CAMERA_FREE || cameramode == CAMERA_FREE_FIXED)
		{
			// change back to normal camera
			cameramode = storedcameramode;
			LogManager::getSingleton().logMessage("exiting free camera mode");
			if(ow) ow->flashMessage(_L("normal camera"));
		} else if(cameramode != CAMERA_FREE && cameramode != CAMERA_FREE_FIXED )
		{
			// enter free camera mode
			storedcameramode = cameramode;
			cameramode = CAMERA_FREE;
			LogManager::getSingleton().logMessage("entering free camera mode");
			if(ow) ow->flashMessage(_L("free camera"));
		}
	}

	if (loading_state==ALL_LOADED)
	{
		if(net)
		{
			CharacterFactory::getSingleton().updateCharacters(dt);
		} else if (!net && cameramode != CAMERA_FREE)
		{
				// do not move the person in free camera mode
				person->update(dt);
		}

		bool enablegrab = true;
		if (cameramode != CAMERA_FREE)
		{
			//GUIManager::getSingleton().setCursorPosition(mouseX, mouseY);
			if (current_truck==-1)
			{
				if(person)
				{
					person->setPhysicsEnabled(true);
				}
				//camera mode
				if (INPUTENGINE.getEventBoolValueBounce(EV_CAMERA_CHANGE) && cameramode != CAMERA_FREE && cameramode != CAMERA_FREE_FIXED)
				{
					if (cameramode==CAMERA_INT)
					{
						//end of internal cam
						camRotX=pushcamRotX;
						camRotY=pushcamRotY;
					}
					cameramode++;
					if (cameramode==CAMERA_INT)
					{
						//start of internal cam
						pushcamRotX=camRotX;
						pushcamRotY=camRotY;
						camRotX=0;
						camRotY=DEFAULT_INTERNAL_CAM_PITCH;
					}
					if (cameramode==CAMERA_END) cameramode=0;
				}
			}
			else //we are in a vehicle
			{
				//the mouse stuff
				const OIS::MouseState mstate = INPUTENGINE.getMouseState();
				static bool buttonsPressed = false;
				int click=-1;
				// click = -1 = nothing clicked
				// click = 0 left click (windows)
				// click = 1 right click (linux)

				// do not move the mouse while rotating the view
				static int oldstate = 0;
				// oldstate = 0 : dragging view to rotate
				// oldstate = 1 : moving mouse
				// oldstate = 2 : picking node
				//LogManager::getSingleton().logMessage("oldstate="+StringConverter::toString(oldstate));

				// this is a workaround to bea able to release mouse buttons in the dynamic mode
				buttonsPressed = (mstate.buttons > 0);

				if(inputGrabMode == GRAB_DYNAMICALLY)
				{
					// we do not use this anymore, as we can set the mouse's position instead of grabbing it
					//INPUTENGINE.grabMouse(buttonsPressed);

					// Hide the mouse if we press any mouse buttons of if we are in mouse mode
					INPUTENGINE.hideMouse((buttonsPressed||(oldstate==1)));

					// if we are rotating, fix the mouse cursor
					if(oldstate == 0)
						INPUTENGINE.setMousePosition(mouseX, mouseY);
				}

				//if(inputGrabMode == GRAB_ALL || (inputGrabMode == GRAB_DYNAMICALLY &&  (mstate.buttons != 0 || buttonsPressed)))

				if(!mstate.buttonDown((switchMouseButtons?(OIS::MB_Left):(OIS::MB_Right))))
				{
					if(oldstate != 1)
					{
						if(ow) ow->mouseOverlay->getChild("mouse/pointer")->setMaterialName("mouse");
						oldstate = 1;
					}

					if(inputGrabMode == GRAB_DYNAMICALLY)
					{
						// using absolute positions!
						mouseX=mstate.X.abs;
						mouseY=mstate.Y.abs;
					} else
					{
						mouseX+=mstate.X.rel;
						mouseY+=mstate.Y.rel;
					}
					if (mouseX<0) mouseX=0;
					if (mouseX>screenWidth-1) mouseX=screenWidth-1;
					if (mouseY<0) mouseY=0;
					if (mouseY>screenHeight-1) mouseY=screenHeight-1;

					// set the final position of the ingame cursor
					if(ow) ow->mouseElement->setPosition(mouseX, mouseY);

					//action
					if(switchMouseButtons)
					{
						if (mstate.buttonDown(OIS::MB_Right)) click=0;
						if (mstate.buttonDown(OIS::MB_Left)) click=1;
					} else
					{
						if (mstate.buttonDown(OIS::MB_Left)) click=0;
						if (mstate.buttonDown(OIS::MB_Right)) click=1;
					}

				}else {
					if(oldstate != 0)
					{
						if(ow) ow->mouseOverlay->getChild("mouse/pointer")->setMaterialName("mouse-rotate");
						oldstate = 0;
					}
				}


				// get commands
				int i;
// -- maxbe here we should define a maximum numbers per trucks. Some trucks does not have that much commands
// -- available, so why should we iterate till MAX_COMMANDS?
				for (i=1; i<=MAX_COMMANDS; i++)
				{
					trucks[current_truck]->commandkey[i].commandValue=0;
					int eventID = EV_COMMANDS_01 + (i - 1);
					float tmp = INPUTENGINE.getEventValue(eventID);
					if(tmp > 0.0)
						trucks[current_truck]->commandkey[i].commandValue = tmp;
				}

				// replay mode
				if (trucks[current_truck]->replaymode)
				{
					if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_REPLAY_FORWARD, 0.1f) && trucks[current_truck]->replaypos<=0)
					{
						trucks[current_truck]->replaypos++;
					}
					if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_REPLAY_BACKWARD, 0.1f) && trucks[current_truck]->replaypos > -trucks[current_truck]->replaylen)
					{
						trucks[current_truck]->replaypos--;
					}
					if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_REPLAY_FAST_FORWARD, 0.1f) && trucks[current_truck]->replaypos+10<=0)
					{
						trucks[current_truck]->replaypos+=10;
					}
					if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_REPLAY_FAST_BACKWARD, 0.1f) && trucks[current_truck]->replaypos-10 > -trucks[current_truck]->replaylen)
					{
						trucks[current_truck]->replaypos-=10;
					}

					if(INPUTENGINE.isKeyDown(OIS::KC_LMENU))
						trucks[current_truck]->replaypos += mstate.X.rel;

				}

				if (trucks[current_truck]->driveable==TRUCK)
				{
					//road construction stuff
					if (INPUTENGINE.getEventBoolValueBounce(EV_TERRAINEDITOR_SELECTROAD, 0.5f) && trucks[current_truck]->editorId>=0 && !trucks[current_truck]->replaymode)
					{
						if (road)
						{
							road->reset(trucks[current_truck]->nodes[trucks[current_truck]->editorId].AbsPosition);
						}
						else
							road=new Road(mSceneMgr, trucks[current_truck]->nodes[trucks[current_truck]->editorId].AbsPosition);
					}

					//editor stuff
					if (INPUTENGINE.getEventBoolValueBounce(EV_TERRAINEDITOR_TOGGLEOBJECT) && trucks[current_truck]->editorId>=0 && !trucks[current_truck]->replaymode)
					{
						if (editor)
						{
							editor->toggleType();
						}
						else
							editor=new Editor(mSceneMgr, this);
					}

					//this should not be there
					if (editor && trucks[current_truck]->editorId>=0) editor->setPos(trucks[current_truck]->nodes[trucks[current_truck]->editorId].AbsPosition);

					if (!trucks[current_truck]->replaymode)
						{
							if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_LEFT_MIRROR_LEFT))
								trucks[current_truck]->leftMirrorAngle-=0.001;

							if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_LEFT_MIRROR_RIGHT))
								trucks[current_truck]->leftMirrorAngle+=0.001;

							if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_RIGHT_MIRROR_LEFT))
								trucks[current_truck]->rightMirrorAngle-=0.001;

							if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_RIGHT_MIRROR_RIGHT))
								trucks[current_truck]->rightMirrorAngle+=0.001;

							if (INPUTENGINE.getEventBoolValueBounce(EV_TERRAINEDITOR_ROTATELEFT, 0.1f))
								{
									float value = 0.5;
									if(INPUTENGINE.isKeyDown(OIS::KC_LSHIFT) || INPUTENGINE.isKeyDown(OIS::KC_RSHIFT)) value = 4;
									if (road) {road->dturn(+value);}
									else if (editor) {editor->dturn(+1);}
								}

							if (INPUTENGINE.getEventBoolValueBounce(EV_TERRAINEDITOR_ROTATERIGHT, 0.1f))
								{
									float value = 0.5;
									if(INPUTENGINE.isKeyDown(OIS::KC_LSHIFT) || INPUTENGINE.isKeyDown(OIS::KC_RSHIFT)) value = 4;
									if (road) {road->dturn(-value);}
									else if (editor) {editor->dturn(-1);}
								}

							if (INPUTENGINE.getEventBoolValueBounce(EV_TERRAINEDITOR_PITCHBACKWARD, 0.1f))
								{
									float value = 0.5;
									if(INPUTENGINE.isKeyDown(OIS::KC_LSHIFT) || INPUTENGINE.isKeyDown(OIS::KC_RSHIFT))
									value = 4;
									if (road) {road->dpitch(-value);}
									else if (editor) {editor->dpitch(-1);}
								}

							if (INPUTENGINE.getEventBoolValueBounce(EV_TERRAINEDITOR_PITCHFOREWARD, 0.1f))
								{
									float value = 0.5;
									if(INPUTENGINE.isKeyDown(OIS::KC_LSHIFT) || INPUTENGINE.isKeyDown(OIS::KC_RSHIFT))
									value = 4;
									if (road) {road-> dpitch(value);}
									else if (editor) {editor->dpitch(1);}
								}

							if (INPUTENGINE.getEventBoolValueBounce(EV_TERRAINEDITOR_TOGGLEROADTYPE, 0.5f))
								{
									if (road)
										road->toggleType();
								}

							if (INPUTENGINE.getEventBoolValueBounce(EV_TERRAINEDITOR_BUILT, 0.5f))
								{
								if (road)
									{
										if (!editorfd)
											{
												String editorfn = SETTINGS.getSetting("Log Path") + "editor_out.txt";
												editorfd = fopen(editorfn.c_str(), "a");
												fprintf(editorfd, " ==== new session\n");
											}
										road->append();
										fprintf(editorfd, "%f, %f, %f, %f, %f, %f, %s\n", road->rpos.x, road->rpos.y, road->rpos.z, road->rrot.x, road->rrot.y, road->rrot.z, road->curtype);
										LogManager::getSingleton().logMessage(StringConverter::toString(road->rpos.x)+", "+
										StringConverter::toString(road->rpos.y)+", "+
										StringConverter::toString(road->rpos.z)+", "+
										StringConverter::toString(road->rrot.x)+", "+
										StringConverter::toString(road->rrot.y)+", "+
										StringConverter::toString(road->rrot.z)+", "+road->curtype);

										loadObject(road->curtype, road->rpos.x, road->rpos.y, road->rpos.z, road->rrot.x, road->rrot.y, road->rrot.z, 0, "generic");
									}

								if (editor)
									{
										if (!editorfd)
											{
												String editorfn = SETTINGS.getSetting("Log Path") + "editor_out.txt";
												editorfd = fopen(editorfn.c_str(), "a");
												fprintf(editorfd, " ==== new session\n");
											}

										fprintf(editorfd, "%f, %f, %f, %f, %f, %f, %s\n", editor->ppos.x, editor->ppos.y, editor->ppos.z, 0.0, editor->pturn, editor->ppitch, editor->curtype);
										LogManager::getSingleton().logMessage(StringConverter::toString(editor->ppos.x)+", "+
										StringConverter::toString(editor->ppos.y)+", "+
										StringConverter::toString(editor->ppos.z)+", "+
										StringConverter::toString(0)+", "+
										StringConverter::toString(editor->pturn)+", "+
										StringConverter::toString(editor->ppitch)+", "+editor->curtype);
										loadObject(editor->curtype, editor->ppos.x, editor->ppos.y, editor->ppos.z, 0, editor->pturn, editor->ppitch, 0, "generic", false);
									}
							}
						} // end of (!trucks[current_truck]->replaymode) block


					// replay mode
					if (trucks[current_truck]->replaymode)
					{
					}
					else	// this else part is called when we are NOT in replaymode
					{
						// steering
						float tmp_left_digital  = INPUTENGINE.getEventValue(EV_TRUCK_STEER_LEFT,  false, InputEngine::ET_DIGITAL);
						float tmp_right_digital = INPUTENGINE.getEventValue(EV_TRUCK_STEER_RIGHT, false, InputEngine::ET_DIGITAL);
						float tmp_left_analog   = INPUTENGINE.getEventValue(EV_TRUCK_STEER_LEFT,  false, InputEngine::ET_ANALOG);
						float tmp_right_analog  = INPUTENGINE.getEventValue(EV_TRUCK_STEER_RIGHT, false, InputEngine::ET_ANALOG);

						float sum = -max(tmp_left_digital,tmp_left_analog)+ max(tmp_right_digital,tmp_right_analog);

						if(sum < -1) sum = -1;
						if(sum > 1) sum = 1;

						trucks[current_truck]->hydrodircommand = sum;
						
						if ((tmp_left_digital<tmp_left_analog) || (tmp_right_digital<tmp_right_analog))
							trucks[current_truck]->hydroSpeedCoupling=false; 
						else
							trucks[current_truck]->hydroSpeedCoupling=true;

						//accelerate
						float accval = INPUTENGINE.getEventValue(EV_TRUCK_ACCELERATE);
						if(trucks[current_truck]->engine) trucks[current_truck]->engine->autoSetAcc(accval);

						//brake
						float brake = INPUTENGINE.getEventValue(EV_TRUCK_BRAKE);
						trucks[current_truck]->brake = brake*trucks[current_truck]->brakeforce;
#ifdef USE_OPENAL
						if (ssm && trucks[current_truck]->brake > trucks[current_truck]->brakeforce/6.0)
							ssm->trigStart(current_truck, SS_TRIG_BRAKE);
						else if (ssm)
							ssm->trigStop(current_truck, SS_TRIG_BRAKE);
#endif //OPENAL

						//IMI
						// gear management -- it might should be transferred to a standalone function of Beam or RoRFrameListener
						if (trucks[current_truck]->engine)
							{
								if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_AUTOSHIFT_UP)) 	trucks[current_truck]->engine->autoShiftUp();
								if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_AUTOSHIFT_DOWN))	trucks[current_truck]->engine->autoShiftDown();
								if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_TOGGLE_CONTACT))	trucks[current_truck]->engine->toggleContact();

								if (INPUTENGINE.getEventBoolValue(EV_TRUCK_STARTER) && trucks[current_truck]->engine->contact && !trucks[current_truck]->replaymode)
									{
										//starter
										trucks[current_truck]->engine->setstarter(1);
#ifdef USE_OPENAL
										if(ssm) ssm->trigStart(current_truck, SS_TRIG_STARTER);
#endif // OPENAL
									}
								else
									{
										trucks[current_truck]->engine->setstarter(0);
#ifdef USE_OPENAL
										if(ssm) ssm->trigStop(current_truck, SS_TRIG_STARTER);
#endif // OPENAL
									}

								if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_SWITCH_SHIFT_MODES))
									{
										//Toggle Auto shift
										trucks[current_truck]->engine->toggleAutoMode();
										if(ow)
										{
											switch(trucks[current_truck]->engine->getAutoMode())
											{
												case AUTOMATIC: ow->flashMessage(_L("Automatic shift")); break;
												case SEMIAUTO: ow->flashMessage(_L("Manual shift - Auto clutch")); break;
												case MANUAL: ow->flashMessage(_L("Fully Manual: sequential shift")); break;
												case MANUAL_STICK: ow->flashMessage(_L("Fully manual: stick shift")); break;
												case MANUAL_RANGES: ow->flashMessage(_L("Fully Manual: stick shift with ranges")); break;
											}
										}
									}

								//joy clutch
								float cval = INPUTENGINE.getEventValue(EV_TRUCK_MANUAL_CLUTCH);
								trucks[current_truck]->engine->setManualClutch(cval);

								bool gear_changed_rel = false;
								int shiftmode = trucks[current_truck]->engine->getAutoMode();

//								if (shiftmode==SEMIAUTO || shiftmode==MANUAL) // manual sequencial shifting
								if (shiftmode<=MANUAL) // manual sequencial shifting, semi auto shifting, auto shifting
									{
										if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_SHIFT_UP))
											{
												trucks[current_truck]->engine->shift(1);
												gear_changed_rel=true;
											}
										else if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_SHIFT_DOWN))
											{
												trucks[current_truck]->engine->shift(-1);
												gear_changed_rel=true;
											}
										else if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_SHIFT_NEUTRAL))
											{
												trucks[current_truck]->engine->shiftTo(0);
											}
									}
								else // if (shiftmode>MANUAL)		// h-shift or h-shift with ranges shifting
									{
										bool gear_changed	= false;
										bool found			= false;
										int curgear		= trucks[current_truck]->engine->getGear();
										int curgearrange= trucks[current_truck]->engine->getGearRange();
										int gearoffset  = curgear-curgearrange*6;
										if (gearoffset<0) gearoffset = 0;
										// one can select range only if in natural
										if(shiftmode==MANUAL_RANGES && curgear == 0)
											{
												//  maybe this should not be here, but should experiment
												if		 (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_SHIFT_LOWRANGE) && curgearrange!=0)
													{
														trucks[current_truck]->engine->setGearRange(0);
														gear_changed = true;
														if(ow) ow->flashMessage(_L("Low range selected"));
													}
												else if  (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_SHIFT_MIDRANGE)  && curgearrange !=1 && trucks[current_truck]->engine->getNumGearsRanges()>1)
													{
														trucks[current_truck]->engine->setGearRange(1);
														gear_changed = true;
														if(ow) ow->flashMessage(_L("Mid range selected"));
													}
												else if  (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_SHIFT_HIGHRANGE) && curgearrange!=2 && trucks[current_truck]->engine->getNumGearsRanges()>2)
													{
														trucks[current_truck]->engine->setGearRange(2);
														gear_changed = true;
														if(ow) ow->flashMessage(_L("High range selected"));
													}
											}
//zaxxon
										if(curgear == -1)
											{
												gear_changed = !INPUTENGINE.getEventBoolValue(EV_TRUCK_SHIFT_GEAR_REVERSE);
											}
										else if(curgear > 0 && curgear < 19)
											{
												if (shiftmode==MANUAL)	gear_changed = !INPUTENGINE.getEventBoolValue(EV_TRUCK_SHIFT_GEAR1 + curgear -1);
												else					gear_changed = !INPUTENGINE.getEventBoolValue(EV_TRUCK_SHIFT_GEAR1 + gearoffset-1); // range mode
											}

										if (gear_changed || curgear==0)
											{
												if      (INPUTENGINE.getEventBoolValue(EV_TRUCK_SHIFT_GEAR_REVERSE))
													{
														trucks[current_truck]->engine->shiftTo(-1);
														found = true;
													}
												else if (INPUTENGINE.getEventBoolValue(EV_TRUCK_SHIFT_NEUTRAL))
													{
														trucks[current_truck]->engine->shiftTo(0);
														found = true;
													}
												else
													{
														if (shiftmode==MANUAL_STICK)
															{
																for (int i=1;i<19 && !found;i++)
																	{
																		if (INPUTENGINE.getEventBoolValue(EV_TRUCK_SHIFT_GEAR1 +i - 1))
																			{
																				trucks[current_truck]->engine->shiftTo(i);
																				found = true;
																			}
																	}
															}
														else	// MANUAL_RANGES
															{
																for (int i=1;i<7 && !found;i++)
																	{
																		if (INPUTENGINE.getEventBoolValue(EV_TRUCK_SHIFT_GEAR1 +i - 1))
																			{
																				trucks[current_truck]->engine->shiftTo(i+curgearrange*6);
																				found = true;
																			}
																	}
															}
													}
												if (!found) trucks[current_truck]->engine->shiftTo(0);
											} // end of if(gear_changed)
//										if (!found && curgear!=0) trucks[current_truck]->engine->shiftTo(0);
									} // end of shitmode>MANUAL
							} // endof ->engine
						} // endof ->replaymode

					if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_TOGGLE_AXLE_LOCK))
					{
						//Toggle Auto shift
						if(!trucks[current_truck]->getAxleLockCount())
						{
							if(ow) ow->flashMessage(_L("No differential installed on current vehicle!"));
						} else
						{
							trucks[current_truck]->toggleAxleLock();
							if(ow) ow->flashMessage(_L("Differentials switched to: ") + _L(trucks[current_truck]->getAxleLockName()) );
						}
					}

#ifdef USE_OPENAL
					if (trucks[current_truck]->ispolice)
					{
						if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_HORN) && ssm)
						{
							ssm->trigToggle(current_truck, SS_TRIG_HORN);
						}
					}
					else
					{
						if (INPUTENGINE.getEventBoolValue(EV_TRUCK_HORN) && !trucks[current_truck]->replaymode)
						{
							if(ssm) ssm->trigStart(current_truck, SS_TRIG_HORN);
						} else
						{
							if(ssm) ssm->trigStop(current_truck, SS_TRIG_HORN);
						};
					}
#endif // OPENAL

					if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_PARKING_BRAKE))
					{
						trucks[current_truck]->parkingbrakeToggle();
					}

				}
				if (trucks[current_truck]->driveable==AIRPLANE)
				{
					//autopilot
					if (trucks[current_truck]->autopilot && trucks[current_truck]->autopilot->wantsdisconnect)
					{
						trucks[current_truck]->disconnectAutopilot();
					}
					//left mouse click
					if (ow && click==0)
					{
						OverlayElement *element=ow->airneedlesOverlay->findElementAt((float)mouseX/(float)screenWidth,(float)mouseY/(float)screenHeight);
						if (element)
						{
							char name[256];
							strcpy(name,element->getName().c_str());
							if (!strncmp(name, "tracks/thrust1", 14)) trucks[current_truck]->aeroengines[0]->setThrotle(1.0f-((((float)mouseY/(float)screenHeight)-ow->thrtop-ow->throffset)/ow->thrheight));
							if (!strncmp(name, "tracks/thrust2", 14) && trucks[current_truck]->free_aeroengine>1) trucks[current_truck]->aeroengines[1]->setThrotle(1.0f-((((float)mouseY/(float)screenHeight)-ow->thrtop-ow->throffset)/ow->thrheight));
							if (!strncmp(name, "tracks/thrust3", 14) && trucks[current_truck]->free_aeroengine>2) trucks[current_truck]->aeroengines[2]->setThrotle(1.0f-((((float)mouseY/(float)screenHeight)-ow->thrtop-ow->throffset)/ow->thrheight));
							if (!strncmp(name, "tracks/thrust4", 14) && trucks[current_truck]->free_aeroengine>3) trucks[current_truck]->aeroengines[3]->setThrotle(1.0f-((((float)mouseY/(float)screenHeight)-ow->thrtop-ow->throffset)/ow->thrheight));
							enablegrab=false;
						}
						//also for main dashboard
						OverlayElement *element2=ow->airdashboardOverlay->findElementAt((float)mouseX/(float)screenWidth,(float)mouseY/(float)screenHeight);
						if (element2)
						{
							enablegrab=false;
							char name[256];
							strcpy(name,element2->getName().c_str());
							//LogManager::getSingleton().logMessage("element "+element2->getName());
							if (!strncmp(name, "tracks/engstart1", 16)) trucks[current_truck]->aeroengines[0]->flipStart();
							if (!strncmp(name, "tracks/engstart2", 16) && trucks[current_truck]->free_aeroengine>1) trucks[current_truck]->aeroengines[1]->flipStart();
							if (!strncmp(name, "tracks/engstart3", 16) && trucks[current_truck]->free_aeroengine>2) trucks[current_truck]->aeroengines[2]->flipStart();
							if (!strncmp(name, "tracks/engstart4", 16) && trucks[current_truck]->free_aeroengine>3) trucks[current_truck]->aeroengines[3]->flipStart();
							//heading group
							if (!strcmp(name, "tracks/ap_hdg_but") && trucks[current_truck]->autopilot && mTimeUntilNextToggle <= 0)
							{
								mTimeUntilNextToggle = 0.2;
								if(trucks[current_truck]->autopilot->toggleHeading(HEADING_FIXED)==HEADING_FIXED)
									OverlayManager::getSingleton().getOverlayElement("tracks/ap_hdg_but")->setMaterialName("tracks/hdg-on");
								else
									OverlayManager::getSingleton().getOverlayElement("tracks/ap_hdg_but")->setMaterialName("tracks/hdg-off");
								OverlayManager::getSingleton().getOverlayElement("tracks/ap_wlv_but")->setMaterialName("tracks/wlv-off");
								OverlayManager::getSingleton().getOverlayElement("tracks/ap_nav_but")->setMaterialName("tracks/nav-off");
							}
							if (!strcmp(name, "tracks/ap_wlv_but") && trucks[current_truck]->autopilot && mTimeUntilNextToggle <= 0)
							{
								mTimeUntilNextToggle = 0.2;
								if(trucks[current_truck]->autopilot->toggleHeading(HEADING_WLV)==HEADING_WLV)
									OverlayManager::getSingleton().getOverlayElement("tracks/ap_wlv_but")->setMaterialName("tracks/wlv-on");
								else
									OverlayManager::getSingleton().getOverlayElement("tracks/ap_wlv_but")->setMaterialName("tracks/wlv-off");
								OverlayManager::getSingleton().getOverlayElement("tracks/ap_hdg_but")->setMaterialName("tracks/hdg-off");
								OverlayManager::getSingleton().getOverlayElement("tracks/ap_nav_but")->setMaterialName("tracks/nav-off");
							}
							if (!strcmp(name, "tracks/ap_nav_but") && trucks[current_truck]->autopilot && mTimeUntilNextToggle <= 0)
							{
								mTimeUntilNextToggle = 0.2;
								if(trucks[current_truck]->autopilot->toggleHeading(HEADING_NAV)==HEADING_NAV)
									OverlayManager::getSingleton().getOverlayElement("tracks/ap_nav_but")->setMaterialName("tracks/nav-on");
								else
									OverlayManager::getSingleton().getOverlayElement("tracks/ap_nav_but")->setMaterialName("tracks/nav-off");
								OverlayManager::getSingleton().getOverlayElement("tracks/ap_wlv_but")->setMaterialName("tracks/wlv-off");
								OverlayManager::getSingleton().getOverlayElement("tracks/ap_hdg_but")->setMaterialName("tracks/hdg-off");
							}
							//altitude group
							if (!strcmp(name, "tracks/ap_alt_but") && trucks[current_truck]->autopilot && mTimeUntilNextToggle <= 0)
							{
								mTimeUntilNextToggle = 0.2;
								if(trucks[current_truck]->autopilot->toggleAlt(ALT_FIXED)==ALT_FIXED)
									OverlayManager::getSingleton().getOverlayElement("tracks/ap_alt_but")->setMaterialName("tracks/hold-on");
								else
									OverlayManager::getSingleton().getOverlayElement("tracks/ap_alt_but")->setMaterialName("tracks/hold-off");
								OverlayManager::getSingleton().getOverlayElement("tracks/ap_vs_but")->setMaterialName("tracks/vs-off");
							}
							if (!strcmp(name, "tracks/ap_vs_but") && trucks[current_truck]->autopilot && mTimeUntilNextToggle <= 0)
							{
								mTimeUntilNextToggle = 0.2;
								if(trucks[current_truck]->autopilot->toggleAlt(ALT_VS)==ALT_VS)
									OverlayManager::getSingleton().getOverlayElement("tracks/ap_vs_but")->setMaterialName("tracks/vs-on");
								else
									OverlayManager::getSingleton().getOverlayElement("tracks/ap_vs_but")->setMaterialName("tracks/vs-off");
								OverlayManager::getSingleton().getOverlayElement("tracks/ap_alt_but")->setMaterialName("tracks/hold-off");
							}
							//IAS
							if (!strcmp(name, "tracks/ap_ias_but") && trucks[current_truck]->autopilot && mTimeUntilNextToggle <= 0)
							{
								mTimeUntilNextToggle = 0.2;
								if(trucks[current_truck]->autopilot->toggleIAS())
									OverlayManager::getSingleton().getOverlayElement("tracks/ap_ias_but")->setMaterialName("tracks/athr-on");
								else
									OverlayManager::getSingleton().getOverlayElement("tracks/ap_ias_but")->setMaterialName("tracks/athr-off");
							}
							//GPWS
							if (!strcmp(name, "tracks/ap_gpws_but") && trucks[current_truck]->autopilot && mTimeUntilNextToggle <= 0)
							{
								mTimeUntilNextToggle = 0.2;
								if(trucks[current_truck]->autopilot->toggleGPWS())
									OverlayManager::getSingleton().getOverlayElement("tracks/ap_gpws_but")->setMaterialName("tracks/gpws-on");
								else
									OverlayManager::getSingleton().getOverlayElement("tracks/ap_gpws_but")->setMaterialName("tracks/gpws-off");
							}
							//BRKS
							if (!strcmp(name, "tracks/ap_brks_but") && trucks[current_truck]->autopilot && mTimeUntilNextToggle <= 0)
							{
								trucks[current_truck]->parkingbrakeToggle();
								if(trucks[current_truck]->parkingbrake)
									OverlayManager::getSingleton().getOverlayElement("tracks/ap_brks_but")->setMaterialName("tracks/brks-on");
								else
									OverlayManager::getSingleton().getOverlayElement("tracks/ap_brks_but")->setMaterialName("tracks/brks-off");
								mTimeUntilNextToggle = 0.2;
							}
							//trims
							if (!strcmp(name, "tracks/ap_hdg_up") && trucks[current_truck]->autopilot && mTimeUntilNextToggle <= 0)
							{
								mTimeUntilNextToggle = 0.1;
								int val=trucks[current_truck]->autopilot->adjHDG(1);
								char str[10];
								sprintf(str, "%.3u", val);
								OverlayManager::getSingleton().getOverlayElement("tracks/ap_hdg_val")->setCaption(str);
							}
							if (!strcmp(name, "tracks/ap_hdg_dn") && trucks[current_truck]->autopilot && mTimeUntilNextToggle <= 0)
							{
								mTimeUntilNextToggle = 0.1;
								int val=trucks[current_truck]->autopilot->adjHDG(-1);
								char str[10];
								sprintf(str, "%.3u", val);
								OverlayManager::getSingleton().getOverlayElement("tracks/ap_hdg_val")->setCaption(str);
							}
							if (!strcmp(name, "tracks/ap_alt_up") && trucks[current_truck]->autopilot && mTimeUntilNextToggle <= 0)
							{
								mTimeUntilNextToggle = 0.1;
								int val=trucks[current_truck]->autopilot->adjALT(100);
								char str[10];
								sprintf(str, "%i00", val/100);
								OverlayManager::getSingleton().getOverlayElement("tracks/ap_alt_val")->setCaption(str);
							}
							if (!strcmp(name, "tracks/ap_alt_dn") && trucks[current_truck]->autopilot && mTimeUntilNextToggle <= 0)
							{
								mTimeUntilNextToggle = 0.1;
								int val=trucks[current_truck]->autopilot->adjALT(-100);
								char str[10];
								sprintf(str, "%i00", val/100);
								OverlayManager::getSingleton().getOverlayElement("tracks/ap_alt_val")->setCaption(str);
							}
							if (!strcmp(name, "tracks/ap_vs_up") && trucks[current_truck]->autopilot && mTimeUntilNextToggle <= 0)
							{
								mTimeUntilNextToggle = 0.1;
								int val=trucks[current_truck]->autopilot->adjVS(100);
								char str[10];
								if (val<0)
									sprintf(str, "%i00", val/100);
								else if (val==0) strcpy(str, "000");
								else sprintf(str, "+%i00", val/100);
								OverlayManager::getSingleton().getOverlayElement("tracks/ap_vs_val")->setCaption(str);
							}
							if (!strcmp(name, "tracks/ap_vs_dn") && trucks[current_truck]->autopilot && mTimeUntilNextToggle <= 0)
							{
								mTimeUntilNextToggle = 0.1;
								int val=trucks[current_truck]->autopilot->adjVS(-100);
								char str[10];
								if (val<0)
									sprintf(str, "%i00", val/100);
								else if (val==0) strcpy(str, "000");
								else sprintf(str, "+%i00", val/100);
								OverlayManager::getSingleton().getOverlayElement("tracks/ap_vs_val")->setCaption(str);
							}
							if (!strcmp(name, "tracks/ap_ias_up") && trucks[current_truck]->autopilot && mTimeUntilNextToggle <= 0)
							{
								mTimeUntilNextToggle = 0.1;
								int val=trucks[current_truck]->autopilot->adjIAS(1);
								char str[10];
								sprintf(str, "%.3u", val);
								OverlayManager::getSingleton().getOverlayElement("tracks/ap_ias_val")->setCaption(str);
							}
							if (!strcmp(name, "tracks/ap_ias_dn") && trucks[current_truck]->autopilot && mTimeUntilNextToggle <= 0)
							{
								mTimeUntilNextToggle = 0.1;
								int val=trucks[current_truck]->autopilot->adjIAS(-1);
								char str[10];
								sprintf(str, "%.3u", val);
								OverlayManager::getSingleton().getOverlayElement("tracks/ap_ias_val")->setCaption(str);
							}
						}

					}
					//AIRPLANE KEYS
					float commandrate=4.0;
					//float dt=evt.timeSinceLastFrame;
					//turning
					if (trucks[current_truck]->replaymode)
					{
						if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_REPLAY_FORWARD, 0.1f) && trucks[current_truck]->replaypos<=0)
						{
							trucks[current_truck]->replaypos++;
						}
						if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_REPLAY_BACKWARD, 0.1f) && trucks[current_truck]->replaypos > -trucks[current_truck]->replaylen)
						{
							trucks[current_truck]->replaypos--;
						}
						if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_REPLAY_FAST_FORWARD, 0.1f) && trucks[current_truck]->replaypos+10<=0)
						{
							trucks[current_truck]->replaypos+=10;
						}
						if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_REPLAY_FAST_BACKWARD, 0.1f) && trucks[current_truck]->replaypos-10 > -trucks[current_truck]->replaylen)
						{
							trucks[current_truck]->replaypos-=10;
						}
					} else
					{
						float tmp_left = INPUTENGINE.getEventValue(EV_AIRPLANE_STEER_LEFT);
						float tmp_right = INPUTENGINE.getEventValue(EV_AIRPLANE_STEER_RIGHT);
						float sum_steer = -tmp_left + tmp_right;
						INPUTENGINE.smoothValue(trucks[current_truck]->aileron, sum_steer, dt*commandrate);
						trucks[current_truck]->hydrodircommand = trucks[current_truck]->aileron;
						trucks[current_truck]->hydroSpeedCoupling = !(INPUTENGINE.isEventAnalog(EV_AIRPLANE_STEER_LEFT) && INPUTENGINE.isEventAnalog(EV_AIRPLANE_STEER_RIGHT));
					}

					//pitch
					float tmp_pitch_up = INPUTENGINE.getEventValue(EV_AIRPLANE_ELEVATOR_UP);
					float tmp_pitch_down = INPUTENGINE.getEventValue(EV_AIRPLANE_ELEVATOR_DOWN);
					float sum_pitch = tmp_pitch_down - tmp_pitch_up;
					INPUTENGINE.smoothValue(trucks[current_truck]->elevator, sum_pitch, dt*commandrate);

					//rudder
					float tmp_rudder_left = INPUTENGINE.getEventValue(EV_AIRPLANE_RUDDER_LEFT);
					float tmp_rudder_right = INPUTENGINE.getEventValue(EV_AIRPLANE_RUDDER_RIGHT);
					float sum_rudder = tmp_rudder_left - tmp_rudder_right;
					INPUTENGINE.smoothValue(trucks[current_truck]->rudder, sum_rudder, dt*commandrate);

					//brake
					if (!trucks[current_truck]->replaymode && !trucks[current_truck]->parkingbrake)
					{
						trucks[current_truck]->brake=0.0;
						float brakevalue = INPUTENGINE.getEventValue(EV_AIRPLANE_BRAKE);
						trucks[current_truck]->brake=trucks[current_truck]->brakeforce*0.66*brakevalue;
					};
					if (INPUTENGINE.getEventBoolValueBounce(EV_AIRPLANE_PARKING_BRAKE))
					{
						trucks[current_truck]->parkingbrakeToggle();
						if(ow)
						{
							if(trucks[current_truck]->parkingbrake)
								OverlayManager::getSingleton().getOverlayElement("tracks/ap_brks_but")->setMaterialName("tracks/brks-on");
							else
								OverlayManager::getSingleton().getOverlayElement("tracks/ap_brks_but")->setMaterialName("tracks/brks-off");
						}
					}
					//reverse
					if (INPUTENGINE.getEventBoolValueBounce(EV_AIRPLANE_REVERSE))
					{
						int i;
						for (i=0; i<trucks[current_truck]->free_aeroengine; i++)
							trucks[current_truck]->aeroengines[i]->toggleReverse();
					}

					// toggle engines
					if (INPUTENGINE.getEventBoolValueBounce(EV_AIRPLANE_TOGGLE_ENGINES))
					{
						int i;
						for (i=0; i<trucks[current_truck]->free_aeroengine; i++)
							trucks[current_truck]->aeroengines[i]->flipStart();
					}

					//flaps
					if (INPUTENGINE.getEventBoolValueBounce(EV_AIRPLANE_FLAPS_NONE))
					{
						if (trucks[current_truck]->flap>0)
							trucks[current_truck]->flap=0;
					}
					if (INPUTENGINE.getEventBoolValueBounce(EV_AIRPLANE_FLAPS_FULL))
					{
						if (trucks[current_truck]->flap<5)
							trucks[current_truck]->flap=5;
					}
					if (INPUTENGINE.getEventBoolValueBounce(EV_AIRPLANE_FLAPS_LESS))
					{
						if (trucks[current_truck]->flap>0)
							trucks[current_truck]->flap=(trucks[current_truck]->flap)-1;
					}
					if (INPUTENGINE.getEventBoolValueBounce(EV_AIRPLANE_FLAPS_MORE))
					{
						if (trucks[current_truck]->flap<5)
							trucks[current_truck]->flap=(trucks[current_truck]->flap)+1;
					}

					//airbrakes
					if (INPUTENGINE.getEventBoolValueBounce(EV_AIRPLANE_AIRBRAKES_NONE))
					{
						if (trucks[current_truck]->airbrakeval>0)
							trucks[current_truck]->airbrakeval=0;
					}
					if (INPUTENGINE.getEventBoolValueBounce(EV_AIRPLANE_AIRBRAKES_FULL))
					{
						if (trucks[current_truck]->airbrakeval<5)
							trucks[current_truck]->airbrakeval=5;
					}
					if (INPUTENGINE.getEventBoolValueBounce(EV_AIRPLANE_AIRBRAKES_LESS))
					{
						if (trucks[current_truck]->airbrakeval>0)
							trucks[current_truck]->airbrakeval=(trucks[current_truck]->airbrakeval)-1;
					}
					if (INPUTENGINE.getEventBoolValueBounce(EV_AIRPLANE_AIRBRAKES_MORE))
					{
						if (trucks[current_truck]->airbrakeval<5)
							trucks[current_truck]->airbrakeval=(trucks[current_truck]->airbrakeval)+1;
					}

					//throttle
					float tmp_throttle = INPUTENGINE.getEventBoolValue(EV_AIRPLANE_THROTTLE);
					if(tmp_throttle > 0)
						for (int i=0; i<trucks[current_truck]->free_aeroengine; i++)
							trucks[current_truck]->aeroengines[i]->setThrotle(tmp_throttle);

					if(INPUTENGINE.isEventDefined(EV_AIRPLANE_THROTTLE_AXIS))
					{
						float f = INPUTENGINE.getEventValue(EV_AIRPLANE_THROTTLE_AXIS);
						for (int i=0; i<trucks[current_truck]->free_aeroengine; i++)
							trucks[current_truck]->aeroengines[i]->setThrotle(f);
					}
					if (INPUTENGINE.getEventBoolValueBounce(EV_AIRPLANE_THROTTLE_DOWN, 0.1f))
					{
						//throtle down
						int i;
						for (i=0; i<trucks[current_truck]->free_aeroengine; i++)
							trucks[current_truck]->aeroengines[i]->setThrotle(trucks[current_truck]->aeroengines[i]->getThrotle()-0.05);
					}
					if (INPUTENGINE.getEventBoolValueBounce(EV_AIRPLANE_THROTTLE_UP, 0.1f))
					{
						//throtle up
						int i;
						for (i=0; i<trucks[current_truck]->free_aeroengine; i++)
							trucks[current_truck]->aeroengines[i]->setThrotle(trucks[current_truck]->aeroengines[i]->getThrotle()+0.05);
					}

					if (INPUTENGINE.getEventBoolValueBounce(EV_AIRPLANE_THROTTLE_NO, 0.1f))
					{
						// no throtle
						int i;
						for (i=0; i<trucks[current_truck]->free_aeroengine; i++)
							trucks[current_truck]->aeroengines[i]->setThrotle(0);
					}
					if (INPUTENGINE.getEventBoolValueBounce(EV_AIRPLANE_THROTTLE_FULL, 0.1f))
					{
						// full throtle
						int i;
						for (i=0; i<trucks[current_truck]->free_aeroengine; i++)
							trucks[current_truck]->aeroengines[i]->setThrotle(1);
					}
					if (trucks[current_truck]->autopilot)
					{
						for (i=0; i<trucks[current_truck]->free_aeroengine; i++)
							trucks[current_truck]->aeroengines[i]->setThrotle(trucks[current_truck]->autopilot->getThrotle(trucks[current_truck]->aeroengines[i]->getThrotle(), dt));
					}


				}
				if (trucks[current_truck]->driveable==BOAT)
				{
					//BOAT SPECIFICS

					//throttle

					if(INPUTENGINE.isEventDefined(EV_BOAT_THROTTLE_AXIS))
					{
						float f = INPUTENGINE.getEventValue(EV_BOAT_THROTTLE_AXIS);
						// use negative values also!
						f = f * 2 - 1;
						for (int i=0; i<trucks[current_truck]->free_screwprop; i++)
							trucks[current_truck]->screwprops[i]->setThrotle(-f);
					}
					if (INPUTENGINE.getEventBoolValueBounce(EV_BOAT_THROTTLE_DOWN, 0.1f))
					{
						//throtle down
						int i;
						for (i=0; i<trucks[current_truck]->free_screwprop; i++)
							trucks[current_truck]->screwprops[i]->setThrotle(trucks[current_truck]->screwprops[i]->getThrotle()-0.05);
					}
					if (INPUTENGINE.getEventBoolValueBounce(EV_BOAT_THROTTLE_UP, 0.1f))
					{
						//throtle up
						int i;
						for (i=0; i<trucks[current_truck]->free_screwprop; i++)
							trucks[current_truck]->screwprops[i]->setThrotle(trucks[current_truck]->screwprops[i]->getThrotle()+0.05);
					}


					// steer
					float tmp_steer_left = INPUTENGINE.getEventValue(EV_BOAT_STEER_LEFT);
					float tmp_steer_right = INPUTENGINE.getEventValue(EV_BOAT_STEER_RIGHT);
					float stime = INPUTENGINE.getEventBounceTime(EV_BOAT_STEER_LEFT) + INPUTENGINE.getEventBounceTime(EV_BOAT_STEER_RIGHT);
					float sum_steer = (tmp_steer_left - tmp_steer_right) * 0.06;
					// do not center the rudder!
					if(fabs(sum_steer)>0 && stime <= 0)
					{
						for (int i=0; i<trucks[current_truck]->free_screwprop; i++)
							trucks[current_truck]->screwprops[i]->setRudder(trucks[current_truck]->screwprops[i]->getRudder() + sum_steer);
					}
					if(INPUTENGINE.isEventDefined(EV_BOAT_STEER_LEFT_AXIS) && INPUTENGINE.isEventDefined(EV_BOAT_STEER_RIGHT_AXIS))
					{
						float tmp_steer_left = INPUTENGINE.getEventValue(EV_BOAT_STEER_LEFT_AXIS);
						float tmp_steer_right = INPUTENGINE.getEventValue(EV_BOAT_STEER_RIGHT_AXIS);
						float sum_steer = (tmp_steer_left - tmp_steer_right);
						for (int i=0; i<trucks[current_truck]->free_screwprop; i++)
							trucks[current_truck]->screwprops[i]->setRudder(sum_steer);
					}
					if (INPUTENGINE.getEventBoolValueBounce(EV_BOAT_CENTER_RUDDER, 0.1f))
					{
						int i;
						for (i=0; i<trucks[current_truck]->free_screwprop; i++)
							trucks[current_truck]->screwprops[i]->setRudder(0);
					}

					if (INPUTENGINE.getEventBoolValueBounce(EV_BOAT_REVERSE))
					{
						int i;
						for (i=0; i<trucks[current_truck]->free_screwprop; i++)
							trucks[current_truck]->screwprops[i]->toggleReverse();
					}
				}
				//COMMON KEYS

				if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_TRUCK_REMOVE))
				{
					removeTruck(current_truck);
				}
				if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_ROPELOCK))
				{
					trucks[current_truck]->ropeToggle(trucks, free_truck, -1);
				}
				if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_LOCK))
				{
					trucks[current_truck]->hookToggle(trucks, free_truck, -1);
					//SlideNodeLock
					trucks[current_truck]->toggleSlideNodeLock(trucks, free_truck, current_truck);
				}
				//strap
				if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_SECURE_LOAD))
				{
					trucks[current_truck]->tieToggle(trucks, free_truck, -1);
				}
				if (INPUTENGINE.getEventBoolValue(EV_COMMON_RESET_TRUCK) && !trucks[current_truck]->replaymode)
				{
					// stop any races
					stopTimer();
					// init
					trucks[current_truck]->reset();
				}
				if (INPUTENGINE.getEventBoolValue(EV_COMMON_REPAIR_TRUCK))
				{
#ifdef USE_OPENAL
					if(ssm) ssm->trigOnce(current_truck, SS_TRIG_REPAIR);
#endif //OPENAL
					trucks[current_truck]->reset(true);
				}
				//replay mode
				if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_TOGGLE_REPLAY_MODE))
				{
					stopTimer();
					trucks[current_truck]->setReplayMode(!trucks[current_truck]->replaymode);
				}

				if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_TOGGLE_CUSTOM_PARTICLES))
				{
					trucks[current_truck]->toggleCustomParticles();
				}


				if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_SHOW_SKELETON))
				{
					if (trucks[current_truck]->skeleton)
					{
						trucks[current_truck]->hideSkeleton(true);
					}
					else
						trucks[current_truck]->showSkeleton(true, true);
					trucks[current_truck]->updateVisual();
				}

				if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_TOGGLE_TRUCK_LIGHTS))
				{
					trucks[current_truck]->lightsToggle(trucks, free_truck);
				}

				if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_TOGGLE_TRUCK_BEACONS))
				{
					trucks[current_truck]->beaconsToggle();
				}
				//camera mode
				if (INPUTENGINE.getEventBoolValueBounce(EV_CAMERA_CHANGE) && cameramode != CAMERA_FREE && cameramode != CAMERA_FREE_FIXED)
				{
					if (cameramode==CAMERA_INT && trucks[current_truck]->currentcamera<trucks[current_truck]->freecinecamera-1)
					{
						trucks[current_truck]->currentcamera++;
					}
					else
					{
						trucks[current_truck]->currentcamera=0;
						if (cameramode==CAMERA_INT)
						{
							//end of internal cam
							camRotX=pushcamRotX;
							camRotY=pushcamRotY;
							trucks[current_truck]->prepareInside(false);
							if(ow) ow->showDashboardOverlays(true, trucks[current_truck]->driveable);
							//if(bigMap) bigMap->setVisibility(true);
						}
						cameramode++;
						if (cameramode==CAMERA_INT)
						{
							//start of internal cam
							pushcamRotX=camRotX;
							pushcamRotY=camRotY;
							camRotX=0;
							camRotY=DEFAULT_INTERNAL_CAM_PITCH;
							trucks[current_truck]->prepareInside(true);
							//if(bigMap) bigMap->setVisibility(false);
							// airplane dashboard in the plane visible
							if(ow)
							{
								if(trucks[current_truck]->driveable == AIRPLANE)
									ow->showDashboardOverlays(true, trucks[current_truck]->driveable);
								else
									ow->showDashboardOverlays(false, 0);
							}
						}
						if (cameramode==CAMERA_END) cameramode=0;
					}
				}
				//camera mode
				if (INPUTENGINE.getEventBoolValue(EV_COMMON_PRESSURE_LESS) && current_truck!=-1)
				{
					if(ow) ow->showPressureOverlay(true);
#ifdef USE_OPENAL
					if(ssm) ssm->trigStart(current_truck, SS_TRIG_AIR);
#endif // OPENAL
					trucks[current_truck]->addPressure(-dt*10.0);
					pressure_pressed=true;
				}
				else if (INPUTENGINE.getEventBoolValue(EV_COMMON_PRESSURE_MORE))
				{
					if(ow) ow->showPressureOverlay(true);
#ifdef USE_OPENAL
					if(ssm) ssm->trigStart(current_truck, SS_TRIG_AIR);
#endif // OPENAL
					trucks[current_truck]->addPressure(dt*10.0);
					pressure_pressed=true;
				} else if (pressure_pressed)
				{
#ifdef USE_OPENAL
					if(ssm) ssm->trigStop(current_truck, SS_TRIG_AIR);
#endif // OPENAL
					pressure_pressed=false;
					if(ow) ow->showPressureOverlay(false);
				}

				if(enablegrab && ow)
				{
					//node grabbing
					bool ctrldown = INPUTENGINE.isKeyDown(OIS::KC_LCONTROL) || INPUTENGINE.isKeyDown(OIS::KC_RCONTROL);
					//node grabbing
					if (isnodegrabbed)
					{
						if(oldstate != 2)
						{
							if(ctrldown)
								ow->mouseOverlay->getChild("mouse/pointer")->setMaterialName("mouse-locked-heavy");
							else
								ow->mouseOverlay->getChild("mouse/pointer")->setMaterialName("mouse-locked");
							pickLineNode->setVisible(true);
							oldstate = 2;
						}

						if (click==0)
						{
							// allow the grab force to change
							if(fabs((float)(mstate.Z.rel)) > 0.01)
							{
								if(INPUTENGINE.isKeyDown(OIS::KC_LSHIFT) || INPUTENGINE.isKeyDown(OIS::KC_RSHIFT))
									mouseGrabForce += mstate.Z.rel * 100.0f;
								else
									mouseGrabForce += mstate.Z.rel * 10.0f;
								// do not allow negative forces, looks weird
								if(mouseGrabForce < 0.0f)
									mouseGrabForce = 0.0f;

								//LogManager::getSingleton().logMessage("mouse force: " + StringConverter::toString(mouseGrabForce));
							}
							//exert forces
							//find pointed position
							Ray mouseRay=mCamera->getCameraToViewportRay((float)mouseX/(float)screenWidth, (float)mouseY/(float)screenHeight);
							Vector3 pos=mouseRay.getPoint(distgrabbed);

							// update pickline
							pickLine->beginUpdate(0);
							pickLine->position(trucks[truckgrabbed]->nodes[nodegrabbed].AbsPosition);
							pickLine->position(pos);
							pickLine->end();

							// add forces

							trucks[truckgrabbed]->mouseMove(nodegrabbed,pos, mouseGrabForce);
						}
						else
						{
							pickLineNode->setVisible(false);
							isnodegrabbed=false;
							trucks[truckgrabbed]->mouseMove(-1,Vector3::ZERO, 0);
						}
					}
					else
					{
						if (click==0)
						{
							//try to grab something
							Ray mouseRay=mCamera->getCameraToViewportRay((float)mouseX/(float)screenWidth, (float)mouseY/(float)screenHeight);
							int t;
							int mindist=30000;
							int mintruck=-1;
							int minnode=-1;
							for (t=0; t<free_truck; t++)
							{
								if(!trucks[t]) continue;
								int i;
								for (i=0; i<trucks[t]->free_node; i++)
								{
									std::pair<bool,Real> pair=mouseRay.intersects(Sphere(trucks[t]->nodes[i].AbsPosition, 0.1));
									if (pair.first)
									{
										if (pair.second<mindist)
										{
											mindist=(int)pair.second;
											mintruck=t;
											minnode=i;
										}
									}
								}
							}
							//okay see if we got a match
							if (mintruck!=-1)
							{
#ifdef USE_ANGELSCRIPT
								ScriptEngine::getSingleton().triggerEvent(ScriptEngine::SE_GENERIC_MOUSE_BEAM_INTERACTION, current_truck);
#endif //ANGELSCRIPT
								truckgrabbed=mintruck;
								nodegrabbed=minnode;
								distgrabbed=mindist;
								isnodegrabbed=true;
							}
						}
					}
				}
			}//end of truck!=-1
		}


		static unsigned char brushNum=0;

		const OIS::MouseState mstate = INPUTENGINE.getMouseState();
		static bool buttonsPressed = false;
		if(ow && inputGrabMode == GRAB_ALL || (inputGrabMode == GRAB_DYNAMICALLY &&  (mstate.buttons != 0 || buttonsPressed)))
		{
			if ((cameramode==CAMERA_INT || cameramode==CAMERA_EXT || cameramode==CAMERA_FIX || cameramode==CAMERA_FREE_FIXED) && current_truck == -1)
			{
				bool btnview = mstate.buttonDown((switchMouseButtons?OIS::MB_Left:OIS::MB_Right));
				if(inputGrabMode == GRAB_DYNAMICALLY)
				{
					if(!buttonsPressed && btnview)
					{
						// set mouse position on the first click
						mouseX = mstate.X.abs;
						mouseY = mstate.Y.abs;
						// display cursor
						ow->mouseElement->setPosition(mouseX, mouseY);
						ow->mouseOverlay->getChild("mouse/pointer")->setMaterialName("mouse-rotate");
						ow->mouseOverlay->show();
						INPUTENGINE.hideMouse(true);
					} else if (buttonsPressed && !btnview)
					{
						// release event
						ow->mouseOverlay->getChild("mouse/pointer")->setMaterialName("mouse");
						ow->mouseOverlay->hide();
						INPUTENGINE.hideMouse(false);
					}
					if(btnview)
						INPUTENGINE.setMousePosition(mouseX, mouseY);

				}
				if(inputGrabMode == GRAB_ALL || (inputGrabMode == GRAB_DYNAMICALLY &&  btnview))
				{
					// 'First person' mode :)
					// x rotation = automatically by rotating the character
					if (mstate.Y.rel != 0)
						camRotY += Degree(-mstate.Y.rel / 10.0);
					if (mstate.Z.rel != 0)
						if(INPUTENGINE.isKeyDown(OIS::KC_LSHIFT) || INPUTENGINE.isKeyDown(OIS::KC_RSHIFT))
							camDist += -mstate.Z.rel / 12.0;
						else
							camDist += -mstate.Z.rel / 120.0;

					// rather hacked workaround :|
					float angle = person->getAngle() + (float)(mstate.X.rel) / 120.0;
					person->getSceneNode()->resetOrientation();
					person->getSceneNode()->yaw(-Radian(angle));
					person->setAngle(angle);
					person->updateMapIcon();
				}
			} else
			{
				if(mstate.buttonDown((switchMouseButtons?OIS::MB_Left:OIS::MB_Right)))
				{
					// fix mouse at the current place :)
					if(inputGrabMode == GRAB_DYNAMICALLY)
						INPUTENGINE.setMousePosition(mouseX, mouseY);
					if (mstate.X.rel != 0)
						camRotX += Degree(mstate.X.rel / 10.0);
					if (mstate.Y.rel != 0)
						camRotY += Degree(-mstate.Y.rel / 10.0);
					if (mstate.Z.rel != 0)
						if(INPUTENGINE.isKeyDown(OIS::KC_LSHIFT) || INPUTENGINE.isKeyDown(OIS::KC_RSHIFT))
							camDist += -mstate.Z.rel / 12.0;
						else
							camDist += -mstate.Z.rel / 120.0;
				}
			}
			buttonsPressed = (mstate.buttons > 0);
		}

		if (INPUTENGINE.getEventBoolValueBounce(EV_CAMERA_LOOKBACK))
		{
			if(camRotX > Degree(0))
				camRotX=Degree(0);
			else
				camRotX=Degree(180);
		}
		if (INPUTENGINE.getEventBoolValue(EV_CAMERA_ROTATE_LEFT))
		{
			// Move camera left
			camRotX-=mRotScale;
		}

		if (INPUTENGINE.getEventBoolValue(EV_CAMERA_ROTATE_RIGHT))
		{
			// Move camera RIGHT
			camRotX+=mRotScale;
		}

		if ((INPUTENGINE.getEventBoolValue(EV_CAMERA_ROTATE_UP)) && camRotY<Degree(88))
		{
			// Move camera up
			camRotY+=mRotScale;
		}

		if ((INPUTENGINE.getEventBoolValue(EV_CAMERA_ROTATE_DOWN)) && camRotY>Degree(-80))
		{
			// Move camera down
			camRotY-=mRotScale;
		}

		if (INPUTENGINE.getEventBoolValue(EV_CAMERA_ZOOM_IN) && camDist>1)
		{
			// Move camera near
			camDist-=mMoveScale;
		}
		if (INPUTENGINE.getEventBoolValue(EV_CAMERA_ZOOM_IN_FAST) && camDist>1)
		{
			// Move camera near
			camDist-=mMoveScale * 10;
		}
		if (INPUTENGINE.getEventBoolValue(EV_CAMERA_ZOOM_OUT))
		{
			// Move camera far
			camDist+=mMoveScale;
		}
		if (INPUTENGINE.getEventBoolValue(EV_CAMERA_ZOOM_OUT_FAST))
		{
			// Move camera far
			camDist+=mMoveScale * 10;
		}
		if (INPUTENGINE.getEventBoolValue(EV_CAMERA_RESET))
		{
			camRotX=0;
			if (cameramode!=CAMERA_INT) camRotY=Degree(12);
			else camRotY=DEFAULT_INTERNAL_CAM_PITCH;
			camDist=20;
		}
#ifdef USE_CAELUM
		if (SETTINGS.getSetting("Sky effects")=="Caelum (best looking, slower)")
		{
			Ogre::Real time_factor = 1000.0f;
			Ogre::Real multiplier = 10;
			bool update_time = false;

			if (INPUTENGINE.getEventBoolValue(EV_CAELUM_INCREASE_TIME) && SkyManager::getSingletonPtr())
			{
				update_time = true;
			}
			else if (INPUTENGINE.getEventBoolValue(EV_CAELUM_INCREASE_TIME_FAST) && SkyManager::getSingletonPtr())
			{
				time_factor *= multiplier;
				update_time = true;
			}
			else if (INPUTENGINE.getEventBoolValue(EV_CAELUM_DECREASE_TIME) && SkyManager::getSingletonPtr())
			{
				time_factor = -time_factor;
				update_time = true;
			}
			else if (INPUTENGINE.getEventBoolValue(EV_CAELUM_DECREASE_TIME_FAST) && SkyManager::getSingletonPtr())
			{
				time_factor *= -multiplier;
				update_time = true;
			}
			else
			{
				time_factor = 1.0f;
				update_time = SkyManager::getSingleton().getTimeFactor() != 1.0f;
			}

			if( update_time )
			{
				SkyManager::getSingleton().setTimeFactor(time_factor);
				if(ow) ow->flashMessage(Ogre::String("Time set to ") + SkyManager::getSingleton().getPrettyTime(), 2.0);
			}
		}
#endif //CAELUM
		if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_TOGGLE_RENDER_MODE, 0.5f))
		{
			mSceneDetailIndex = (mSceneDetailIndex+1)%3 ;
			switch(mSceneDetailIndex) {
				case 0 : mCamera->setPolygonMode(Ogre::PM_SOLID) ; break ;
				case 1 : mCamera->setPolygonMode(Ogre::PM_WIREFRAME) ; break ;
				case 2 : mCamera->setPolygonMode(Ogre::PM_POINTS) ; break ;
			}
#ifdef USE_MYGUI
			if(mtc && interactivemap)
			{
				switch(mSceneDetailIndex) {
					case 0 : mtc->setCameraMode(Ogre::PM_SOLID) ; break ;
					case 1 : mtc->setCameraMode(Ogre::PM_WIREFRAME) ; break ;
					case 2 : mtc->setCameraMode(Ogre::PM_POINTS) ; break ;
				}
				mtc->update();

			}
#endif //MYGUI
		}

#ifdef USE_MYGUI
		if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_VIEW_MAP))
		{
			if(bigMap)
			{
				mapMode++;
				if(mapMode>2)
					mapMode=0;

				if(mapMode==0)
				{
					bigMap->setVisibility(true);
					if(cameramode!=CAMERA_INT)
					{
						if(mtc) mtc->update();
						//make it small again
						bigMap->updateRenderMetrics(mWindow);
						bigMap->setPosition(0, 0.81, 0.14, 0.19, mWindow);
					}
				} else if(mapMode==1)
				{
					bigMap->setVisibility(true);
					if(mtc) mtc->update();
					// make it big
					bigMap->updateRenderMetrics(mWindow);
					bigMap->setPosition(0.2, 0, 0.8, 0.8, mWindow);
					//NETCHAT.setMode(this, NETCHAT_MAP, true);
				} else
				{
					bigMap->setVisibility(false);
				}
			}

		}
		if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_MAP_ALPHA))
		{
			if(bigMap)
			{
				if(fabs(1-bigMap->getAlpha()) < 0.001)
				{
					bigMap->setAlpha(0.5);
					if(mtc) mtc->setTranlucency(0.5);
				}
				else if(fabs(0.5-bigMap->getAlpha()) < 0.001)
				{
					bigMap->setAlpha(0.2);
					if(mtc) mtc->setTranlucency(0.2);
				}
				else if(fabs(0.2-bigMap->getAlpha()) < 0.001)
				{
					bigMap->setAlpha(1);
					if(mtc) mtc->setTranlucency(1);
				}
			}
		}
#endif // MYGUI
		if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_RESCUE_TRUCK, 0.5f) && current_truck>=0 && trucks[current_truck] && !netmode && trucks[current_truck]->driveable != AIRPLANE)
		{
			//rescue!
			//if (current_truck!=-1) setCurrentTruck(-1);
			int rtruck=-1;
			// search a rescue truck
			for (int i=0; i<free_truck; i++)
			{
				if(!trucks[i]) continue;
				if (trucks[i]->rescuer)
					rtruck=i;
			}
			if(rtruck == -1)
			{
				if(ow) ow->flashMessage("No rescue truck found!", 3);
			} else
			{
				// go to person mode first
				setCurrentTruck(-1);
				// then to the rescue truck, this fixes overlapping interfaces
				setCurrentTruck(rtruck);
			}
		}

		if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_BLINK_LEFT) && current_truck>=0)
		{
			if (trucks[current_truck]->getBlinkType() == BLINK_LEFT)
				trucks[current_truck]->setBlinkType(BLINK_NONE);
			else
				trucks[current_truck]->setBlinkType(BLINK_LEFT);
		}

		if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_BLINK_RIGHT) && current_truck>=0)
		{
			if (trucks[current_truck]->getBlinkType() == BLINK_RIGHT)
				trucks[current_truck]->setBlinkType(BLINK_NONE);
			else
				trucks[current_truck]->setBlinkType(BLINK_RIGHT);
		}

		if (INPUTENGINE.getEventBoolValueBounce(EV_TRUCK_BLINK_WARN) && current_truck>=0)
		{
			if (trucks[current_truck]->getBlinkType() == BLINK_WARN)
				trucks[current_truck]->setBlinkType(BLINK_NONE);
			else
				trucks[current_truck]->setBlinkType(BLINK_WARN);
		}

		if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_NETCHATDISPLAY))
		{
			NETCHAT.toggleVisible(this);
		}

#ifdef USE_MYGUI
		if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_CONSOLEDISPLAY))
		{
			Console::get()->setVisible(!Console::get()->getVisible());
		}
#endif // MYGUI

		if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_NETCHATMODE))
		{
			NETCHAT.toggleMode(this);
		}

		if (INPUTENGINE.getEventBoolValue(EV_COMMON_ENTER_OR_EXIT_TRUCK) && !chatting && mTimeUntilNextToggle <= 0)
		{
			mTimeUntilNextToggle = 0.5; //Some delay before trying to re-enter(exit) truck
			//perso in/out
			if (current_truck==-1)
			{
				//find the nearest truck
				int i;
				float mindist=1000.0;
				int minindex=-1;
				for (i=0; i<free_truck; i++)
				{
					if (!trucks[i]) continue;
					if (!trucks[i]->driveable)

						continue;
					if (trucks[i]->cinecameranodepos[0]==-1)
					{
						LogManager::getSingleton().logMessage("cinecam missing, cannot enter truck!");
						continue;
					}
					float len=(trucks[i]->nodes[trucks[i]->cinecameranodepos[0]].AbsPosition-(person->getPosition()+Vector3(0.0, 2.0, 0.0))).length();
					if (len<mindist)
					{
						mindist=len;
						minindex=i;
					}
				}
				if (mindist<20.0) setCurrentTruck(minindex);
			}
			else if (trucks[current_truck]->nodes[trucks[current_truck]->cinecameranodepos[0]].Velocity.length()<1)
			{
				setCurrentTruck(-1);
			} else
			{
				trucks[current_truck]->brake=trucks[current_truck]->brakeforce*0.66;
				mTimeUntilNextToggle = 0.0; //No delay in this case: the truck must brake like braking normally
			}
		}

	} else
	{
		//no terrain or truck loaded

		//uiloader->updateEvents(dt);


#ifdef USE_MYGUI
		if (SelectorWindow::get()->isFinishedSelecting())
		{
			if (loading_state==NONE_LOADED)
			{
				Cache_Entry *sel = SelectorWindow::get()->getSelection();
				if(sel)
				{
					terrainUID = sel->uniqueid;
					loadTerrain(sel->fname);

					// no trucks loaded?
					if (truck_preload_num == 0)
					{
						// show truck selector
						if(w)
						{
							hideMap();
							SelectorWindow::get()->show(SelectorWindow::LT_NetworkWithBoat);
						}
						else
						{
							hideMap();
							SelectorWindow::get()->show(SelectorWindow::LT_Network);
						}
					} else
					{
						// init no trucks, as there were found some
						initTrucks(false, sel->fname);
					}
				}
			} else if (loading_state==TERRAIN_LOADED)
			{
				Cache_Entry *selt = SelectorWindow::get()->getSelection();
				std::vector<Ogre::String> config = SelectorWindow::get()->getTruckConfig();
				std::vector<Ogre::String> *configptr = &config;
				if(config.size() == 0) configptr = 0;
				if(selt)
					initTrucks(true, selt->fname, selt->fext, configptr);
				// show console in netmode!
				if(netmode)
					NETCHAT.setMode(this, NETCHAT_LEFT_SMALL, true);

			} else if (loading_state==RELOADING)
			{
				Cache_Entry *selt = SelectorWindow::get()->getSelection();
				Skin *skin = SelectorWindow::get()->getSelectedSkin();
				Beam *localTruck = 0;
				if(selt)
				{
					//we load an extra truck
					String selected = selt->fname;
					std::vector<Ogre::String> config = SelectorWindow::get()->getTruckConfig();
					std::vector<Ogre::String> *configptr = &config;
					if(config.size() == 0) configptr = 0;

					localTruck = BeamFactory::getSingleton().createLocal(reload_pos, reload_dir, selected, reload_box, false, flaresMode, configptr, skin);
					//trucks[free_truck] = new Beam(free_truck, mSceneMgr, mSceneMgr->getRootSceneNode(), mWindow, net, &mapsizex, &mapsizez, reload_pos.x, reload_pos.y, reload_pos.z, reload_dir, selected, collisions, dustp, clumpp, sparksp, dripp, splashp, ripplep, hfinder, w, mCamera, mirror, true, false, false, reload_box, false, flaresMode, configptr, skin);
				}



				if(bigMap && localTruck)
				{
					MapEntity *e = bigMap->createNamedMapEntity("Truck"+StringConverter::toString(localTruck->trucknum), MapControl::getTypeByDriveable(localTruck->driveable));
					if(e)
					{
						e->setState(DESACTIVATED);
						e->setVisibility(true);
						e->setPosition(reload_pos);
						e->setRotation(-Radian(localTruck->getHeadingDirectionAngle()));
						// create a map icon
						//createNamedMapEntity();
					}
				}

				SelectorWindow::get()->hide();
				loading_state=ALL_LOADED;
				if(localTruck && localTruck->driveable)
				{
					//we are supposed to be in this truck, if it is a truck
					if (localTruck->engine)
						localTruck->engine->start();
					setCurrentTruck(localTruck->trucknum);
				} else
				{
					// if it is a load or trailer, than stay in person mode
					// but relocate to the new position, so we dont spawn the dialog again
					//personode->setPosition(reload_pos);
					person->move(Vector3(3.0, 0.2, 0.0)); //bad, but better
					//setCurrentTruck(-1);
				}
			}

		}
#endif //MYGUI
	}



	if(INPUTENGINE.getEventBoolValueBounce(EV_COMMON_TRUCK_INFO) && !showcredits && current_truck != -1)
	{
		mTruckInfoOn = ! mTruckInfoOn;
		dirty=true;
		if(ow) ow->truckhud->show(mTruckInfoOn);
	}

	if(INPUTENGINE.getEventBoolValueBounce(EV_COMMON_HIDE_GUI) && !showcredits)
	{
		hidegui = !hidegui;
		hideGUI(hidegui);
		dirty=true;
	}

	if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_TOGGLE_STATS) && loading_state == ALL_LOADED)
	{
		dirty=true;
		if(mStatsOn==0)
			mStatsOn=1;
		else if(mStatsOn==1)
			mStatsOn=0;
		else if(mStatsOn==2)
			mStatsOn=0;

		if(ow) ow->showDebugOverlay(mStatsOn);
	}

	if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_TOGGLE_MAT_DEBUG))
	{
		if(mStatsOn==0)
			mStatsOn=2;
		else if(mStatsOn==1)
			mStatsOn=2;
		else if(mStatsOn==2)
			mStatsOn=0;
		dirty=true;
		if(ow) ow->showDebugOverlay(mStatsOn);
	}

#ifdef USE_PAGED
	if (INPUTENGINE.getEventBoolValueBounce(EV_GRASS_MORE))
	{
		Vector3 pos = Vector3::ZERO;
		if(current_truck == -1)
			pos = person->getPosition();
		else
			pos = trucks[current_truck]->getPosition();
		setGrassDensity(pos.x, pos.z, 20, true);
	}
#endif //USE_PAGED

#ifdef USE_MYGUI
	if (INPUTENGINE.getEventBoolValueBounce(EV_MAP_INTERACTIVE_TOGGLE, 0.5f) && mtc)
	{
		if(mtc && bigMap)
		{
			if(interactivemap)
			{
				interactivemap=0;
				mtc->setCamZoom(((mapsizex+mapsizez)/2)*0.5); // zoom that fits 1:1 to the map
				mtc->setCamPosition(Vector3(mapsizex/2, hfinder->getHeightAt(mapsizex/2, mapsizez/2) , mapsizez/2), Quaternion(Degree(0), Vector3::UNIT_X));
				mtc->update();
				bigMap->setEntitiesVisibility(true);
				LogManager::getSingleton().logMessage("disabled interactive Map");
			} else
			{
				mtc->setCamZoom(30); // zoom very near
				bigMap->setEntitiesVisibility(false);
				interactivemap=1;
				LogManager::getSingleton().logMessage("enabled interactive Map");
			}
		}
	}

	if (INPUTENGINE.getEventBoolValueBounce(EV_MAP_IN) && interactivemap && mtc)
	{
		//LogManager::getSingleton().logMessage("zoom in");
		if(INPUTENGINE.isKeyDown(OIS::KC_LSHIFT) || INPUTENGINE.isKeyDown(OIS::KC_RSHIFT))
			mtc->setCamZoomRel(4);
		else
			mtc->setCamZoomRel(1);
		mtc->update();
	}
	if (INPUTENGINE.getEventBoolValueBounce(EV_MAP_OUT) && interactivemap && mtc)
	{
		//LogManager::getSingleton().logMessage("zoom out");
		if(INPUTENGINE.isKeyDown(OIS::KC_LSHIFT) || INPUTENGINE.isKeyDown(OIS::KC_RSHIFT))
			mtc->setCamZoomRel(-4);
		else
			mtc->setCamZoomRel(-1);
		mtc->update();
	}
#endif //MYGUI
#ifdef USE_PAGED
//TODO: fix code below
#if 0
	if (INPUTENGINE.getEventBoolValue(EV_GRASS_LESS) && mTimeUntilNextToggle <= 0)
	{
		if(grass)
		{
			Vector3 pos = Vector3::ZERO;
			if(current_truck == -1)
				pos = person->getPosition();
			else
				pos = trucks[current_truck]->getPosition();
			setGrassDensity(pos.x, pos.z, -20, true);
			mTimeUntilNextToggle = 0.2;
		}
	}

	if (INPUTENGINE.getEventBoolValue(EV_GRASS_SAVE) && mTimeUntilNextToggle <= 0)
	{
		if(grass)
		{
			saveGrassDensity();
			mTimeUntilNextToggle = 1;
		}
	}

	if (INPUTENGINE.getEventBoolValue(EV_GRASS_MOST) && mTimeUntilNextToggle <= 0)
	{
		if(grass)
		{
			Vector3 pos = Vector3::ZERO;
			if(current_truck == -1)
				pos = person->getPosition();
			else
				pos = trucks[current_truck]->getPosition();
			setGrassDensity(pos.x, pos.z, 255);
			mTimeUntilNextToggle = 0.2;
		}
	}

	if (INPUTENGINE.getEventBoolValue(EV_GRASS_NONE) && mTimeUntilNextToggle <= 0)
	{
		if(grass)
		{
			Vector3 pos = Vector3::ZERO;
			if(current_truck == -1)
				pos = person->getPosition();
			else
				pos = trucks[current_truck]->getPosition();
			setGrassDensity(pos.x, pos.z, 0);
			mTimeUntilNextToggle = 0.2;
		}
	}
#endif //0
#endif //USE_PAGED
	if (INPUTENGINE.getEventBoolValueBounce(EV_COMMON_OUTPUT_POSITION) && loading_state == ALL_LOADED)
	{
		Vector3 pos = Vector3::ZERO;
		float rotz = 0;
		if(current_truck == -1)
		{
			pos = person->getPosition();
			rotz = person->getOrientation().getYaw().valueDegrees()+180;
		}
		else
		{
			pos = trucks[current_truck]->getPosition();
			Vector3 idir=trucks[current_truck]->nodes[trucks[current_truck]->cameranodepos[0]].RelPosition-trucks[current_truck]->nodes[trucks[current_truck]->cameranodedir[0]].RelPosition;
			rotz = atan2(idir.dotProduct(Vector3::UNIT_X), idir.dotProduct(-Vector3::UNIT_Z));
			rotz = -Radian(rotz).valueDegrees();
		}
		LogManager::getSingleton().logMessage("position-x " + StringConverter::toString(pos.x) + ", "+ StringConverter::toString(pos.y) + ", " + StringConverter::toString(pos.z) + ", 0, " + StringConverter::toString(rotz)+", 0");

	}

	//update window
	if (!mWindow->isAutoUpdated())
	{
#ifdef HAS_EDITOR
		if ((trucked && trucked->dirty)||dirty) {trucked->dirty=false;mWindow->update();}
#else
		if (dirty) {mWindow->update();}
#endif
		else
#if OGRE_PLATFORM == OGRE_PLATFORM_WIN32
			Sleep(10);
#endif
#if OGRE_PLATFORM == OGRE_PLATFORM_LINUX
		usleep(10000);
#endif
#if OGRE_PLATFORM == OGRE_PLATFORM_APPLE
		usleep(10000);
#endif
	}
	// Return true to continue rendering
	return true;
}

void RoRFrameListener::removeTruck(int truck)
{
	if(truck == -1 || truck > free_truck)
		// invalid number
		return;
	if(current_truck == truck)
		setCurrentTruck(-1);

	if(BeamFactory::getSingleton().removeBeam(trucks[truck]))
	{
		// deletion over beamfactory failed, delete by hand
		// then delete the class
		delete trucks[truck];
		// then set the array to zero, so it wont be used anymore
		trucks[truck] = 0;
	}
}

int RoRFrameListener::addTruck(char *fname, Vector3 pos)
{
	Beam *b = BeamFactory::getSingleton().createLocal(pos, Quaternion::ZERO, fname, 0, false, flaresMode);

#ifdef USE_MYGUI
	if(b && bigMap)
	{
		MapEntity *e = bigMap->createNamedMapEntity("Truck"+StringConverter::toString(b->trucknum), MapControl::getTypeByDriveable(b->driveable));
		if(e)
		{
			e->setState(DESACTIVATED);
			e->setVisibility(true);
			e->setPosition(reload_pos);
			e->setRotation(-Radian(b->getHeadingDirectionAngle()));
		}
		return b->trucknum;
	}
#else
	if(b) return b->trucknum;
#endif //MYGUI
	return -1;
}

void RoRFrameListener::shutdown_final()
{
	LogManager::getSingleton().logMessage(" ** Shutdown final");
	if (editorfd) fclose(editorfd);
	if (w) w->prepareShutdown();
	if (dashboard) dashboard->prepareShutdown();
	if (heathaze) heathaze->prepareShutdown();
	if (current_truck!=-1) trucks[current_truck]->prepareShutdown();
	INPUTENGINE.prepareShutdown();

	// destroy input things properly
	//mInputManager->destroyInputObject(mMouse); mMouse = 0;
	//mInputManager->destroyInputObject(mKeyboard); mKeyboard = 0;
	//OIS::InputManager::destroyInputSystem(mInputManager); mInputManager = 0;

	shutdownall=true;
	//terrainmaterial->getBestTechnique()->getPass(0)->getTextureUnitState(0)->setTextureName(terrainoriginalmaterial);
}

void RoRFrameListener::shutdown_pre()
{
	LogManager::getSingleton().logMessage(" ** Shutdown preparation");
	//GUIManager::getSingleton().shutdown();
#ifdef USE_SOCKETW
	if (net) net->disconnect();
#endif //SOCKETW
	showcredits=1;
	loading_state=EXITING;
	if(ow) OverlayManager::getSingleton().getByName("tracks/CreditsOverlay")->show();
#ifdef USE_OPENAL
	if(ssm) ssm->soundEnable(false);
#endif // OPENAL
#ifdef USE_OIS_G27
	//logitech G27 LEDs tachometer
	if (leds)
	{
		leds->play(0, 10, 20);//stop the LEDs
	}
#endif //OIS_G27
}

void RoRFrameListener::hideMap()
{
#ifdef USE_MYGUI
	if(bigMap)
		bigMap->setVisibility(false);
#endif // MYGUI
}

void RoRFrameListener::processConsoleInput()
{
	UTFString chatline = INPUTENGINE.getKeyLine();

	if (chatline.size()==0) return;
#ifdef USE_SOCKETW
	if(netmode)
	{
		NETCHAT.addText(net->getNickname(true) + ": ^7" + ColoredTextAreaOverlayElement::StripColors(chatline), false);
		if(netChat) netChat->sendChat(chatline);
	} else
#endif // SOCKETW
		NETCHAT.addText(_L("^8 Player: ^7") + chatline);

	NETCHAT.setEnterText("", false);
	//NETCHAT.noScroll();
}

void RoRFrameListener::initializeCompontents()
{
	// load map
#ifdef USE_MYGUI
	LoadingWindow::get()->setProgress(0, _L("Loading Terrain"));
	bool disableMap = (SETTINGS.getSetting("disableOverViewMap") == "Yes");

	// map must be loaded before lua!
	// init the map
	if(!disableMap)
	{
		bigMap = new MapControl((int)mapsizex, (int)mapsizez);
		// important: update first!
		bigMap->updateRenderMetrics(mWindow);
		bigMap->setVisibility(true);
		if(mtc) mtc->update();
		//make it small again
		bigMap->updateRenderMetrics(mWindow);
		bigMap->setPosition(0, 0.81, 0.14, 0.19, mWindow);
		//bigMap->setPosition(0, 0, 1, 1);
		//bigMap->resizeToScreenRatio(win);
	}
#endif // MYGUI

	// load lua and collisions
#ifdef USE_LUA
	//setup lua
	LogManager::getSingleton().logMessage("Loading LUA Script engine." );
	lua=new LuaSystem(this);
	//setup collision system
	collisions=new Collisions(lua, this, debugCollisions);

	if(!netmode && lua)
		lua->loadTerrain(loadedTerrain);
#else
	collisions=new Collisions(this, debugCollisions);
#endif
	// load AS
#ifdef USE_ANGELSCRIPT
	ScriptEngine::getSingleton().setCollisions(collisions);
	if(!netmode)
	{
		LogManager::getSingleton().logMessage("Loading Angelscript Script engine." );
		if(ResourceGroupManager::getSingleton().resourceExistsInAnyGroup(loadedTerrain+".as"))
			ScriptEngine::getSingleton().loadTerrainScript(loadedTerrain+".as");
	}
#endif

	// update icollisions instance in factory
	BeamFactory::getSingleton().icollisions = collisions;

	if(person) person->setCollisions(collisions);
#ifdef USE_MYGUI
	GUI_Friction::getSingleton().setCollisions(collisions);
#endif //MYGUI

	// advanced camera collision tools
	mCollisionTools = new MOC::CollisionTools(mSceneMgr);
	// set how far we want the camera to be above ground
	mCollisionTools->setHeightAdjust(0.2f);

#ifdef USE_XFIRE
	updateXFire();
#endif

}

void RoRFrameListener::loadOgitorTerrain(String terrainfile)
{
	// find the group the terrain is in
	Ogre::String group = "";
	CACHE.checkResourceLoaded(terrainfile, group);

	// start up the dotsceneloader
    mLoader = new DotSceneLoader();
    mLoader->parseDotScene(terrainfile, group, mSceneMgr);

	// next, setup the heightfinder
	{
		hfinder = new OgitorSceneHeightFinder(mLoader);
		collisions->setHfinder(hfinder);
		if(person) person->setHFinder(hfinder);
		// update hfinder instance in factory
		BeamFactory::getSingleton().mfinder = hfinder;
	}



}

void RoRFrameListener::loadTerrain(String terrainfile)
{
	ScopeLog log("terrain_"+terrainfile);

	// check if the resource is loaded
	if(!CACHE.checkResourceLoaded(terrainfile))
	{
		LogManager::getSingleton().logMessage("Terrain not found: " + terrainfile);
		showError(_L("Terrain loading error"), _L("Terrain not found: ") + terrainfile);
		exit(123);
	}

	loadedTerrain = terrainfile;

	initializeCompontents();

	if(terrainfile.find(".scene") != String::npos)
	{
		LogManager::getSingleton().logMessage("Loading Ogitor scene format: " + terrainfile);
		loadOgitorTerrain(terrainfile);

		LoadingWindow::get()->hide();
		return;
	}

	if(terrainfile.find(".terrn") != String::npos)
	{
		LogManager::getSingleton().logMessage("Loading classic terrain format: " + terrainfile);
		loadClassicTerrain(terrainfile);
		
		LoadingWindow::get()->hide();
		return;
	}

	// exit on unkown terrain handler
	LogManager::getSingleton().logMessage("Terrain not supported, unknown format: " + terrainfile);
	showError(_L("Terrain loading error"), _L("Terrain not supported, unknown format: ") + terrainfile);
	exit(123);

}

void RoRFrameListener::loadClassicTerrain(String terrainfile)
{	
	//we load a classic terrain
	//FILE *fd;
	char geom[1024];
	char sandstormcubemap[255]="";
	char caelumconfig[255]="ror_default_sky"; // setup some default
	char line[1024];
	float r,g,b;
	float cx,cy,cz;
	String group="";
	try
	{
		group = ResourceGroupManager::getSingleton().findGroupContainingResource(terrainfile);
	}catch(...)
	{
	}
	if(group == "")
	{
		// we need to do a bit more here, since this can also happen on joining a MP server, in that case the user should get a better error message ...
		LogManager::getSingleton().logMessage("Terrain not found: " + String(terrainfile));
		showError(_L("Terrain loading error"), _L("Terrain not found: ") + terrainfile);
		exit(125);
	}


	// set the terrain cache entry
	loaded_terrain = CACHE.getResourceInfo(terrainfile);

	DataStreamPtr ds=ResourceGroupManager::getSingleton().openResource(terrainfile, group);
	ds->readLine(line, 1023);
	//geometry
	ds->readLine(geom, 1023);
	//colour
	ds->readLine(line, 1023);
	//water stuff
	float waterline=-9999;
	if (line[0]=='w')
	{
		sscanf(line+1, "%f", &waterline);
		//fscanf(fd," %[^\n\r]",line);
		ds->readLine(line, 1023);
	};
	//Caelum maps
	if (!strncmp(line,"caelum", 6))
	{
		// deprecated
		ds->readLine(line, 1023);
	};

	sscanf(line,"%f, %f, %f",&r,&g,&b);
	//coordinates
	//fscanf(fd," %[^\n\r]",line);
	ds->readLine(line, 1023);
	sscanf(line, "%f, %f, %f, %f, %f, %f, %f, %f, %f",&truckx,&trucky,&truckz,&cx,&cy,&cz, &persostart.x, &persostart.y, &persostart.z);
	spawn_location_t spl;
	memset(&spl, 0, sizeof(spl));
	spl.pos = Vector3(truckx, trucky, truckz);
	spl.rot = Quaternion::ZERO;
	netSpawnPos["truck"] = spl;
	netSpawnPos["airplane"] = spl;
	netSpawnPos["boat"] = spl;
	netSpawnPos["car"] = spl;

#if OGRE_VERSION>0x010602
	Vector4 splitPoints;
#endif

	//shadows
	new ShadowManager(mSceneMgr, mWindow, mCamera);
	ShadowManager::getSingleton().loadConfiguration();

	ColourValue fadeColour(r,g,b);

	bool fogEnable = true;
	if (SETTINGS.getSetting("Fog") == "No")
	{
		fogEnable = false;
		fogmode=0;
	}

	float farclipPercent = 0.3;
	if (SETTINGS.getSetting("FarClip Percent") != "")
		farclipPercent = StringConverter::parseInt(SETTINGS.getSetting("FarClip Percent"));

	float farclip = 1000;
	terrainxsize=1000;
	terrainzsize=1000;

	bool disableTetrrain=false;

	{
		//compute farclip from terrain size
	    ConfigFile config;
		ResourceGroupManager& rgm = ResourceGroupManager::getSingleton();
		String group="";
		try
		{
			group = ResourceGroupManager::getSingleton().findGroupContainingResource(geom);
		}catch(...)
		{
		}
		if(group == "")
			return;
		DataStreamPtr stream=rgm.openResource(geom, group);
		config.load( stream );
	    String val;
		float fval=0.0f;
		val = config.getSetting("PageWorldX");
		if ( !val.empty() )
			fval = atof( val.c_str() );
		farclip=fval;
		terrainxsize=fval;
		val = config.getSetting("PageWorldZ");
		if ( !val.empty() )
			fval = atof( val.c_str() );
		if (fval>farclip) farclip=fval;
		terrainzsize=fval;
		//we take farclip=1/3rd the terrain size (default)
		farclip = farclip * farclipPercent / 100.0f;
		if (farclip<1000.0)
			//cap for small terrains
			farclip=1000.0;

		disableTetrrain = (config.getSetting("disable") != "");
	}

	String fcos = SETTINGS.getSetting("Farclip");
	if(fcos != "")
		farclip = atof(fcos.c_str());

	LogManager::getSingleton().logMessage("Farclip computed:" + StringConverter::toString(farclip));

	float fogstart = 0;


	Light *mainLight = 0;
#ifdef USE_CAELUM
	bool useCaelum = SETTINGS.getSetting("Sky effects")=="Caelum (best looking, slower)";
	if(!useCaelum)
	{
		mainLight = mSceneMgr->createLight("MainLight");
		//directional light for shadow
		mainLight->setType(Light::LT_DIRECTIONAL);
		mainLight->setDirection(0.785, -0.423, 0.453);
	}
#else // USE_CAELUM
	mainLight = mSceneMgr->createLight("MainLight");
	//directional light for shadow
	mainLight->setType(Light::LT_DIRECTIONAL);
	mainLight->setDirection(0.785, -0.423, 0.453);
#endif // USE_CAELUM

#ifdef USE_CAELUM
	//Caelum skies
	if (useCaelum)
	{
		//mCamera->setNearClipDistance (0.01);
		mCamera->setFarClipDistance( farclip*1.733 );
		new SkyManager();

		SkyManager::getSingleton().init(mScene, mWindow, mCamera);
		mainLight = SkyManager::getSingleton().getMainLight();
	}
	else
#endif //CAELUM
	{
		fogmode=3;
		fogstart = farclip * 0.8;
//		if (SETTINGS.getSetting("Sandstorm Fog Start") != "")
//			fogstart = StringConverter::parseLong(SETTINGS.getSetting("Sandstorm Fog Start"));

		// Create a light
		if(mainLight)
		{
			//directional light for shadow
			mainLight->setType(Light::LT_DIRECTIONAL);
			mainLight->setDirection(0.785, -0.423, 0.453);

			mainLight->setDiffuseColour(fadeColour);
			mainLight->setSpecularColour(fadeColour);
		}

		mCamera->setFarClipDistance( farclip*1.733 );

		// Fog
		// NB it's VERY important to set this before calling setWorldGeometry
		// because the vertex program picked will be different
		if(fogEnable)
		{
			fogdensity = 0.001;
			mSceneMgr->setFog(FOG_LINEAR, fadeColour, fogdensity, fogstart, farclip);
		} else
			mSceneMgr->setFog(FOG_LINEAR, fadeColour, 0, 999998, 999999);

		//mSceneMgr->setSkyBox(true, sandstormcubemap, farclip);
		//mSceneMgr->setSkyDome(true, "Examples/CloudySky", 5, 8);

		mCamera->getViewport()->setBackgroundColour(fadeColour);
	}

	bool newTerrainMode = (SETTINGS.getSetting("new Terrain Mode") == "Yes");

	MaterialPtr terMat = (MaterialPtr)(MaterialManager::getSingleton().getByName("TerrainSceneManager/Terrain"));
	{
		// load configuration from STM (sizes)
		ConfigFile cfg;
		String group="";
		try
		{
			group = ResourceGroupManager::getSingleton().findGroupContainingResource(String(geom));
		}catch(...)
		{
		}
		if(group == "")
			return;
		DataStreamPtr ds_config = ResourceGroupManager::getSingleton().openResource(String(geom), group);
		cfg.load(ds_config, "\t:=", false);

		// X and Z scale
		String tmpSize = cfg.getSetting("PageWorldX");
		if (tmpSize != String(""))
			mapsizex = atof(tmpSize.c_str());

		tmpSize = cfg.getSetting("PageWorldZ");
		if (tmpSize != String(""))
			mapsizez = atof(tmpSize.c_str());
#ifdef USE_MYGUI
		if(bigMap)
			bigMap->setWorldSize(mapsizex, mapsizez);
#endif //MYGUI

		if(!newTerrainMode && !disableTetrrain)
		{
			// classic mode
			mSceneMgr->setWorldGeometry(geom);
		} else if (newTerrainMode && !disableTetrrain)
		{
			// new terrain mode
			// new terrain
			int pageSize = StringConverter::parseInt(cfg.getSetting("PageSize"));
			int worldSize = StringConverter::parseInt(cfg.getSetting("PageWorldX"));
			int pageMaxHeight = StringConverter::parseInt(cfg.getSetting("MaxHeight"));

			String TERRAIN_FILE_PREFIX  = String(geom); //"testTerrain";
			String TERRAIN_FILE_SUFFIX  = "mapbin";
			float TERRAIN_WORLD_SIZE    = worldSize; //1000.0f; // PageWorldX?
			int TERRAIN_SIZE            = pageSize;
			int TERRAIN_PAGE_MIN_X=0, TERRAIN_PAGE_MAX_X=0;
			int TERRAIN_PAGE_MIN_Y=0, TERRAIN_PAGE_MAX_Y=0;
			bool usepaging = (cfg.getSetting("UsePaging") == "1");
			if(usepaging)
			{
				TERRAIN_PAGE_MAX_X = StringConverter::parseInt(cfg.getSetting("Pages_X"));
				TERRAIN_PAGE_MAX_Y = StringConverter::parseInt(cfg.getSetting("Pages_Y"));
			}
			bool mTerrainsImported=false;
			TerrainPaging* mTerrainPaging=0;
			PageManager* mPageManager=0;

			Vector3 mTerrainPos(0,0,0);
			mTerrainGroup = OGRE_NEW TerrainGroup(mSceneMgr, Terrain::ALIGN_X_Z, TERRAIN_SIZE, TERRAIN_WORLD_SIZE);
			mTerrainGroup->setFilenameConvention(TERRAIN_FILE_PREFIX, TERRAIN_FILE_SUFFIX);
			mTerrainGroup->setOrigin(mTerrainPos);

			new TerrainGlobalOptions();
			// Configure global
			TerrainGlobalOptions::getSingleton().setMaxPixelError(StringConverter::parseInt(cfg.getSetting("MaxPixelError")));
			// testing composite map
			TerrainGlobalOptions::getSingleton().setCompositeMapDistance(300);
			//mTerrainGlobals->setUseRayBoxDistanceCalculation(true);
			//mTerrainGlobals->getDefaultMaterialGenerator()->setDebugLevel(1);
			//mTerrainGlobals->setLightMapSize(256);

			TerrainGlobalOptions::getSingleton().setLightMapSize(256);
			TerrainGlobalOptions::getSingleton().setCastsDynamicShadows(false);
			// Important to set these so that the terrain knows what to use for derived (non-realtime) data
			if(mainLight) TerrainGlobalOptions::getSingleton().setLightMapDirection(mainLight->getDerivedDirection());
			TerrainGlobalOptions::getSingleton().setCompositeMapAmbient(mSceneMgr->getAmbientLight());
			//mTerrainGlobals->setCompositeMapAmbient(ColourValue::Red);
			if(mainLight) TerrainGlobalOptions::getSingleton().setCompositeMapDiffuse(mainLight->getDiffuseColour());

			// Configure default import settings for if we use imported image
			Terrain::ImportData& defaultimp = mTerrainGroup->getDefaultImportSettings();
			defaultimp.terrainSize  = TERRAIN_SIZE;
			defaultimp.worldSize    = TERRAIN_WORLD_SIZE;

			defaultimp.inputScale   = pageMaxHeight;
			defaultimp.minBatchSize = StringConverter::parseInt(cfg.getSetting("minBatchSize"));;
			defaultimp.maxBatchSize = StringConverter::parseInt(cfg.getSetting("maxBatchSize"));;
			// textures
			defaultimp.layerList.resize(3);
			defaultimp.layerList[0].worldSize = 10;
			defaultimp.layerList[0].textureNames.push_back("dirt_grayrocky_diffusespecular.dds");
			defaultimp.layerList[0].textureNames.push_back("dirt_grayrocky_normalheight.dds");
			defaultimp.layerList[1].worldSize = 10;
			defaultimp.layerList[1].textureNames.push_back("growth_weirdfungus-03_diffusespecular.dds");
			defaultimp.layerList[1].textureNames.push_back("growth_weirdfungus-03_normalheight.dds");
			defaultimp.layerList[2].worldSize = 20;
			defaultimp.layerList[2].textureNames.push_back("grass_green-01_diffusespecular.dds");
			defaultimp.layerList[2].textureNames.push_back("grass_green-01_normalheight.dds");

			String filename = mTerrainGroup->generateFilename(0, 0);
			bool paging = (ResourceGroupManager::getSingleton().resourceExists(mTerrainGroup->getResourceGroup(), filename));
			if(!paging)
			{
				for (long x = TERRAIN_PAGE_MIN_X; x <= TERRAIN_PAGE_MAX_X; ++x)
				{
					for (long y = TERRAIN_PAGE_MIN_Y; y <= TERRAIN_PAGE_MAX_Y; ++y)
					{
						String filename = mTerrainGroup->generateFilename(x, y);
						if (ResourceGroupManager::getSingleton().resourceExists(mTerrainGroup->getResourceGroup(), filename))
						{
							mTerrainGroup->defineTerrain(x, y);
						}
						else
						{
							String heightmapString = "Heightmap.image." + StringConverter::toString(x) + "." + StringConverter::toString(y);
							String heightmapFilename = cfg.getSetting(heightmapString);
							Image img;
							if(heightmapFilename.find(".raw") != String::npos)
							{
								int rawSize = StringConverter::parseInt(cfg.getSetting(heightmapString + ".size"));
								int bpp = StringConverter::parseInt(cfg.getSetting(heightmapString + ".bpp"));

								// load raw data
								DataStreamPtr stream = ResourceGroupManager::getSingleton().openResource(heightmapFilename);
								LogManager::getSingleton().logMessage(" loading RAW image: " + StringConverter::toString(stream->size()) + " / " + StringConverter::toString(rawSize*rawSize*bpp));
								PixelFormat pformat = PF_L8;
								if(bpp == 2)
									pformat = PF_L16;
								img.loadRawData(stream, rawSize, rawSize, 1, pformat);
							} else
							{
								img.load(heightmapFilename, ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
							}

							//if (x % 2 != 0)
							//	img.flipAroundY();
							//if (y % 2 != 0)
							//	img.flipAroundX();

							mTerrainGroup->defineTerrain(x, y, &img);
							mTerrainsImported = true;
						}
					}
				}
				// sync load since we want everything in place when we start
				mTerrainGroup->loadAllTerrains(true);

				for (long x = TERRAIN_PAGE_MIN_X; x <= TERRAIN_PAGE_MAX_X; ++x)
				{
					for (long y = TERRAIN_PAGE_MIN_Y; y <= TERRAIN_PAGE_MAX_Y; ++y)
					{
						Terrain* terrain = mTerrainGroup->getTerrain(x,y);
						if(!terrain) continue;
						TerrainLayerBlendMap* blendMap0 = terrain->getLayerBlendMap(1);
						TerrainLayerBlendMap* blendMap1 = terrain->getLayerBlendMap(2);
						Real minHeight0 = 70;
						Real fadeDist0 = 40;
						Real minHeight1 = 70;
						Real fadeDist1 = 15;
						float* pBlend1 = blendMap1->getBlendPointer();
						for (Ogre::uint16 yb = 0; yb < terrain->getLayerBlendMapSize(); ++yb)
						{
							for (Ogre::uint16 xb = 0; xb < terrain->getLayerBlendMapSize(); ++xb)
							{
								Real tx, ty;

								blendMap0->convertImageToTerrainSpace(xb, yb, &tx, &ty);
								Real height = terrain->getHeightAtTerrainPosition(tx, ty);
								Real val = (height - minHeight0) / fadeDist0;
								val = Math::Clamp(val, (Real)0, (Real)1);
								//*pBlend0++ = val;

								val = (height - minHeight1) / fadeDist1;
								val = Math::Clamp(val, (Real)0, (Real)1);
								*pBlend1++ = val;
							}
						}
						blendMap0->dirty();
						blendMap1->dirty();
						//blendMap0->loadImage("blendmap1.png", ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
						blendMap0->update();
						blendMap1->update();

						// set up a colour map
						String textureString = "Texture.image." + StringConverter::toString(x) + "." + StringConverter::toString(y);
						String textureFilename = cfg.getSetting(textureString);
						if (!terrain->getGlobalColourMapEnabled())
						{
							terrain->setGlobalColourMapEnabled(true);
							Image colourMap;
							colourMap.load(textureFilename, ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME);
							terrain->getGlobalColourMap()->loadImage(colourMap);
						}
					}
				}
				mTerrainGroup->saveAllTerrains(false);
			} else
			{
				// paging, yeah!
				// Paging setup
				mPageManager = OGRE_NEW PageManager();
				// Since we're not loading any pages from .page files, we need a way just
				// to say we've loaded them without them actually being loaded
				mPageManager->setPageProvider(&mDummyPageProvider);
				mPageManager->addCamera(mCamera);
				mTerrainPaging = OGRE_NEW TerrainPaging(mPageManager);
				PagedWorld* world = mPageManager->createWorld();
				mTerrainPaging->createWorldSection(world, mTerrainGroup, TERRAIN_SIZE, TERRAIN_SIZE*1.2f,
					TERRAIN_PAGE_MIN_X, TERRAIN_PAGE_MIN_Y,
					TERRAIN_PAGE_MAX_X, TERRAIN_PAGE_MAX_Y);
			}

			mTerrainGroup->freeTemporaryResources();
		}
	}


	// get vegetation mode
	int pagedMode = 0; //None
	float pagedDetailFactor = 0;
	if(SETTINGS.getSetting("Vegetation") == "None (fastest)")
	{
		pagedMode = 0;
		pagedDetailFactor = 0.001;
	}
	else if(SETTINGS.getSetting("Vegetation") == "20%")
	{
		pagedMode = 1;
		pagedDetailFactor = 0.2;
	}
	else if(SETTINGS.getSetting("Vegetation") == "50%")
	{
		pagedMode = 2;
		pagedDetailFactor = 0.5;
	}
	else if(SETTINGS.getSetting("Vegetation") == "Full (best looking, slower)")
	{
		pagedMode = 3;
		pagedDetailFactor = 1;
	}

	// Define the required skyplane
	Plane plane;
	// 1000 world units from the camera
	plane.d = 200;
	// Above the camera, facing down
	plane.normal = -Vector3::UNIT_Y;


	if(!terMat.isNull())
		terrainmaterial = terMat.get();
	if(terrainmaterial)
		LogManager::getSingleton().logMessage("using Terrain Material '"+terrainmaterial->getName()+"'");

	//create sky material
	//			MaterialPtr skmat=(MaterialPtr)(MaterialManager::getSingleton().create("Skycol", "Standard"));
	//			Technique* sktechnique = skmat->getTechnique(0);
	//			Pass* skpass = sktechnique->getPass(0);
	//			skpass->setDepthWriteEnabled(false);
	//			skpass->setLightingEnabled(false);
	//			TextureUnitState* sktunit=skpass->createTextureUnitState();
	//			sktunit->setColourOperationEx(LBX_MODULATE, LBS_MANUAL, LBS_CURRENT, fadeColour);

	//		mSceneMgr->setSkyPlane(true, plane, "tracks/skyplanecol", 1000, 1, true, 0.5, 100, 100);
	//		mSceneMgr->setSkyBox(true, "tracks/skycol", 1000);

	//bloom effect
	/*
	// replaced by HDR
	if (SETTINGS.getSetting("Bloom")=="Yes")
	{
		CompositorManager::getSingleton().addCompositor(mCamera->getViewport(),"Bloom");
		CompositorManager::getSingleton().setCompositorEnabled(mCamera->getViewport(), "Bloom", true);
	}*/

	// first compositor: HDR!
	// HDR if wished
	bool useHDR = (SETTINGS.getSetting("HDR") == "Yes");
	if(useHDR)
		initHDR();

	// SSAO?
	bool useSSAO = (SETTINGS.getSetting("SSAO") == "Yes");
	if(useSSAO)
		initSSAO();

	// DOF?
	bool useDOF = (SETTINGS.getSetting("DOF") == "Yes");
	if(useDOF)
	{
		mDOF = new DOFManager(mRoot, mCamera, mSceneMgr);
		mDOF->setEnabled(true);
		// debug enabled via event
		mDOF->setDebugEnabled(false);
	}


	if (SETTINGS.getSetting("Glow") == "Yes")
	{
		CompositorManager::getSingleton().addCompositor(mCamera->getViewport(), "Glow");
		CompositorManager::getSingleton().setCompositorEnabled(mCamera->getViewport(), "Glow", true);
		GlowMaterialListener *gml = new GlowMaterialListener();
		Ogre::MaterialManager::getSingleton().addListener(gml);
	}

	// for menu effects
	// not working currently :(
	if (SETTINGS.getSetting("GaussianBlur") == "Yes")
	{
		CompositorManager::getSingleton().addCompositor(mCamera->getViewport(),"Gaussian Blur");
		CompositorManager::getSingleton().setCompositorEnabled(mCamera->getViewport(), "Gaussian Blur", false);
	}

	// Motion blur stuff :)
	if (SETTINGS.getSetting("Motion blur")=="Yes")
	{
		/// Motion blur effect
		CompositorPtr comp3 = CompositorManager::getSingleton().create(
			"MotionBlur", ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME
			);
		{
			CompositionTechnique *t = comp3->createTechnique();
			{
				CompositionTechnique::TextureDefinition *def = t->createTextureDefinition("scene");
				def->width = 0;
				def->height = 0;
#if OGRE_VERSION>0x010602
				def->formatList.push_back(PF_R8G8B8);
#else
				def->format = PF_R8G8B8;
#endif //OGRE_VERSION
			}
			{
				CompositionTechnique::TextureDefinition *def = t->createTextureDefinition("sum");
				def->width = 0;
				def->height = 0;
#if OGRE_VERSION>0x010602
				def->formatList.push_back(PF_R8G8B8);
#else
				def->format = PF_R8G8B8;
#endif //OGRE_VERSION
			}
			{
				CompositionTechnique::TextureDefinition *def = t->createTextureDefinition("temp");
				def->width = 0;
				def->height = 0;
#if OGRE_VERSION>0x010602
				def->formatList.push_back(PF_R8G8B8);
#else
				def->format = PF_R8G8B8;
#endif //OGRE_VERSION
			}
			/// Render scene
			{
				CompositionTargetPass *tp = t->createTargetPass();
				tp->setInputMode(CompositionTargetPass::IM_PREVIOUS);
				tp->setOutputName("scene");
			}
			/// Initialisation pass for sum texture
			{
				CompositionTargetPass *tp = t->createTargetPass();
				tp->setInputMode(CompositionTargetPass::IM_PREVIOUS);
				tp->setOutputName("sum");
				tp->setOnlyInitial(true);
			}
			/// Do the motion blur
			{
				CompositionTargetPass *tp = t->createTargetPass();
				tp->setInputMode(CompositionTargetPass::IM_NONE);
				tp->setOutputName("temp");
				{ CompositionPass *pass = tp->createPass();
				pass->setType(CompositionPass::PT_RENDERQUAD);
				pass->setMaterialName("Ogre/Compositor/Combine");
				pass->setInput(0, "scene");
				pass->setInput(1, "sum");
				}
			}
			/// Copy back sum texture
			{
				CompositionTargetPass *tp = t->createTargetPass();
				tp->setInputMode(CompositionTargetPass::IM_NONE);
				tp->setOutputName("sum");
				{ CompositionPass *pass = tp->createPass();
				pass->setType(CompositionPass::PT_RENDERQUAD);
				pass->setMaterialName("Ogre/Compositor/Copyback");
				pass->setInput(0, "temp");
				}
			}
			/// Display result
			{
				CompositionTargetPass *tp = t->getOutputTargetPass();
				tp->setInputMode(CompositionTargetPass::IM_NONE);
				{ CompositionPass *pass = tp->createPass();
				pass->setType(CompositionPass::PT_RENDERQUAD);
				pass->setMaterialName("Ogre/Compositor/MotionBlur");
				pass->setInput(0, "sum");
				}
			}
		}
		CompositorManager::getSingleton().addCompositor(mCamera->getViewport(),"MotionBlur");
		CompositorManager::getSingleton().setCompositorEnabled(mCamera->getViewport(), "MotionBlur", true);
	}
	// End of motion blur :(

	//SUNBURN
	if (SETTINGS.getSetting("Sunburn")=="Yes")
	{
		CompositorManager::getSingleton().addCompositor(mCamera->getViewport(),"Sunburn");
		CompositorManager::getSingleton().setCompositorEnabled(mCamera->getViewport(), "Sunburn", true);
	}



	//hack
	// now with extensive error checking
	if (CompositorManager::getSingleton().hasCompositorChain(mCamera->getViewport()))
	{
	//	//CompositorManager::getSingleton().getCompositorChain(mCamera->getViewport())->getCompositor(0)->getTechnique()->getOutputTargetPass()->getPass(0)->setClearColour(fadeColour);
		CompositorInstance *co = CompositorManager::getSingleton().getCompositorChain(mCamera->getViewport())->_getOriginalSceneCompositor();
		if(co)
		{
			CompositionTechnique *ct = co->getTechnique();
			if(ct)
			{
				CompositionTargetPass *ctp = ct->getOutputTargetPass();
				if(ctp)
				{
					CompositionPass *p = ctp->getPass(0);
					if(p)
						p->setClearColour(fadeColour);
				}
			}
		}
	}


	// not such ugly anymore: read .raw heightmap filename out of the terrain .cfg file
	{
		ConfigFile config;
		ResourceGroupManager& rgm = ResourceGroupManager::getSingleton();
		String group="";
		try
		{
			group = ResourceGroupManager::getSingleton().findGroupContainingResource(String(geom));
		}catch(...)
		{
		}
		if(group == "")
			return;
		DataStreamPtr stream=rgm.openResource(geom, group);
		config.load(stream);
		String val = config.getSetting("Heightmap.image");
		if (!val.empty())
		{
			strcpy(terrainmap, val.c_str());
		} else
		{
			// bad ugly hack
			strcpy(terrainmap, geom);
			terrainmap[strlen(terrainmap)-3]='r';
			terrainmap[strlen(terrainmap)-2]='a';
			terrainmap[strlen(terrainmap)-1]='w';
		}
		//ensure file gets closed again using this braces
	}

	//set terrain map
	//MaterialPtr mat=(MaterialPtr)(MaterialManager::getSingleton().getByName("tracks/BigMap"));
	//if(terrainmaterial && bigMap)
	//mat->getTechnique(0)->getPass(0)->getTextureUnitState(0)->setTextureName(terrainmaterial->getTechnique(0)->getPass(0)->getTextureUnitState(0)->getTextureName());
	//	bigMap->setBackground(terrainmaterial->getTechnique(0)->getPass(0)->getTextureUnitState(0)->getTextureName());

	mCamera->setPosition(Vector3(cx,cy,cz));

	//water!
	bool useHydrax = (SETTINGS.getSetting("Hydrax") == "Yes");
	String hydraxConfig = "hydrax_default.hdx";

	if (waterline != -9999)
	{
		bool usewaves=(SETTINGS.getSetting("Waves")=="Yes");

		// disable waves in multiplayer
		if(net)
			usewaves=false;

#ifndef HYDRAX
	useHydrax=false;
#endif

    if(useHydrax)
    {
#ifdef USE_HYDRAX
      w = new HydraxWater(WATER_BASIC, mCamera, mSceneMgr, mWindow, waterline, &mapsizex, &mapsizez, usewaves);
#endif
	}
    else if(!useHydrax)
		{
			if (SETTINGS.getSetting("Water effects")=="None")
				w=0;
			else if (SETTINGS.getSetting("Water effects")=="Basic (fastest)")
				w=new WaterOld(WATER_BASIC, mCamera, mSceneMgr, mWindow, waterline, &mapsizex, &mapsizez, usewaves);
			else if (SETTINGS.getSetting("Water effects")=="Reflection")
				w=new WaterOld(WATER_REFLECT, mCamera, mSceneMgr, mWindow, waterline, &mapsizex, &mapsizez, usewaves);
			else if (SETTINGS.getSetting("Water effects")=="Reflection + refraction (speed optimized)")
				w=new WaterOld(WATER_FULL_SPEED, mCamera, mSceneMgr, mWindow, waterline, &mapsizex, &mapsizez, usewaves);
			else if (SETTINGS.getSetting("Water effects")=="Reflection + refraction (quality optimized)")
				w=new WaterOld(WATER_FULL_QUALITY, mCamera, mSceneMgr, mWindow, waterline, &mapsizex, &mapsizez, usewaves);
		}
	}
	if(w) w->setFadeColour(fadeColour);
	if(person) person->setWater(w);
	BeamFactory::getSingleton().w = w;
	DustManager::getSingleton().setWater(w);

	//environment map
	if (SETTINGS.getSetting("Envmapdisable")!="Yes")
	{
		envmap=new Envmap(mSceneMgr, mWindow, mCamera, SETTINGS.getSetting("Envmap")=="Yes");
	}

	//mirrors!
	if(SETTINGS.getSetting("Mirrors")=="Yes")
	{
		mirror = new Mirrors(mSceneMgr, mWindow, mCamera);
	}
	BeamFactory::getSingleton().mmirror0 = mirror;

	//dashboard
	if(SETTINGS.getSetting("Dashboard")=="Yes")
	{
		dashboard = new Dashboard(mSceneMgr,mWindow);
	}
	else
	{
		//we must do something to fix the texture mapping
		MaterialPtr mat = MaterialManager::getSingleton().getByName("renderdash");
		mat->getTechnique(0)->getPass(0)->getTextureUnitState(0)->setTextureName("virtualdashboard.dds");

	}


	//setup heightfinder
	float wheight=0.0;
	if (w) wheight=w->getHeight()-30.0;

	// we choose the heightfinder depending on whether we use the classical
	// terrain or the new one
	if(newTerrainMode)
		hfinder = new NTHeightFinder(mTerrainGroup, Vector3::ZERO);
	else
		hfinder = new TSMHeightFinder(geom, terrainmap, wheight);

	collisions->setHfinder(hfinder);
	if(person) person->setHFinder(hfinder);

	// update hfinder instance in factory
	BeamFactory::getSingleton().mfinder = hfinder;

	// set camera to some nice spot, overviewing the terrain, showing the loading progress
	if(spl.pos != Vector3::ZERO)    mCamera->setPosition(spl.pos);
	if(spl.rot != Quaternion::ZERO) mCamera->setOrientation(spl.rot);

#ifdef USE_MYGUI
	if(bigMap)
	{
		mtc = new MapTextureCreator(mScene, mCamera, this);
		//mtc->setCamClip(mapsizex*1.2);
		mtc->setCamZoom(((mapsizex+mapsizez)/2)*0.5);
		mtc->setCamPosition(Vector3(mapsizex/2, hfinder->getHeightAt(mapsizex/2, mapsizez/2) , mapsizez/2), Quaternion(Degree(0), Vector3::UNIT_X));
		mtc->setAutoUpdated(false); // important!
		bigMap->setVisibility(false);
		bigMap->setMapTexture(mtc->getRTName());
	}
#endif // MYGUI

	// fix the person starting position
	if(persostart.isZeroLength() && !spl.pos.isZeroLength())
		if(hfinder)
			persostart = Vector3(spl.pos.x, hfinder->getHeightAt(spl.pos.x, spl.pos.z), spl.pos.z);
		else
			persostart = spl.pos;

	//prepare road2
	proceduralManager = new ProceduralManager(mSceneMgr, hfinder, collisions);

	Vector3 r2lastpos=Vector3::ZERO;
	Quaternion r2lastrot=Quaternion::IDENTITY;
	int r2counter=0;

	//prepare for baking
	SceneNode *bakeNode=mSceneMgr->getRootSceneNode()->createChildSceneNode();
	//load objects
	//while (!feof(fd))
	bool proroad=false;
#ifdef USE_PAGED
	int treemode=0;
	treeLoader = 0;
	Entity *curTree = 0;
	int treecounter=0;
	float treescale_min=1,treescale_max=1;
	String treename="";
#endif

	ProceduralObject po;
	po.loadingState = -1;
	int r2oldmode=0;

	int lastprogress = -1;
	while (!ds->eof())
	{
		int progress = ((float)(ds->tell()) / (float)(ds->size())) * 100.0f;
		if(progress-lastprogress > 20)
		{
#ifdef USE_MYGUI
			LoadingWindow::get()->setProgress(progress, _L("Loading Terrain"));
#endif //MYGUI
			lastprogress = progress;
		}

		char oname[1024];
		char type[256];
		char name[256];
		int r;
		float ox, oy, oz;
		float rx, ry, rz;
		//fscanf(fd," %[^\n\r]",line);
		size_t ll=ds->readLine(line, 1023);
		if (line[0]=='/' || ll==0) continue; //comments
		if (!strcmp("end",line)) break;
		//sandstorm cube texture
		if (!strncmp(line,"sandstormcubemap", 16))
		{
			sscanf(line, "sandstormcubemap %s", sandstormcubemap);
		};
		if (!strncmp("landuse-config", line, 14))
		{
			collisions->setupLandUse(line+15);
			continue;
		}

		//Caelum config
		if (!strncmp(line,"caelumconfig", 12))
		{
			sscanf(line, "caelumconfig %s", caelumconfig);
		};

#ifdef USE_HYDRAX
		if (!strncmp("hydraxconfig", line, 12))
		{
			char tmp[255]="";
			int res = sscanf(line, "hydraxconfig %s", tmp);
			if(res < 1)
			{
				LogManager::getSingleton().logMessage("error reading hydraxconfig command!");
				continue;
			}
			hydraxConfig=String(tmp);
		}
#endif //HYDRAX
		if (!strncmp("mpspawn", line, 7))
		{
			spawn_location_t spl;
			memset(&spl, 0, sizeof(spawn_location_t));

			char tmp[255]="";
			float x=0,y=0,z=0, rx=0, ry=0, rz=0;
			int res = sscanf(line, "mpspawn %s %f %f %f %f %f %f", tmp, &x, &y, &z, &rx, &ry, &rz);
			if(res < 7)
			{
				LogManager::getSingleton().logMessage("error reading mpspawn command!");
				continue;
			}
			spl.pos = Vector3(x, y, z);
			spl.rot = Quaternion(Degree(rx), Vector3::UNIT_X)*Quaternion(Degree(ry), Vector3::UNIT_Y)*Quaternion(Degree(rz), Vector3::UNIT_Z);
			netSpawnPos[String(tmp)] = spl;
			continue;
		}
		if (!strncmp("gravity", line, 7))
		{
			int res = sscanf(line, "gravity %f", &gravity);
			if(res < 1)
			{
				LogManager::getSingleton().logMessage("error reading gravity command!");
			}
			continue;
		}
		//ugly stuff to parse map size
		if (!strncmp("mapsize", line, 7))
		{
			// this is deprecated!!! (replaced by direct .cfg reads)
			//sscanf(line, "mapsize %f, %f", &mapsizex, &mapsizez);
			continue;
		}
#ifdef USE_PAGED
		//ugly stuff to parse trees :)
		if(!strncmp("trees", line, 5))
		{
			if(pagedMode==0)
				continue;
			char ColorMap[255]="";
			char DensityMap[255]="";
			char treemesh[255]="";
			float yawfrom=0, yawto=0, scalefrom=0, scaleto=0, highdens=1;
			int minDist=90, maxDist=700;
			sscanf(line, "trees %f, %f, %f, %f, %f, %d, %d, %s %s %s", &yawfrom, &yawto, &scalefrom, &scaleto, &highdens, &minDist, &maxDist, treemesh, ColorMap, DensityMap);
			if(strnlen(ColorMap, 3) == 0)
			{
				LogManager::getSingleton().logMessage("tree ColorMap map zero!");
				continue;
			}
			if(strnlen(DensityMap, 3) == 0)
			{
				LogManager::getSingleton().logMessage("tree DensityMap zero!");
				continue;
			}
			Forests::DensityMap *densityMap = Forests::DensityMap::load(DensityMap, CHANNEL_COLOR);
			if(!densityMap)
			{
				LogManager::getSingleton().logMessage("could not load densityMap: "+String(DensityMap));
				continue;
			}
			densityMap->setFilter(Forests::MAPFILTER_BILINEAR);
			//densityMap->setMapBounds(TRect(0, 0, mapsizex, mapsizez));

			paged_geometry_t paged;
			paged.geom = new PagedGeometry();
			//paged.geom->setTempDir(SETTINGS.getSetting("User Path") + "cache" + SETTINGS.getSetting("dirsep"));
			paged.geom->setCamera(mCamera);
			paged.geom->setPageSize(50);
			paged.geom->setInfinite();
			Ogre::TRect<Ogre::Real> bounds = TBounds(0, 0, mapsizex, mapsizez);
			//trees->setBounds(bounds);

			//Set up LODs
			//trees->addDetailLevel<EntityPage>(50);
			float min = minDist * pagedDetailFactor;
			if(min<10) min = 10;
			paged.geom->addDetailLevel<BatchPage>(min, min/2);
			float max = maxDist * pagedDetailFactor;
			if(max<10) max = 10;
			paged.geom->addDetailLevel<ImpostorPage>(max, max/10);
			TreeLoader2D *treeLoader = new TreeLoader2D(paged.geom, TBounds(0, 0, mapsizex, mapsizez));
			paged.geom->setPageLoader(treeLoader);
			treeLoader->setHeightFunction(&getTerrainHeight);
			if(String(ColorMap) != "none")
				treeLoader->setColorMap(ColorMap);

			curTree = mSceneMgr->createEntity(String("paged_")+treemesh+StringConverter::toString(pagedGeometry.size()), treemesh);

			float density = 0, yaw=0, scale=0;
			int numTreesToPlace=0;
			int gridsize = 10;
			for(int x=0;x<mapsizex;x+=gridsize)
			{
				for(int z=0;z<mapsizez;z+=gridsize)
				{
					density = densityMap->_getDensityAt_Unfiltered(x, z, bounds);
					numTreesToPlace = (int)((float)(highdens) * density * pagedDetailFactor);
					float nx=0, nz=0;
					while(numTreesToPlace-->0)
					{
						nx = Math::RangeRandom(x, x + gridsize);
						nz = Math::RangeRandom(z, z + gridsize);
						yaw = Math::RangeRandom(yawfrom, yawto);
						scale = Math::RangeRandom(scalefrom, scaleto);
						treeLoader->addTree(curTree, Vector3(nx, 0, nz), Degree(yaw), (Ogre::Real)scale);
					}
				}
			}
			paged.loader = (void*)treeLoader;
			pagedGeometry.push_back(paged);
		}
		//ugly stuff to parse grass :)
		if (!strncmp("grass", line, 5) || !strncmp("grass2", line, 6))
		{
			// is paged geometry disabled by configuration?
			if(pagedMode==0)
				continue;
			int range=80;
			float SwaySpeed=0.5, SwayLength=0.05, SwayDistribution=10.0, minx=0.2, miny=0.2, maxx=1, maxy=0.6, Density=0.6, minH=-9999, maxH=9999;
			char grassmat[255]="";
			char ColorMap[255]="";
			char DensityMap[255]="";
			int growtechnique = 0;
			int techn = GRASSTECH_CROSSQUADS;
			if(!strncmp("grass2", line, 6))
				sscanf(line, "grass2 %d, %f, %f, %f, %f, %f, %f, %f, %f, %d, %f, %f, %d, %s %s %s", &range, &SwaySpeed, &SwayLength, &SwayDistribution, &Density, &minx, &miny, &maxx, &maxy, &growtechnique, &minH, &maxH, &techn, grassmat, ColorMap, DensityMap);
			else if(!strncmp("grass", line, 5))
				sscanf(line, "grass %d, %f, %f, %f, %f, %f, %f, %f, %f, %d, %f, %f, %s %s %s", &range, &SwaySpeed, &SwayLength, &SwayDistribution, &Density, &minx, &miny, &maxx, &maxy, &growtechnique, &minH, &maxH, grassmat, ColorMap, DensityMap);

			//Initialize the PagedGeometry engine
			try
			{
				paged_geometry_t paged;
				PagedGeometry *grass = new PagedGeometry(mCamera, 30);
				//Set up LODs

				grass->addDetailLevel<GrassPage>(range * pagedDetailFactor); // original value: 80

				//Set up a GrassLoader for easy use
				GrassLoader *grassLoader = new GrassLoader(grass);
				grass->setPageLoader(grassLoader);
				grassLoader->setHeightFunction(&getTerrainHeight);

				// render grass at first
				grassLoader->setRenderQueueGroup(RENDER_QUEUE_MAIN);

				GrassLayer* grassLayer = grassLoader->addLayer(grassmat);
				grassLayer->setHeightRange(minH, maxH);
				//grassLayer->setLightingEnabled(true);

				grassLayer->setAnimationEnabled((SwaySpeed>0));
				grassLayer->setSwaySpeed(SwaySpeed);
				grassLayer->setSwayLength(SwayLength);
				grassLayer->setSwayDistribution(SwayDistribution);

				grassdensityTextureFilename = String(DensityMap);

				grassLayer->setDensity(Density * pagedDetailFactor);
				if(techn>10)
					grassLayer->setRenderTechnique(static_cast<GrassTechnique>(techn-10), true);
				else
					grassLayer->setRenderTechnique(static_cast<GrassTechnique>(techn), false);

				grassLayer->setMapBounds(TBounds(0, 0, mapsizex, mapsizez));

				if(strcmp(ColorMap,"none") != 0)
				{
					grassLayer->setColorMap(ColorMap);
					grassLayer->setColorMapFilter(MAPFILTER_BILINEAR);
				}

				if(strcmp(DensityMap,"none") != 0)
				{
					grassLayer->setDensityMap(DensityMap);
					grassLayer->setDensityMapFilter(MAPFILTER_BILINEAR);
				}

				//grassLayer->setMinimumSize(0.5,0.5);
				//grassLayer->setMaximumSize(1.0, 1.0);

				grassLayer->setMinimumSize(minx, miny);
				grassLayer->setMaximumSize(maxx, maxy);

				// growtechnique
				if(growtechnique == 0)
					grassLayer->setFadeTechnique(FADETECH_GROW);
				else if(growtechnique == 1)
					grassLayer->setFadeTechnique(FADETECH_ALPHAGROW);
				else if(growtechnique == 2)
					grassLayer->setFadeTechnique(FADETECH_ALPHA);
				paged.geom = grass;
				paged.loader = (void*)grassLoader;
				pagedGeometry.push_back(paged);
			} catch(...)
			{
				LogManager::getSingleton().logMessage("error loading grass!");
			}

			continue;
		}
#endif //USE_PAGED
		//ugly stuff to parse procedural roads
		if (!strncmp("begin_procedural_roads", line, 22))
		{
			proroad=true;
			po = ProceduralObject();
			po.loadingState = 1;
			r2oldmode=1;
			continue;
		}
		if (!strncmp("end_procedural_roads", line, 20))
		{
			proroad=false;
			if(r2oldmode)
			{
				if(proceduralManager)
					proceduralManager->addObject(po);
				po = ProceduralObject();
			}
			continue;
		}
		if (proroad)
		{

			float rwidth, bwidth, bheight;
			//position x,y,z rotation rx,ry,rz, width, border width, border height, type
			r=sscanf(line, "%f, %f, %f, %f, %f, %f, %f, %f, %f, %s",&ox,&oy,&oz, &rx, &ry, &rz, &rwidth, &bwidth, &bheight, oname);
			Vector3 pos=Vector3(ox, oy, oz);
			Quaternion rotation = Quaternion(Degree(rx), Vector3::UNIT_X)*Quaternion(Degree(ry), Vector3::UNIT_Y)*Quaternion(Degree(rz), Vector3::UNIT_Z);
			int roadtype=ROAD_AUTOMATIC;
			int pillartype = 0;
			if (!strcmp(oname, "flat")) roadtype=ROAD_FLAT;
			if (!strcmp(oname, "left")) roadtype=ROAD_LEFT;
			if (!strcmp(oname, "right")) roadtype=ROAD_RIGHT;
			if (!strcmp(oname, "both")) roadtype=ROAD_BOTH;
			if (!strcmp(oname, "bridge")) {roadtype=ROAD_BRIDGE;pillartype=1;}
			if (!strcmp(oname, "monorail")) {roadtype=ROAD_MONORAIL;pillartype=2;}
			if (!strcmp(oname, "monorail2")) {roadtype=ROAD_MONORAIL;pillartype=0;}
			if (!strcmp(oname, "bridge_no_pillars")) {roadtype=ROAD_BRIDGE;pillartype=0;}

			if(r2oldmode)
			{
				//fill object
				ProceduralPoint pp;
				pp.bheight = bheight;
				pp.bwidth = bwidth;
				pp.pillartype = pillartype;
				pp.position = pos;
				pp.rotation = rotation;
				pp.type = roadtype;
				pp.width = rwidth;

				po.points.push_back(pp);
			}
			continue;
		}
		//end of the ugly (somewhat)
		strcpy(name, "generic");
		memset(oname, 0, 255);
		memset(type, 0, 255);
		memset(name, 0, 255);
		r=sscanf(line, "%f, %f, %f, %f, %f, %f, %s %s %s",&ox,&oy,&oz, &rx, &ry, &rz, oname, type, name);
		if(r<6)
			continue;
		if((!strcmp(oname, "truck")) || (!strcmp(oname, "load") || (!strcmp(oname, "machine")) || (!strcmp(oname, "boat")) || (!strcmp(oname, "truck2")) ))
		{
			bool newFormat = (!strcmp(oname, "truck2"));

			if(!strcmp(oname, "boat") && !w)
				// no water so do not load boats!
				continue;
			String group="";
			String truckname=String(type);
			if(!CACHE.checkResourceLoaded(truckname, group))
			{
				LogManager::getSingleton().logMessage("error while loading terrain: truck " + String(type) + " not found. ignoring.");
				continue;
			}
			//this is a truck or load declaration
			truck_preload[truck_preload_num].px=ox;
			truck_preload[truck_preload_num].py=oy;
			truck_preload[truck_preload_num].pz=oz;
			truck_preload[truck_preload_num].freePosition = newFormat;
			truck_preload[truck_preload_num].ismachine=(!strcmp(oname, "machine"));
			truck_preload[truck_preload_num].rotation=Quaternion(Degree(rx), Vector3::UNIT_X)*Quaternion(Degree(ry), Vector3::UNIT_Y)*Quaternion(Degree(rz), Vector3::UNIT_Z);
			//truck_preload[truck_preload_num].ry=ry;
			strcpy(truck_preload[truck_preload_num].name, truckname.c_str());
			truck_preload_num++;
			continue;
		}
		if (   !strcmp(oname, "road")
			|| !strcmp(oname, "roadborderleft")
			|| !strcmp(oname, "roadborderright")
			|| !strcmp(oname, "roadborderboth")
			|| !strcmp(oname, "roadbridgenopillar")
			|| !strcmp(oname, "roadbridge"))
		{
			int pillartype = !(strcmp(oname, "roadbridgenopillar") == 0);
			//okay, this is a job for roads2
			int roadtype=ROAD_AUTOMATIC;
			if (!strcmp(oname, "road")) roadtype=ROAD_FLAT;
			Vector3 pos=Vector3(ox, oy, oz);
			Quaternion rotation;
			rotation=Quaternion(Degree(rx), Vector3::UNIT_X)*Quaternion(Degree(ry), Vector3::UNIT_Y)*Quaternion(Degree(rz), Vector3::UNIT_Z);
			if ((pos-r2lastpos).length()>20.0)
			{
				//break the road
				if (r2oldmode!=0)
				{
					//fill object
					ProceduralPoint pp;
					pp.bheight = 0.2;
					pp.bwidth = 1.4;
					pp.pillartype = pillartype;
					pp.position = r2lastpos+r2lastrot*Vector3(10.0,0,0);
					pp.rotation = r2lastrot;
					pp.type = roadtype;
					pp.width = 8;
					po.points.push_back(pp);

					// finish it and start new object
					if(proceduralManager)
						proceduralManager->addObject(po);
					po = ProceduralObject();
					r2oldmode=1;
				}
				r2oldmode=1;
				// beginning of new
				ProceduralPoint pp;
				pp.bheight = 0.2;
				pp.bwidth = 1.4;
				pp.pillartype = pillartype;
				pp.position = pos;
				pp.rotation = rotation;
				pp.type = roadtype;
				pp.width = 8;
				po.points.push_back(pp);
			}
			else
			{
				//fill object
				ProceduralPoint pp;
				pp.bheight = 0.2;
				pp.bwidth = 1.4;
				pp.pillartype = pillartype;
				pp.position = pos;
				pp.rotation = rotation;
				pp.type = roadtype;
				pp.width = 8;
				po.points.push_back(pp);
			}
			r2lastpos=pos;
			r2lastrot=rotation;


			continue;
		}
		loadObject(oname, ox, oy, oz, rx, ry, rz, bakeNode, name, true, -1, type);
	}
	//fclose(fd);

	// ds closes automatically, so do not close it explicitly here:
	//ds->close();

	//finish the last road
	if (r2oldmode!=0)
	{
		//fill object
		ProceduralPoint pp;
		pp.bheight = 0.2;
		pp.bwidth = 1.4;
		pp.pillartype = 1;
		pp.position = r2lastpos+r2lastrot*Vector3(10.0,0,0);
		pp.rotation = r2lastrot;
		pp.type = ROAD_AUTOMATIC;
		pp.width = 8;
		po.points.push_back(pp);

		// finish it and start new object
		if(proceduralManager)
			proceduralManager->addObject(po);
	}


	//okay now bake everything
	bakesg=mSceneMgr->createStaticGeometry("bakeSG");
	bakesg->setCastShadows(true);
	bakesg->addSceneNode(bakeNode);
	bakesg->setRegionDimensions(Vector3(farclip/2.0, 10000.0, farclip/2.0));
	bakesg->setRenderingDistance(farclip);
	try
	{
		bakesg->build();
		bakeNode->detachAllObjects();
		// crash under linux:
		//bakeNode->removeAndDestroyAllChildren();
	}catch(...)
	{
		LogManager::getSingleton().logMessage("error while baking roads. ignoring.");

	}

#ifdef USE_MYGUI
	// tell this the map, so it can change the drawing distance !
	if(mtc)
		mtc->setStaticGeometry(bakesg);
#endif // MYGUI

	collisions->printStats();
	loading_state=TERRAIN_LOADED;

	// we set the sky this late, so the user can configure it ...
	if (SETTINGS.getSetting("Sky effects")!="Caelum (best looking, slower)" && strlen(sandstormcubemap)>0)
	{
		mSceneMgr->setSkyBox(true, sandstormcubemap, farclip);
	}
#ifdef USE_CAELUM
	// load caelum config
	if (SETTINGS.getSetting("Sky effects")=="Caelum (best looking, slower)")
	{
		SkyManager::getSingleton().loadScript(String(caelumconfig));
	}
#endif //USE_CAELUM

#ifdef USE_HYDRAX
	if(w && useHydrax)
		((HydraxWater*)w)->loadConfig(hydraxConfig);
#endif // HYDRAX

	if(debugCollisions)
		collisions->createCollisionDebugVisualization();

#ifdef USE_MYGUI
	LoadingWindow::get()->hide();

	if(bigMap)
	{
		// this has a slight offset in size, thus forces the icons to recalc their size -> correct size on screen
		bigMap->updateRenderMetrics(mWindow);
		bigMap->setPosition(0, 0.81, 0.14, 0.1901, mWindow);
	}
#endif //MYGUI

	//okay, taking a picture of the scene for the envmap
	// SAY CHEESE!
	//no, not yet, Caelum is not ready!
	//if (envmap) envmap->update(Vector3(terrainxsize/2.0, hfinder->getHeightAt(terrainxsize/2.0, terrainzsize/2.0)+50.0, terrainzsize/2.0));

}

void RoRFrameListener::updateXFire()
{
#if OGRE_PLATFORM == OGRE_PLATFORM_WIN32
    if(!xfire_enabled)
        // user mus explicitly enable it
        return;
	// ----
#ifdef USE_XFIRE
	char terrainname[100]="";
	strncpy(terrainname, const_cast<char*>(loadedTerrain.c_str()), 99);

	// ----
	String gameState = "unkown";
	switch(loading_state)
	{
		case NONE_LOADED: gameState = "in menu"; break;
		case TERRAIN_LOADED: gameState = "selecting vehicle"; break;
		case ALL_LOADED: gameState = "playing"; break;
		case EXITING: gameState = "exiting the game"; break;
		case EDITING: gameState = "editing"; break;
		case RELOADING: gameState = "selecting additional vehicle"; break;
		case EDITOR_PAUSE: gameState = "pause mode"; break;
	}

	// ----
	String vehicleName = "unkown";
	if(loading_state == ALL_LOADED)
	{
		if(current_truck == -1)
			vehicleName = "person";
		else if(current_truck != -1 && current_truck <= free_truck)
				vehicleName = trucks[current_truck]->getTruckName();
	}

	// ----
	char playingTime[100]="";
	int minutes = (CACHE.getTimeStamp() - gameStartTime) / 60;
	int hours = minutes / 60;
	if (minutes > 60)
		sprintf(playingTime, "%d hour(s), %d minutes", hours, minutes-60*hours);
	else
		sprintf(playingTime, "%d minute(s)", minutes);

	// ----
	char gameType[100]="";
	if (!netmode)
		strcpy(gameType, "Single Player");
	else
		strcpy(gameType, "Multi Player");

	// ----
	static String servername = "unkown";
	static int serverport=0;
	if(netmode && servername == "unkown" && serverport == 0)
	{
		servername = SETTINGS.getSetting("Server name").c_str();
		serverport=StringConverter::parseLong(SETTINGS.getSetting("Server port"));
	}
	int players = 0;
	//if(net) players = net->getConnectedClientCount();

	char serverString[100]="";
	if(netmode)
		sprintf(serverString, "%s:%d (%d players)", servername.c_str(), serverport, players);
	else
		strcpy(serverString, "Playing Offline");

	// ----
	String gameVersion = "RoR: "+String(ROR_VERSION_STRING) + " / protocol: " + String(RORNET_VERSION);

	// ----
	const char *key[] = {
		"Game State",
		"Terrain",
		"Used Vehicle",
		"Playing since",
		"Game Type",
		"Server",
		"Game Version",
	};
	const char *value[] = {
		const_cast<char*>(gameState.c_str()),
		(const char *)terrainname,
		const_cast<char*>(vehicleName.c_str()),
		(const char *)playingTime,
		(const char *)gameType,
		(const char *)serverString,
		const_cast<char*>(gameVersion.c_str()),
	};
	if(XfireIsLoaded() == 1)
	{
		int res = XfireSetCustomGameData(7, key, value);
		LogManager::getSingleton().logMessage("XFire GameData updated, result code: "+StringConverter::toString(res));
	}

#endif // XFIRE
#endif // WIN32
}

void RoRFrameListener::setGrassDensity(float x, float y, int density, bool relative)
{
#ifdef USE_PAGED
// todo to fix
#if 0
	if(!grassLoader)
		return;
	GrassLayer *grassLayer = grassLoader->getLayerList().front();
	PixelBox *b = grassLayer->getDensityMapData();
	if(!b || ! grassLayer)
		return;
	int gwidth = (int)b->getWidth();
	int gheight = (int)b->getHeight();
	int nx = (int)(x / mapsizex * gwidth);
	int ny = (int)(y / mapsizez * gwidth);
	unsigned char *data = ((unsigned char*)b->data) + nx + ny * gwidth;
	int value=0, valuechange=0;
	if(relative)
	{
		value = changeGrassBuffer(data, density);
		valuechange = density/2;
	}
	else
	{
		value = density;
		valuechange = (value - *data);
	}
	// surrounding value of the pixel (brush like)
	if(valuechange != 0)
		valuechange /= 2;
	// so set some data, like a brush, to make everything smoother :)
	/* pixels:
	1 2 3
	4 5 6
	7 8 9
	*/
	if(ny > 1 && nx > 1)
	{
		// set 1,2,3
		changeGrassBuffer(data-1-gwidth, valuechange);
		changeGrassBuffer(data-gwidth, valuechange);
		changeGrassBuffer(data+1-gwidth, valuechange);
		// set 4,5,6
		changeGrassBuffer(data-1, valuechange);
		changeGrassBuffer(data, valuechange);
		changeGrassBuffer(data+1, valuechange);
		// set 7,8,9
		changeGrassBuffer(data-1+gwidth, valuechange);
		changeGrassBuffer(data+gwidth, valuechange);
		changeGrassBuffer(data+1+gwidth, valuechange);
	}

	LogManager::getSingleton().logMessage("setting grass: "+ \
		StringConverter::toString(gwidth)+"x"+StringConverter::toString(gheight)+", "+ \
		"("+StringConverter::toString(nx)+"x"+StringConverter::toString(ny)+") = " + \
		StringConverter::toString(*data)+" / " + StringConverter::toString(value)+", "+StringConverter::toString(valuechange));
	grass->reloadGeometryPage(Vector3(x, 0, y));
#endif
#endif //USE_PAGED
}

void RoRFrameListener::updateGrass(Vector3 pos)
{
#if 0
// todo: fix
	if(!grassLoader || !grass)
		return;

	grass->reloadGeometryPage(pos);
#endif
}

int RoRFrameListener::changeGrassBuffer(unsigned char *data, int relchange)
{
#ifdef USE_PAGED
	int newdata = *data + relchange;
	if(newdata < 0)
		newdata = 0;
	if(newdata > 255)
		newdata = 255;
	*data = newdata;
	return newdata;
#else
	return 0;
#endif
}

void RoRFrameListener::saveGrassDensity()
{
#ifdef USE_PAGED
#if 0
	if(!grassLoader)
		return;
	GrassLayer *grassLayer = grassLoader->getLayerList().front();
	PixelBox *b = grassLayer->getDensityMapData();
	if(!b || !grassLayer)
		return;
	int gwidth = (int)b->getWidth();
	int gheight = (int)b->getHeight();
	grass->reloadGeometry();

	Image img;
	img = img.loadDynamicImage ((uchar *)b->data, gwidth, gheight, PF_BYTE_L);

	String filename = String("data/terrains/") + grassdensityTextureFilename;
	img.save(filename.c_str());
	LogManager::getSingleton().logMessage("saving grass to "+filename);
#endif
#endif //USE_PAGED
}


void RoRFrameListener::initTrucks(bool loadmanual, Ogre::String selected, Ogre::String selectedExtension, std::vector<Ogre::String> *truckconfig, bool enterTruck)
{
	//we load truck
	char *selectedchr = const_cast<char *>(selected.c_str());
	if (loadmanual)
	{
		Beam *b=0;
		if(net)
		{
			Vector3 spawnpos = Vector3(truckx, trucky, truckz);
			Quaternion spawnrot = Quaternion::ZERO;
			if(selectedExtension.size() > 0)
			{
				String nsp = SETTINGS.getSetting("net spawn location");
				if(!nsp.empty())
				{
					// override-able by cmdline
					spawnpos = Ogre::StringConverter::parseVector3(nsp);
					spawnrot = Quaternion::ZERO;
				} else
				{
					// classical, search start points
					try
					{
						spawnpos = netSpawnPos[selectedExtension].pos;
						spawnrot = netSpawnPos[selectedExtension].rot;
					} catch(...)
					{
						spawnpos = Vector3(truckx, trucky, truckz);
						spawnrot = Quaternion::ZERO;
					}
				}
			}
			//trucks[free_truck]=new Beam(free_truck, mSceneMgr, mSceneMgr->getRootSceneNode(), mWindow, net, &mapsizex, &mapsizez, spawnpos.x, spawnpos.y, spawnpos.z, spawnrot, selectedchr, collisions, dustp, clumpp, sparksp, dripp, splashp, ripplep, hfinder, w, mCamera, mirror, false, false, netmode,0,false,flaresMode, truckconfig);
			b = BeamFactory::getSingleton().createLocal(spawnpos, spawnrot, selectedchr, 0, false, flaresMode, truckconfig);
//IMI - on network mode we should be directly jump in
			if (b && enterTruck)
			{
					cameramode = CAMERA_INT;
					setCurrentTruck(b->trucknum);
			} else if(!b && enterTruck)
				setCurrentTruck(-1);

		} else
		{
			Beam *b = BeamFactory::getSingleton().createLocal(Vector3(truckx, trucky, truckz), Quaternion::ZERO, selectedchr, 0, false, flaresMode, truckconfig);
			//trucks[free_truck]=new Beam(free_truck, mSceneMgr, mSceneMgr->getRootSceneNode(), mWindow, net, &mapsizex, &mapsizez, truckx, trucky, truckz, Quaternion::ZERO, selectedchr, collisions, dustp, clumpp, sparksp, dripp, splashp, ripplep, hfinder, w, mCamera, mirror, false, false, netmode,0,false,flaresMode, truckconfig);
			if(b && enterTruck)
			{
				setCurrentTruck(b->trucknum);
			} else if(!b && enterTruck)
				setCurrentTruck(-1);
		}

#ifdef USE_MYGUI
		if(b && bigMap)
		{
			MapEntity *e = bigMap->createNamedMapEntity("Truck"+StringConverter::toString(b->trucknum), MapControl::getTypeByDriveable(b->driveable));
			if(e)
			{
				e->setState(DESACTIVATED);
				e->setVisibility(true);
				e->setPosition(truckx, truckz);
				e->setRotation(-Radian(b->getHeadingDirectionAngle()));
			}
		}
#endif // MYGUI

		if (b && b->engine) b->engine->start();
	}


	// load the rest in SP
	// in netmode, dont load other trucks!
	if (!netmode)
	{
		int i;
		for (i=0; i<truck_preload_num; i++)
		{
			Beam *b = BeamFactory::getSingleton().createLocal(Vector3(truck_preload[i].px, truck_preload[i].py, truck_preload[i].pz), truck_preload[i].rotation, truck_preload[i].name, 0, truck_preload[i].ismachine, flaresMode, truckconfig, 0, truck_preload[i].freePosition);

			//trucks[free_truck]=new Beam(free_truck, mSceneMgr, mSceneMgr->getRootSceneNode(), mWindow, net,
			//	&mapsizex, &mapsizez, truck_preload[i].px, truck_preload[i].py, truck_preload[i].pz, truck_preload[i].rotation, truck_preload[i].name, collisions, dustp, clumpp, sparksp, dripp, splashp, ripplep, hfinder, w, mCamera, mirror,false,false,false,0,truck_preload[i].ismachine,flaresMode, truckconfig);
#ifdef USE_MYGUI
			if(b && bigMap)
			{
				MapEntity *e = bigMap->createNamedMapEntity("Truck"+StringConverter::toString(b->trucknum), MapControl::getTypeByDriveable(b->driveable));
				if(e)
				{
					e->setState(DESACTIVATED);
					e->setVisibility(true);
					e->setPosition(truck_preload[i].px, truck_preload[i].pz);
					e->setRotation(-Radian(b->getHeadingDirectionAngle()));
				}
			}
#endif // MYGUI
		}

	}
	LogManager::getSingleton().logMessage("EFL: beam instanciated");

	if(!enterTruck) setCurrentTruck(-1);

	// fix for problem on loading
	if(enterTruck && trucks[current_truck] && trucks[current_truck]->free_node == 0) setCurrentTruck(-1);

	//force perso start
	if (persostart!=Vector3(0,0,0)) person->setPosition(persostart);
	//bigMap->getEntityByName("person")->onTop();

	/*cameramode=CAMERA_INT;
	pushcamRotX=camRotX;
	pushcamRotY=camRotY;
	camRotX=0;
	camRotY=DEFAULT_INTERNAL_CAM_PITCH;
	*/
	loading_state=ALL_LOADED;
	//uiloader->hide();
	showcredits=0;
	LogManager::getSingleton().logMessage("initTrucks done");

#ifdef USE_MYGUI
	if(mtc)
		mtc->update();
#endif // MYGUI
}

void RoRFrameListener::setCurrentTruck(int v)
{
	if (cameramode==CAMERA_FREE) return;
	if (v==current_truck) return;
	int previous_truck=current_truck;
	if (trucks[current_truck] && current_truck!=-1 && current_truck<free_truck)
		trucks[current_truck]->desactivate();
	current_truck=v;

	if (current_truck==-1)
	{
		//if(bigMap) bigMap->setVisibility(false);
		if(netmode && NETCHAT.getVisible()) NETCHAT.setMode(this, NETCHAT_LEFT_FULL, true);

		// detach person to truck
		if(person)
			person->setBeamCoupling(false);

		//force feedback
		if (forcefeedback) forcefeedback->setEnabled(false);
		//LEDs
#ifdef USE_OIS_G27
		//logitech G27 LEDs tachometer
		if (leds)
		{
			leds->play(0, 10, 20);//stop the LEDs
		}
#endif //OIS_G27

		// hide truckhud
		if(ow) ow->truckhud->show(false);

#ifdef USE_MYGUI
		// return to normal mapmode
		if(mtc && interactivemap > 1)
		{
			// 2 = disabled normally, enabled for car
			interactivemap = 0;
			bigMap->setEntitiesVisibility(true);
		}
#endif //MYGUI

		//getting outside
		if(ow) ow->mouseOverlay->hide();
		Vector3 position = Vector3::ZERO;
		if(trucks[previous_truck])
		{
			trucks[previous_truck]->prepareInside(false);

			// this workaround enables trucks to spawn that have no cinecam. required for cmdline options
			if(trucks[previous_truck]->cinecameranodepos[0] != -1)
			{
				// truck has a cinecam
				position=trucks[previous_truck]->nodes[trucks[previous_truck]->cinecameranodepos[0]].AbsPosition;
				position+=-2.0*((trucks[previous_truck]->nodes[trucks[previous_truck]->cameranodepos[0]].RelPosition-trucks[previous_truck]->nodes[trucks[previous_truck]->cameranoderoll[0]].RelPosition).normalisedCopy());
				position+=Vector3(0.0, -1.0, 0.0);
			}
			else
			{
				// truck has no cinecam
				position=trucks[previous_truck]->nodes[0].AbsPosition;
			}
		}
		//			position.y=hfinder->getHeightAt(position.x,position.z);
		if(position != Vector3::ZERO) person->setPosition(position);
		//person->setVisible(true);
		if(ow) ow->showDashboardOverlays(false,0);
		if(ow) ow->showEditorOverlay(false);
#ifdef USE_OPENAL
		if(ssm) ssm->trigStop(previous_truck, SS_TRIG_AIR);
		if(ssm) ssm->trigStop(previous_truck, SS_TRIG_PUMP);
#endif // OPENAL
		int t;
		for (t=0; t<free_truck; t++)
		{
			if(!trucks[t]) continue;
			trucks[t]->sleepcount=9;
		} //make trucks synchronous
		//lastangle=0;
		camRotX=0;
		camRotY=Degree(12);
		camDist=20;
#ifdef USE_ANGELSCRIPT
		ScriptEngine::getSingleton().triggerEvent(ScriptEngine::SE_TRUCK_ENTER, previous_truck);
#endif //ANGELSCRIPT
	}
	else
	{
		//getting inside
		if(netmode && NETCHAT.getVisible()) NETCHAT.setMode(this, NETCHAT_LEFT_SMALL, true);
		if(ow) ow->mouseOverlay->show();
		//person->setVisible(false);
		if(ow &&!hidegui)
		{
			ow->showDashboardOverlays(true, trucks[current_truck]->driveable);
			ow->showEditorOverlay(trucks[current_truck]->editorId>=0);
		}

		// mapmode change?
#ifdef USE_MYGUI
		if(mtc && trucks[current_truck]->dynamicMapMode > 0)
		{
			// > 1 = disabled normally, enabled for car
			if(interactivemap == 0)
				interactivemap = 1 + trucks[current_truck]->dynamicMapMode;
			else if(interactivemap == 1 && trucks[current_truck]->dynamicMapMode == 2)
				interactivemap = 3;
			mtc->setCamZoom(30);
			bigMap->setEntitiesVisibility(false);
		}

		// show minimap and put it into lower left corner
		if(bigMap)
		{
			//bigMap->setVisibility(true);
			bigMap->setPosition(0, 0.81, 0.14, 0.19, mWindow);
		}
#endif // MYGUI

		trucks[current_truck]->activate();
		//if (trucks[current_truck]->engine->running) trucks[current_truck]->audio->playStart();
		//hide unused items
		if (ow && trucks[current_truck]->free_active_shock==0)
			(OverlayManager::getSingleton().getOverlayElement("tracks/rollcorneedle"))->hide();
		//					rollcorr_node->setVisible((trucks[current_truck]->free_active_shock>0));
		//help panel
		//force feedback
		if (forcefeedback) forcefeedback->setEnabled(trucks[current_truck]->driveable==TRUCK); //only for trucks so far
		//LEDs
#ifdef USE_OIS_G27
		//logitech G27 LEDs tachometer
		if (leds && trucks[current_truck]->driveable!=TRUCK)
		{
			leds->play(0, 10, 20);//stop the LEDs
		}
#endif //OIS_G27


		// attach person to truck
		if(person)
			person->setBeamCoupling(true, trucks[current_truck]);
		if(ow)
		{
			try
			{
				// we wont crash for help panels ...
				if (trucks[current_truck]->hashelp)
				{
					OverlayManager::getSingleton().getOverlayElement("tracks/helppanel")->setMaterialName(trucks[current_truck]->helpmat);
					OverlayManager::getSingleton().getOverlayElement("tracks/machinehelppanel")->setMaterialName(trucks[current_truck]->helpmat);
				}
				else
				{
					OverlayManager::getSingleton().getOverlayElement("tracks/helppanel")->setMaterialName("tracks/black");
					OverlayManager::getSingleton().getOverlayElement("tracks/machinehelppanel")->setMaterialName("tracks/black");
				}
			} catch(...)
			{
			}
			// enable gui mods
			if (trucks[current_truck]->speedomat != String(""))
				OverlayManager::getSingleton().getOverlayElement("tracks/speedo")->setMaterialName(trucks[current_truck]->speedomat);
			else
				OverlayManager::getSingleton().getOverlayElement("tracks/speedo")->setMaterialName("tracks/Speedo");

			if (trucks[current_truck]->tachomat != String(""))
				OverlayManager::getSingleton().getOverlayElement("tracks/tacho")->setMaterialName(trucks[current_truck]->tachomat);
			else
				OverlayManager::getSingleton().getOverlayElement("tracks/tacho")->setMaterialName("tracks/Tacho");
		}

		//lastangle=0;
		camRotX=0;
		camRotY=Degree(12);
		camDist=20;
		if (cameramode==CAMERA_INT)
		{
			trucks[current_truck]->prepareInside(true);
			if(ow) ow->showDashboardOverlays(false, 0);
			camRotY=DEFAULT_INTERNAL_CAM_PITCH;
			//if(bigMap) bigMap->setVisibility(false);
		}
#ifdef USE_ANGELSCRIPT
		ScriptEngine::getSingleton().triggerEvent(ScriptEngine::SE_TRUCK_ENTER, current_truck);
#endif //ANGELSCRIPT
	}
#ifdef USE_XFIRE
	updateXFire();
#endif
}

void RoRFrameListener::moveCamera(float dt)
{
	if(!hfinder) return;
	if (loading_state!=ALL_LOADED && loading_state != EDITOR_PAUSE) return;

#ifdef USE_MYGUI
	if(GUI_MainMenu::getSingleton().getVisible()) return; // disable camera movement in menu mode
#endif // MYGUI

	if (isnodegrabbed) return; //freeze camera

	bool changeCamMode = (lastcameramode != cameramode);
	lastcameramode = cameramode;

	if (cameramode==CAMERA_FREE)
	{
		// this is a workaround for the free camera mode :)
		Real mMoveScale = 0.1;
		Ogre::Degree mRotScale(0.1f);
		Ogre::Degree mRotX(0);
		Ogre::Degree mRotY(0);
		Vector3 mTranslateVector = Vector3::ZERO;

		if(INPUTENGINE.isKeyDown(OIS::KC_LSHIFT) || INPUTENGINE.isKeyDown(OIS::KC_RSHIFT))
		{
			mRotScale *= 3;
			mMoveScale *= 3;
		}

		if(INPUTENGINE.isKeyDown(OIS::KC_LCONTROL))
		{
			mRotScale *= 30;
			mMoveScale *= 30;
		}

		if(INPUTENGINE.isKeyDown(OIS::KC_LMENU))
		{
			mRotScale *= 0.05;
			mMoveScale *= 0.05;
		}

		const OIS::MouseState &ms = INPUTENGINE.getMouseState();
		if( ms.buttonDown(OIS::MB_Right) )
		{
			mTranslateVector.x += ms.X.rel * 0.13;
			mTranslateVector.y -= ms.Y.rel * 0.13;
		}
		else
		{
			mRotX = Degree(-ms.X.rel * 0.13);
			mRotY = Degree(-ms.Y.rel * 0.13);
		}

		if(INPUTENGINE.getEventBoolValue(EV_CHARACTER_SIDESTEP_LEFT))
			mTranslateVector.x = -mMoveScale;	// Move camera left

		if(INPUTENGINE.getEventBoolValue(EV_CHARACTER_SIDESTEP_RIGHT))
			mTranslateVector.x = mMoveScale;	// Move camera RIGHT

		if(INPUTENGINE.getEventBoolValue(EV_CHARACTER_FORWARD))
			mTranslateVector.z = -mMoveScale;	// Move camera forward

		if(INPUTENGINE.getEventBoolValue(EV_CHARACTER_BACKWARDS))
			mTranslateVector.z = mMoveScale;	// Move camera backward

		if(INPUTENGINE.getEventBoolValue(EV_CHARACTER_ROT_UP))
			mRotY += mRotScale;

		if(INPUTENGINE.getEventBoolValue(EV_CHARACTER_ROT_DOWN))
			mRotY += -mRotScale;

		if(INPUTENGINE.getEventBoolValue(EV_CHARACTER_UP))
			mTranslateVector.y = mMoveScale;	// Move camera up

		if(INPUTENGINE.getEventBoolValue(EV_CHARACTER_DOWN))
			mTranslateVector.y = -mMoveScale;	// Move camera down

		if(INPUTENGINE.getEventBoolValue(EV_CHARACTER_RIGHT))
			mRotX += -mRotScale;

		if(INPUTENGINE.getEventBoolValue(EV_CHARACTER_LEFT))
			mRotX += mRotScale;

		mCamera->yaw(mRotX);
		mCamera->pitch(mRotY);

		Vector3 trans = mCamera->getOrientation() * mTranslateVector;
		setCameraPositionWithCollision(mCamera->getPosition() + trans);
	}
	if (current_truck==-1)
	{
#ifdef USE_MYGUI
		if(mtc && interactivemap)
		{
			mtc->setCamPosition(person->getPosition(), mCamera->getOrientation());
			mtc->update();
		}
#endif //MYGUI
		//perso mode
		if (cameramode==CAMERA_EXT)
		{
			if (collisions->forcecam)
			{
				mCamera->setPosition(collisions->forcecampos);
				mCamera->lookAt(person->getPosition()+Vector3(0.0,1.0,0.0));
				if(changeCamMode)
					mCamera->setFOVy(Degree(80));
				collisions->forcecam=false;
			}
			else
			{
				// Make all the changes to the camera
				//Vector3 delta=lastPosition-personode->getPosition();
				//delta.y=0.0;
				float angle=-person->getAngle()-(3.14159/2.0);
				//			float angle2;
				//if (delta.length()>0.01) angle=atan2(delta.x,delta.z); else angle=lastangle;

				// fix camera distance a bit
				if(camDist < 3) camDist = 3.0f;

				camIdealPosition=camDist/2.0*Vector3(sin(angle+camRotX.valueRadians())*cos(camRotY.valueRadians()),sin(camRotY.valueRadians()),cos(angle+camRotX.valueRadians())*cos(camRotY.valueRadians()));


				camIdealPosition=camIdealPosition+person->getPosition();
				Vector3 newposition=(camIdealPosition+10.0*mCamera->getPosition())/11.0;
				Real h=hfinder->getHeightAt(newposition.x,newposition.z);

				if (w && !w->allowUnderWater() && w->getHeightWaves(newposition) > h)
					h=w->getHeightWaves(newposition);

				h+=1.0;
				if (newposition.y<h) newposition.y=h;
				setCameraPositionWithCollision(newposition);
				mCamera->lookAt(person->getPosition()+Vector3(0.0,1.1f,0.0));
				if(changeCamMode)
					mCamera->setFOVy(Degree(60));

				lastPosition=person->getPosition();
				//lastangle=angle;
			}
		}
		else if (cameramode==CAMERA_FIX)
		{
			float px, pz;
			px=((int)(person->getPosition().x)/100)*100;
			pz=((int)(person->getPosition().z)/100)*100;
			Real h=hfinder->getHeightAt(px+50.0,pz+50.0);
			Real random = Ogre::Math::RangeRandom(0.0f, 1.0f);
			if(w && random > 0.3f && !w->allowUnderWater())
			{
				// chance of 30% to get an underwater view?
				if (w && w->getHeightWaves(Vector3(px+50.0,0,pz+50.0)) > h)
					h=w->getHeightWaves(Vector3(px+50.0,0,pz+50.0));
			} else if (w && w->allowUnderWater())
			{
				h = w->getHeightWaves(Vector3(px+50.0,0,pz+50.0) - 10.0f);
			}
			mCamera->setPosition(Vector3(px+50.0, h+1.7, pz+50.0));
			mCamera->lookAt(person->getPosition());
			mCamera->setFOVy(Radian(atan2(20.0f,(mCamera->getPosition()-person->getPosition()).length())));
		}
		else if (cameramode==CAMERA_INT)
		{
			if(changeCamMode)
				mCamera->setFOVy(Degree(75));
			mCamera->setPosition(person->getPosition()+Vector3(0,1.7,0));
			Vector3 dir=Vector3(cos(person->getAngle()), 0.0, sin(person->getAngle()));
			mCamera->lookAt(mCamera->getPosition()+dir);
			mCamera->yaw(-camRotX);
			mCamera->pitch(camRotY);
			if (w && lastPosition.y<w->getHeightWaves(lastPosition))
			{
				cameramode=CAMERA_EXT;
				camRotX=pushcamRotX;
				camRotY=pushcamRotY;
			}
		}
	}
	else
	{
#ifdef USE_MYGUI
		if(mtc && interactivemap)
		{
			// update the interactive map
			// to improve: make the map, so it "looks forward", means the truck is at the bottom
			// to improve: use average vehicle speed, not the current one
			if(interactivemap == 3) // auto - zoom
			{
				mtc->setCamZoom(30 + trucks[current_truck]->WheelSpeed * 0.5);
			}
			mtc->setCamPosition(trucks[current_truck]->getPosition(), mCamera->getOrientation());
			mtc->update();
		}
#endif // MYGUI
		if (cameramode==CAMERA_EXT)
		{
			if (collisions->forcecam)
			{
				mCamera->setPosition(collisions->forcecampos);
				mCamera->lookAt(trucks[current_truck]->getPosition());
				if(changeCamMode)
					mCamera->setFOVy(Degree(80));
				collisions->forcecam=false;
			}
			else
			{
				// Make all the changes to the camera
				//Vector3 delta=lastPosition-trucks[current_truck]->position;
				//delta.y=0.0;
				float angle;
				//			float angle2;
				//				if (delta.length()>0.05) angle=atan2(delta.x,delta.z); else angle=lastangle;
				Vector3 dir=trucks[current_truck]->nodes[trucks[current_truck]->cameranodepos[0]].smoothpos-trucks[current_truck]->nodes[trucks[current_truck]->cameranodedir[0]].smoothpos;
				dir.normalise();
				angle=-atan2(dir.dotProduct(Vector3::UNIT_X), dir.dotProduct(-Vector3::UNIT_Z));

				if(externalCameraMode==0)
				{
					float pitch=-asin(dir.dotProduct(Vector3::UNIT_Y));
					camIdealPosition=camDist*Vector3(sin(angle+camRotX.valueRadians())*cos(pitch+camRotY.valueRadians()),sin(pitch+camRotY.valueRadians()),cos(angle+camRotX.valueRadians())*cos(pitch+camRotY.valueRadians()));
				} else if(externalCameraMode==1)
				{
					camIdealPosition=camDist*Vector3(sin(angle+camRotX.valueRadians())*cos(camRotY.valueRadians()),sin(camRotY.valueRadians()),cos(angle+camRotX.valueRadians())*cos(camRotY.valueRadians()));
				}

				camIdealPosition=camIdealPosition+trucks[current_truck]->getPosition();
				Vector3 oldposition=mCamera->getPosition()+trucks[current_truck]->nodes[0].Velocity*trucks[current_truck]->ttdt;
				float ratio=1.0/(trucks[current_truck]->tdt*4.0);
				//float ratio=0.001;
				//Vector3 newposition=(camIdealPosition+ratio*mCamera->getPosition())/(ratio+1.0);
				//Vector3 newposition=camIdealPosition;
				Vector3 newposition=(1/(ratio+1.0))*camIdealPosition+(ratio/(ratio+1.0))*oldposition;

				Real h=hfinder->getHeightAt(newposition.x,newposition.z);
				if (w && !w->allowUnderWater() && w->getHeightWaves(newposition)>h)
					h=w->getHeightWaves(newposition);
				h+=1.0;
				if (newposition.y<h) newposition.y=h;
				setCameraPositionWithCollision(newposition);
				mCamera->lookAt(trucks[current_truck]->getPosition());
				if(changeCamMode)
					mCamera->setFOVy(Degree(60));

				lastPosition=trucks[current_truck]->getPosition();
				//lastangle=angle;
			}
		}
		if (cameramode==CAMERA_FIX)
		{
			if (trucks[current_truck]->driveable==AIRPLANE)
			{
				if ((mCamera->getPosition()-trucks[current_truck]->getPosition()).length()>500.0)
				{
					Vector3 newposition=trucks[current_truck]->getPosition();
					Vector3 dir=trucks[current_truck]->nodes[0].Velocity;
					dir.normalise();
					newposition=newposition+dir*450.0+Vector3(5.0, 0.0, 5.0);
					Real h=hfinder->getHeightAt(newposition.x,newposition.z);
					Real random = Ogre::Math::RangeRandom(0.0f, 1.0f);
					if(w && random > 0.3f && !w->allowUnderWater())
					{
						// chance of 30% to get an underwater view?
						if (w && w->getHeightWaves(newposition)>h)
							h=w->getHeightWaves(newposition);
					} else if (w && w->allowUnderWater())
					{
						h=w->getHeightWaves(newposition) - 10.0f;
					}

					if (newposition.y<h+2.0) newposition.y=h+2.0;
					mCamera->setPosition(newposition);
				}
				mCamera->lookAt(trucks[current_truck]->getPosition());
				mCamera->setFOVy(Radian(atan2(100.0f,(mCamera->getPosition()-trucks[current_truck]->getPosition()).length())));
			}
			else
			{
				float px, pz;
				px=((int)(trucks[current_truck]->getPosition().x)/100)*100;
				pz=((int)(trucks[current_truck]->getPosition().z)/100)*100;
				Real h=hfinder->getHeightAt(px+50.0,pz+50.0);
				if (w && !w->allowUnderWater() && w->getHeightWaves(Vector3(px+50.0,0,pz+50.0))>h)
					h=w->getHeightWaves(Vector3(px+50.0,0,pz+50.0));
				mCamera->setPosition(Vector3(px+50.0, h+1.7, pz+50.0));
				mCamera->lookAt(trucks[current_truck]->getPosition());
				mCamera->setFOVy(Radian(atan2(20.0f,(mCamera->getPosition()-trucks[current_truck]->getPosition()).length())));
			}
		}
		if (cameramode==CAMERA_INT)
		{
			int currentcamera=trucks[current_truck]->currentcamera;
			if(changeCamMode)
				mCamera->setFOVy(Degree(90));
			if (trucks[current_truck]->cinecameranodepos>=0) lastPosition=trucks[current_truck]->nodes[trucks[current_truck]->cinecameranodepos[currentcamera]].smoothpos;
			else lastPosition=trucks[current_truck]->nodes[trucks[current_truck]->cameranodepos[currentcamera]].smoothpos;
			mCamera->setPosition(lastPosition);
			if(trucks[current_truck]->cablightNode)
				trucks[current_truck]->cablightNode->setPosition(lastPosition);
			//old direction code
			/*
			Vector3 dir=trucks[current_truck]->nodes[trucks[current_truck]->cameranodepos[currentcamera]].smoothpos-trucks[current_truck]->nodes[trucks[current_truck]->cameranoderoll[currentcamera]].smoothpos;
			dir.normalise();
			mCamera->lookAt(lastPosition+trucks[current_truck]->nodes[trucks[current_truck]->cameranodepos[currentcamera]].smoothpos-trucks[current_truck]->nodes[trucks[current_truck]->cameranodedir[currentcamera]].smoothpos);
			mCamera->roll(Radian(asin(dir.dotProduct(Vector3::UNIT_Y))));
			mCamera->yaw(-camRotX);
			mCamera->pitch(camRotY);
			*/
			Vector3 dir=trucks[current_truck]->nodes[trucks[current_truck]->cameranodepos[currentcamera]].smoothpos-trucks[current_truck]->nodes[trucks[current_truck]->cameranodedir[currentcamera]].smoothpos;
			dir.normalise();
			Vector3 side=trucks[current_truck]->nodes[trucks[current_truck]->cameranodepos[currentcamera]].smoothpos-trucks[current_truck]->nodes[trucks[current_truck]->cameranoderoll[currentcamera]].smoothpos;
			side.normalise();
			if (trucks[current_truck]->revroll[currentcamera]) side=-side; //to fix broken vehicles
			Vector3 up=dir.crossProduct(side);
			//we recompute the side vector to be sure we make an orthonormal system
			side=up.crossProduct(dir);
			Quaternion cdir=Quaternion(camRotX, up)*Quaternion(Degree(180.0)+camRotY, side)*Quaternion(side, up, dir);
			mCamera->setOrientation(cdir);

#ifdef USE_MPLATFORM
			mstat_t mStatInfo;

			// roll
			dir = trucks[current_truck]->nodes[trucks[current_truck]->cameranodepos[0]].RelPosition-trucks[current_truck]->nodes[trucks[current_truck]->cameranoderoll[0]].RelPosition;
			dir.normalise();

			float angle = asin(dir.dotProduct(Vector3::UNIT_Y));
			if (angle<-1) angle=-1;
			if (angle>1) angle=1;

			mStatInfo.roll = Radian(angle).valueRadians();

			//pitch
			dir=trucks[current_truck]->nodes[trucks[current_truck]->cameranodepos[0]].RelPosition-trucks[current_truck]->nodes[trucks[current_truck]->cameranodedir[0]].RelPosition;
			dir.normalise();

			angle=asin(dir.dotProduct(Vector3::UNIT_Y));
			if (angle<-1) angle=-1;
			if (angle>1) angle=1;

			mStatInfo.pitch = Radian(angle).valueRadians();

			mStatInfo.speed    = trucks[current_truck]->WheelSpeed;
			mStatInfo.clutch   = trucks[current_truck]->engine->getClutch();
			mStatInfo.rpm      = trucks[current_truck]->engine->getRPM();
			mStatInfo.throttle = INPUTENGINE.getEventValue(EV_TRUCK_ACCELERAT);
			mStatInfo.gear	   = trucks[current_truck]->engine->getGear();
			mStatInfo.brake	   = INPUTENGINE.getEventValue(EV_TRUCK_BRAKE);
			mStatInfo.steer	   = trucks[current_truck]->hydrodircommand;


			mplatform->update(mCamera->getPosition(), mCamera->getOrientation(), mStatInfo);
#endif

			if (w && lastPosition.y<w->getHeightWaves(lastPosition))
			{
				cameramode=CAMERA_EXT;
				camRotX=pushcamRotX;
				camRotY=pushcamRotY;
				trucks[current_truck]->prepareInside(false);
				if(ow) ow->showDashboardOverlays(true, trucks[current_truck]->driveable);
			}
		}
	}

	//set LOD per truck
	/*
	// TODO: XXX: fix below
	int i;
	for (i=0; i<free_truck; i++)
	{
		if(!trucks[i]) continue;
		trucks[i]->setDetailLevel((mCamera->getPosition()-trucks[i]->getPosition()).length()>trucks[i]->fadeDist);
	}
	*/
	//envmap
	if (envmap)
	{
		if (!envmap->inited)
			envmap->forceUpdate(Vector3(terrainxsize/2.0, hfinder->getHeightAt(terrainxsize/2.0, terrainzsize/2.0)+50.0, terrainzsize/2.0));
		if (current_truck != -1)
			envmap->update(trucks[current_truck]->getPosition(), trucks[current_truck]);
	}

	//position audio listener
	Vector3 cpos=mCamera->getPosition();
	Vector3 cdir=mCamera->getDirection();
	Vector3 cup=mCamera->getUp();
	Vector3 cspeed=(cpos-cdoppler)/dt;
	cdoppler=cpos;
	// XXX maybe thats the source of sound destorsion: runtime order???
#ifdef USE_OPENAL
	if(ssm) ssm->setCamera(cpos, cdir, cup, cspeed);
#endif // OPENAL
	//if (cspeed.length()>50.0) {cspeed.normalise(); cspeed=50.0*cspeed;};
	//if (audioManager) audioManager->setListenerPosition(cpos.x, cpos.y, cpos.z, cspeed.x, cspeed.y, cspeed.z, cdir.x, cdir.y, cdir.z, cup.x, cup.y, cup.z);
	//water
	if (w)
	{
		if (current_truck!=-1)
			w->moveTo(mCamera, w->getHeightWaves(trucks[current_truck]->getPosition()));
		else
			w->moveTo(mCamera, w->getHeight());
	}
}

#define isnan(x) (x!=x)


bool RoRFrameListener::updateAnimatedObjects(float dt)
{
	if(animatedObjects.size() == 0)
		return true;
	std::vector<animated_object_t>::iterator it;
	for(it=animatedObjects.begin(); it!=animatedObjects.end(); it++)
	{
		if(it->anim && it->speedfactor != 0)
		{
			Real time = dt * it->speedfactor;
			it->anim->addTime(time);
		}
	}
	return true;
}


bool RoRFrameListener::updateTruckMirrors(float dt)
{
	//mirror
	if (mirror && current_truck!=-1)
	{
		//searching the best mirror=the nearest in the fov
		int i,j;
		float minlen=10000.0;
		SceneNode *mirrornode=0;
		int mirrortype=0;
		//simplify
		//for (i=0; i<free_truck; i++)
		i=current_truck;
		{
			for (j=0; j<trucks[i]->free_prop; j++)
			{
				if (trucks[i]->props[j].mirror)
				{
					Vector3 dist=trucks[i]->props[j].snode->getPosition()-mCamera->getPosition();
					//is it in the fov?
					//						if (dist.directionEquals(mCamera->getDirection(), mCamera->getFOVy()*mCamera->getAspectRatio()/2.0))
					//(enlarged FOV)
					if (dist.directionEquals(mCamera->getDirection(), mCamera->getFOVy()*mCamera->getAspectRatio()/1.2)) // 1.6 -> 1.2
					{
						//yes maam
						float fdist=dist.length();
						if (fdist<minlen)
						{
							minlen=fdist;
							mirrornode=trucks[i]->props[j].snode;
							mirrortype=trucks[i]->props[j].mirror;
						};
					}
				}
			}

		}
		if (mirrornode)
		{
			/*
			static SceneNode *sn=0;
			static Entity *mda=0;
			if (sn == 0)
			{
				mda = mSceneMgr->createEntity("MirrorAxesDebug", "axes.mesh");
				sn = mSceneMgr->getRootSceneNode()->createChildSceneNode();
				sn->attachObject(mda);
				sn->setScale(0.1, 0.1, 0.1);
			}
			*/

			//woohee, we have found it
			//mirrornode->showBoundingBox(!mirrornode->getShowBoundingBox());
			//				mirror->update(Plane(mirrornode->getOrientation()*Vector3(0.947,0.316,0), mirrornode->getPosition()+mirrornode->getOrientation()*Vector3(0.07,-0.22,0)));
			//				mirror->update(Plane(mirrornode->getOrientation()*Vector3(1,0,0), mirrornode->getPosition()));
			//				mirror->update(Plane(Vector3(1,0,0), mirrornode->getPosition()));
			//				mirror->update(mirrornode->getOrientation()*Vector3(1,0,0), mirrornode->getPosition());

			//				if (mirrortype==1) mirror->update(mirrornode->getOrientation()*Vector3(0.866,0.5,0), mirrornode->getPosition()+mirrornode->getOrientation()*Vector3(0.07,-0.22,0));
			//				if (mirrortype==-1) mirror->update(mirrornode->getOrientation()*Vector3(0.866,-0.5,0), mirrornode->getPosition()+mirrornode->getOrientation()*Vector3(0.07,0.22,0));
			Vector3 updateNormal = Vector3::ZERO, updateCenter = Vector3::ZERO;

			// calculate truck roll
			Vector3 dir=trucks[current_truck]->nodes[trucks[current_truck]->cameranodepos[0]].RelPosition-trucks[current_truck]->nodes[trucks[current_truck]->cameranoderoll[0]].RelPosition;
			dir.normalise();
			Radian rollangle = Degree(360) - Radian(asin(dir.dotProduct(Vector3::UNIT_Y)));

			// two mirror types: left and right
			if (mirrortype==1)
			{
				updateNormal = mirrornode->getOrientation() * Vector3(cos(trucks[current_truck]->leftMirrorAngle),sin(trucks[current_truck]->leftMirrorAngle),0);
				updateCenter = mirrornode->getPosition()+mirrornode->getOrientation()*Vector3(0.07,-0.22,0);
			}
			if (mirrortype==-1)
			{
				updateNormal = mirrornode->getOrientation()*Vector3(cos(trucks[current_truck]->rightMirrorAngle),sin(trucks[current_truck]->rightMirrorAngle),0);
				updateCenter = mirrornode->getPosition()+mirrornode->getOrientation()*Vector3(0.07,0.22,0);
			}
			if(updateNormal != Vector3::ZERO && updateCenter != Vector3::ZERO)
			{
				//sn->setPosition(updateCenter);
				//sn->setDirection(updateNormal,Node::TS_WORLD);
				mirror->update(updateNormal, updateCenter, rollangle);
			}

		}
	}
	return true;
}

// Override frameStarted event to process that (don't care about frameEnded)
bool RoRFrameListener::frameStarted(const FrameEvent& evt)
{
	float dt=evt.timeSinceLastFrame;
	if (dt==0) return true;
	if (dt>1.0/20.0) dt=1.0/20.0;
	rtime+=dt; //real time
	if(mWindow->isClosed())
		return false;

	// update GUI
	INPUTENGINE.Capture();

	//if(collisions) 	printf("> ground model used: %s\n", collisions->last_used_ground_model->name);

	// exit frame started method when just displaying the GUI
#ifdef USE_MYGUI
	if (LoadingWindow::get()->getFrameForced())
		return true;
#endif //MYGUI

	if(showcredits && creditsviewtime > 0)
		creditsviewtime-= dt;
	if(showcredits && creditsviewtime < 0 && !shutdownall)
	{
		shutdown_final();
		return true;
	}
	else if(showcredits && creditsviewtime < 0 && shutdownall)
		return false;

	if(shutdownall) // shortcut: press ESC in credits
		return false;

	// the truck we use got deleted D:
	if(current_truck != -1 && trucks[current_truck] == 0)
		setCurrentTruck(-1);

	// update animated objects
	updateAnimatedObjects(dt);

	// update network gui if required, at most every 2 seconds
	if(net)
	{
		netcheckGUITimer += dt;
		if(netcheckGUITimer > 2)
		{
			checkRemoteStreamResultsChanged();
			netcheckGUITimer=0;
		}

#ifdef USE_SOCKETW
#ifdef USE_MYGUI
		// update net quality icon
		if(getNetQualityChanged())
		{
			GUI_Multiplayer::getSingleton().update();
		}
#endif // USE_MYGUI
#endif // USE_SOCKETW
	}

	// updating mirrors fixes its shaking!
	if (cameramode==CAMERA_INT)
		updateTruckMirrors(dt);

	moveCamera(dt); //antishaking

	// update water after the camera!
	if(loading_state==ALL_LOADED && w) w->framestep(dt);

	//update visual - antishaking
	int t;
	if (loading_state==ALL_LOADED)
	{
		for (t=0; t<free_truck; t++)
		{
			if(!trucks[t]) continue;
			if (trucks[t]->state!=SLEEPING && trucks[t]->loading_finished)
			{
				trucks[t]->updateSkidmarks();
				trucks[t]->updateVisual(dt);
			}
			//trucks[t]->updateFlares();
		}
	}

	if(!updateEvents(dt))
	{
		LogManager::getSingleton().logMessage("exiting...");
		return false;
	}

	// update gui 3d arrow
	if(ow && dirvisible && loading_state==ALL_LOADED)
	{
		dirArrowNode->lookAt(dirArrowPointed, Node::TS_WORLD,Vector3::UNIT_Y);
		char tmp[255];
		Real distance = 0;
		if(current_truck != -1 && trucks[current_truck]->state == ACTIVATED)
			distance = trucks[current_truck]->getPosition().distance(dirArrowPointed);
		else
			distance = person->getPosition().distance(dirArrowPointed);
		sprintf(tmp,"%0.1f meter", distance);
		ow->directionArrowDistance->setCaption(tmp);
	}

	// one of the input modes is immediate, so setup what is needed for immediate mouse/key movement
	if (mTimeUntilNextToggle >= 0)
		mTimeUntilNextToggle -= evt.timeSinceLastFrame;

	// If this is the first frame, pick a speed
	if (evt.timeSinceLastFrame == 0)
	{
		mMoveScale = 1;
		mRotScale = 0.1;
	}
	// Otherwise scale movement units by time passed since last frame
	else
	{
		// Move about 100 units per second,
		mMoveScale = mMoveSpeed * evt.timeSinceLastFrame;
		// Take about 10 seconds for full rotation
		mRotScale = mRotateSpeed * evt.timeSinceLastFrame;
	}

	// one of the input modes is immediate, so update the movement vector
	if (loading_state==ALL_LOADED)
	{
#ifdef USE_PAGED
		// paged geometry
		for(std::vector<paged_geometry_t>::iterator it=pagedGeometry.begin();it!=pagedGeometry.end();it++)
		{
			if(it->geom) it->geom->update();
		}
#endif //USE_PAGED

		//airplane chatter
		//chatter disabled for the moment
		//if (current_truck!=-1 && trucks[current_truck]->driveable==AIRPLANE && trucks[current_truck]->audio) trucks[current_truck]->audio->playChatter(dt);

		//the dirt
		//if (dirt) dirt->update(dt);
		if (current_truck!=-1)
		{
			trucks[current_truck]->disableDrag=false;
			recursiveActivation(current_truck);
			//if its grabbed, its moving
			if (isnodegrabbed && trucks[truckgrabbed]->state==SLEEPING) trucks[truckgrabbed]->desactivate();
			//put to sleep
			for (int t=0; t<free_truck; t++)
			{
				if(!trucks[t]) continue;
				if (trucks[t]->state==MAYSLEEP)
				{
					bool sleepyList[MAX_TRUCKS];
					for (int i=0; i<MAX_TRUCKS; i++) sleepyList[i]=false;
					if (!checkForActive(t, sleepyList))
					{
						//no active truck in the set, put everybody to sleep
						for (int i=0; i<free_truck; i++)
						{
							if(!trucks[i]) continue;
							if (sleepyList[i])
								trucks[i]->state=GOSLEEP;
						}
					}
				}
			}
		}

		//special stuff for rollable gear
		int t;
		bool rollmode=false;
		for (t=0; t<free_truck; t++)
		{
			if(!trucks[t]) continue;
			trucks[t]->updateFlares(dt, (t==current_truck) );
			if (trucks[t]->state!=SLEEPING)	rollmode=rollmode || trucks[t]->wheel_contact_requested;
			trucks[t]->requires_wheel_contact=rollmode;// && !trucks[t]->wheel_contact_requested;
		}

/* OLD CODE
		for (t=0; t<free_truck; t++)
		{
			if(!trucks[t]) continue;
			trucks[t]->updateFlares(dt, (t==current_truck) );
		}
		for (t=0; t<free_truck; t++)
		{
			if(!trucks[t]) continue;
			if (trucks[t]->state!=SLEEPING)
				rollmode=rollmode || trucks[t]->wheel_contact_requested;
		}
		for (t=0; t<free_truck; t++)
		{
			if(!trucks[t]) continue;
			trucks[t]->requires_wheel_contact=rollmode;// && !trucks[t]->wheel_contact_requested;
		}
END OF OLD CODE */

		//we simulate one truck, it will take care of the others (except networked ones)
		//this is the big "shaker"
		if (current_truck!=-1)
		{
			// now handle inter truck coll in different HT modes
			if (thread_mode == THREAD_HT2)
			{
				// wait for all threads to finish
				for (t=0; t<free_truck; t++)
				{
					if(!trucks[t]) continue;
					pthread_mutex_lock(&trucks[t]->done_count_mutex);
					while(trucks[t]->done_count > 0)
						pthread_cond_wait(&trucks[t]->done_count_cv, &trucks[t]->done_count_mutex);
					pthread_mutex_unlock(&trucks[t]->done_count_mutex);
				}

				// smooth the stuff
				for (t=0; t<free_truck; t++)
				{
					if(!trucks[t]) continue;
					trucks[t]->frameStep(dt, trucks, free_truck);
				}


				// inter truck coll.
				float dtperstep=dt/(Real)trucks[current_truck]->tsteps;
				trucks[current_truck]->truckTruckCollisions(dtperstep, trucks, free_truck);

				// unlock all threads
				for (t=0; t<free_truck; t++)
				{
					if(!trucks[t]) continue;
					trucks[t]->done_count=1;
					pthread_mutex_lock(&trucks[t]->work_mutex);
					pthread_cond_broadcast(&trucks[t]->work_cv);
					pthread_mutex_unlock(&trucks[t]->work_mutex);
				}
			} else
			{
				// classic mode
				trucks[current_truck]->frameStep(evt.timeSinceLastFrame, trucks, free_truck);
			}

		}

		//things always on
		for (t=0; t<free_truck; t++)
		{
			if(!trucks[t]) continue;
			//networked trucks must be taken care of

			switch(trucks[t]->state)
			{

				case NETWORKED:
				{
					trucks[t]->calcNetwork();
					break;
				}
				case RECYCLE:
				{
					break;
				}
				default:
				{
					if (t!=current_truck && trucks[t]->engine)
						trucks[t]->engine->update(dt, 1);
					if(trucks[t]->networking)
						trucks[t]->sendStreamData();
				}
			}
/* -- OLD CODE --

			if (trucks[t]->state==NETWORKED) trucks[t]->calcNetwork();
			//the flares are always on
			//trucks[t]->updateFlares(dt);

			//let the engines run
			if (t!=current_truck && trucks[t]->state!=NETWORKED && trucks[t]->state!=RECYCLE)
			{
				if (trucks[t]->engine) trucks[t]->engine->update(dt, 1);
			}
-- END OF OLD CODE */
		}
	}

	if (loading_state==ALL_LOADED)
	{
#ifdef USE_LUA
		if(lua) lua->framestep();
#endif //USE_LUA
		updateIO(dt);

		if(!isEmbedded)
		{
			updateGUI(dt);
		}
	}


	// TODO: check if all wheels are on a certain event id
	// wheels[nodes[i].wheelid].lastEventHandler

#ifdef USE_ANGELSCRIPT
	ScriptEngine::getSingleton().framestep(dt, trucks, free_truck);
#endif

	// update network labels
	if(net)
	{
		CharacterFactory::getSingleton().updateLabels();
	}

	return true;
}

void RoRFrameListener::removeBeam(Beam *b)
{
	int i;
	for (i=0; i<free_truck; i++)
	{
		if(!trucks[i]) continue;
		if(trucks[i] == b)
		{
			trucks[i] = 0;
			break;
		}
	}
}

void RoRFrameListener::recursiveActivation(int j)
{
	int i;
	for (i=0; i<free_truck; i++)
	{
		if(!trucks[i]) continue;
		if ((trucks[i]->state==SLEEPING || trucks[i]->state==MAYSLEEP || trucks[i]->state==GOSLEEP ||(trucks[i]->state==DESACTIVATED && trucks[i]->sleepcount>=5)) &&
			((trucks[j]->minx<trucks[i]->minx && trucks[i]->minx<trucks[j]->maxx) || (trucks[j]->minx<trucks[i]->maxx && trucks[i]->maxx<trucks[j]->maxx) || (trucks[i]->minx<trucks[j]->maxx && trucks[j]->maxx<trucks[i]->maxx)) &&
			((trucks[j]->miny<trucks[i]->miny && trucks[i]->miny<trucks[j]->maxy) || (trucks[j]->miny<trucks[i]->maxy && trucks[i]->maxy<trucks[j]->maxy) || (trucks[i]->miny<trucks[j]->maxy && trucks[j]->maxy<trucks[i]->maxy)) &&
			((trucks[j]->minz<trucks[i]->minz && trucks[i]->minz<trucks[j]->maxz) || (trucks[j]->minz<trucks[i]->maxz && trucks[i]->maxz<trucks[j]->maxz) || (trucks[i]->minz<trucks[j]->maxz && trucks[j]->maxz<trucks[i]->maxz))
			)
		{
			trucks[i]->desactivate();//paradoxically, this activates the truck!
			trucks[i]->disableDrag=trucks[current_truck]->driveable==AIRPLANE;
			recursiveActivation(i);
		};
	}
}

//j is the index of a MAYSLEEP truck, returns true if one active was found in the set
bool RoRFrameListener::checkForActive(int j, bool *sleepyList)
{
	int i;
	sleepyList[j]=true;
	for (i=0; i<free_truck; i++)
	{
		if(!trucks[i]) continue;
		if ( !sleepyList[i] &&
			((trucks[j]->minx<trucks[i]->minx && trucks[i]->minx<trucks[j]->maxx) || (trucks[j]->minx<trucks[i]->maxx && trucks[i]->maxx<trucks[j]->maxx) || (trucks[i]->minx<trucks[j]->maxx && trucks[j]->maxx<trucks[i]->maxx)) &&
			((trucks[j]->miny<trucks[i]->miny && trucks[i]->miny<trucks[j]->maxy) || (trucks[j]->miny<trucks[i]->maxy && trucks[i]->maxy<trucks[j]->maxy) || (trucks[i]->miny<trucks[j]->maxy && trucks[j]->maxy<trucks[i]->maxy)) &&
			((trucks[j]->minz<trucks[i]->minz && trucks[i]->minz<trucks[j]->maxz) || (trucks[j]->minz<trucks[i]->maxz && trucks[i]->maxz<trucks[j]->maxz) || (trucks[i]->minz<trucks[j]->maxz && trucks[j]->maxz<trucks[i]->maxz))
			)
		{
			if (trucks[i]->state==MAYSLEEP || (trucks[i]->state==DESACTIVATED && trucks[i]->sleepcount>=5))
			{
				if (checkForActive(i, sleepyList)) return true;
			}
			else return true;
		};
	}
	return false;
}

bool RoRFrameListener::setCameraPositionWithCollision(Vector3 newPos)
{
	bool res = true;
// put 1 here to enable camera collision
#if 0
	if(!mCollisionTools) return false;
	if(newPos == mCamera->getPosition()) return false;

	if(mCollisionTools->collidesWithEntity(mCamera->getPosition(), newPos, 1.0f, -1.0f, OBJECTS_MASK | TRUCKS_MASK))
	{
		// collides, move back to last known stable position
		newPos = camPosColl;
		res = false;
	} else
	{
		// no collision, store position as stable
		camPosColl = newPos;
	}
	camCollided = !res;
	// does not collide, move
	mCamera->setPosition(newPos);
#else
	// no collision of camera, normal mode
	mCamera->setPosition(newPos);
#endif
	return res;
}

bool RoRFrameListener::frameEnded(const FrameEvent& evt)
{
	// TODO: IMPROVE STATS
	if(ow) ow->updateStats();

#if OGRE_PLATFORM == OGRE_PLATFORM_WIN32
		/*
		// this *could* improve the event handling under windows ...
		MSG msg;
		if (PeekMessage( &msg, NULL, 0U, 0U, PM_REMOVE )>0)
		{
			TranslateMessage( &msg );
			DispatchMessage( &msg );
		}
		*/
#endif

	//		moveCamera();

	// workaround to be able to show a single waiting sign before working on the files
	//if(uiloader && uiloader->hasWork())
	//	uiloader->dowork();

	if(heathaze)
		heathaze->update();
#ifdef USE_SOCKETW
	if(net)
	{
		// process all packets and streams received
		NetworkStreamManager::getSingleton().update();
	}
#endif //SOCKETW
	return true;
}


void RoRFrameListener::showLoad(int type, char* instance, char* box)
{
	// check for water
	/*
	if ((SETTINGS.getSetting("Water effects")=="None") && type == LOADER_BOAT)
	{
		if(ow) ow->flashMessage("Closed (No water)", 4);
		return;
	}
	*/

	//first, test if the place if clear
	collision_box_t *spawnbox=collisions->getBox(instance, box);
	for (int t=0; t<free_truck; t++)
	{
		if(!trucks[t]) continue;
		for (int i=0; i<trucks[t]->free_node; i++)
		{
			if (collisions->isInside(trucks[t]->nodes[i].AbsPosition, spawnbox))
			{
				//boy, thats bad
				if(ow) ow->flashMessage(_L("Please clear the place first"), 4);
				return;
			}
		}
	}
	reload_pos=collisions->getPosition(instance, box);
	reload_dir=collisions->getDirection(instance, box);
	reload_box=collisions->getBox(instance, box);
	loading_state=RELOADING;
	hideMap();
#ifdef USE_MYGUI
	SelectorWindow::get()->show(SelectorWindow::LoaderType(type));
#endif // MYGUI
}

bool RoRFrameListener::fileExists(const char* filename)
{
	FILE* f = fopen(filename, "rb");
	if(f != NULL) {
		fclose(f);
		return true;
	}
	return false;
}

void RoRFrameListener::setDirectionArrow(char *text, Vector3 position)
{
	if(!ow) return;
	if(!text)
	{
		dirArrowNode->setVisible(false);
		dirvisible = false;
		dirArrowPointed = Vector3::ZERO;
		ow->directionOverlay->hide();
	}
	else
	{
		ow->directionOverlay->show();
		ow->directionArrowText->setCaption(String(text));
		float w = ow->directionArrowText->getWidth();
		//LogManager::getSingleton().logMessage("*** new pointed position: " + StringConverter::toString(position));
		ow->directionArrowDistance->setCaption("");
		dirvisible = true;
		dirArrowPointed = position;
		dirArrowNode->setVisible(true);
	}

}

void RoRFrameListener::netDisconnectTruck(int number)
{
	// we will remove the truck completely
	// TODO: fix that below!
	//removeTruck(number);
#ifdef USE_MYGUI
	if(bigMap)
	{
		MapEntity *e = bigMap->getEntityByName("Truck"+StringConverter::toString(number));
		if(e)
			e->setVisibility(false);
	}
#endif // MYGUI
}


/* --- Window Events ------------------------------------------ */
void RoRFrameListener::windowResized(RenderWindow* rw)
{
	if(!rw)
		return;
	LogManager::getSingleton().logMessage("*** windowResized");

	// Update mouse screen width/height
	unsigned int width, height, depth;
	int left, top;
	rw->getMetrics(width, height, depth, left, top);
	screenWidth = width;
	screenHeight = height;

	//update mouse area
	INPUTENGINE.windowResized(rw);
}

//Unattach OIS before window shutdown (very important under Linux)
void RoRFrameListener::windowClosed(RenderWindow* rw)
{
	LogManager::getSingleton().logMessage("*** windowClosed");
}

void RoRFrameListener::windowMoved(RenderWindow* rw)
{
	LogManager::getSingleton().logMessage("*** windowMoved");
}

void RoRFrameListener::windowFocusChange(RenderWindow* rw)
{
	LogManager::getSingleton().logMessage("*** windowFocusChange");
	INPUTENGINE.resetKeys();
}

Ogre::Ray RoRFrameListener::getMouseRay()
{
	return mCamera->getCameraToViewportRay((float)mouseX/(float)screenWidth, (float)mouseY/(float)screenHeight);
}

void RoRFrameListener::pauseSim(bool value)
{
	// TODO: implement this (how to do so?)
	static int savedmode = -1;
	if(value && loading_state == EDITOR_PAUSE)
		// already paused
		return;
	if(value)
	{
		savedmode = loading_state;
		loading_state = EDITOR_PAUSE;
		LogManager::getSingleton().logMessage("** pausing game");
	} else if (!value && savedmode != -1)
	{
		loading_state = savedmode;
		LogManager::getSingleton().logMessage("** unpausing game");
	}
}

void RoRFrameListener::initSoftShadows()
{
	// we'll be self shadowing
	mSceneMgr->setShadowTextureSelfShadow(true);

	// our caster material
	mSceneMgr->setShadowTextureCasterMaterial("shadow_caster");
	// note we have no "receiver".  all the "receivers" are integrated.

	// get the shadow texture count from the cfg file
	String tempData = SETTINGS.getSetting("shadowTextureCount");
	if(tempData.empty()) tempData = "4";
	// (each light needs a shadow texture)
	mSceneMgr->setShadowTextureCount(Ogre::StringConverter::parseInt(tempData));

	// the size, too (1024 looks good with 3x3 or more filtering)
	tempData = SETTINGS.getSetting("shadowTextureRes");
	if(tempData.empty()) tempData = "256";
	mSceneMgr->setShadowTextureSize(Ogre::StringConverter::parseInt(tempData));

	// float 16 here.  we need the R and G channels.
	// float 32 works a lot better with a low/none VSM epsilon (wait till the shaders)
	// but float 16 is good enough and supports bilinear filtering on a lot of cards
	// (we should use _GR, but OpenGL doesn't really like it for some reason)
	mSceneMgr->setShadowTexturePixelFormat(Ogre::PF_FLOAT16_RGB);

	// big NONO to render back faces for VSM.  it doesn't need any biasing
	// so it's worthless (and rather problematic) to use the back face hack that
	// works so well for normal depth shadow mapping (you know, so you don't
	// get surface acne)
	mSceneMgr->setShadowCasterRenderBackFaces(false);

	const unsigned numShadowRTTs = mSceneMgr->getShadowTextureCount();
	for (unsigned i = 0; i < numShadowRTTs; ++i)
	{
		Ogre::TexturePtr tex = mSceneMgr->getShadowTexture(i);
		Ogre::Viewport *vp = tex->getBuffer()->getRenderTarget()->getViewport(0);
		vp->setBackgroundColour(Ogre::ColourValue(1, 1, 1, 1));
		vp->setClearEveryFrame(true);
	}

	// enable integrated additive shadows
	// actually, since we render the shadow map ourselves, it doesn't
	// really matter whether they are additive or modulative
	// as long as they are integrated v(O_o)v
	mSceneMgr->setShadowTechnique(Ogre::SHADOWTYPE_TEXTURE_ADDITIVE_INTEGRATED);

	// and add the shader listener
	SoftShadowListener *ssl = new SoftShadowListener();
#if OGRE_VERSION<0x010602
	mSceneMgr->addShadowListener(ssl);
#else
	mSceneMgr->addListener(ssl);
#endif //OGRE_VERSION
}

void RoRFrameListener::initSSAO()
{
	Viewport *vp = mCamera->getViewport();
    CompositorInstance *ssao = Ogre::CompositorManager::getSingleton().addCompositor(vp, "ssao");
    ssao->setEnabled(true);
	SSAOListener *ssaol = new SSAOListener(mSceneMgr, mCamera);
    ssao->addListener(ssaol);
}

void RoRFrameListener::initHDR()
{
	Viewport *vp = mCamera->getViewport();
	Ogre::CompositorInstance *instance = Ogre::CompositorManager::getSingleton().addCompositor(vp, "HDR", 0);
	Ogre::CompositorManager::getSingleton().setCompositorEnabled(vp, "HDR", true);

	// HDR needs a special listener
	hdrListener = new HDRListener();
	instance->addListener(hdrListener);
	hdrListener->notifyViewportSize(vp->getActualWidth(), vp->getActualHeight());
	hdrListener->notifyCompositor(instance);
}

void RoRFrameListener::hideGUI(bool visible)
{
	if(visible)
	{
		if(ow) ow->mouseOverlay->hide();
		if (netmode && NETCHAT.getVisible())
			NETCHAT.toggleVisible(this);

		if(ow) ow->showDashboardOverlays(false,0);
		if(ow) ow->showEditorOverlay(false);
		if(ow) ow->truckhud->show(false);
		//if(bigMap) bigMap->setVisibility(false);
#ifdef USE_MYGUI
#ifdef USE_SOCKETW
		if(net) GUI_Multiplayer::getSingleton().setVisible(false);
#endif // USE_SOCKETW
#endif // USE_MYGUI
	}
	else
	{
		if (netmode && !NETCHAT.getVisible())
			NETCHAT.toggleVisible(this);
		if(current_truck != -1 && cameramode!=CAMERA_INT)
		{
			if(ow) ow->mouseOverlay->show();
			if(ow) ow->showDashboardOverlays(true, trucks[current_truck]->driveable);
			//if(bigMap) bigMap->setVisibility(true);
		}
#ifdef USE_SOCKETW
#ifdef USE_MYGUI
		if(net) GUI_Multiplayer::getSingleton().setVisible(true);
#endif // USE_MYGUI
#endif // USE_SOCKETW
	}
}

// from http://www.ogre3d.org/wiki/index.php/High_resolution_screenshots
void RoRFrameListener::gridScreenshots(Ogre::RenderWindow* pRenderWindow, Ogre::Camera* pCamera, const int& pGridSize, const Ogre::String& path, const Ogre::String& pFileName, const Ogre::String& pFileExtention, const bool& pStitchGridImages)
{
  /* Parameters:
   *  pRenderWindow:    Pointer to the render window.  This could be "mWindow" from the ExampleApplication,
   *              the window automatically created obtained when calling
   *              Ogre::Root::getSingletonPtr()->initialise(false) and retrieved by calling
   *              "Ogre::Root::getSingletonPtr()->getAutoCreatedWindow()", or the manually created
   *              window from calling "mRoot->createRenderWindow()".
   *  pCamera:      Pointer to the camera "looking at" the scene of interest
   *  pGridSize:      The magnification factor.  A 2 will create a 2x2 grid, doubling the size of the
                screenshot.  A 3 will create a 3x3 grid, tripling the size of the screenshot.
   *  pFileName:      The filename to generate, without an extention.  To generate "MyScreenshot.png" this
   *              parameter would contain the value "MyScreenshot".
   *  pFileExtention:    The extention of the screenshot file name, hence the type of graphics file to generate.
   *              To generate "MyScreenshot.pnh" this parameter would contain ".png".
   *  pStitchGridImages:  Determines whether the grid screenshots are (true) automatically stitched into a single
   *              image (and discarded) or whether they should (false) remain in their unstitched
   *              form.  In that case they are sequentially numbered from 0 to
   *              pGridSize * pGridSize - 1 (if pGridSize is 3 then from 0 to 8).
   *
  */
  Ogre::String gridFilename;
  Ogre::Matrix4 orgmat = pCamera->getProjectionMatrix();

  // hack: add path to resource
  ResourceGroupManager::getSingleton().addResourceLocation(path, "FileSystem");

  if(pGridSize <= 1)
  {
    // Simple case where the contents of the screen are taken directly
    // Also used when an invalid value is passed within pGridSize (zero or negative grid size)
    gridFilename = pFileName + pFileExtention;

    pRenderWindow->writeContentsToFile(path + gridFilename);
  }
  else
  {
    // Generate a grid of screenshots
    pCamera->setCustomProjectionMatrix(false); // reset projection matrix
    Ogre::Matrix4 standard = pCamera->getProjectionMatrix();
    double nearDist = pCamera->getNearClipDistance();
    double nearWidth = (pCamera->getWorldSpaceCorners()[0] - pCamera->getWorldSpaceCorners()[1]).length();
    double nearHeight = (pCamera->getWorldSpaceCorners()[1] - pCamera->getWorldSpaceCorners()[2]).length();
    Ogre::Image sourceImage;
    Ogre::uchar* stitchedImageData = 0;

    // Process each grid
    for (int nbScreenshots = 0; nbScreenshots < pGridSize * pGridSize; nbScreenshots++)
    {
      // Use asymmetrical perspective projection. For more explanations check out:
      // http://www.cs.kuleuven.ac.be/cwis/research/graphics/INFOTEC/viewing-in-3d/node8.html
      int y = nbScreenshots / pGridSize;
      int x = nbScreenshots - y * pGridSize;
      Ogre::Matrix4 shearing(
        1, 0,(x - (pGridSize - 1) * 0.5) * nearWidth / nearDist, 0,
        0, 1, -(y - (pGridSize - 1) * 0.5) * nearHeight / nearDist, 0,
        0, 0, 1, 0,
        0, 0, 0, 1);
      Ogre::Matrix4 scale(
        pGridSize, 0, 0, 0,
        0, pGridSize, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1);
      pCamera->setCustomProjectionMatrix(true, standard * shearing * scale);
      Ogre::Root::getSingletonPtr()->renderOneFrame();
      gridFilename = pFileName + Ogre::StringConverter::toString(nbScreenshots) + pFileExtention;


      // Screenshot of the current grid
      pRenderWindow->writeContentsToFile(path + gridFilename);

      if(pStitchGridImages)
      {
        // Automatically stitch the grid screenshots
		if(!CacheSystem::resourceExistsInAllGroups(gridFilename))
		{
			LogManager::getSingleton().logMessage("Unable to stich image. Image not found: "+gridFilename);
			return ;
		}

		String group = ResourceGroupManager::getSingleton().findGroupContainingResource(gridFilename);

        sourceImage.load(gridFilename, group);
        int sourceWidth = (int) sourceImage.getWidth();
        int sourceHeight = (int) sourceImage.getHeight();
        Ogre::ColourValue colourValue;
        int stitchedX, stitchedY, stitchedIndex;

        // Allocate memory for the stitched image when processing the screenshot of the first grid
        if(nbScreenshots == 0)
          stitchedImageData = new Ogre::uchar[(sourceImage.getWidth() * pGridSize) * (sourceImage.getHeight() * pGridSize) * 3]; // 3 colors per pixel

        // Copy each pixel within the grid screenshot to the proper position within the stitched image
        for(int rawY = 0; rawY < sourceHeight; rawY++)
        {
          for(int rawX = 0; rawX < sourceWidth; rawX++)
          {
            colourValue = sourceImage.getColourAt(rawX, rawY, 0);
            stitchedX = x * sourceWidth + rawX;
            stitchedY = y * sourceHeight + rawY;
            stitchedIndex = stitchedY * sourceWidth * pGridSize + stitchedX;
            Ogre::PixelUtil::packColour(colourValue,
                          Ogre::PF_R8G8B8,
                          (void*) &stitchedImageData[stitchedIndex * 3]);
          }
        }
        // The screenshot of the grid is no longer needed
        remove((path + gridFilename).c_str());
      }
    }
    pCamera->setCustomProjectionMatrix(false); // reset projection matrix

    if(pStitchGridImages)
    {
      // Save the stitched image to a file
      Ogre::Image targetImage;
      targetImage.loadDynamicImage(stitchedImageData,
                    sourceImage.getWidth() * pGridSize,
                    sourceImage.getHeight() * pGridSize,
                    1, // depth
                    Ogre::PF_R8G8B8,
                    false);
      targetImage.save(path + pFileName + pFileExtention);
      delete[] stitchedImageData;
    }
  }

  pCamera->setCustomProjectionMatrix(true, orgmat);
}

// show/hide all particle systems
void RoRFrameListener::showspray(bool s)
{
	DustManager::getSingleton().setVisible(s);
}


int RoRFrameListener::getFreeTruckSlot()
{
	// find a free slot for the truck
	for (int i=0; i<MAX_TRUCKS; i++)
	{
		if(trucks[i] == 0 && i >= free_truck) // XXX: TODO: remove this hack
		{
			// reuse slots
			if(i >= free_truck)
				free_truck = i + 1;
			return i;
		}
	}
	return -1;
}

int RoRFrameListener::addTruck(Beam *b)
{
	// find a free slot for the truck
	for (int i=0; i<MAX_TRUCKS; i++)
	{
		if(trucks[i] == 0 && i >= free_truck) // XXX: TODO: remove this hack
		{
			// reuse old slots
			trucks[i] = b;
			if(i >= free_truck)
				free_truck = i + 1;
			return i;
		}
	}
	return -1;
}

void RoRFrameListener::setLoadingState(int value)
{
	loading_state = value;
}

void RoRFrameListener::setNetPointToUID(int uid)
{
	// TODO: setup arrow
	netPointToUID = uid;
}


void RoRFrameListener::checkRemoteStreamResultsChanged()
{
#ifdef USE_MYGUI
#ifdef USE_SOCKETW
	if(BeamFactory::getSingleton().checkStreamsResultsChanged())
		GUI_Multiplayer::getSingleton().update();
#endif // USE_SOCKETW
#endif // USE_MYGUI
}


void RoRFrameListener::setNetQuality(int q)
{
	pthread_mutex_lock(&mutex_data);
	net_quality = q;
	net_quality_changed = true;
	pthread_mutex_unlock(&mutex_data);
}

int RoRFrameListener::getNetQuality(bool ack)
{
	int res = 0;
	pthread_mutex_lock(&mutex_data);
	res = net_quality;
	if(ack) net_quality_changed=false;
	pthread_mutex_unlock(&mutex_data);
	return res;
}

bool RoRFrameListener::getNetQualityChanged()
{
	bool res = false;
	pthread_mutex_lock(&mutex_data);
	res = net_quality_changed;
	pthread_mutex_unlock(&mutex_data);
	return res;
}
