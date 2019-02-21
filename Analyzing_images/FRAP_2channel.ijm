//Macro to analyze FRAP movies in the Drosophila epidermis using 1 channel. (Data comes from SP8 using the Live Data Mode)
//Usage: Open Prebleach and Postbleach series for 1 embryo from the ".lif" file. Then the Macro will guide the user through the process. The image is named, the correct slices are taken for an average projection.
//Then, the user aligns the movie, selects the ROIs to be analyzed.
//Prerequisites: The following plugins have to be installed: TemplateMatching, TimeSeriesAnalyzer V3
//Input: Two 3D images in x,y,t with the series before and the series after bleaching.
//Output: A folder with the original combined image, the average projection, the registered and cropped movie, all ROIs as a ".zip" file and the Histograms for each timepoint (in a seperate folder).



//Create a folder specified by the user to save all the data in
savepath_images = getDirectory("Choose a directory for saving your images");
savepath_histograms = savepath_images + "Histograms/";
if (File.isDirectory(savepath_histograms) == 0){
	File.makeDirectory(savepath_histograms);
}

//Search in open images for the prelbeach and postbleach movies, they have a Pre and Post in their name
list = getList("image.titles");
for(image = 0; image < list.length; image++){
	if(matches(list[image], ".*Pre.*")){
		selectWindow(list[image]);
		rename("prebleach");
		print(list[image]+" was renamed to prebleach");
	}
	else if(matches(list[image], ".*Post.*")){
		selectWindow(list[image]);
		rename("postbleach");
		print(list[image]+" was renamed to postbleach");
	}
}

//Get data about images for combining them later
selectWindow("prebleach");
getDimensions(prewidth, preheight, prechannels, preslices, preframes);
selectWindow("postbleach");
getDimensions(postwidth, postheight, postchannels, postslices, postframes);

//Ask user for the filename of the final concentated image and calculate the slices and frames for the Hyperstack; save the combined image afterwards
filename = getString("Please enter the Filename", "File");
zslices = preslices;
tframes = preframes + postframes;
run("Concatenate...", "  title=&filename image1=[prebleach] image2=[postbleach] image3=[-- None --]");
run("Stack to Hyperstack...", "order=xyczt(default) channels=2 slices=&zslices frames=&tframes display=Color");
saveAs("tiff", savepath_images+filename+".tif");

//Prepare image for analysis e.g. make average projection if needed, align image, draw ROIs...
//Make average projection of important slices and save the projection
waitForUser("Waiting...", "Please look through the stack and find the z-planes you want to use for the projection");
start = getNumber("Please state your starting z-slice for the average projection", 0);
end = getNumber("Please state your end frame z-slice for the average projection", 0);
run("Z Project...", "start=&start stop=&end projection=[Average Intensity] all");
avg_filename = filename + "_avg_" + start + "_" + end;
rename(avg_filename);
saveAs("tiff", savepath_images + avg_filename + ".tif");
selectWindow(filename+".tif");
close();

//Test image registration until the user is happy
channel = getNumber("Please specify, which channel you want to test the registration on.", 1);
yes = 0;
while(yes != 1){
	run("Clear Results");
	run("Duplicate...", "title=Duplicate duplicate channels=&channel");
	run("Brightness/Contrast...");
	setTool("rectangle");
	selectWindow("Duplicate");
	waitForUser("Please use Template matching to align the movie. Click OK afterwards.");

	//Create Dialog
	Dialog.create("Hello World");
	Dialog.addMessage("Are you satisfied with this alignment?");
	Dialog.addCheckboxGroup(1, 2, newArray("Yes!", "No, try again."), newArray(false, false));
	Dialog.show()
	yes = Dialog.getCheckbox();
	no = Dialog.getCheckbox();

	selectWindow("Duplicate");
	close();
}

//Register the full movie with the tested values
//Works by reading the Results table (that has all values of the test registration) for every timepoint and translating the orinial image using these coordinates
selectWindow(avg_filename + ".tif");
getDimensions(width, height, channels, slices, frames);
j = 0;
for (frame=2; frame<=frames; frame++) {
	for (slice=1; slice<=slices; slice++){
		for (channel=1; channel<=channels; channel++){
			i = ((frame-1)*(slices*channels))+((slice-1)*channels)+channel;
			setSlice(i);
			xdeplace = getResult("dX",j);
			ydeplace = getResult("dY",j);
 			run("Translate...", "x=xdeplace y=ydeplace interpolation=None slice");			
		};
	};
	j++;	
}

//Delete all black pixels that occur after drift correction and save the result
//Initiate values for movement in x and y
xl = 0;
xr = 0;
yu = 0;
yd = 0;
for(i=0; i<nResults; i++){ //loop over the results and save the minimum and maximum x and y
	x = getResult("dX", i);
	y = getResult("dY", i);
	if(x>=0){
		if(x > xr){
			xr = x;
		}
	}
	if(x<0){
		if(x < xl){
			xl = x;
		}
	}
	if(y>=0){
		if(y > yd){
			yd = y;
		}
	}
	if(y<0){
		if(y < yu){
			yu = y;
		}
	}
}
getDimensions(w, h, c, s, f);
makeRectangle(xr, yd, (w - xr + xl), (h - yd + yu)); //make the rectangle as big as possible without having black pixels
imagename_cropped = avg_filename + "_algn_crop.tif";
run("Duplicate...", "title=&imagename_cropped duplicate");
saveAs("tiff", savepath_images + imagename_cropped + ".tif");
selectWindow(avg_filename + ".tif");
close();

//Analysis of the movie
//Get the histograms for every z-slice and save it in a new folder for R analysis
selectWindow(imagename_cropped + ".tif");
getDimensions(width, height, channels, slices, frames);
first_channel_name = getString("Please name the protein in the first channel", "Gli");
second_channel_name = getString("Please name the protein in the first channel", "Dlg");
for(current_channel = 1; current_channel <= channels; current_channel++){
	for(j=1; j<=frames; j++){
		Stack.setPosition(current_channel, 1, frames); //need to use 1 as slice as the method expects 3 arguments
		bitdepth = bitDepth();
		nBins = pow(2, bitdepth);
		run("Clear Results");
		row = 0;
		getHistogram(values, counts, nBins);
		for (i=0; i<nBins; i++) {
		    setResult("Value", row, values[i]);
		    setResult("Count", row, counts[i]);
		    row++;
		}
		updateResults();
		//Save the histograms; did not find a method to link iteration to channel name, used if/else instead
		if (current_channel == 1){
			saveAs("Results", savepath_histograms + first_channel_name + j + ".csv");
		}
		else if (current_channel == 2){
			saveAs("Results", savepath_histograms + second_channel_name + j + ".csv");
		}
		else{
			print("The Histrogram saving did not work, as the current_channel variable is out of the range of channels");
		}
	}
}
run("Clear Results");
selectWindow("Results");
run("Close");

//Make the evaluation of ROIs over time using the TimeSeriesAnalyzer V3 plugin and save the results
run("Rainbow RGB");
Stack.setFrame(1);
roiManager("reset");
setTool("polygon");
waitForUser("ROI drawing for measuring recovery", "Please draw ROIs around the TCJs you want to measure the recovery of and add them to the ROIManager by pressing 't'. When you are finished, press 'OK'!");
numberrois_TCJ = roiManager("count");
for(i=0; i<numberrois_TCJ; i++){
	j = i+1;
	roiManager("select", i);
	roiManager("rename", "TCJ"+j);
}
waitForUser("ROI drawing for measuring recovery", "Please draw ROIs around the BCJs you want to measure the recovery of and add them to the ROIManager by pressing 't'. When you are finished, press 'OK'!");
numberrois_BCJ = roiManager("count");
for(i=numberrois_TCJ; i<numberrois_BCJ; i++){
	j = i - numberrois_TCJ +1;
	roiManager("select", i);
	roiManager("rename", "BCJ" + j);
}
roiManager("deselect");
run("Grays");
roiManager("save", savepath_images+"ROIs.zip");
run("Split Channels");
selectWindow("C1-" + imagename_cropped + ".tif");
waitForUser("Measuring recovery", "Measure the recovery of the selected ROIs of the " + first_channel_name + " channel by using the TimeSeriesAnalyzer V3, use the 'Get Average' function. When you are finished, press 'OK'!");
IJ.renameResults("Time Trace(s)", "Results");
saveAs("Results", savepath_histograms + "Results_" + first_channel_name + ".csv");
selectWindow("Results");
run("Close");
selectWindow("C2-" + imagename_cropped + ".tif");
waitForUser("Measuring recovery", "Measure the recovery of the selected ROIs of the " + second_channel_name + " channel by using the TimeSeriesAnalyzer V3, use the 'Get Average' function. When you are finished, press 'OK'!");
IJ.renameResults("Time Trace(s)", "Results");
saveAs("Results", savepath_histograms + "Results_" + second_channel_name + ".csv");


//Clean up the Screen and prompt success message
selectWindow("C1-" + imagename_cropped + ".tif");
close();
selectWindow("C2-" + imagename_cropped + ".tif");
close();
selectWindow("ROI Manager");
run("Close");
selectWindow("Time Trace Average");
run("Close");
selectWindow("Log");
run("Close");
selectWindow("Time Series V3_0");
run("Close");
selectWindow("Results");
run("Close");
setTool("rectangle");
showMessage("Congratulations, you can now analyze the data!");