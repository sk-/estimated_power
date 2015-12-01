using Toybox.Lang as Lang;
using Toybox.Math as Math;
using Toybox.Sensor as Sensor;
using Toybox.UserProfile as UserProfile;
using Toybox.WatchUi as Ui;

class EstimatedPowerView extends Ui.SimpleDataField {
	var lastPower;
	var height;
	var weight;
	
	var altitudes;
	var distances;

	var cwaRiderConst;
	var cwaRiderConstCCad;
	var gM;

    function initialize() {
        label = Ui.loadResource(Rez.Strings.labelName);

		altitudes = new CircularArray(5);
		distances = new CircularArray(5);

        lastPower = "---";

        var profile = UserProfile.getProfile();
        if (profile.height != null) {
        	height = profile.height / 100.0;
        } else {
        	height = 1.75;
        }
        if (profile.weight != null) {
        	weight = profile.weight / 1000.0;
        } else {
        	weight = 75.0;
        }

        var afCd = 0.6;
		var afSin = 0.67;
        var adipos = Math.sqrt(weight / (height * 750));
        cwaRiderConst = afCd * adipos * (((height - adipos) * afSin) + adipos);
        var cCad=0.002;
        cwaRiderConstCCad = cCad * cwaRiderConst;
        var mBike = 9.5;
		var g = 9.80665;
        gM = g * (mBike + weight);
        //var P0 = 101325;
		//var rho0 = 1.2922;
		//var e = 2.7182818284590452353602875; Math.E
        // C = e^(-1 * rho0 * g / P0)
        // C = Math.pow(Math.E, -0.00012506442763385146) = 0.9998749433925956;
    }

    function compute(info) {
    	var currentAltitude = info.altitude;
		var currentDistance = info.elapsedDistance;

		var lastDistance = distances.last();
		if (lastDistance != null && currentDistance <= distances.last()) {
			return lastPower;
		}

		distances.add(currentDistance);
		altitudes.add(currentAltitude);
		
		var firstAltitude = altitudes.first();
		var firstDistance = distances.first();
		
		var deltaAltitude = null;
		if (firstAltitude != null) {
			deltaAltitude = currentAltitude - firstAltitude;
		}
		
		var deltaDistance = null;
		if (firstDistance != null) {
			deltaDistance = currentDistance - firstDistance;
		}
		
		var powerString = "---";
		if (deltaAltitude != null && deltaDistance != null && deltaDistance > 0.0) {
			var angle = Math.asin(deltaAltitude / deltaDistance);
			var power = computePower(angle, info.currentCadence, currentAltitude, info.currentSpeed, null);
			//grade = Lang.format("$1$/$2$", [(100 * Math.tan(angle)).format("%.2f") + "%", power.format("%.2f") + "W"]);
			powerString = power.format("%3.0f") + "W";
		}
		
		lastPower = powerString;

        return powerString;
    }
    
    function computePower(theta, cadence, altitude, speed, temperature) {
    	if (cadence == null) {
    		cadence = 90;
    	} else if (cadence < 10) {
    		return 0.0;
    	}
 
    	if (temperature == null) {
    		temperature = 15.0;
    	}
		//var tire = 0.021;
		var cr = 0.0033;
		//var afAFrame = 0.048;
		var cosTheta = Math.cos(theta);
		var sinTheta = Math.sin(theta);
		
		
		//var Cwa_bike = afCdBike[bikeI] * ((afCATireV[bikeI] + afCATireH[bikeI]) * tire + afAFrame);
		//var Cwa_bike = 1.5 * (2.0 * 0.021 + 0.048) = 0.135
		//var Cwa_bike = 1.5 * (2.0 * 0.021 + 0.048)
		//var Cwa_bike = 1.25 * (1.8 * 0.021 + 0.048) = 0.10725
		var cwaBike = 0.135;
		//var Cwa_rider = (1 + cadence * cCad) * Cwa_rider_const;
		var cwaRider = cwaRiderConst + cadence * cwaRiderConstCCad;
		
		//var Frg = g * (m_bike + weight) * (Cr * Math.cos(theta) + Math.sin(theta));
		var frg = gM * (cr * cosTheta + sinTheta);
		
		//var rho = rho0 * 273 / (273 + T) * Math.pow(e, -1 * rho0 * g * H / P0);
		var halfRho = 176.3853 / (273 + temperature) * Math.pow(0.9998749433925956, altitude);
		
		// power transmission losses coefficient
		// 1/(1 - effectiveness) => effectiveness = 97.56%
		var cm = 1.025;
		
		// Velocity-dependent dynamic rolling resistance coefficient
		var crV = 0.1;
		// bicycle + wind speed
		var w = 0;
		var vw = speed + w;
		// Dynamic rolling resistance coefficient
		var crVn = crV * cosTheta;
	
		var p = cm * speed * (halfRho * (cwaRider + cwaBike) * vw * vw + frg + speed * crVn);
		if (p < 0.0) {
			p = 0.0;
		}
		return p;
	}
}