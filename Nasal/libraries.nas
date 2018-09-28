# PA28-161 Libraries
# Joshua Davidson (it0uchpods)

rightDoor = aircraft.door.new("/sim/model/door-positions/rightDoor", 2, 0);

setlistener("/sim/sounde/switch1", func {
	if (!getprop("/sim/sounde/switch1")) {
		return;
	}
	settimer(func {
		props.globals.getNode("/sim/sounde/switch1").setBoolValue(0);
	}, 0.05);
});

setlistener("/sim/sounde/switch2", func {
	if (!getprop("/sim/sounde/switch2")) {
		return;
	}
	settimer(func {
		props.globals.getNode("/sim/sounde/switch2").setBoolValue(0);
	}, 0.05);
});

setlistener("/sim/sounde/switch3", func {
	if (!getprop("/sim/sounde/switch3")) {
		return;
	}
	settimer(func {
		props.globals.getNode("/sim/sounde/switch3").setBoolValue(0);
	}, 0.05);
});

setlistener("/sim/sounde/knob", func {
	if (!getprop("/sim/sounde/knob")) {
		return;
	}
	settimer(func {
		props.globals.getNode("/sim/sounde/knob").setBoolValue(0);
	}, 0.05);
});

var systemsInit = func {
	systems.ELEC.init();
	systems.FUEL.init();
	variousReset();
	var autopilot = gui.Dialog.new("sim/gui/dialogs/autopilot/dialog", "Aircraft/PA28-Warrior/Systems/stec-55x-dlg.xml");
	setprop("/controls/engines/engine[0]/magnetos-switch", 0);
	setprop("/engines/engine[0]/fuel-flow-gph", 0.0);
	setprop("/sim/model/material/LandingLight/factor", 0.0);
	setprop("/sim/model/material/LandingLight/factorAGL", 0.0);
	setprop("/instrumentation/adf[0]/rotation-deg", 0);
	systemsLoop.start();
}

var systemsReset = func {
	systemsInit();
	stec55x.ITAF.init();
}

setlistener("sim/signals/fdm-initialized", func {
	systemsInit();
});

var systemsLoop = maketimer(0.1, func {
	systems.ELEC.loop();
	systems.FUEL.loop();
});

var variousReset = func {
	setprop("/controls/switches/beacon", 1);
	setprop("/controls/switches/fuel-pump", 0);
	setprop("/controls/switches/landing-light", 0);
	setprop("/controls/switches/nav-lights-factor", 0);
	setprop("/controls/switches/panel-lights-factor", 0);
	setprop("/controls/switches/pitot-heat", 0);
	setprop("/controls/switches/strobe-lights", 0);
	setprop("/systems/fuel/selected-tank", 1);
	setprop("/controls/anti-ice/engine[0]/carb-heat-cmd", 0);
	setprop("/controls/engines/engine[0]/magnetos-switch", 0);
	setprop("/controls/engines/engine[0]/mixture", 0);
	setprop("/fdm/jsbsim/extra/door-main-cmd", 0);
}

if (getprop("/controls/flight/auto-coordination") == 1) {
	setprop("/controls/flight/auto-coordination", 0);
	setprop("/controls/flight/aileron-drives-tiller", 1);
} else {
	setprop("/controls/flight/aileron-drives-tiller", 0);
}

var slewProp = func(prop, delta) {
	delta *= getprop("/sim/time/delta-realtime-sec");
	setprop(prop, getprop(prop) + delta);
	return getprop(prop);
}

controls.elevatorTrim = func(speed) {
	slewProp("/controls/flight/elevator-trim", speed * 0.04);
}
