//Create a folder specified by the user to save all the data in and get image data
savepath_images = getDirectory("Choose a directory for saving your images");
run("Duplicate...", "title=Workimage duplicate");
getDimensions(width, height, channels, slices, frames);

//Let user draw ROI for which the Kymograph should be made
setTool("rectangle");
waitForUser("Please draw a rectangular ROI around the junction for which you want to generate a Kymograph");

//Duplicate the same ROI for each frame and make a montage of it
setBatchMode(true);
selectWindow("Workimage");
if(channels > 1){
	for(channel=1; channel<=channels; channel++){
		for(frame=1; frame<=frames; frame++){
			selectWindow("Workimage");
			thistitle = "c" + channel + "_f" + frame;
			run("Duplicate...", "duplicate channels=&channel frames=&frame title=&thistitle");
		}
	}
}

else if(channels == 1){
	for(frame=1; frame<=frames; frame++){
		selectWindow("Workimage");
		setSlice(frame);
		thistitle = "c" + 1 + "_f" + frame;
		run("Duplicate...", "title=&thistitle");
	}
}
for(channel=1; channel<=channels; channel++){
	for(frame=1; frame<=frames; frame++){
		if(frame == 1){
			firstframe = "c" + channel + "_f1";
			secondframe = "c" + channel + "_f2";
			run("Combine...", "stack1=&firstframe stack2=&secondframe");
		}
		else if(frame == 2){
			//do nothing here
		}
		else {
			nextframe =  "c" + channel + "_f" + frame;
			run("Combine...", "stack1=[Combined Stacks] stack2=&nextframe");
		}
	}
	selectWindow("Combined Stacks");
	rename("Channel" + channel);
	saveAs("tiff", savepath_images + "Channel" + channel);
	close();
}
selectWindow("Workimage");
close();
setBatchMode(false);
waitForUser("The making of the kymograph was successful and can be found in your specified folder");
open(savepath_images + "Channel" + channel-1 + ".tif");