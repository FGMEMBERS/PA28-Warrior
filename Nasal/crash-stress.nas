# Crash and Stress
# Copyright (c) 2019 Joshua Davidson (it0uchpods)

var loaded = 0;
var damagedHappened = 0;
setprop("/fdm/jsbsim/crash-stress/nose-damaged", 0);
setprop("/fdm/jsbsim/crash-stress/lwing-damaged", 0);
setprop("/fdm/jsbsim/crash-stress/rwing-damaged", 0);
setprop("/fdm/jsbsim/crash-stress/htail-damaged", 0);
setprop("/fdm/jsbsim/crash-stress/vtail-damaged", 0);

var crashStress = {
	reset: func() {
		if (damagedHappened) {
			loaded = 0;
			setprop("/position/altitude-ft", getprop("/position/altitude-ft") + 5);
			setprop("/orientation/roll-deg", 0);
			setprop("/orientation/pitch-deg", 4); # Prevent tail from striking when the gears come back
			setprop("/fdm/jsbsim/gear/unit[0]/pos-norm", 1); # Nose Gear
			setprop("/fdm/jsbsim/gear/unit[1]/pos-norm", 1); # Left Gear
			setprop("/fdm/jsbsim/gear/unit[2]/pos-norm", 1); # Right Gear
			setprop("/fdm/jsbsim/contact/unit[9]/pos-norm", 1);
			setprop("/fdm/jsbsim/contact/unit[11]/pos-norm", 1);
			setprop("/fdm/jsbsim/contact/unit[12]/pos-norm", 1);
			setprop("/fdm/jsbsim/contact/unit[13]/pos-norm", 1);
			setprop("/fdm/jsbsim/contact/unit[14]/pos-norm", 1);
			setprop("/fdm/jsbsim/contact/unit[15]/pos-norm", 1);
			setprop("/fdm/jsbsim/crash-stress/nose-damaged", 0);
			setprop("/fdm/jsbsim/crash-stress/lwing-damaged", 0);
			setprop("/fdm/jsbsim/crash-stress/rwing-damaged", 0);
			setprop("/fdm/jsbsim/crash-stress/htail-damaged", 0);
			setprop("/fdm/jsbsim/crash-stress/vtail-damaged", 0);
			damagedHappened = 0;
			settimer(func { # Delay taking damage again just in case
				loaded = 1;
			}, 1);
		} else {
			loaded = 1;
		}
	},
};

setlistener("/gear/gear[3]/wow", func {
	if (getprop("/gear/gear[3]/wow") == 1 and loaded) {
		damagedHappened = 1;
		setprop("/fdm/jsbsim/crash-stress/nose-damaged", 1);
		setprop("/fdm/jsbsim/contact/unit[9]/pos-norm", 1);
		setprop("/fdm/jsbsim/gear/unit[0]/pos-norm", 0); # Nose Gear
	}
}, 0, 0);

setlistener("/gear/gear[4]/wow", func {
	if (getprop("/gear/gear[4]/wow") == 1 and loaded) {
		damagedHappened = 1;
		setprop("/fdm/jsbsim/crash-stress/nose-damaged", 1);
		setprop("/fdm/jsbsim/contact/unit[9]/pos-norm", 1);
		setprop("/fdm/jsbsim/gear/unit[0]/pos-norm", 0); # Nose Gear
	}
}, 0, 0);

setlistener("/gear/gear[9]/wow", func {
	if (getprop("/gear/gear[9]/wow") == 1 and loaded) {
		damagedHappened = 1;
		setprop("/fdm/jsbsim/crash-stress/nose-damaged", 1);
		setprop("/fdm/jsbsim/contact/unit[9]/pos-norm", 1);
		setprop("/fdm/jsbsim/gear/unit[0]/pos-norm", 0); # Nose Gear
	}
}, 0, 0);

setlistener("/gear/gear[10]/wow", func {
	if (getprop("/gear/gear[10]/wow") == 1 and loaded) {
		damagedHappened = 1;
		setprop("/fdm/jsbsim/crash-stress/htail-damaged", 1);
		setprop("/fdm/jsbsim/contact/unit[14]/pos-norm", 0);
		setprop("/fdm/jsbsim/contact/unit[15]/pos-norm", 0);
	}
}, 0, 0);

setlistener("/gear/gear[11]/wow", func {
	if (getprop("/gear/gear[11]/wow") == 1 and loaded) {
		damagedHappened = 1;
		setprop("/fdm/jsbsim/crash-stress/vtail-damaged", 1);
		setprop("/fdm/jsbsim/contact/unit[11]/pos-norm", 0);
	}
}, 0, 0);

setlistener("/gear/gear[12]/wow", func {
	if (getprop("/gear/gear[12]/wow") == 1 and loaded) {
		damagedHappened = 1;
		setprop("/fdm/jsbsim/crash-stress/lwing-damaged", 1);
		setprop("/fdm/jsbsim/contact/unit[12]/pos-norm", 0);
		setprop("/fdm/jsbsim/gear/unit[1]/pos-norm", 0); # Left Gear
	}
}, 0, 0);

setlistener("/gear/gear[13]/wow", func {
	if (getprop("/gear/gear[13]/wow") == 1 and loaded) {
		damagedHappened = 1;
		setprop("/fdm/jsbsim/crash-stress/rwing-damaged", 1);
		setprop("/fdm/jsbsim/contact/unit[13]/pos-norm", 0);
		setprop("/fdm/jsbsim/gear/unit[2]/pos-norm", 0); # Right Gear
	}
}, 0, 0);

setlistener("/gear/gear[14]/wow", func {
	if (getprop("/gear/gear[14]/wow") == 1 and loaded) {
		damagedHappened = 1;
		setprop("/fdm/jsbsim/crash-stress/htail-damaged", 1);
		setprop("/fdm/jsbsim/contact/unit[14]/pos-norm", 0);
		setprop("/fdm/jsbsim/contact/unit[15]/pos-norm", 0);
	}
}, 0, 0);

setlistener("/gear/gear[15]/wow", func {
	if (getprop("/gear/gear[15]/wow") == 1 and loaded) {
		damagedHappened = 1;
		setprop("/fdm/jsbsim/crash-stress/htail-damaged", 1);
		setprop("/fdm/jsbsim/contact/unit[14]/pos-norm", 0);
		setprop("/fdm/jsbsim/contact/unit[15]/pos-norm", 0);
	}
}, 0, 0);
