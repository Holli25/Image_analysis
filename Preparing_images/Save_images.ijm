//Macro for saving all open images in a specified folder
//Usage: Open ".lif" file. Run the macro and select the folder you want to save the images in. The folder should have a folder called "Images" already.

images = getList("image.titles");
folder = getDirectory("Open a file") + "Images/";
image_amount = nImages;
for(image=0; image<image_amount; image++){
	selectWindow(images[image]);
	saveAs("Tiff", folder + images[image] + ".tif");
	close();
}