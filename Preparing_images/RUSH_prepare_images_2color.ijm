//Preparing 2-color RUSH movies. The first channel should be the nuclei.
//Usage: Open the original file. Run the macro.
//First, select the movies before and after injection.
//Second, save your movie and name it. Press "OK" afterwards.
//Third, align your movie using the "Template matching" plugin in the nuclei channel.
//Fourth, check the alignment, then click "Yes" if you are happy with it.
//Lastly, save the "_algn.tif" movie (aligned version) and the "_algn_crop.tif" movie (aligned and cropped version).

//Concatenate Preinject and Postinject movies
run("Concatenate...");
waitForUser("Name and save the image, then press OK in this dialog.");
imagename_with_tif = getInfo("image.filename");
string_tif = lengthOf(imagename_with_tif) - 4;
imagename = substring(imagename_with_tif, 0, string_tif); //Gets the position of the ".tif" ending and deletes it from the string

//Make z-projection, seperate channels
selectWindow(imagename + ".tif");
run("Z Project...", "projection=[Max Intensity] all");
run("Split Channels");
selectWindow("C1-MAX_" + imagename_with_tif);
close();

//Prealign using the nuclei channel and save image; Use a loop to try more often if needed
yes = 0;
while(yes != 1){
	run("Clear Results");
	run("Duplicate...", "title=Duplicate duplicate");
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
selectWindow("C2-MAX_" + imagename_with_tif);
close();

//Align the full movie
selectWindow(imagename_with_tif);
run("Duplicate...", "title=NewStack.tif duplicate");
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
rename(imagename + "_algn.tif");

//Delete all black pixels that occur after drift correction

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
imagename_cropped = imagename + "_algn_crop.tif";
run("Duplicate...", "title=&imagename_cropped duplicate");