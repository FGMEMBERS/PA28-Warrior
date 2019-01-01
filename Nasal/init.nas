# PA28-161 Init File
# Copyright (c) 2019 Joshua Davidson (it0uchpods)

#############
# Init Vars #
#############

var INIT = {
	ENG: func() {
		setprop("/controls/engines/engine[0]/magnetos-switch", 0);
	},
	FUEL: func() {
		setprop("/systems/fuel/selected-tank", 1);
		setprop("/controls/switches/fuel-pump", 0);
		setprop("/systems/fuel/suck-psi", 0);
		setprop("/systems/fuel/pump-psi", 0);
		setprop("/fdm/jsbsim/fuel/pump-psi-feedback", 0);
		setprop("/fdm/jsbsim/fuel/suck-psi-feedback", 0);
	},
};
