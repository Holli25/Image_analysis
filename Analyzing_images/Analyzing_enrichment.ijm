//Macro to analyze the enrichment of a protein in live or stainings at TCJs compared to BCJs. Substracts the background, then takes the ratio of TCJ to BCJ intensity.
//Usage: Run the macro. You have to choose a folder that has an Images folder with your images in it as tif files. You have to check which slices to take for the average projection. Afterwards, you draw the ROIs for TCJs (add by pressing t), afterwards BCJs and background.
//Input: Nothing, you specify everything during the script.
//Output: A csv file containing the measured TCJ, BCJ and background intensities per image as well as the drawn ROIs as zip files. The columns in the csv are "X", "Label", "Area", "Mean". (depending on your FIJI settings in Analyze -> Set measurements)

//Get the working folder and prepare folder structure
folder = getDirectory("Open a file");
if (File.isDirectory(folder + "Images/") == 0){
	print("The folder 'Images' does not exist, please choose a different folder for analysis."); 
}
files = getFileList(folder + "Images/");
file_amount = lengthOf(files);
if (File.isDirectory(folder + "Output/") == 0){
	File.makeDirectory(folder + "Output/");
}
savepath = folder + "Output/";

//Iterate over all images in the folder
for (image = 0; image < file_amount; image ++){
	open("Images/" + files[image]);
	imagename = getTitle;
		
	//Make Average projection
	waitForUser("Waiting...", "Please look through the stack and find the z-planes you want to use for the projection");
	start = getNumber("Please state your starting z-slice for the average projection", 0);
	end = getNumber("Please state your end frame z-slice for the average projection", 0);
	run("Z Project...", "start=&start stop=&end projection=[Average Intensity] all");
	avg_Filename = imagename +"_avg_" + start + "_" + end;
	rename(avg_Filename);
	saveAs("tiff", savepath + avg_Filename + ".tif");
	selectWindow(imagename);
	close();
	
	//Let User draw ROIs for TCJs, BCJs and background.
	makeOval(50, 50, 20, 20);
	waitForUser("Please mark the TCJ ROIs by pressing t");
	TCJs = roiManager("count");
	waitForUser("Please mark the BCJ ROIs by pressing t");
	BCJs = roiManager("count");
	waitForUser("Please mark the background ROIs by pressing t");
	background = roiManager("count");
	
	for (roi = 0; roi < background; roi++){
		roiManager("select", roi);
		if(0<=roi && roi<TCJs){
			roiManager("rename", "TCJ");
		}
		else if(TCJs<=roi && roi<BCJs){
			roiManager("rename", "BCJ");
		}
		else if(BCJs<=roi && roi<=background){
			roiManager("rename", "background");
		}
	}
	roiManager("deselect");
	roiManager("Remove Channel Info");
	roiManager("Remove Slice Info");
	roiManager("save", savepath + imagename + "_ROIs.zip");
	
	//Measure and save data
	getDimensions(width, height, channels, slices, frames);
	for(channel = 1; channel <= channels; channel++){
		Stack.setChannel(channel);
		roiManager("measure");		
	}
	selectWindow("Results");
	saveAs("results", savepath + imagename + "_results.csv");
	
	//Clean up for next run
	run("Clear Results");
	roiManager("delete");
	selectWindow(avg_Filename + ".tif");
	close();
	print("Image was successfully analyzed!");
}
