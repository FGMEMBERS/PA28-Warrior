# S-TEC Fifty Five X Autopilot System
# Copyright (c) 2018 Joshua Davidson (it0uchpods)

var cdiDefl = 0;
var aoffset = 0;
var vspeed = 0;
var NAV = 0;
var CNAV = 0;
var ALTOffsetDeltaMax = 0;
var NAVGainStd = 1.0;
var NAVGainCap = 0.9;
var NAVGainCapSoft = 0.8;
var NAVGainSoft = 0.6;

# Initialize all used property nodes
var elapsedSec = props.globals.getNode("/sim/time/elapsed-sec");
var powerSrc = props.globals.initNode("/systems/electrical/outputs/autopilot", 0, "DOUBLE"); # Autopilot power source
var serviceable = props.globals.initNode("/it-stec55x/serviceable", 1, "BOOL");
var systemAlive = props.globals.initNode("/it-stec55x/internal/system-alive", 0, "BOOL");
var hdg = props.globals.initNode("/it-stec55x/input/hdg", 360, "DOUBLE");
var hdgButton = props.globals.initNode("/it-stec55x/input/hdg-button", 0, "BOOL");
var alt = props.globals.initNode("/it-stec55x/input/alt", 0, "DOUBLE"); # Altitude is in static pressure, not feet
var altOffset = props.globals.initNode("/it-stec55x/input/alt-offset", 0, "DOUBLE"); # Altitude offset
var vs = props.globals.initNode("/it-stec55x/input/vs", 0, "DOUBLE");
var cwsSW = props.globals.initNode("/it-stec55x/input/cws", 0, "BOOL");
var discSW = props.globals.initNode("/it-stec55x/input/disc", 0, "BOOL");
var manTrimSW = props.globals.initNode("/it-stec55x/input/man-trim", 0, "INT");
var masterAPSW = props.globals.initNode("/it-stec55x/input/ap-master-sw", 0, "BOOL");
var masterAPFDSW = props.globals.initNode("/it-stec55x/input/apfd-master-sw", 0, "INT");
var elecTrimSW = props.globals.initNode("/it-stec55x/input/electric-trim-sw", 0, "BOOL");
var hasPower = props.globals.initNode("/it-stec55x/internal/hasPower", 0, "BOOL");
var roll = props.globals.initNode("/it-stec55x/output/roll", -1, "INT");
var pitch = props.globals.initNode("/it-stec55x/output/pitch", -1, "INT");
var HDG_annun = props.globals.initNode("/it-stec55x/annun/hdg", 0, "BOOL");
var NAV_annun = props.globals.initNode("/it-stec55x/annun/nav", 0, "BOOL");
var APR_annun = props.globals.initNode("/it-stec55x/annun/apr", 0, "BOOL");
var REV_annun = props.globals.initNode("/it-stec55x/annun/rev", 0, "BOOL");
var ALT_annun = props.globals.initNode("/it-stec55x/annun/alt", 0, "BOOL");
var GS_annun = props.globals.initNode("/it-stec55x/annun/gs", 0, "BOOL");
var VS_annun = props.globals.initNode("/it-stec55x/annun/vs", 0, "BOOL");
var RDY_annun = props.globals.initNode("/it-stec55x/annun/rdy", 0, "BOOL");
var CWS_annun = props.globals.initNode("/it-stec55x/annun/cws", 0, "BOOL");
var FAIL_annun = props.globals.initNode("/it-stec55x/annun/fail", 0, "BOOL");
var GPSS_annun = props.globals.initNode("/it-stec55x/annun/gpss", 0, "BOOL");
var TRIM_annun = props.globals.initNode("/it-stec55x/annun/trim", 0, "BOOL");
var UP_annun = props.globals.initNode("/it-stec55x/annun/up", 0, "BOOL");
var DN_annun = props.globals.initNode("/it-stec55x/annun/dn", 0, "BOOL");
var NAVFlash_annun = props.globals.initNode("/it-stec55x/annun/nav-flash", 0, "BOOL");
var NAVManIntercept = props.globals.initNode("/it-stec55x/internal/nav-man-intercept", 1, "BOOL");
var minTurnRate = props.globals.initNode("/it-stec55x/internal/min-turn-rate", -0.9, "DOUBLE");
var maxTurnRate = props.globals.initNode("/it-stec55x/internal/max-turn-rate", 0.9, "DOUBLE");
var manTurnRate = props.globals.initNode("/it-stec55x/internal/man-turn-rate", 0, "DOUBLE");
var NAVGain = props.globals.initNode("/it-stec55x/internal/nav-gain", NAVGainStd, "DOUBLE");
var NAVStep1Time = props.globals.initNode("/it-stec55x/internal/nav-step1-time", 0, "DOUBLE");
var NAVStep2Time = props.globals.initNode("/it-stec55x/internal/nav-step2-time", 0, "DOUBLE");
var NAVStep3Time = props.globals.initNode("/it-stec55x/internal/nav-step3-time", 0, "DOUBLE");
var NAVOver50Time = props.globals.initNode("/it-stec55x/internal/nav-over50-time", 0, "DOUBLE");
var NAVOver50Counting = props.globals.initNode("/it-stec55x/internal/nav-over50-counting", 0, "BOOL");
var hdgButtonTime = props.globals.initNode("/it-stec55x/internal/hdg-button-time", 0, "DOUBLE");
var powerUpTime = props.globals.initNode("/it-stec55x/internal/powerup-time", 0, "DOUBLE");
var powerUpTest = props.globals.initNode("/it-stec55x/internal/powerup-test", -1, "INT"); # -1 = Powerup test not done, 0 = Powerup test complete, 1 = Powerup test in progress
var APRModeActive = props.globals.initNode("/it-stec55x/internal/apr-mode-active", 0, "BOOL");
var ALTOffsetDelta = props.globals.getNode("/it-stec55x/internal/static-20ft-delta");
var masterSW = props.globals.initNode("/it-stec55x/internal/master-sw", 0, "INT"); # 0 = OFF, 1 = FD, 2 = AP/FD
var servoRollPower = props.globals.initNode("/it-stec55x/internal/servo-roll-power", 0, "BOOL");
var servoPitchPower = props.globals.initNode("/it-stec55x/internal/servo-pitch-power", 0, "BOOL");
var discSound = props.globals.initNode("/it-stec55x/sound/disc", 0, "BOOL");
var HDGIndicator = props.globals.getNode("/instrumentation/heading-indicator/indicated-heading-deg");
var OBSNAVNeedle = props.globals.getNode("/instrumentation/nav[0]/heading-needle-deflection");
var OBSCourse = props.globals.getNode("/instrumentation/nav[0]/radials/selected-deg");
var OBSActive = props.globals.getNode("/instrumentation/nav[0]/in-range");
var OBSIsLOC = props.globals.getNode("/instrumentation/nav[0]/nav-loc");
var GPSActive = props.globals.getNode("/autopilot/route-manager/active");
var turnRate = props.globals.getNode("/instrumentation/turn-indicator/indicated-turn-rate");
var turnRateSpin = props.globals.getNode("/instrumentation/turn-indicator/spin");
var staticPress = props.globals.getNode("/systems/static[0]/pressure-inhg");

# Initialize setting property nodes
var HSIequipped = props.globals.getNode("/it-stec55x/settings/hsi-equipped"); # Does the aircraft have an HSI or DG?
var isTurboprop = props.globals.getNode("/it-stec55x/settings/is-turboprop"); # Does the aircraft have turboprop engines?
var FDequipped = props.globals.getNode("/it-stec55x/settings/fd-equipped"); # Does the aircraft have a flight director installed?
var useControlsFlight = props.globals.getNode("/it-stec55x/settings/use-controls-flight"); # Use generic /controls/flight for flight controls instead of custom properties

setlistener("/sim/signals/fdm-initialized", func {
	ITAF.init();
});

var ITAF = {
	init: func() {
		hdg.setValue(360);
		alt.setValue(0);
		altOffset.setValue(0);
		vs.setValue(0);
		cwsSW.setBoolValue(0);
		discSW.setBoolValue(0);
		masterAPSW.setBoolValue(0);
		masterAPFDSW.setValue(0);
		elecTrimSW.setBoolValue(0);
		NAVManIntercept.setBoolValue(0);
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
		TRIM_annun.setBoolValue(0);
		UP_annun.setBoolValue(0);
		DN_annun.setBoolValue(0);
		NAVFlash_annun.setBoolValue(0);
		discSound.setBoolValue(0);
		update.start();
		updateFast.start();
	},
	loop: func() {
		if (FDequipped.getBoolValue() == 1) {
			masterSW.setValue(masterAPFDSW.getValue());
			if (masterAPSW.getBoolValue() != 0) { # Just in case the FD equipped option is changed while system operating
				masterAPSW.setBoolValue(0);
			}
		} else {
			masterSW.setValue(masterAPSW.getValue() * 2);
			if (masterAPFDSW.getValue() != 0) { # Just in case the FD equipped option is changed while system operating
				masterAPFDSW.setValue(0);
			}
		}
		
		if (hasPower.getBoolValue() == 1 and turnRateSpin.getValue() >= 0.2) { # Requires turn indicator spin over 20%
			systemAlive.setBoolValue(1);
		} else {
			systemAlive.setBoolValue(0);
			if (roll.getValue() != -1 or pitch.getValue() != -1) {
				ITAF.killAP(); # Called with ITAF.killAP not me.killAP because this function is called from the timer outside this class
			}
		}
		
		if (powerSrc.getValue() >= 8 and masterSW.getValue() > 0) {
			hasPower.setBoolValue(1);
			if (powerUpTest.getValue() == -1 and systemAlive.getBoolValue() == 1) { # Begin power on test
				powerUpTest.setValue(1);
				powerUpTime.setValue(elapsedSec.getValue());
				vs.setValue(1800); # For startup test only
			}
		} else {
			hasPower.setBoolValue(0);
			if (powerUpTest.getValue() != -1 or systemAlive.getBoolValue() != 1) {
				powerUpTest.setValue(-1);
			}
			if (roll.getValue() != -1 or pitch.getValue() != -1) {
				ITAF.killAP(); # Called with ITAF.killAP not me.killAP because this function is called from the timer outside this class
			}
		}
		
		NAV = roll.getValue() == 3 or roll.getValue() == 4; # Is NAV armed?
		CNAV = roll.getValue() == 0 and NAVManIntercept.getBoolValue(); # Is NAV with custom intercept heading armed?
		
		if (systemAlive.getBoolValue() == 0) { # AP Failed when false
			RDY_annun.setBoolValue(0);
			FAIL_annun.setBoolValue(0);
		} else {
			if (powerUpTest.getValue() == 1 and powerUpTime.getValue() + 10 < elapsedSec.getValue()) {
				powerUpTest.setValue(0);
			}
			if (roll.getValue() == -1 and serviceable.getBoolValue() == 1) {
				RDY_annun.setBoolValue(1);
			} else {
				RDY_annun.setBoolValue(0);
			}
			if (serviceable.getBoolValue() != 1) {
				FAIL_annun.setBoolValue(1);
				if (roll.getValue() != -1 or pitch.getValue() != -1) {
					ITAF.killAP(); # Called with ITAF.killAP not me.killAP because this function is called from the timer outside this class
				}
			} else if (powerUpTest.getValue() == 1 or ((roll.getValue() == 1 or roll.getValue() == 3 or CNAV) and OBSActive.getBoolValue() != 1)) {
				FAIL_annun.setBoolValue(1);
			} else if (powerUpTest.getValue() == 1 or ((roll.getValue() == 2 or roll.getValue() == 4) and GPSActive.getBoolValue() != 1)) {
				FAIL_annun.setBoolValue(1);
			} else {
				FAIL_annun.setBoolValue(0);
			}
		}
		
		# Mode Annunciators
		# AP does not power up or show any signs of life unless if has power (obviously), and the turn coordinator is working
		if ((roll.getValue() == 0 or powerUpTest.getValue() == 1) and systemAlive.getBoolValue() == 1) {
			HDG_annun.setBoolValue(1);
		} else {
			HDG_annun.setBoolValue(0);
		}
		
		if ((roll.getValue() == 1 or roll.getValue() == 2 or ((NAV or CNAV) and NAVFlash_annun.getBoolValue()) or powerUpTest.getValue() == 1) and systemAlive.getBoolValue() == 1) {
			NAV_annun.setBoolValue(1);
		} else {
			NAV_annun.setBoolValue(0);
		}
		
		if ((((roll.getValue() == 1 or ((CNAV or roll.getValue() == 3) and NAVFlash_annun.getBoolValue())) and APRModeActive.getBoolValue() == 1) or powerUpTest.getValue() == 1) and systemAlive.getBoolValue() == 1) {
			APR_annun.setBoolValue(1);
		} else {
			APR_annun.setBoolValue(0);
		}
		
		if ((pitch.getValue() == 0 or powerUpTest.getValue() == 1) and systemAlive.getBoolValue() == 1) {
			ALT_annun.setBoolValue(1);
		} else {
			ALT_annun.setBoolValue(0);
		}
		
		if ((pitch.getValue() == 1 or pitch.getValue() == -2 or powerUpTest.getValue() == 1) and systemAlive.getBoolValue() == 1) {
			VS_annun.setBoolValue(1);
		} else {
			VS_annun.setBoolValue(0);
		}
		
		if ((roll.getValue() == 5 or roll.getValue() == -2 or powerUpTest.getValue() == 1) and systemAlive.getBoolValue() == 1) {
			CWS_annun.setBoolValue(1);
		} else {
			CWS_annun.setBoolValue(0);
		}
		
		if ((roll.getValue() == 2 or (roll.getValue() == 4 and NAVFlash_annun.getBoolValue()) or powerUpTest.getValue() == 1) and systemAlive.getBoolValue() == 1) {
			GPSS_annun.setBoolValue(1);
		} else {
			GPSS_annun.setBoolValue(0);
		}
		
		# Temporary stuff because these lights aren't implemented yet
		if (powerUpTest.getValue() == 1 and systemAlive.getBoolValue() == 1) {
			REV_annun.setBoolValue(1);
			GS_annun.setBoolValue(1);
		} else {
			REV_annun.setBoolValue(0);
			GS_annun.setBoolValue(0);
		}
		
		# Electric Pitch Trim
		if (systemAlive.getBoolValue() == 1) {
			if (powerUpTest.getValue() == 1 or (pitch.getValue() > -1 and getprop("/it-stec55x/internal/elevator") < -0.025 and masterSW.getValue() == 2)) {
				UP_annun.setBoolValue(1);
			} else if (pitch.getValue() > -1 and UP_annun.getBoolValue() == 1 and getprop("/it-stec55x/internal/elevator") < -0.01 and masterSW.getValue() == 2) {
				UP_annun.setBoolValue(1);
			} else {
				UP_annun.setBoolValue(0);
			}
			if (powerUpTest.getValue() == 1 or (pitch.getValue() > -1 and getprop("/it-stec55x/internal/elevator") > 0.025 and masterSW.getValue() == 2)) {
				DN_annun.setBoolValue(1);
			} else if (pitch.getValue() > -1 and DN_annun.getBoolValue() == 1 and getprop("/it-stec55x/internal/elevator") > 0.01 and masterSW.getValue() == 2) {
				DN_annun.setBoolValue(1);
			} else {
				DN_annun.setBoolValue(0);
			}
		} else {
			UP_annun.setBoolValue(0);
			DN_annun.setBoolValue(0);
		}
		
		if ((UP_annun.getBoolValue() == 1 or DN_annun.getBoolValue() == 1 or manTrimSW.getValue() != 0 or powerUpTest.getValue() == 1) and systemAlive.getBoolValue() == 1) {
			TRIM_annun.setBoolValue(1);
		} else {
			TRIM_annun.setBoolValue(0);
		}
		
		# NAV mode gain, reduces as the system captures the course
		if (roll.getValue() == 1) {
			cdiDefl = OBSNAVNeedle.getValue();
			if (abs(cdiDefl) <= 1.5 and NAVGain.getValue() == NAVGainStd) { # CAP mode
				NAVGain.setValue(NAVGainCap);
				NAVStep1Time.setValue(elapsedSec.getValue());
			} else if (NAVStep1Time.getValue() + 15 <= elapsedSec.getValue() and NAVGain.getValue() == NAVGainCap) { # CAP SOFT mode
				NAVGain.setValue(NAVGainCapSoft);
				NAVStep2Time.setValue(elapsedSec.getValue());
			} else if (NAVStep2Time.getValue() + 75 <= elapsedSec.getValue() and NAVGain.getValue() == NAVGainCapSoft and APRModeActive.getBoolValue() == 0) { # SOFT mode
				NAVGain.setValue(NAVGainSoft);
				NAVStep3Time.setValue(elapsedSec.getValue());
			}
			
			# Return to CAP SOFT if needle deflection is >= 50% for 60 seconds
			if (cdiDefl >= 5 and NAVGain.getValue() == NAVGainSoft) {
				if (NAVOver50Counting.getBoolValue() != 1) { # Prevent it from constantly updating the time
					NAVOver50Counting.setBoolValue(1);
					NAVOver50Time.setValue(elapsedSec.getValue());
				}
				if (NAVOver50Time.getValue() + 60 < elapsedSec.getValue()) { # CAP SOFT mode
					NAVGain.setValue(NAVGainCapSoft);
					NAVStep2Time.setValue(elapsedSec.getValue());
					if (NAVOver50Counting.getBoolValue() != 0) {
						NAVOver50Counting.setBoolValue(0);
					}
				}
			}
		} else {
			if (NAVGain.getValue() != NAVGainStd) {
				NAVGain.setValue(NAVGainStd);
			}
			if (NAVOver50Counting.getBoolValue() != 0) {
				NAVOver50Counting.setBoolValue(0);
			}
		}
		
		# Limit the turn rate depending on the mode
		if (isTurboprop.getBoolValue() == 1) { # Turboprop aircraft have lower turn rates
			if (roll.getValue() == 1) { # Turn rate in NAV mode
				if (NAVGain.getValue() == NAVGainCapSoft) {
					minTurnRate.setValue(-0.375);
					maxTurnRate.setValue(0.375);
				} else if (NAVGain.getValue() == NAVGainSoft) {
					minTurnRate.setValue(-0.125);
					maxTurnRate.setValue(0.125);
				} else {
					minTurnRate.setValue(-0.75);
					maxTurnRate.setValue(0.75);
				}
			} else { # 75% turn rate in all other modes
				minTurnRate.setValue(-0.75);
				maxTurnRate.setValue(0.75);
			}
		} else {
			if (roll.getValue() == 1) { # Turn rate in NAV mode
				if (NAVGain.getValue() == NAVGainCapSoft) {
					minTurnRate.setValue(-0.45);
					maxTurnRate.setValue(0.45);
				} else if (NAVGain.getValue() == NAVGainSoft) {
					minTurnRate.setValue(-0.15);
					maxTurnRate.setValue(0.15);
				} else {
					minTurnRate.setValue(-0.9);
					maxTurnRate.setValue(0.9);
				}
			} else { # 90% turn rate in all other modes
				minTurnRate.setValue(-0.9);
				maxTurnRate.setValue(0.9);
			}
		}
	},
	loopFast: func() {
		# Roll Servo
		if (masterSW.getValue() == 2 and roll.getValue() > -1) {
			if (servoRollPower.getBoolValue() != 1) {
				servoRollPower.setBoolValue(1);
				discSound.setBoolValue(0);
			}
		} else {
			if (servoRollPower.getBoolValue() != 0) {
				servoRollPower.setBoolValue(0);
				if (useControlsFlight.getBoolValue()) {
					setprop("/controls/flight/aileron", 0);
				}
				if (roll.getValue() != -2) {
					discSound.setBoolValue(1);
				}
			}
		}
		
		# Pitch Servo
		if (masterSW.getValue() == 2 and pitch.getValue() > -1) {
			if (servoPitchPower.getBoolValue() != 1) {
				servoPitchPower.setBoolValue(1);

			}
		} else {
			if (servoPitchPower.getBoolValue() != 0) {
				servoPitchPower.setBoolValue(0);
				if (useControlsFlight.getBoolValue()) {
					setprop("/controls/flight/elevator", 0);
				}
			}
		}
		
		# Man Trim AP DISC
		if (manTrimSW.getValue() != 0 and pitch.getValue() > -1 and masterSW.getValue() == 2) {
			ITAF.killAPPitch(); # Called with ITAF.killAPPitch not me.killAPPitch because this function is called from the timer outside this class
		}
	},
	killAP: func() { # Kill all AP modes
		NAVt.stop();
		GPSt.stop();
		roll.setValue(-1);
		pitch.setValue(-1);
	},
	killAPPitch: func() { # Kill only the pitch modes
		pitch.setValue(-1);
	},
};

var button = {
	DISC: func() {
		ITAF.killAP();
	},
	HDGB: func(d) {
		if (systemAlive.getBoolValue() == 1 and powerUpTest.getValue() != 1 and serviceable.getBoolValue() == 1) {
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
		if (systemAlive.getBoolValue() == 1 and powerUpTest.getValue() != 1 and serviceable.getBoolValue() == 1) {
			NAVManIntercept.setBoolValue(0);
			roll.setValue(0);
		}
	},
	HDGInt: func() { # Heading Custom Intercept Mode
		if (systemAlive.getBoolValue() == 1 and powerUpTest.getValue() != 1 and serviceable.getBoolValue() == 1) {
			NAVManIntercept.setBoolValue(1);
			roll.setValue(0);
		}
	},
	NAV: func() {
		if (systemAlive.getBoolValue() == 1 and powerUpTest.getValue() != 1 and serviceable.getBoolValue() == 1) {
			APRModeActive.setBoolValue(0);
			if (hdgButton.getBoolValue() == 1) { # If the HDG button is being pushed, arm NAV for custom intercept angle
				me.CNAV();
			} else {
				if (roll.getValue() == 1 or roll.getValue() == 3) { # If NAV active or armed, switch to GPSS NAV mode
					roll.setValue(4);
					GPSchk();
					GPSt.start();
				} else { # If not regular NAV mode, switch to NAV
					roll.setValue(3);
					NAVchk();
					NAVt.start();
				}
			}
		}
	},
	APR: func() {
		hdgButton.setBoolValue(0);
		CNAV = roll.getValue() == 0 and NAVManIntercept.getBoolValue(); # Is NAV with custom intercept heading armed?
		if (systemAlive.getBoolValue() == 1 and powerUpTest.getValue() != 1 and (CNAV or roll.getValue() == 1 or roll.getValue() == 3) and serviceable.getBoolValue() == 1) {
			APRModeActive.setBoolValue(1);
			# If in SOFT mode, go back to CAP SOFT
			if (APRModeActive.getBoolValue() and NAVGain.getValue() == NAVGainSoft) {
				NAVGain.setValue(NAVGainCapSoft);
				NAVStep2Time.setValue(elapsedSec.getValue());
			}
		}
	},
	CNAV: func() {
		me.HDGInt();
		NAVchk();
		NAVt.start();
		hdgButton.setBoolValue(0);
	},
	ALT: func() {
		hdgButton.setBoolValue(0);
		if (systemAlive.getBoolValue() == 1 and powerUpTest.getValue() != 1 and roll.getValue() != -1 and serviceable.getBoolValue() == 1) {
			altOffset.setValue(0);
			alt.setValue(staticPress.getValue());
			pitch.setValue(0);
		}
	},
	VS: func() {
		hdgButton.setBoolValue(0);
		if (systemAlive.getBoolValue() == 1 and powerUpTest.getValue() != 1 and roll.getValue() != -1 and serviceable.getBoolValue() == 1) {
			pitch.setValue(1);
		}
	},
	Knob: func(d) {
		if (pitch.getValue() == 0 and powerUpTest.getValue() != 1 and serviceable.getBoolValue() == 1) {
			if (d < 0) {
				aoffset = altOffset.getValue() + ALTOffsetDelta.getValue();
				ALTOffsetDeltaMax = ALTOffsetDelta.getValue() * 18; # Get the static pressure value and multiply by 18 to limit it at +360
				if (aoffset > ALTOffsetDeltaMax) {
					aoffset = ALTOffsetDeltaMax;
				}
			} else {
				aoffset = altOffset.getValue() - ALTOffsetDelta.getValue();
				ALTOffsetDeltaMax = ALTOffsetDelta.getValue() * -18; # Get the static pressure value and multiply by -18 to limit it at -360
				if (aoffset < ALTOffsetDeltaMax) {
					aoffset = ALTOffsetDeltaMax;
				}
			}
			altOffset.setValue(aoffset);
		} else if (pitch.getValue() == 1 and powerUpTest.getValue() != 1) {
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
			if (systemAlive.getBoolValue() == 1 and powerUpTest.getValue() != 1 and roll.getValue() != -1 and serviceable.getBoolValue() == 1) {
				roll.setValue(-2);
				pitch.setValue(-2);
			}
		} else if (d == 0) { # Button released
			cwsSW.setBoolValue(0);
			if (systemAlive.getBoolValue() == 1 and powerUpTest.getValue() != 1 and roll.getValue() != -1 and serviceable.getBoolValue() == 1) {
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
			if (OBSIsLOC.getBoolValue()) {
				APRModeActive.setBoolValue(1);
			}
			if (abs(OBSNAVNeedle.getValue()) <= 1 and abs(HDGIndicator.getValue() - OBSCourse.getValue()) < 5) { # Immediately go to SOFT mode if within 10% of deflection and within 5 degrees of course.
				NAVGain.setValue(NAVGainSoft);
				NAVStep1Time.setValue(elapsedSec.getValue() - 90);
				NAVStep2Time.setValue(elapsedSec.getValue() - 75);
				NAVStep3Time.setValue(elapsedSec.getValue());
			}
		} else {
			NAVl.start();
		}
	} else if (roll.getValue() == 0 and NAVManIntercept.getBoolValue() == 1) {
		if (abs(OBSNAVNeedle.getValue()) < 10) { # Only engage NAV if OBS is within capture
			NAVt.stop();
			NAVFlash_annun.setBoolValue(0);
			roll.setValue(1);
			if (OBSIsLOC.getBoolValue()) {
				APRModeActive.setBoolValue(1);
			}
			if (abs(OBSNAVNeedle.getValue()) <= 1 and abs(HDGIndicator.getValue() - OBSCourse.getValue()) < 5) { # Immediately go to SOFT mode if within 10% of deflection and within 5 degrees of course.
				NAVGain.setValue(NAVGainSoft);
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
var updateFast = maketimer(0.05, ITAF.loopFast);
