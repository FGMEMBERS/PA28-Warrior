# Piper PA28 Systems
# Copyright (c) 2019 Joshua Davidson (Octal450)

var ELEC = {
	Bus: {
		avionics: props.globals.getNode("/systems/electrical/bus/avionics"),
		main: props.globals.getNode("/systems/electrical/bus/main"),
	},
	CB: {
		alternatorField: props.globals.getNode("/controls/electrical/circuit-breakers/alternator-field"),
		fuelPump: props.globals.getNode("/controls/electrical/circuit-breakers/fuel-pump"),
	},
	Fail: {
		alternator: props.globals.getNode("/systems/failures/electrical/alternator"),
		avionicsBus: props.globals.getNode("/systems/failures/electrical/avionics-bus"),
		battery: props.globals.getNode("/systems/failures/electrical/battery"),
		batteryTemp: 0,
	},
	Misc: {
		elapsedSecTemp: 0,
	},
	Source: {
		Alt: {
			amp: props.globals.getNode("/systems/electrical/sources/alt/amp"),
			ampTemp: 0,
			ampCalc: props.globals.getNode("/systems/electrical/sources/alt/amp-calc"),
			ampCalcTemp: 0,
			volt: props.globals.getNode("/systems/electrical/sources/alt/volt"),
		},
		Bat: {
			amp: props.globals.getNode("/systems/electrical/sources/bat/amp"),
			percent: props.globals.getNode("/systems/electrical/sources/bat/percent"),
			percentCalc: 100,
			percentTemp: 100,
			time: 0,
			volt: props.globals.getNode("/systems/electrical/sources/bat/volt"),
		},
	},
	Switch: {
		alternator: props.globals.getNode("/controls/electrical/switches/alternator"),
		avionicsMaster: props.globals.getNode("/controls/electrical/switches/avionics-master"),
		avionicsSecondary: props.globals.getNode("/controls/electrical/switches/avionics-secondary"),
		battery: props.globals.getNode("/controls/electrical/switches/battery"),
	},
	init: func() {
		me.resetFail();
		me.resetCB();
		me.Switch.alternator.setBoolValue(0);
		me.Switch.avionicsMaster.setBoolValue(0);
		me.Switch.avionicsSecondary.setBoolValue(0);
		me.Switch.battery.setBoolValue(0);
		me.Source.Bat.percent.setValue(100);
		ampereTimer.start();
	},
	resetCB: func() {
		me.CB.alternatorField.setBoolValue(0);
		me.CB.fuelPump.setBoolValue(0);
	},
	resetFail: func() {
		me.Fail.alternator.setBoolValue(0);
		me.Fail.avionicsBus.setBoolValue(0);
		me.Fail.battery.setBoolValue(0);
	},
	loop: func() {
		me.Fail.batteryTemp = me.Fail.battery.getBoolValue();
		me.Misc.elapsedSecTemp = pts.Sim.Time.elapsedSec.getValue();
		me.Source.Bat.percentTemp = me.Source.Bat.percent.getValue();
		me.Switch.batteryTemp = me.Switch.battery.getBoolValue();
		
		# Battery Charging/Decharging
		if (me.Source.Bat.percentTemp < 100 and me.Source.Alt.amp.getValue() >= 30 and me.Switch.batteryTemp and !me.Fail.batteryTemp) {
			if (me.Source.Bat.time + 5 < me.Misc.elapsedSecTemp) {
				me.Source.Bat.percentCalc = me.Source.Bat.percentTemp + 0.75; # Roughly 90 percent every 10 mins
				if (me.Source.Bat.percentCalc > 100) {
					me.Source.Bat.percentCalc = 100;
				}
				me.Source.Bat.percent.setValue(me.Source.Bat.percentCalc);
				me.Source.Bat.time = me.Misc.elapsedSecTemp;
			}
		} else if (me.Source.Bat.percentTemp == 100 and me.Source.Alt.amp.getValue() >= 30 and me.Switch.batteryTemp and !me.Fail.batteryTemp) {
			me.Source.Bat.time = me.Misc.elapsedSecTemp;
		} else if (me.Source.Bat.amp.getValue() > 0 and me.Switch.batteryTemp and !me.Fail.batteryTemp) {
			if (me.Source.Bat.time + 5 < me.Misc.elapsedSecTemp) {
				me.Source.Bat.percentCalc = me.Source.Bat.percentTemp - 0.25; # Roughly 90 percent every 30 mins
				if (me.Source.Bat.percentCalc < 5) {
					me.Source.Bat.percentCalc = 5;
				}
				me.Source.Bat.percent.setValue(me.Source.Bat.percentCalc);
				me.Source.Bat.time = me.Misc.elapsedSecTemp;
			}
		} else {
			me.Source.Bat.time = me.Misc.elapsedSecTemp;
		}
	},
	ampereCalc: func() {
		me.Source.Alt.ampTemp = me.Source.Alt.amp.getValue();
		if (me.Source.Alt.ampTemp > 0) {
			me.Source.Alt.ampCalcTemp = me.Source.Alt.ampTemp + (rand() - 0.5) * 15;
			if (me.Source.Alt.ampCalcTemp < 0.1) {
				me.Source.Alt.ampCalcTemp = 0.1;
			}
			me.Source.Alt.ampCalc.setValue(me.Source.Alt.ampCalcTemp);
		} else {
			me.Source.Alt.ampCalc.setValue(0);
		}
	},
};

var ampereTimer = maketimer(0.05, ELEC, ELEC.ampereCalc);

# TODO: Rewrite completely as IntegratedSystems node
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
