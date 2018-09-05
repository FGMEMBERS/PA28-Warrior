# S-TEC Fifty Five X Autopilot System
# Copyright (c) 2018 Joshua Davidson (it0uchpods)

setprop("/systems/electrical/outputs/autopilot", 0); # Autopilot power source
setprop("/it-autoflight/internal/hsi-equipped", 1);
setprop("/it-autoflight/internal/min-turn-rate", -0.9);
setprop("/it-autoflight/internal/max-turn-rate", 0.9);
setprop("/it-autoflight/internal/nav-gain", 1.0);
setprop("/it-autoflight/internal/nav-step1-time", 0);
setprop("/it-autoflight/internal/nav-step2-time", 0);
setprop("/it-autoflight/internal/nav-step3-time", 0);
setprop("/it-autoflight/internal/nav-over50-time", 0);
setprop("/it-autoflight/internal/nav-over50-counting", 0);

setlistener("/sim/signals/fdm-initialized", func {
	var hasPower = 0;
	var roll = 0;
	var pitch = 0;
	var cdiDefl = 0;
	var vs = 0;
	ITAF.init();
});

var ITAF = {
	init: func() {
		setprop("/it-autoflight/input/hdg", 360);
		setprop("/it-autoflight/input/alt", 0);
		setprop("/it-autoflight/input/alt-offset", 0);
		setprop("/it-autoflight/input/vs", 0);
		setprop("/it-autoflight/input/cws-switch", 0);
		setprop("/it-autoflight/output/roll", -1);
		setprop("/it-autoflight/output/pitch", -1);
		setprop("/it-autoflight/annun/hdg", 0);
		setprop("/it-autoflight/annun/nav", 0);
		setprop("/it-autoflight/annun/nav-flash", 0);
		setprop("/it-autoflight/annun/apr", 0);
		setprop("/it-autoflight/annun/rev", 0);
		setprop("/it-autoflight/annun/trim", 0);
		setprop("/it-autoflight/annun/alt", 0);
		setprop("/it-autoflight/annun/gs", 0);
		setprop("/it-autoflight/annun/vs", 0);
		setprop("/it-autoflight/annun/rdy", 0);
		setprop("/it-autoflight/annun/cws", 0);
		setprop("/it-autoflight/annun/fail", 0);
		setprop("/it-autoflight/annun/gpss", 0);
		setprop("/it-autoflight/annun/up", 0);
		setprop("/it-autoflight/annun/dn", 0);
		update.start();
	},
	loop: func () {
		if (getprop("/systems/electrical/outputs/autopilot") >= 8) {
			setprop("/it-autoflight/internal/hasPower", 1);
		} else {
			setprop("/it-autoflight/internal/hasPower", 0);
			if (getprop("/it-autoflight/output/roll") != -1 or getprop("/it-autoflight/output/pitch") != -1) {
				me.killAP();
			}
		}
		
		# Annunciators
		if (getprop("/it-autoflight/output/roll") == 0) {
			setprop("/it-autoflight/annun/hdg", 1);
		} else {
			setprop("/it-autoflight/annun/hdg", 0);
		}
		
		if (getprop("/it-autoflight/output/roll") == 1 or getprop("/it-autoflight/output/roll") == 2) {
			setprop("/it-autoflight/annun/nav", 1);
		} else {
			setprop("/it-autoflight/annun/nav", 0);
		}
		
		if (getprop("/it-autoflight/output/roll") == 5) {
			setprop("/it-autoflight/annun/rev", 1);
		} else {
			setprop("/it-autoflight/annun/rev", 0);
		}
		
		if (getprop("/it-autoflight/output/pitch") == 0) {
			setprop("/it-autoflight/annun/alt", 1);
		} else {
			setprop("/it-autoflight/annun/alt", 0);
		}
		
		if (getprop("/it-autoflight/output/pitch") == 1) {
			setprop("/it-autoflight/annun/vs", 1);
		} else {
			setprop("/it-autoflight/annun/vs", 0);
		}
		
		if (getprop("/it-autoflight/output/roll") == 2) {
			setprop("/it-autoflight/annun/gpss", 1);
		} else {
			setprop("/it-autoflight/annun/gpss", 0);
		}
		
		# NAV mode gain, reduces as the system captures the course
		if (getprop("/it-autoflight/output/roll") == 1) {
			cdiDefl = getprop("/instrumentation/nav[0]/heading-needle-deflection");
			if (abs(cdiDefl) <= 1.5 and getprop("/it-autoflight/internal/nav-gain") == 1.0) { # CAP mode
				setprop("/it-autoflight/internal/nav-gain", 0.9);
				setprop("/it-autoflight/internal/nav-step1-time", getprop("/sim/time/elapsed-sec"));
			} else if (getprop("/it-autoflight/internal/nav-step1-time") + 15 <= getprop("/sim/time/elapsed-sec") and getprop("/it-autoflight/internal/nav-gain") == 0.9) { # CAP SOFT mode
				setprop("/it-autoflight/internal/nav-gain", 0.8);
				setprop("/it-autoflight/internal/nav-step2-time", getprop("/sim/time/elapsed-sec"));
			} else if (getprop("/it-autoflight/internal/nav-step2-time") + 75 <= getprop("/sim/time/elapsed-sec") and getprop("/it-autoflight/internal/nav-gain") == 0.8) { # SOFT mode
				setprop("/it-autoflight/internal/nav-gain", 0.6);
				setprop("/it-autoflight/internal/nav-step3-time", getprop("/sim/time/elapsed-sec"));
			}
			
			# Return to CAP SOFT if needle deflection is >= 50% for 60 seconds
			if (cdiDefl >= 5 and getprop("/it-autoflight/internal/nav-gain") == 0.6) {
				if (getprop("/it-autoflight/internal/nav-over50-counting") != 1) { # Prevent it from constantly updaing the time
					setprop("/it-autoflight/internal/nav-over50-counting", 1);
					setprop("/it-autoflight/internal/nav-over50-time", getprop("/sim/time/elapsed-sec"));
				}
				if (getprop("/it-autoflight/internal/nav-over50-time") + 60 < getprop("/sim/time/elapsed-sec")) { # CAP SOFT mode
					setprop("/it-autoflight/internal/nav-gain", 0.8);
					setprop("/it-autoflight/internal/nav-step2-time", getprop("/sim/time/elapsed-sec"));
					if (getprop("/it-autoflight/internal/nav-over50-counting") != 0) {
						setprop("/it-autoflight/internal/nav-over50-counting", 0);
					}
				}
			}
		} else {
			if (getprop("/it-autoflight/internal/nav-gain") != 1.0) {
				setprop("/it-autoflight/internal/nav-gain", 1.0);
			}
			if (getprop("/it-autoflight/internal/nav-over50-counting") != 0) {
				setprop("/it-autoflight/internal/nav-over50-counting", 0);
			}
		}
		
		# Limit the turn rate depending on the mode
		if (getprop("/it-autoflight/output/roll") == 1 or getprop("/it-autoflight/output/roll") == 2) {
			if (getprop("/it-autoflight/internal/nav-gain") == 0.8) {
				setprop("/it-autoflight/internal/min-turn-rate", -0.45);
				setprop("/it-autoflight/internal/max-turn-rate", 0.45);

			} else if (getprop("/it-autoflight/internal/nav-gain") == 0.6) {
				setprop("/it-autoflight/internal/min-turn-rate", -0.15);
				setprop("/it-autoflight/internal/max-turn-rate", 0.15);

			} else {
				setprop("/it-autoflight/internal/min-turn-rate", -0.9);
				setprop("/it-autoflight/internal/max-turn-rate", 0.9);
			}
		} else {
			setprop("/it-autoflight/internal/min-turn-rate", -0.9);
			setprop("/it-autoflight/internal/max-turn-rate", 0.9);
		}
	},
	killAP: func() { # Kill all AP modes
		NAVt.stop();
		GPSt.stop();
		setprop("/it-autoflight/output/roll", -1);
		setprop("/it-autoflight/output/pitch", -1);
		setprop("/controls/flight/aileron", 0);
		setprop("/controls/flight/elevator", 0);
	},
	killAPPitch: func() { # Kill only the pitch modes
		setprop("/it-autoflight/output/pitch", -1);
		setprop("/controls/flight/elevator", 0);
	},
};

var button = {
	HDG: func() {
		if (getprop("/it-autoflight/internal/hasPower") == 1) {
			if (getprop("/it-autoflight/output/roll") == 0) {
				ITAF.killAP();
			} else {
				setprop("/it-autoflight/output/roll", 0);
			}
		}
	},
	NAV: func() {
		if (getprop("/it-autoflight/internal/hasPower") == 1) {
			if (getprop("/it-autoflight/output/roll") == 1 or getprop("/it-autoflight/output/roll") == 3) { # If NAV active or armed, switch to GPSS NAV mode
				setprop("/it-autoflight/output/roll", 4);
				GPSchk();
				GPSt.start();
			} else if (getprop("/it-autoflight/output/roll") == 2 or getprop("/it-autoflight/output/roll") == 4) { # If GPSS NAV active or armed, turn off AP
				ITAF.killAP();
			} else { # If not in NAV mode, switch to NAV
				setprop("/it-autoflight/output/roll", 3);
				NAVchk();
				NAVt.start();
			}
		}
	},
	ALT: func() {
		if (getprop("/it-autoflight/internal/hasPower") == 1 and getprop("/it-autoflight/output/roll") != -1) {
			if (getprop("/it-autoflight/output/pitch") == 0) {
				ITAF.killAPPitch();
			} else {
				setprop("/it-autoflight/input/alt-offset", 0);
				setprop("/it-autoflight/input/alt", getprop("/systems/static[0]/pressure-inhg"));
				setprop("/it-autoflight/output/pitch", 0);
			}
		}
	},
	VS: func() {
		if (getprop("/it-autoflight/internal/hasPower") == 1 and getprop("/it-autoflight/output/roll") != -1) {
			if (getprop("/it-autoflight/output/pitch") == 1) {
				ITAF.killAPPitch();
			} else {
				setprop("/it-autoflight/output/pitch", 1);
			}
		}
	},
	Knob: func(d) {
		if (getprop("/it-autoflight/output/pitch") == 1) {
			if (d < 0) {
				vs = getprop("/it-autoflight/input/vs") - 100;
				if (vs < -1600) {
					vs = -1600;
				}
				setprop("/it-autoflight/input/vs", vs);
			} else {
				vs = getprop("/it-autoflight/input/vs") + 100;
				if (vs > 1600) {
					vs = 1600;
				}
				setprop("/it-autoflight/input/vs", vs);
			}
		}
	},
};

var NAVchk = func {
	if (getprop("/it-autoflight/output/roll") == 3) {
		if (getprop("/instrumentation/nav[0]/in-range") == 1) { # Only engage NAV if OBS reports in range
			NAVt.stop();
			setprop("/it-autoflight/annun/nav-flash", 0);
			setprop("/it-autoflight/output/roll", 1);
			if (abs(getprop("/instrumentation/nav[0]/heading-needle-deflection")) <= 0.1) { # Immediately go to SOFT mode if within 10% of deflection
				setprop("/it-autoflight/internal/nav-gain", 0.65);
				setprop("/it-autoflight/internal/nav-step1-time", getprop("/sim/time/elapsed-sec") - 90);
				setprop("/it-autoflight/internal/nav-step2-time", getprop("/sim/time/elapsed-sec") - 75);
				setprop("/it-autoflight/internal/nav-step3-time", getprop("/sim/time/elapsed-sec"));
			}
		} else {
			NAVl.start();
		}
	} else {
		NAVt.stop();
	}
}

var GPSchk = func {
	if (getprop("/it-autoflight/output/roll") == 4) {
		if (getprop("/autopilot/route-manager/active") == 1) { # Only engage GPSS NAV if GPS is activated
			GPSt.stop();
			setprop("/it-autoflight/annun/nav-flash", 0);
			setprop("/it-autoflight/output/roll", 2);
		} else {
			NAVl.start();
		}
	} else {
		GPSt.stop();
	}
}

var NAVl = maketimer(0.4, func { # Flashes the NAV (and sometimes GPSS) lights when NAV modes are armed
	if ((getprop("/it-autoflight/output/roll") == 3 or getprop("/it-autoflight/output/roll") == 4) and getprop("/it-autoflight/annun/nav-flash") != 1) {
		setprop("/it-autoflight/annun/nav-flash", 1);
	} else if ((getprop("/it-autoflight/output/roll") == 3 or getprop("/it-autoflight/output/roll") == 4) and getprop("/it-autoflight/annun/nav-flash") != 0) {
		setprop("/it-autoflight/annun/nav-flash", 0);
	} else {
		NAVl.stop();
		setprop("/it-autoflight/annun/nav-flash", 0);
	}
});

var NAVt = maketimer(0.5, NAVchk);
var GPSt = maketimer(0.5, GPSchk);
var update = maketimer(0.1, ITAF.loop);
