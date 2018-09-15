# S-TEC Fifty Five X Autopilot System
# Copyright (c) 2018 Joshua Davidson (it0uchpods)

var NAVGainStd = 1.0;
var NAVGainCap = 0.9;
var NAVGainCapSoft = 0.8;
var NAVGainSoft = 0.6;
var elapsedSec = props.globals.getNode("/sim/time/elapsed-sec");
var powerSrc = props.globals.initNode("/systems/electrical/outputs/autopilot", 0, "DOUBLE"); # Autopilot power source
var serviceable = props.globals.initNode("/it-autoflight/serviceable", 1, "BOOL");
var hdg = props.globals.initNode("/it-autoflight/input/hdg", 360, "DOUBLE");
var hdgButton = props.globals.initNode("/it-autoflight/input/hdg-button", 0, "BOOL");
var alt = props.globals.initNode("/it-autoflight/input/alt", 0, "DOUBLE"); # Altitude is in static pressure, not feet
var altOffset = props.globals.initNode("/it-autoflight/input/alt-offset", 0, "DOUBLE"); # Altitude offset
var vs = props.globals.initNode("/it-autoflight/input/vs", 0, "DOUBLE");
var cwsSW = props.globals.initNode("/it-autoflight/input/cws", 0, "BOOL");
var discSW = props.globals.initNode("/it-autoflight/input/disc", 0, "BOOL");
var masterSW = props.globals.initNode("/it-autoflight/input/ap-master-sw", 0, "BOOL");
var elecTrimSW = props.globals.initNode("/it-autoflight/input/electric-trim-sw", 0, "BOOL");
var hasPower = props.globals.initNode("/it-autoflight/internal/hasPower", 0, "BOOL");
var roll = props.globals.initNode("/it-autoflight/output/roll", -1, "INT");
var pitch = props.globals.initNode("/it-autoflight/output/pitch", -1, "INT");
var HDG_annun = props.globals.initNode("/it-autoflight/annun/hdg", 0, "BOOL");
var NAV_annun = props.globals.initNode("/it-autoflight/annun/nav", 0, "BOOL");
var APR_annun = props.globals.initNode("/it-autoflight/annun/apr", 0, "BOOL");
var REV_annun = props.globals.initNode("/it-autoflight/annun/rev", 0, "BOOL");
var ALT_annun = props.globals.initNode("/it-autoflight/annun/alt", 0, "BOOL");
var GS_annun = props.globals.initNode("/it-autoflight/annun/gs", 0, "BOOL");
var VS_annun = props.globals.initNode("/it-autoflight/annun/vs", 0, "BOOL");
var RDY_annun = props.globals.initNode("/it-autoflight/annun/rdy", 0, "BOOL");
var CWS_annun = props.globals.initNode("/it-autoflight/annun/cws", 0, "BOOL");
var FAIL_annun = props.globals.initNode("/it-autoflight/annun/fail", 0, "BOOL");
var GPSS_annun = props.globals.initNode("/it-autoflight/annun/gpss", 0, "BOOL");
var UP_annun = props.globals.initNode("/it-autoflight/annun/up", 0, "BOOL");
var DN_annun = props.globals.initNode("/it-autoflight/annun/dn", 0, "BOOL");
var NAVFlash_annun = props.globals.initNode("/it-autoflight/annun/nav-flash", 0, "BOOL");
var HSIequipped = props.globals.initNode("/it-autoflight/internal/hsi-equipped", 1, "BOOL"); # Does the aircraft have an HSI or DG? The Autopilot behavior changes slightly depending on this
var NAVManIntercept = props.globals.initNode("/it-autoflight/internal/nav-man-intercept", 1, "BOOL");
var minTurnRate = props.globals.initNode("/it-autoflight/internal/min-turn-rate", -0.9, "DOUBLE");
var maxTurnRate = props.globals.initNode("/it-autoflight/internal/max-turn-rate", 0.9, "DOUBLE");
var manTurnRate = props.globals.initNode("/it-autoflight/internal/man-turn-rate", 0, "DOUBLE");
var NAVPreGain = props.globals.initNode("/it-autoflight/internal/nav-pre-gain", NAVGainStd, "DOUBLE");
var NAVGain = props.globals.initNode("/it-autoflight/internal/nav-gain", NAVGainStd, "DOUBLE");
var NAVStep1Time = props.globals.initNode("/it-autoflight/internal/nav-step1-time", 0, "DOUBLE");
var NAVStep2Time = props.globals.initNode("/it-autoflight/internal/nav-step2-time", 0, "DOUBLE");
var NAVStep3Time = props.globals.initNode("/it-autoflight/internal/nav-step3-time", 0, "DOUBLE");
var NAVOver50Time = props.globals.initNode("/it-autoflight/internal/nav-over50-time", 0, "DOUBLE");
var NAVOver50Counting = props.globals.initNode("/it-autoflight/internal/nav-over50-counting", 0, "BOOL");
var hdgButtonTime = props.globals.initNode("/it-autoflight/internal/hdg-button-time", 0, "DOUBLE");
var powerUpTime = props.globals.initNode("/it-autoflight/internal/powerup-time", 0, "DOUBLE");
var powerUpTest = props.globals.initNode("/it-autoflight/internal/powerup-test", -1, "INT"); # -1 = Powerup test not done, 0 = Powerup test complete, 1 = Powerup test in progress
var APRGainActive = props.globals.initNode("/it-autoflight/internal/apr-gain-active", 0, "BOOL");
var GPSActive = props.globals.getNode("/autopilot/route-manager/active");
var OBSNeedle = props.globals.getNode("/instrumentation/nav[0]/heading-needle-deflection");
var OBSActive = props.globals.getNode("/instrumentation/nav[0]/in-range");
var turnRate = props.globals.getNode("/instrumentation/turn-indicator/indicated-turn-rate");
var turnRateOK = props.globals.getNode("/instrumentation/turn-indicator/serviceable");
var staticPress = props.globals.getNode("/systems/static[0]/pressure-inhg");

setlistener("/sim/signals/fdm-initialized", func {
	var cdiDefl = 0;
	var vspeed = 0;
	var NAV = 0;
	var CNAV = 0;
	ITAF.init();
});

var ITAF = {
	init: func() {
		hdg.setValue(360);
		alt.setValue(0);
		altOffset.setValue(0);
		vs.setValue(0);
		cwsSW.setValue(0);
		discSW.setValue(0);
		masterSW.setValue(0);
		elecTrimSW.setValue(0);
		NAVManIntercept.setValue(0);
		roll.setValue(-1);
		pitch.setValue(-1);
		HDG_annun.setBoolValue(0);
		NAV_annun.setBoolValue(0);
		APR_annun.setBoolValue(0);
		REV_annun.setBoolValue(0);
		ALT_annun.setBoolValue(0);
		GS_annun.setBoolValue(0);
		VS_annun.setBoolValue(0);
		RDY_annun.setBoolValue(0);
		CWS_annun.setBoolValue(0);
		FAIL_annun.setBoolValue(0);
		GPSS_annun.setBoolValue(0);
		UP_annun.setBoolValue(0);
		DN_annun.setBoolValue(0);
		NAVFlash_annun.setBoolValue(0);
		update.start();
	},
	loop: func() {
		# AP does not power up or show any signs of life unless if has power (obviously), and the turn coordinator is working
		if (powerSrc.getValue() >= 8 and masterSW.getBoolValue() == 1 and turnRateOK.getBoolValue() == 1) {
			hasPower.setBoolValue(1);
			if (powerUpTest.getValue() == -1) { # Begin power on test
				powerUpTest.setValue(1);
				powerUpTime.setValue(elapsedSec.getValue());
				vs.setValue(1800); # For startup test only
			}
		} else {
			hasPower.setBoolValue(0);
			if (powerUpTest.getValue() != -1) {
				powerUpTest.setValue(-1);
			}
			if (roll.getValue() != -1 or pitch.getValue() != -1) {
				ITAF.killAP(); # Called with ITAF.killAP not me.killAP because this function is called from the timer outside this class
			}
		}
		
		if (serviceable.getBoolValue() == 0) { # AP Failed when true
			RDY_annun.setBoolValue(0);
			FAIL_annun.setBoolValue(1);
		} else {
			if (powerUpTest.getValue() == 1 and powerUpTime.getValue() + 10 < elapsedSec.getValue()) {
				powerUpTest.setValue(0);
			}
			if (roll.getValue() == -1) {
				RDY_annun.setBoolValue(1);
			} else {
				RDY_annun.setBoolValue(0);
			}
			if (powerUpTest.getValue()) {
				FAIL_annun.setBoolValue(1);
			} else {
				FAIL_annun.setBoolValue(0);
			}
		}
		
		# Mode Annunciators
		if (roll.getValue() == 0 or powerUpTest.getValue()) {
			HDG_annun.setBoolValue(1);
		} else {
			HDG_annun.setBoolValue(0);
		}
		
		NAV = roll.getValue() == 3 or roll.getValue() == 4; # Is NAV armed?
		CNAV = roll.getValue() == 0 and NAVManIntercept.getBoolValue(); # Is NAV with custom intercept heading armed?
		if (roll.getValue() == 1 or roll.getValue() == 2 or ((NAV or CNAV) and NAVFlash_annun.getBoolValue()) or powerUpTest.getValue()) {
			NAV_annun.setBoolValue(1);
		} else {
			NAV_annun.setBoolValue(0);
		}
		
		if (((roll.getValue() == 1 or NAVFlash_annun.getBoolValue()) and APRGainActive.getBoolValue() == 1) or powerUpTest.getValue()) {
			APR_annun.setBoolValue(1);
		} else {
			APR_annun.setBoolValue(0);
		}
		
		if (pitch.getValue() == 0 or powerUpTest.getValue()) {
			ALT_annun.setBoolValue(1);
		} else {
			ALT_annun.setBoolValue(0);
		}
		
		if (pitch.getValue() == 1 or pitch.getValue() == -2 or powerUpTest.getValue()) {
			VS_annun.setBoolValue(1);
		} else {
			VS_annun.setBoolValue(0);
		}
		
		if (roll.getValue() == 5 or roll.getValue() == -2 or powerUpTest.getValue()) {
			CWS_annun.setBoolValue(1);
		} else {
			CWS_annun.setBoolValue(0);
		}
		
		if (roll.getValue() == 2 or (roll.getValue() == 4 and NAVFlash_annun.getBoolValue()) or powerUpTest.getValue()) {
			GPSS_annun.setBoolValue(1);
		} else {
			GPSS_annun.setBoolValue(0);
		}
		
		# Temporary stuff because these lights aren't implemented yet
		if (powerUpTest.getValue()) {
			REV_annun.setBoolValue(1);
			GS_annun.setBoolValue(1);
		} else {
			REV_annun.setBoolValue(0);
			GS_annun.setBoolValue(0);
		}
		
		# Electric Pitch Trim
		if (powerUpTest.getValue() or (pitch.getValue() > -1 and getprop("/controls/flight/elevator") < -0.05)) {
			UP_annun.setBoolValue(1);
		} else if (pitch.getValue() > -1 and UP_annun.getBoolValue() == 1 and getprop("/controls/flight/elevator") < -0.015) {
			UP_annun.setBoolValue(1);
		} else {
			UP_annun.setBoolValue(0);
		}
		if (powerUpTest.getValue() or (pitch.getValue() > -1 and getprop("/controls/flight/elevator") > 0.05)) {
			DN_annun.setBoolValue(1);
		} else if (pitch.getValue() > -1 and DN_annun.getBoolValue() == 1 and getprop("/controls/flight/elevator") > 0.015) {
			DN_annun.setBoolValue(1);
		} else {
			DN_annun.setBoolValue(0);
		}
		
		# NAV mode gain, reduces as the system captures the course
		if (roll.getValue() == 1) {
			cdiDefl = OBSNeedle.getValue();
			if (abs(cdiDefl) <= 1.5 and NAVPreGain.getValue() == NAVGainStd) { # CAP mode
				NAVPreGain.setValue(NAVGainCap);
				NAVStep1Time.setValue(elapsedSec.getValue());
			} else if (NAVStep1Time.getValue() + 15 <= elapsedSec.getValue() and NAVPreGain.getValue() == NAVGainCap) { # CAP SOFT mode
				NAVPreGain.setValue(NAVGainCapSoft);
				NAVStep2Time.setValue(elapsedSec.getValue());
			} else if (NAVStep2Time.getValue() + 75 <= elapsedSec.getValue() and NAVPreGain.getValue() == NAVGainCapSoft) { # SOFT mode
				NAVPreGain.setValue(NAVGainSoft);
				NAVStep3Time.setValue(elapsedSec.getValue());
			}
			
			# Return to CAP SOFT if needle deflection is >= 50% for 60 seconds
			if (cdiDefl >= 5 and NAVPreGain.getValue() == NAVGainSoft) {
				if (NAVOver50Counting.getBoolValue() != 1) { # Prevent it from constantly updating the time
					NAVOver50Counting.setBoolValue(1);
					NAVOver50Time.setValue(elapsedSec.getValue());
				}
				if (NAVOver50Time.getValue() + 60 < elapsedSec.getValue()) { # CAP SOFT mode
					NAVPreGain.setValue(NAVGainCapSoft);
					NAVStep2Time.setValue(elapsedSec.getValue());
					if (NAVOver50Counting.getBoolValue() != 0) {
						NAVOver50Counting.setBoolValue(0);
					}
				}
			}
		} else {
			if (NAVPreGain.getValue() != NAVGainStd) {
				NAVPreGain.setValue(NAVGainStd);
			}
			if (NAVOver50Counting.getBoolValue() != 0) {
				NAVOver50Counting.setBoolValue(0);
			}
		}
		
		# Actual NAV mode gain, when APR mode is added, the sensitivity of the entire system is increased
		if (APRGainActive.getBoolValue()) {
			NAVGain.setValue(NAVPreGain.getValue() + 0.5);
		} else {
			NAVGain.setValue(NAVPreGain.getValue());
		}
		
		# Limit the turn rate depending on the mode
		if (roll.getValue() == 1 or roll.getValue() == 2) {
			if (NAVPreGain.getValue() == NAVGainCapSoft) {
				minTurnRate.setValue(-0.45);
				maxTurnRate.setValue(0.45);
			} else if (NAVPreGain.getValue() == NAVGainSoft) {
				minTurnRate.setValue(-0.15);
				maxTurnRate.setValue(0.15);
			} else {
				minTurnRate.setValue(-0.9);
				maxTurnRate.setValue(0.9);
			}
		} else {
			minTurnRate.setValue(-0.9);
			maxTurnRate.setValue(0.9);
		}
	},
	killAP: func() { # Kill all AP modes
		NAVt.stop();
		GPSt.stop();
		roll.setValue(-1);
		pitch.setValue(-1);
		setprop("/controls/flight/aileron", 0);
		setprop("/controls/flight/elevator", 0);
	},
	killAPPitch: func() { # Kill only the pitch modes
		pitch.setValue(-1);
		setprop("/controls/flight/elevator", 0);
	},
};

var button = {
	DISC: func() {
		ITAF.killAP();
	},
	HDGB: func(d) {
		if (hasPower.getBoolValue() == 1 and powerUpTest.getValue() != 1) {
			if (d == 1) { # Button pushed
				hdgButton.setBoolValue(1);
				hdgButtonTime.setValue(elapsedSec.getValue());
			} else if (d == 0) { # Button released
				if (hdgButtonTime.getValue() + 0.48 >= elapsedSec.getValue()) { # Button pops out and HDG gets engaged only if depressed for less than 0.48 seconds
					me.HDG();
					hdgButton.setBoolValue(0);
				}
			}
		} else {
			if (d == 1) { # Button pushed
				hdgButton.setBoolValue(1);
			} else if (d == 0) { # Button released
				hdgButton.setBoolValue(0);
			}
		}
	},
	HDG: func() {
		if (hasPower.getBoolValue() == 1 and powerUpTest.getValue() != 1) {
			NAVManIntercept.setBoolValue(0);
			roll.setValue(0);
		}
	},
	HDGInt: func() { # Heading Custom Intercept Mode
		if (hasPower.getBoolValue() == 1 and powerUpTest.getValue() != 1) {
			NAVManIntercept.setBoolValue(1);
			roll.setValue(0);
		}
	},
	NAV: func() {
		if (hasPower.getBoolValue() == 1 and powerUpTest.getValue() != 1) {
			APRGainActive.setBoolValue(0);
			if (roll.getValue() == 1 or roll.getValue() == 3) { # If NAV active or armed, switch to GPSS NAV mode
				roll.setValue(4);
				GPSchk();
				GPSt.start();
			} else { # If not regular NAV mode, switch to NAV
				if (hdgButton.getBoolValue() == 1) { # If the HDG button is being pushed, arm NAV for custom intercept angle
					me.CNAV();
				} else {
					roll.setValue(3);
					NAVchk();
					NAVt.start();
				}
			}
		}
	},
	APR: func() {
		if (hasPower.getBoolValue() == 1 and powerUpTest.getValue() != 1 and (roll.getValue() == 1 or roll.getValue() == 3)) {
			APRGainActive.setBoolValue(1);
		}
	},
	CNAV: func() {
		me.HDGInt();
		NAVchk();
		NAVt.start();
		hdgButton.setBoolValue(0);
	},
	ALT: func() {
		if (hasPower.getBoolValue() == 1 and powerUpTest.getValue() != 1 and roll.getValue() != -1) {
			altOffset.setValue(0);
			alt.setValue(staticPress.getValue());
			pitch.setValue(0);
		}
	},
	VS: func() {
		if (hasPower.getBoolValue() == 1 and powerUpTest.getValue() != 1 and roll.getValue() != -1) {
			pitch.setValue(1);
		}
	},
	Knob: func(d) {
		if (pitch.getValue() == 1 and powerUpTest.getValue() != 1) {
			if (d < 0) {
				vspeed = vs.getValue() - 100;
				if (vspeed < -1600) {
					vspeed = -1600;
				}
			} else {
				vspeed = vs.getValue() + 100;
				if (vspeed > 1600) {
					vspeed = 1600;
				}
			}
			vs.setValue(vspeed);
		}
	},
	CWS: func(d) {
		if (d == 1) { # Button pushed
			cwsSW.setBoolValue(1);
			if (hasPower.getBoolValue() == 1 and powerUpTest.getValue() != 1 and roll.getValue() != -1) {
				roll.setValue(-2);
				pitch.setValue(-2);
				setprop("/controls/flight/aileron", 0);
				setprop("/controls/flight/elevator", 0);
			}
		} else if (d == 0) { # Button released
			cwsSW.setBoolValue(0);
			if (hasPower.getBoolValue() == 1 and powerUpTest.getValue() != 1 and roll.getValue() != -1) {
				manTurnRate.setValue(math.clamp(turnRate.getValue(), -0.9, 0.9));
				roll.setValue(5);
				me.VS();
			}
		}
	},
};

var NAVchk = func {
	if (roll.getValue() == 3) {
		if (OBSActive.getBoolValue() == 1) { # Only engage NAV if OBS reports in range
			NAVt.stop();
			NAVFlash_annun.setBoolValue(0);
			roll.setValue(1);
			if (abs(OBSNeedle.getValue()) <= 1) { # Immediately go to SOFT mode if within 10% of deflection
				NAVPreGain.setValue(NAVGainSoft);
				NAVStep1Time.setValue(elapsedSec.getValue() - 90);
				NAVStep2Time.setValue(elapsedSec.getValue() - 75);
				NAVStep3Time.setValue(elapsedSec.getValue());
			}
		} else {
			NAVl.start();
		}
	} else if (roll.getValue() == 0 and NAVManIntercept.getBoolValue() == 1) {
		if (abs(OBSNeedle.getValue()) < 8) { # Only engage NAV if OBS is within capture
			NAVt.stop();
			NAVFlash_annun.setBoolValue(0);
			roll.setValue(1);
			if (abs(OBSNeedle.getValue()) <= 1) { # Immediately go to SOFT mode if within 10% of deflection
				NAVPreGain.setValue(NAVGainSoft);
				NAVStep1Time.setValue(elapsedSec.getValue() - 90);
				NAVStep2Time.setValue(elapsedSec.getValue() - 75);
				NAVStep3Time.setValue(elapsedSec.getValue());
			}
		} else {
			NAVl.start();
		}
	} else {
		NAVt.stop();
	}
}

var GPSchk = func {
	if (roll.getValue() == 4) {
		if (GPSActive.getBoolValue() == 1) { # Only engage GPSS NAV if GPS is activated
			GPSt.stop();
			NAVFlash_annun.setBoolValue(0);
			roll.setValue(2);
		} else {
			NAVl.start();
		}
	} else {
		GPSt.stop();
	}
}

var NAVl = maketimer(0.5, func { # Flashes the NAV (and sometimes GPSS) lights when NAV modes are armed
	NAV = roll.getValue() == 3 or roll.getValue() == 4; # Is NAV armed?
	CNAV = roll.getValue() == 0 and NAVManIntercept.getBoolValue(); # Is NAV with custom intercept heading armed?
	if ((NAV or CNAV) and NAVFlash_annun.getBoolValue() != 1) {
		NAVFlash_annun.setBoolValue(1);
	} else if ((NAV or CNAV) and NAVFlash_annun.getBoolValue() != 0) {
		NAVFlash_annun.setBoolValue(0);
	} else {
		NAVl.stop();
		NAVFlash_annun.setBoolValue(0);
	}
});

var NAVt = maketimer(0.5, NAVchk);
var GPSt = maketimer(0.5, GPSchk);
var update = maketimer(0.1, ITAF.loop);
