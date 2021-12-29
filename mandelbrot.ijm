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

var HIGH_RES_FACTOR = 10;
var LUT = getLUT(24);			// Random in my case

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

function getLUT(nr) {
	luts = getList("LUTs");
	return luts[nr];
}

function highRes() {
	oldWidth = iWidth;
	iWidth = iWidth * HIGH_RES_FACTOR;
	oldHeight = iHeight;
	iHeight = iHeight * HIGH_RES_FACTOR;
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
