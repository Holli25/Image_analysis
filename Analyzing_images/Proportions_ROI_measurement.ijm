//Macro to evaluate amount of different TCJ proteins at TCJs to determine proportions using fluorescent tagged lines. This version uses automatically drawn circles around the Maxima that are detected at TCJs.
//Usage: Open 3 images of the folder in which you want to run the macro and select the best noise settings for the "Find Maxima" function. Then run the macro and select the folder in the Dialog.
//Input: Nothing, folder will be selected during the macro. The folder should contain single tif files that are 3-dimensional stacks (x, y, z).
//Output: A csv file containing all ROIs measured over the whole image. The columns are "X", "Label", "Area", "Mean".

//Open the files
folder = getDirectory("Open a file");
files = getFileList(folder + "Images/");
file_amount = lengthOf(files);

//Let the user define the noise settings for the Find Maxima function and save the value
Dialog.create("Define noise setting for Find Maxima method.")
Dialog.addNumber("Please define the noise setting ", 10);
Dialog.show();
noise = Dialog.getNumber();

//Prepare folder structure
if (File.isDirectory(folder + "Rois/") == 0){
	File.makeDirectory(folder + "Rois/");
}
if (File.isDirectory(folder + "Results/") == 0){
	File.makeDirectory(folder + "Results/");
}

//Go over all images in the folder, find maxima in every z-slice and draw a ROI with radius 4px around it. Measure all ROIs in the image, save the ROIs and save the Results.
setBatchMode(true);

for(image=0; image<file_amount; image++){
	open("Images/" + files[image]);
	imagename = getTitle;
	
	for (slice=1; slice<=nSlices; slice++){
		setSlice(slice);
		run("Find Maxima...", "noise=&noise output=List exclude");
		for(result=0; result<nResults; result++){
			x = getResult("X", result);
			y = getResult("Y", result);
			makeOval(x-4, y-4, 8, 8);
			roiManager("add");
		}
		run("Clear Results");
		run("Select None");
	}
	roiManager("deselect");
	roiManager("save", folder + "Rois/" + imagename + "_rois.zip");
	roiManager("measure");
	roiManager("delete");
	saveAs("Results", folder + "Results/" + imagename + "_results.csv");
	run("Clear Results");
	close(imagename);
	print("Finished with image " + imagename);
}

setBatchMode(false);