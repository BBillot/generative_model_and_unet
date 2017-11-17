# generative_model_and_unet



Abstract

This project attempts to perform axon segmentation of cortical images by using a Convolutional Neural Network. These networks have to be trained with several thousands of images. However in the case of brain images, such a dataset would be very difficult to obtain. That is why, in order to limit overfitting due to the lack of data, we propose a generative model of surrogate images that would be used as a complementary tool to data augmentation. The potential benefits of this model are assessed by evaluating the segmentation maps obtained on real data after having pre-trained an Autoencoder with generated images. This repository contains the Matlab code of the generative model and also the Pyhton code of the Convolutional Neural Network. 



MODEL:

-By running ImageProducer.m one would produce 4 3D-matrices. The first one contains 2D independent images, the second provides their corresponding binary segmentation, the 3rd one returns the same images cleaned from all sources of noise, and the 4th one gives back the bouton segmentation.

-SeriesProducer.m uses the same algorithm than ImageProducer.m to produce time-serie images where slight variations can be observed between images (apparition/disapearance of synaptic boutons, background noise, shiftings/rotations)

-To run Imageproducer or SeriesProducer you have to create a json file with the parameters_struct_creation.m script. 

one example of json file is also provided (parameters_64x64_images.json)



CNN FOR SEGMENTATION:

the main script is unets.py

it uses the functions stored in func.py

resume_seg.py is provided in order to resume a paused training (very useful for pre-training a network)

the last file testing-seg.y allows to only perform testing of an existing network.
    
