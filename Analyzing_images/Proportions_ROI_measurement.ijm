//Test macro to evaluate brightness of different TCJ proteins at TCJs to determine proportions. This version uses automatically drawn circles around the TCJs.
//Usage: Run the macro on the image you want to analyze.

for(slice=1; slice<=nSlices; slice++){
	setSlice(slice);
	run("Duplicate...", "title=Duplicate");
	setThreshold(4, 255);
	run("Make Binary", "thresholded remaining");
	run("Convert to Mask");
	run("Options...", "iterations=3 count=4 black do=Erode");
	run("Analyze Particles...", "size=0.1-Infinity display");
	for(result=0; result<nResults; result++){
		x = getResult("X", result) * 640/48.49;
		y = getResult("Y", result) * 640/48.49;
		makeOval(x-5, y-5, 10, 10);
		roiManager("add");
	}
	close("Duplicate");
	run("Clear Results");
	roiManager("deselect");
	roiManager("measure");
	saveAs("Results", "/Users/Holli/Desktop/Test/"+slice+".csv");
	run("Clear Results");
	roiManager("delete");
}

