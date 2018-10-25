//Macro for measuring the fluorescent intensity at TCJs in an image. Uses a threshold of 2 and takes the mean of all values above that. Selects the brightest slice in a z-stack.
//Input: A folder that has multiple stacks with only one protein labeled.
//Output: A table with the image name, the selected slice and the intensity value.
//Usage: Run the macro. Select the folder you want to analyze. After analyzation, save the results as a ".csv" file.

//Open the files
folder = getDirectory("Open a file");
files = getFileList(folder);
file_amount = lengthOf(files);

//Get a list of all images open and iterate over the list
setBatchMode(true);
for(image=0; image<file_amount; image++){
	open(files[image]);
	name = getTitle;

//Duplicate the image, then select pixels with value bigger than 2 and make a mask
	run("Duplicate...", "title=Duplicate duplicate");
	selectWindow("Duplicate");
	setThreshold(2,255);
	run("Convert to Mask", "method=Default background=Light calculate");

//Go over every slice in the stack and measure the mean intensity of the selected pixels
	for(slice=1; slice<=nSlices; slice++){
		setSlice(slice);
		run("Create Selection");
		run("Make Inverse");
		roiManager("Add");
		selectWindow(name);
		setSlice(slice);
		roiManager("Select", 0);
		run("Measure");
		roiManager("Deselect");
		roiManager("Delete");
		selectWindow("Duplicate");
	}
	run("Close");
//Get the slice with the highest mean intensity and save the value
	result = 0;
	
	for(slice=0; slice<nResults; slice++){
		if(getResult("Mean", slice) >= result){
			result = getResult("Mean", slice);
			evaluated_slice = slice;
		}
	}
	List.set(image, result);
	image_slice = image + 0.5;
	List.set(image_slice, (evaluated_slice + 1));
	run("Clear Results");
	selectWindow(name);
	run("Close");
	print("Success with image " + image);
}
setBatchMode(false);
for(datapoint=0; datapoint<List.size/2; datapoint+=0.5){
	if((datapoint/0.5)%2 != 0){
		setResult("Evaluated Slice", datapoint-0.5, List.get(datapoint));
	}
	else if((datapoint/0.5)%2 == 0){
		output = files[datapoint];
		setResult("Image", datapoint, output);
		setResult("Fluorescence", datapoint, List.get(datapoint));
	}
}