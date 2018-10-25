//Aligning movie with multiple channels using the "Template matching" plugin
//Usage: Duplicate the channel that is best/easiest to align. On a maximum projection, align the duplicate version with the "Template matching" plugin. (Do not use "subpixel alignment" if you want to quantify later"!)
//Keep the Results table!!! (it has the amount of displacement you will use for all channels.
//Select the movie you want to align and run the script. If you want the movie cropped so only pixels that are never black, select "Yes" in the options.
//The amount of z-slices, channels or timeframes does not matter. The new stack called "AlignedMovie.tif" should be correct.


//Create dialog for optional last step (cropping the movie to only keep never black pixels - information that never moved out of the movie).
Dialog.create("Options");
Dialog.addChoice("Autocrop movie", newArray("Yes", "No"), "Yes");
Dialog.show();
choice = Dialog.getChoice();


run("Duplicate...", "title=AlignedMovie.tif duplicate");
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

//Autocrop, only done if "Yes" was selected in Options. Deletes all black pixels that occur after drift correction.
if (choice == "Yes") {
	//Initiate values for movement in x and y
	xl = 0; 
	xr = 0;
	yu = 0;
	yd = 0;
	
	//loop over the results and save the minimum and maximum x and y
	for(i=0; i<nResults; i++){ 
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
	run("Duplicate...", "title=CroppedAlignedMovie.tif duplicate");
}