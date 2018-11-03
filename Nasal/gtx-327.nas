# Garmin GTX 327 Transponder
# Copyright (c) 2018 Joshua Davidson (it0uchpods)

# Initialize variables
var code = 1200;
var modes = ["OFF", "STANDBY", "TEST", "GROUND", "ON", "ALTITUDE"];

# Initialize all used property nodes
var elapsedSec = props.globals.getNode("/sim/time/elapsed-sec");
var powerSrc = props.globals.getNode("/systems/electrical/outputs/transponder", 1); # Transponder power source
var serviceable = props.globals.initNode("/it-gtx327/serviceable", 1, "BOOL");
var systemAlive = props.globals.initNode("/it-gtx327/internal/system-alive", 0, "BOOL");
var IDCode = props.globals.getNode("/instrumentation/transponder/id-code", 1);
var modeKnob = props.globals.getNode("/instrumentation/transponder/inputs/knob-mode", 1);
var modeID = props.globals.getNode("/sim/gui/dialogs/radios/transponder-mode", 1);
var displayMode = props.globals.initNode("/it-gtx327/internal/display-mode", "PA", "STRING");
var MODE_annun = props.globals.initNode("/it-gtx327/annun/mode", "off", "STRING");
var R_annun = props.globals.initNode("/it-gtx327/annun/reply", 0, "BOOL");

setlistener("/sim/signals/fdm-initialized", func {
	system.init();
});

var system = {
	init: func() {
		code = IDCode.getValue(); # If a code was saved via aircraft-data or other means, import it
		me.setMode(0);
		update.start();
	},
	loop: func() {
		if (powerSrc.getValue() >= 8) {
			systemAlive.setBoolValue(1);
		} else {
			systemAlive.setBoolValue(0);
			if (modeKnob.getValue() != 0) {
				system.setMode(0);
			}
		}
	},
	setMode: func(m) {
		modeKnob.setValue(m);
		modeID.setValue(modes[m]);
	},
};

var button = {
	OFF: func() {
		system.setMode(0);
		displayMode.setValue("PA");
	},
	STBY: func() {
		system.setMode(1);
	},
	ON: func() {
		system.setMode(4);
	},
	ALT: func() {
		system.setMode(5);
	},
	VFR: func() {
		code = 1200;
		IDCode.setValue(1200);
	},
};

var update = maketimer(0.1, system.loop);
#setprop("/options/wip", 1); # This should be commented out, or it0uchpods is an idiot! :)
