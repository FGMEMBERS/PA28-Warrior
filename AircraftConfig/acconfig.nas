# Aircraft Config Center
# Joshua Davidson (it0uchpods)

# Copyright (c) 2018 Joshua Davidson (it0uchpods)

var spinning = maketimer(0.05, func {
	var spinning = getprop("/systems/acconfig/spinning");
	if (spinning == 0) {
		setprop("/systems/acconfig/spin", "\\");
		setprop("/systems/acconfig/spinning", 1);
	} else if (spinning == 1) {
		setprop("/systems/acconfig/spin", "|");
		setprop("/systems/acconfig/spinning", 2);
	} else if (spinning == 2) {
		setprop("/systems/acconfig/spin", "/");
		setprop("/systems/acconfig/spinning", 3);
	} else if (spinning == 3) {
		setprop("/systems/acconfig/spin", "-");
		setprop("/systems/acconfig/spinning", 0);
	}
});

var failReset = func {
	setprop("/systems/failures/battery", 0);
	setprop("/systems/failures/alternator", 0);
	setprop("/systems/failures/elec-1", 0);
	setprop("/systems/failures/elec-2", 0);
	setprop("/systems/failures/avionics-1", 0);
	setprop("/systems/failures/avionics-2", 0);
	setprop("/systems/failures/eng-suck", 0);
	setprop("/systems/failures/fuel-pump", 0);
	setprop("/systems/failures/starter", 0);
	setprop("/systems/failures/l-magneto", 0);
	setprop("/systems/failures/r-magneto", 0);
	setprop("/systems/failures/l-brake", 0);
	setprop("/systems/failures/r-brake", 0);
	setprop("/systems/failures/stec-55x", 0);
};

setlistener("/systems/failures/stec-55x", func {
	if (getprop("/systems/failures/stec-55x") == 1) {
		setprop("/it-stec55x/serviceable", 0);
	} else {
		setprop("/it-stec55x/serviceable", 1);
	}
});

failReset();
setprop("/systems/acconfig/autoconfig-running", 0);
setprop("/systems/acconfig/spinning", 0);
setprop("/systems/acconfig/spin", "-");
setprop("/systems/acconfig/options/revision", 0);
setprop("/systems/acconfig/new-revision", "");
setprop("/systems/acconfig/out-of-date", 0);
setprop("/systems/acconfig/options/welcome-skip", 0);
setprop("/systems/acconfig/options/panel", "HSI Panel");
setprop("/systems/acconfig/options/show-l-yoke", 1);
setprop("/systems/acconfig/options/show-r-yoke", 1);
setprop("/systems/acconfig/options/fd-equipped", 0);
setprop("/systems/acconfig/options/mini-panel", 0);
var main_dlg = gui.Dialog.new("sim/gui/dialogs/acconfig/main/dialog", "Aircraft/PA28-Warrior/AircraftConfig/main.xml");
var welcome_dlg = gui.Dialog.new("sim/gui/dialogs/acconfig/welcome/dialog", "Aircraft/PA28-Warrior/AircraftConfig/welcome.xml");
var ps_load_dlg = gui.Dialog.new("sim/gui/dialogs/acconfig/psload/dialog", "Aircraft/PA28-Warrior/AircraftConfig/psload.xml");
var ps_loaded_dlg = gui.Dialog.new("sim/gui/dialogs/acconfig/psloaded/dialog", "Aircraft/PA28-Warrior/AircraftConfig/psloaded.xml");
var init_dlg = gui.Dialog.new("sim/gui/dialogs/acconfig/init/dialog", "Aircraft/PA28-Warrior/AircraftConfig/ac_init.xml");
var help_dlg = gui.Dialog.new("sim/gui/dialogs/acconfig/help/dialog", "Aircraft/PA28-Warrior/AircraftConfig/help.xml");
var about_dlg = gui.Dialog.new("sim/gui/dialogs/acconfig/about/dialog", "Aircraft/PA28-Warrior/AircraftConfig/about.xml");
var update_dlg = gui.Dialog.new("sim/gui/dialogs/acconfig/update/dialog", "Aircraft/PA28-Warrior/AircraftConfig/update.xml");
var updated_dlg = gui.Dialog.new("sim/gui/dialogs/acconfig/update/dialog", "Aircraft/PA28-Warrior/AircraftConfig/updated.xml");
var fail_dlg = gui.Dialog.new("sim/gui/dialogs/acconfig/fail/dialog", "Aircraft/PA28-Warrior/AircraftConfig/fail.xml");
var controlpanel_dlg = gui.Dialog.new("sim/gui/dialogs/acconfig/controlpanel/dialog", "Aircraft/PA28-Warrior/AircraftConfig/control-panel.xml");
var minipanel_dlg = gui.Dialog.new("sim/gui/dialogs/acconfig/minipanel/dialog", "Aircraft/PA28-Warrior/AircraftConfig/mini-panel.xml");
spinning.start();
init_dlg.open();

http.load("https://raw.githubusercontent.com/it0uchpods/PA28-Warrior/master/revision.txt").done(func(r) setprop("/systems/acconfig/new-revision", r.response));
var revisionFile = (getprop("/sim/aircraft-dir")~"/revision.txt");
var current_revision = io.readfile(revisionFile);
setprop("/systems/acconfig/revision", current_revision);

setlistener("/systems/acconfig/new-revision", func {
	if (getprop("/systems/acconfig/new-revision") > current_revision) {
		setprop("/systems/acconfig/out-of-date", 1);
	} else {
		setprop("/systems/acconfig/out-of-date", 0);
	}
});

setlistener("/sim/signals/fdm-initialized", func {
	init_dlg.close();
	if (getprop("/systems/acconfig/out-of-date") == 1) {
		update_dlg.open();
		print("The PA28-Warrior is out of date!");
	}
	readSettings();
	if (getprop("/systems/acconfig/out-of-date") != 1 and getprop("/systems/acconfig/options/revision") < current_revision) {
		updated_dlg.open();
	} else if (getprop("/systems/acconfig/out-of-date") != 1 and getprop("/systems/acconfig/options/welcome-skip") != 1) {
		welcome_dlg.open();
	}
	setprop("/systems/acconfig/options/revision", current_revision);
	writeSettings();
	spinning.stop();
	if (getprop("/options/mini-panel") == 1) {
		minipanel_dlg.open();
	}
});

var readSettings = func {
	io.read_properties(getprop("/sim/fg-home") ~ "/Export/PA28-Warrior-config.xml", "/systems/acconfig/options");
	setprop("/options/show-l-yoke", getprop("/systems/acconfig/options/show-l-yoke"));
	setprop("/options/show-r-yoke", getprop("/systems/acconfig/options/show-r-yoke"));
	setprop("/options/panel", getprop("/systems/acconfig/options/panel"));
	setprop("/it-stec55x/settings/fd-equipped", getprop("/systems/acconfig/options/fd-equipped"));
	setprop("/options/mini-panel", getprop("/systems/acconfig/options/mini-panel"));
	autopilotSettings();
}

var writeSettings = func {
	setprop("/systems/acconfig/options/show-l-yoke", getprop("/options/show-l-yoke"));
	setprop("/systems/acconfig/options/show-r-yoke", getprop("/options/show-r-yoke"));
	setprop("/systems/acconfig/options/panel", getprop("/options/panel"));
	setprop("/systems/acconfig/options/fd-equipped", getprop("/it-stec55x/settings/fd-equipped"));
	setprop("/systems/acconfig/options/mini-panel", getprop("/options/mini-panel"));
	autopilotSettings();
	io.write_properties(getprop("/sim/fg-home") ~ "/Export/PA28-Warrior-config.xml", "/systems/acconfig/options");
}

var autopilotSettings = func {
	if (getprop("/options/panel") == "HSI Panel") {
		setprop("/it-stec55x/settings/hsi-equipped-1", 1);
	} else {
		setprop("/it-stec55x/settings/hsi-equipped-1", 0);
	}
}

################
# Panel States #
################

# Cold and Dark
var colddark = func {
	spinning.start();
	ps_load_dlg.open();
	setprop("/systems/acconfig/autoconfig-running", 1);
	# Initial shutdown, and reinitialization.
	setprop("/controls/flight/flaps", 0.0);
	setprop("/controls/flight/elevator-trim", 0.11);
	setprop("/controls/gear/brake-parking", 0);
	libraries.systemsReset();
	failReset();
	if (getprop("/engines/engine[0]/rpm") < 421) {
		colddark_b();
	} else {
		var colddark_eng_off = setlistener("/engines/engine[0]/rpm", func {
			if (getprop("/engines/engine[0]/rpm") < 421) {
				removelistener(colddark_eng_off);
				colddark_b();
			}
		});
	}
}
var colddark_b = func {
	# Continues the Cold and Dark script, after engines fully shutdown.
	setprop("/systems/acconfig/autoconfig-running", 0);
	ps_load_dlg.close();
	ps_loaded_dlg.open();
	spinning.stop();
}

# Ready to Start Eng
var beforestart = func {
	spinning.start();
	ps_load_dlg.open();
	setprop("/systems/acconfig/autoconfig-running", 1);
	# First, we set everything to cold and dark.
	setprop("/controls/flight/flaps", 0.0);
	setprop("/controls/flight/elevator-trim", 0.11);
	setprop("/controls/gear/brake-parking", 0);
	libraries.systemsReset();
	failReset();
	
	# Now the Startup!
	setprop("/controls/electrical/battery", 1);
	setprop("/controls/electrical/alternator", 1);
	setprop("/controls/switches/beacon", 1);
	setprop("/controls/switches/strobe-lights", 1);
	setprop("/controls/switches/avionics-master", 1);
	setprop("/controls/engines/engine[0]/mixture", 1);
	setprop("/systems/acconfig/autoconfig-running", 0);
	ps_load_dlg.close();
	ps_loaded_dlg.open();
	spinning.stop();
}

# Ready to Taxi
var taxi = func {
	spinning.start();
	ps_load_dlg.open();
	setprop("/systems/acconfig/autoconfig-running", 1);
	# First, we set everything to cold and dark.
	setprop("/controls/flight/flaps", 0.0);
	setprop("/controls/flight/elevator-trim", 0.11);
	setprop("/controls/gear/brake-parking", 0);
	libraries.systemsReset();
	failReset();
	
	# Now the Startup!
	setprop("/controls/electrical/battery", 1);
	setprop("/controls/electrical/alternator", 1);
	setprop("/controls/switches/beacon", 1);
	setprop("/controls/switches/strobe-lights", 1);
	setprop("/controls/switches/nav-lights-factor", 1);
	setprop("/controls/switches/avionics-master", 1);
	setprop("/controls/engines/engine[0]/mixture", 1);
	setprop("/controls/engines/engine[0]/throttle", 0.25);
	setprop("/controls/engines/engine[0]/magnetos-switch", 4);
	interpolate("/controls/engines/engine[0]/throttle", 0.0, 2);
	var runchk = setlistener("/engines/engine[0]/running", func {
		if (getprop("/engines/engine[0]/running") == 1) {
			removelistener(runchk);
			interpolate("/controls/engines/engine[0]/throttle", 0.16, 1);
		}
	});
	settimer(func {
		setprop("/controls/engines/engine[0]/magnetos-switch", 3);
		setprop("/systems/acconfig/autoconfig-running", 0);
		ps_load_dlg.close();
		ps_loaded_dlg.open();
		spinning.stop();
	}, 3);
}

# Ready to Takeoff
var takeoff = func {
	# The same as taxi, except we set some things afterwards.
	taxi();
	var rpmchk = setlistener("/engines/engine[0]/rpm", func {
		if (getprop("/engines/engine[0]/rpm") >= 421) {
			removelistener(rpmchk);
			setprop("/controls/switches/fuel-pump", 1);
			setprop("/controls/switches/landing-light", 1);
		}
	});
}
