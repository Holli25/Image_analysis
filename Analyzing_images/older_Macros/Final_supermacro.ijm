//Macro for measuring the fluorescent intensity at TCJs in an image. Uses a threshold of 2 and takes the mean of all values above that. Selects the brightest slice in a z-stack.
//Input: A folder that has multiple stacks with only one protein labeled.
//Output: A table with the image name, the selected slice and the intensity value.
//Usage: Run the macro. Select the folder you want to analyze. After analyzation, save the results as a ".csv" file.

//Open the files
folder = getDirectory("Open a file");
files = getFileList(folder);
file_amount = lengthOf(files);

//Let the user define the lower threshold boundary and save the value
Dialog.create("Define lower threshold boundary")
Dialog.addNumber("Please define the lower threshold boundary", 2);
Dialog.show();
lower_threshold = Dialog.getNumber();

//Get a list of all images open and iterate over the list
setBatchMode(true);
image_name_array = newArray;
image_results_array = newArray;
slice_results_array = newArray;
setOption("ExpandableArrays", true);

for(image=0; image<file_amount; image++){
	open(files[image]);
	name = getTitle;

//Duplicate the image, then select pixels with value bigger than 2 and make a mask
	run("Duplicate...", "title=Duplicate duplicate");
	selectWindow("Duplicate");
	setThreshold(lower_threshold,255);

//Go over every slice in the stack and measure the mean intensity of the selected pixels
	for(slice=1; slice<=nSlices; slice++){
		setSlice(slice);
		run("Create Selection");
		run("Measure");
	}
	selectWindow("Duplicate");
	run("Close");
//Get the slice with the highest mean intensity and save the value
	result = 0;
	
	for(slice=0; slice<nResults; slice++){
		if(getResult("Mean", slice) >= result){
			result = getResult("Mean", slice);
			evaluated_slice = slice;
		}
	}
	image_name_array[image] = name;
	image_results_array[image] = result;
	slice_results_array[image] = evaluated_slice + 1;
	run("Clear Results");
	selectWindow(name);
	run("Close");
	print("Success with image " + image);
}

for(result = 0; result<image_name_array.length; result++){
	setResult("Image", result, image_name_array[result]);
	setResult("Fluorescence", result, image_results_array[result]);
	setResult("Slice", result, slice_results_array[result]);
	setResult("Lower_threshold", result, lower_threshold);
}
setBatchMode(false);

