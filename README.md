# estimated_power
Cycling Estimated Power for Garmin 920xt

It is based on http://www.kreuzotter.de/english/espeed.htm

Another similar site is http://www.gribble.org/cycling/power_v_speed.html

Disclaimer: 
The code is ugly, as mathematical operations are simplified by hand (the compiler is just a translator).
There are no tests, see http://stackoverflow.com/questions/32699445/how-to-unit-test-connect-iq
Space usage may be considered high, this is because I need to keep track of the last 5 elevations to smooth the slope.

Contributions and ideas are more than welcome.
