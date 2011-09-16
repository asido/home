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
#ifndef __ForceFeedback_H__
#define __ForceFeedback_H__

#include "Ogre.h"
#include <math.h>
#include "OISForceFeedback.h"

using namespace Ogre;
class ForceFeedback
{
private:
	OIS::ForceFeedback* ffdevice;
	OIS::Effect* hydroEffect;
	Real overall_gain;
	Real stress_gain;
	Real centering_gain;
	Real camera_gain;
	bool enabled_state;
public:

	ForceFeedback(OIS::ForceFeedback* ffdevice, Real overall_gain, Real stress_gain, Real centering_gain, Real camera_gain);
	~ForceFeedback();

	/*we take here :
	  -roll and pitch inertial forces at the camera: this is not used currently, but it can be used for 2 axes force feedback devices, like FF joysticks, to render shocks
	  -wheel speed and direction command, for the artificial auto-centering (which is wheel speed dependant)
	  -hydro beam stress, the ideal data source for FF wheels
	 */
	void setForces(Real roll, Real pitch, Real wspeed, Real dircommand, Real stress);
	void setEnabled(bool b);

};


#endif
