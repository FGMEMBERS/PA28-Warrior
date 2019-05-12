# PA28-161 Electrical
# Copyright (c) 2019 Joshua Davidson (Octal450)

var batt_sw = 0;
var altn_sw = 0;
var avionics_master = 0;
var rpm = 0;
var src = "XX";
var batt_volt = 12;
var batt_amp = 35;
var altn_volt = 0;
var altn_amp = 0;
var bus_volt = 0;
var elec1 = 0;
var elec2 = 0;
var avionics1 = 0;
var avionics2 = 0;
var nav_factor = 0;
var panel_factor = 0;
var calc = 0;
setprop("/systems/electrical/bus/elec1", 0);
setprop("/systems/electrical/bus/elec2", 0);
setprop("/systems/electrical/outputs/adf", 0);
setprop("/systems/electrical/outputs/autopilot", 0);
setprop("/systems/electrical/outputs/comm[0]", 0);
setprop("/systems/electrical/outputs/comm[1]", 0);
setprop("/systems/electrical/outputs/dme", 0);
setprop("/systems/electrical/outputs/electrim", 0);
setprop("/systems/electrical/outputs/fuel-pump", 0);
setprop("/systems/electrical/outputs/hsi", 0);
setprop("/systems/electrical/outputs/nav[0]", 0);
setprop("/systems/electrical/outputs/nav[1]", 0);
setprop("/systems/electrical/outputs/oat", 0);
setprop("/systems/electrical/outputs/stby", 0);
setprop("/systems/electrical/outputs/transponder", 0);

var ELEC = {
	init: func() {
		setprop("/controls/electrical/battery", 0);
		setprop("/controls/electrical/alternator", 0);
		setprop("/controls/switches/avionics-master", 0);
		setprop("/controls/switches/avionics-secondary", 0);
		src = "XX";
		setprop("/systems/electrical/batt-volt", 12);
		setprop("/systems/electrical/batt-amp", 35);
		setprop("/systems/electrical/altn-volt", 0);
		setprop("/systems/electrical/altn-amp", 0);
		setprop("/systems/electrical/bus/elec1", 0);
		setprop("/systems/electrical/bus/elec2", 0);
		setprop("/systems/electrical/bus/avionics1", 0);
		setprop("/systems/electrical/bus/avionics2", 0);
		setprop("/controls/switches/nav-lights-factor", 0);
		setprop("/controls/switches/panel-lights-factor", 0);
		ampereCalc.start();
	},
	loop: func() {
		batt_sw = getprop("/controls/electrical/battery");
		altn_sw = getprop("/controls/electrical/alternator");
		rpm = getprop("/engines/engine[0]/rpm");
		batt_volt = getprop("/systems/electrical/batt-volt");
		batt_amp = getprop("/systems/electrical/batt-amp");
		elec1 = getprop("/systems/electrical/bus/elec1");
		elec2 = getprop("/systems/electrical/bus/elec2");
		
		if (rpm >= 511 and altn_sw and getprop("/systems/failures/alternator") == 0) {
			setprop("/systems/electrical/altn-volt", 14);
			setprop("/systems/electrical/altn-amp", 35);
		} else {
			setprop("/systems/electrical/altn-volt", 0);
			setprop("/systems/electrical/altn-amp", 0);
		}
		
		altn_volt = getprop("/systems/electrical/altn-volt");
		altn_amp = getprop("/systems/electrical/altn-amp");
		
		if (altn_volt >= 8 and altn_sw) {
			src = "ALTN";
			if (elec1 != altn_volt) {
				bus_volt = altn_volt;
			}
		} else if (batt_volt >= 8 and batt_sw and getprop("/systems/failures/battery") == 0) {
			src = "BATT";
			if (elec1 != batt_volt) {
				bus_volt = batt_volt;
			}
		} else {
			src = "XX";
			bus_volt = 0;
		}
		
		if (getprop("/systems/failures/elec-1") == 0) {
			if (getprop("/systems/electrical/bus/elec1") != bus_volt) {
				setprop("/systems/electrical/bus/elec1", bus_volt);
			}
		} else {
			if (getprop("/systems/electrical/bus/elec1") != 0) {
				setprop("/systems/electrical/bus/elec1", 0);
			}
		}
		
		if (getprop("/systems/failures/elec-2") == 0) {
			if (getprop("/systems/electrical/bus/elec2") != bus_volt) {
				setprop("/systems/electrical/bus/elec2", bus_volt);
			}
		} else {
			if (getprop("/systems/electrical/bus/elec2") != 0) {
				setprop("/systems/electrical/bus/elec2", 0);
			}
		}
		
		elec1 = getprop("/systems/electrical/bus/elec1");
		elec2 = getprop("/systems/electrical/bus/elec2");
		avionics_master = getprop("/controls/switches/avionics-master");
		
		setprop("/systems/electrical/outputs/cabin-lights", elec1);
		setprop("/systems/electrical/outputs/map-lights", elec1);
		
		if (elec1 >= 8 and getprop("/controls/switches/fuel-pump") == 1) {
			setprop("/systems/electrical/outputs/fuel-pump", elec1);
		} else {
			setprop("/systems/electrical/outputs/fuel-pump", 0);
		}
		
		if (elec1 >= 8 and getprop("/controls/switches/beacon") == 1) {
			setprop("/controls/lighting/beacon", 1);
		} else {
			setprop("/controls/lighting/beacon", 0);
		}
		
		if (elec1 >= 8 and getprop("/controls/switches/strobe-lights") == 1) {
			setprop("/controls/lighting/strobe", 1);
		} else {
			setprop("/controls/lighting/strobe", 0);
		}
		
		if (elec1 >= 8 and getprop("/controls/switches/landing-light") == 1) {
			setprop("/controls/lighting/landing-lights", 1);
		} else {
			setprop("/controls/lighting/landing-lights", 0);
		}
		
		setprop("/systems/electrical/outputs/turn-coordinator", elec2);
		
		if (elec2 >= 8 and getprop("/controls/switches/nav-lights-factor") >= 0.1) {
			nav_factor = getprop("/controls/switches/nav-lights-factor");
			setprop("/controls/lighting/nav-lights", nav_factor);
		} else {
			setprop("/controls/lighting/nav-lights", 0);
		}
		
		if (elec2 >= 8 and getprop("/controls/switches/panel-lights-factor") >= 0.1) {
			panel_factor = getprop("/controls/switches/panel-lights-factor");
			setprop("/systems/electrical/outputs/instrument-lights", elec2);
			setprop("/controls/switches/panel-lights-cmd", elec2 * 0.071428571 * panel_factor);
		} else {
			setprop("/systems/electrical/outputs/instrument-lights", 0);
			setprop("/controls/switches/panel-lights-cmd", 0);
		}
		
		if (elec2 >= 8 and getprop("/controls/switches/pitot-heat") == 1) {
			setprop("/systems/electrical/outputs/pitot-heat", elec2);
		} else {
			setprop("/systems/electrical/outputs/pitot-heat", 0);
		}
		
		if (avionics_master and getprop("/systems/failures/avionics-1") == 0) {
			setprop("/systems/electrical/bus/avionics1", elec1);
		} else {
			setprop("/systems/electrical/bus/avionics1", 0);
		}
		
		if (avionics_master and getprop("/systems/failures/avionics-2") == 0) {
			setprop("/systems/electrical/bus/avionics2", elec2);
		} else {
			setprop("/systems/electrical/bus/avionics2", 0);
		}
		
		setprop("/systems/electrical/outputs/annunciators", elec2);
		
		avionics1 = getprop("/systems/electrical/bus/avionics1");
		avionics2 = getprop("/systems/electrical/bus/avionics2");

		setprop("/systems/electrical/outputs/comm[0]", avionics1);
		setprop("/systems/electrical/outputs/hsi", avionics1);
		setprop("/systems/electrical/outputs/nav[0]", avionics1);
		setprop("/systems/electrical/outputs/oat", avionics1);
		setprop("/systems/electrical/outputs/dme", avionics1);
		setprop("/systems/electrical/outputs/stby", avionics1);
		
		setprop("/systems/electrical/outputs/adf", avionics2);
		setprop("/systems/electrical/outputs/autopilot", avionics2);
		setprop("/systems/electrical/outputs/electrim", avionics2);
		setprop("/systems/electrical/outputs/comm[1]", avionics2);
		setprop("/systems/electrical/outputs/nav[1]", avionics2);
		setprop("/systems/electrical/outputs/transponder", avionics2);
	},
};

var ampereCalc = maketimer(0.05, func {
	if (getprop("/systems/electrical/altn-amp") > 0) {
		calc = getprop("/systems/electrical/altn-amp") + (rand() - 0.5) * 15;
		if (calc < 1) {
			calc = 1;
		}
		setprop("/systems/electrical/altn-amp-calc", calc);
	} else {
		setprop("/systems/electrical/altn-amp-calc", 0);
	}
});
