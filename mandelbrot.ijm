var maxIterations = 500;
var iWidth = 256;
var iHeight = 256;

var xMin = -2;
var xMax = 0.47;
var yMin = -1.12;
var yMax = 1.12;

var xStart = xMin;
var xEnd = xMax;
var yStart = yMin;
var yEnd = yMax;

var HIGH_RES_WIDTH = 2560;
var HIGH_RES_HEIGHT = 2560;
var LUT = getLUT(24);			// Random in my case

var JULIA_EXPONENT = 2;
var JULIA_N_R = 2;

run("Set Measurements...", "area mean standard modal min centroid center integrated display redirect=None decimal=9");

macro "mandelbrot Action Tool - C000T4b12m" {
	mandelbrot(-2, 0.47, -1.12, 1.12);
}

macro "zoom Action Tool - C000T4b12z" {
	zoom();
}

macro "high resolution image Action Tool - C000T4b12h" {
	highRes();
}

macro "julia Tool - C000T4b12j" {
	getCursorLoc(x, y, z, modifiers);
	toScaled(x, y);
	if (JULIA_EXPONENT==2) julia(x, y);
	else juliaN(x,y);
}

macro "mandelbrot Action Tool Options" {
	Dialog.create("Mandelbrot Options");
	Dialog.addNumber("max. iterations", maxIterations);
	Dialog.addNumber("image width", iWidth);
	Dialog.addNumber("image height", iHeight);
	Dialog.show();
	maxIterations = Dialog.getNumber();
	iWidth = Dialog.getNumber();
	iHeight = Dialog.getNumber();
}

macro "high resolution image Action Tool Options" {
	Dialog.create("High resolution image options");
	Dialog.addNumber("image width: ", HIGH_RES_WIDTH);
	Dialog.addNumber("image height: ", HIGH_RES_HEIGHT);
	Dialog.show();
	HIGH_RES_WIDTH = Dialog.getNumber();
	HIGH_RES_HEIGHT = Dialog.getNumber();
}

macro "julia Tool Options" {
	Dialog.create("Julia Options");
	Dialog.addNumber("exponent (n): ", JULIA_EXPONENT);
	Dialog.addNumber("escape radius (R): ", JULIA_N_R);
	Dialog.show();
	JULIA_EXPONENT = Dialog.getNumber();
	JULIA_N_R = Dialog.getNumber();	
}

function getLUT(nr) {
	luts = getList("LUTs");
	return luts[nr];
}

function highRes() {
	title = getTitle();
	if (indexOf(title, "mandel")>-1) {
		highResMandel();
	} else {
		highResJulia();
	}
}

function highResJulia() {
	oldWidth = iWidth;
	iWidth = HIGH_RES_WIDTH;
	oldHeight = iHeight;
	iHeight = HIGH_RES_HEIGHT;
	info = getMetadata("Info");
	parts = split(info, ",");
	part1 = split(parts[0], "=");
	part2 = split(parts[1], "=");
	cx = parseFloat(part1[1]);
	cy = parseFloat(part2[1]);
	if (JULIA_EXPONENT==2) julia(cx, cy);
	else juliaN(cx, cy);
	iWidth = oldWidth;
	iHeight = oldHeight;
}

function highResMandel() {
	oldWidth = iWidth;
	iWidth = HIGH_RES_WIDTH;
	oldHeight = iHeight;
	iHeight = HIGH_RES_HEIGHT;
	run("Select All");
	getSelectionBounds(x, y, width, height);
	run("Select None");
	xS = x;
	yS = y;
	toScaled(xS, yS);
	x2 = x + width;
	y2 = y + width;
	toScaled(x2, y2);
	mandelbrot(xS, x2, yS, y2); 
	iWidth = oldWidth;
	iHeight = oldHeight;	
}

function zoom() {
	getSelectionBounds(x, y, width, height);
	xS = x;
	yS = y;
	toScaled(xS, yS);
	x2 = x + width;
	y2 = y + width;
	toScaled(x2, y2);
	mandelbrot(xS, x2, yS, y2); 	
}

function randomRegion() {
	rand1 = random;
	rand2 = random;
	xStart = rand1 * (xMax-xMin) + xMin;
	xEnd = rand2 * (xMax-xStart) + xStart;
	yStart = rand1 * (yMax-yMin) + yMin;
	yEnd = rand2 * (yMax-yStart) + yStart;
}

function mandelbrot(xStart, xEnd, yStart, yEnd) {
	deltaX = xEnd - xStart;
	deltaY = yEnd - yStart;
	ixMax = iWidth-1;
	iyMax = iHeight-1;
	print(xStart, xEnd, yStart, yEnd);
	newImage("mandelbrot", "16-bit black", iWidth, iHeight, 1);
	run("Coordinates...", "left="+xStart+" right="+xEnd+" top="+yStart+" bottom="+yEnd);
	setBatchMode("hide");
	xFactor = deltaX / ixMax;
	yFactor = deltaY / iyMax;
	for (x = 0; x < iWidth; x++) {
		showProgress(x, iWidth-1);
		x0 = x * xFactor + xStart;
		for (y = 0; y < iHeight; y++) {
			y0 = y * yFactor + yStart;
			c = iterations(x0, y0, maxIterations);
			if (c<maxIterations) setPixel(x, y, c);
		}	
	}
	run(LUT);
	run("Enhance Contrast", "saturated=0.35");
	setBatchMode("show");
}

function iterations(x0, y0, max) {
	x2 = 0;
	y2 = 0;
	w = 0;
	iteration = 0;
	while (x2 + y2 <= 4 && iteration < max) {
	    x = x2 - y2 + x0;
	    y = w - x2 - y2 + y0;
	    x2 = x * x;
	    y2 = y * y;
	    w = (x + y) * (x + y);
	    iteration++;
	}
	return iteration;
}

function julia(cx, cy) {
	R = (sqrt(4*sqrt(cx*cx+cy*cy) + 1) + 1) / 2;
	RR = R*R;
	rangeStart = -1*R;
	rangeEnd = R;
	delta = rangeEnd - rangeStart;
	ixMax = iWidth-1;
	iyMax = iHeight-1;	
	xFactor = delta / ixMax;
	yFactor = delta / iyMax;
	print(cx, cy);
	newImage("julia", "16-bit black", iWidth, iHeight, 1);
	setMetadata("Info", "cx="+cx+", cy="+cy);
	setBatchMode("hide");
	for (x = 0; x < iWidth; x++) {
		showProgress(x, iWidth-1);
		x0 = x * xFactor + rangeStart;
		for (y = 0; y < iHeight; y++) {
			y0 = y * yFactor + rangeStart;
			c = juliaIterations(x0, y0, cx, cy, RR);
			setPixel(x, y, c);
		}
	}
	run(LUT);
	run("Enhance Contrast", "saturated=0.35");
	setBatchMode("show");
}

function juliaN(cx, cy) {
	RR = JULIA_N_R*JULIA_N_R;
	rangeStart = -1*JULIA_N_R;
	rangeEnd = JULIA_N_R;
	delta = rangeEnd - rangeStart;
	ixMax = iWidth-1;
	iyMax = iHeight-1;	
	xFactor = delta / ixMax;
	yFactor = delta / iyMax;
	print(cx, cy);
	newImage("julia", "16-bit black", iWidth, iHeight, 1);
	setMetadata("Info", "cx="+cx+", cy="+cy);
	setBatchMode("hide");
	for (x = 0; x < iWidth; x++) {
		showProgress(x, iWidth-1);
		x0 = x * xFactor + rangeStart;
		for (y = 0; y < iHeight; y++) {
			y0 = y * yFactor + rangeStart;
			c = juliaNIterations(x0, y0, cx, cy, RR);
			setPixel(x, y, c);
		}
	}
	run(LUT);
	run("Enhance Contrast", "saturated=0.35");
	setBatchMode("show");
}

function juliaIterations(x, y, cx, cy, RR) {
	zx = x;
	zy = y;
	iteration = 0;
	 while (zx * zx + zy * zy < RR  &&  iteration < maxIterations) 
    {
        xtemp = zx * zx - zy * zy;
        zy = 2 * zx * zy  + cy; 
        zx = xtemp + cx;   
        iteration++;
    }
    if (iteration == maxIterations)
        return 0;
    else
        return iteration;
}

function juliaNIterations(x, y, cx, cy, RR) {
	zx = x;
	zy = y;
	iteration = 0;
	 while (zx * zx + zy * zy < RR  &&  iteration < maxIterations) 
    {
        xtmp = pow((zx * zx + zy * zy), (JULIA_EXPONENT / 2)) * cos(JULIA_EXPONENT * atan2(zy, zx)) + cx;
	    zy = pow((zx * zx + zy * zy),   (JULIA_EXPONENT / 2)) * sin(JULIA_EXPONENT * atan2(zy, zx)) + cy;
	    zx = xtmp;
	    iteration++;
    }
    if (iteration == maxIterations)
        return 0;
    else
        return iteration;
}