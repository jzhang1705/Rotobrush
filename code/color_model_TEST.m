
img = imread("./test_images/1.jpg");
mask = roipoly(img);
WindowWidth = 50;
NumWindows = 3;
BoundaryWidth = 0;

[mask_outline, LocalWindows] = initLocalWindows(img,mask,NumWindows,WindowWidth,true);

ColorModels = ...
      initColorModels(img,mask,mask_outline,LocalWindows,BoundaryWidth,WindowWidth);