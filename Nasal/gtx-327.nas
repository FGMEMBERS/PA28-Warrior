# Garmin GTX-327 Transponder
# Copyright (c) 2018 Joshua Davidson (it0uchpods)

# Initialize variables
var code = 1200;
var mode = 0; # 0 = OFF, 1 = STANDBY, 4 = ON, 5 = ALTITUDE
var modes = ["OFF", "STANDBY", "TEST", "GROUND", "ON", "ALTITUDE"];
var powerUpTime = 0;
var powerUpTestAnnun = 0;

# Initialize all used property nodes
var elapsedSec = props.globals.getNode("/sim/time/elapsed-sec");
var powerSrc = props.globals.getNode("/systems/electrical/outputs/transponder", 1); # Transponder power source
var serviceable = props.globals.initNode("/instrumentation/it-gtx327/serviceable", 1, "BOOL");
var systemAlive = props.globals.initNode("/instrumentation/it-gtx327/internal/system-alive", 0, "BOOL");
var powerUpTest = props.globals.initNode("/instrumentation/it-gtx327/internal/powerup-test", -1, "INT"); # -1 = Powerup test not done, 0 = Powerup test complete, 1 = Powerup test in progress
var IDCode = props.globals.getNode("/instrumentation/transponder/id-code", 1);
var modeKnob = props.globals.getNode("/instrumentation/transponder/inputs/knob-mode", 1);
var modeID = props.globals.getNode("/sim/gui/dialogs/radios/transponder-mode", 1);
var displayMode = props.globals.initNode("/instrumentation/it-gtx327/internal/display-mode", "PA", "STRING");
var FAIL_annun = props.globals.initNode("/instrumentation/it-gtx327/annun/fail", 0, "BOOL");
var MODE_annun = props.globals.initNode("/instrumentation/it-gtx327/annun/mode", "off", "STRING");
var R_annun = props.globals.initNode("/instrumentation/it-gtx327/annun/reply", 0, "BOOL");
var TEST_annun = props.globals.initNode("/instrumentation/it-gtx327/annun/test", 0, "BOOL");

setlistener("/sim/signals/fdm-initialized", func {
	system.init();
});

var system = {
	init: func() {
		code = IDCode.getValue(); # If a code was saved via aircraft-data or other means, import it
		powerUpTest.setValue(-1);
		FAIL_annun.setBoolValue(0);
		MODE_annun.setBoolValue(0);
		R_annun.setBoolValue(0);
		TEST_annun.setBoolValue(0);
		me.setMode(0);
		if (getprop("/options/wip") == 1) {
			update.start();
		}
	},
	loop: func() {
		if (powerSrc.getValue() >= 8) {
			systemAlive.setBoolValue(1);
			if (powerUpTest.getValue() == -1 and mode != 0) { # Begin power on test
				powerUpTest.setValue(1);
				powerUpTime = elapsedSec.getValue();
			} else if (powerUpTest.getValue() != -1 and mode == 0) {
				powerUpTest.setValue(-1);
			}
		} else {
			systemAlive.setBoolValue(0);
			mode = 0;
			displayMode.setValue("PA");
			if (powerUpTest.getValue() != -1) {
				powerUpTest.setValue(-1);
			}
		}
		
		if (systemAlive.getBoolValue() != 0 and serviceable.getBoolValue() == 1) {
			if (powerUpTest.getValue() >= 1 and powerUpTime + 3 < elapsedSec.getValue()) {
				powerUpTest.setValue(0);
			}
		} else if (systemAlive.getBoolValue() != 0 and serviceable.getBoolValue() == 0) {
			if ((powerUpTest.getValue() == 0 or powerUpTest.getValue() == 1) and powerUpTime + 3 < elapsedSec.getValue()) {
				powerUpTest.setValue(2);
			}
		}
		
		# Annunciators
		if (powerUpTest.getValue() == 1 and systemAlive.getBoolValue() == 1) {
			TEST_annun.setBoolValue(1);
		} else {
			TEST_annun.setBoolValue(0);
		}
		
		if (powerUpTest.getValue() == 2 and systemAlive.getBoolValue() == 1) {
			FAIL_annun.setBoolValue(1);
		} else {
			FAIL_annun.setBoolValue(0);
		}
		
		# Update transponder modes
		if (modeKnob.getValue() != mode and powerUpTest.getValue() == 0 and serviceable.getBoolValue() == 1) {
			system.setMode(mode);
		} else {
			system.setMode(0);
		}
	},
	setMode: func(m) {
		modeKnob.setValue(m);
		modeID.setValue(modes[m]);
	},
};

var button = {
	OFF: func() {
		if (systemAlive.getBoolValue() == 1) {
			mode = 0;
			displayMode.setValue("PA");
		}
	},
	STBY: func() {
		if (systemAlive.getBoolValue() == 1) {
			mode = 1;
		}
	},
	ON: func() {
		if (systemAlive.getBoolValue() == 1) {
			mode = 4;
		}
	},
	ALT: func() {
		if (systemAlive.getBoolValue() == 1) {
			mode = 5;
		}
	},
	VFR: func() {
		if (systemAlive.getBoolValue() == 1 and powerUpTest.getValue() == 0 and serviceable.getBoolValue() == 1) {
			code = 1200;
			IDCode.setValue(1200);
		}
	},
};

var update = maketimer(0.1, system.loop);
#setprop("/options/wip", 1); # This should be commented out, or it0uchpods is an idiot! :)
