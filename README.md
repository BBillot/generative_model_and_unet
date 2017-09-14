# generative_model_and_unet

This repository contains the codes of a generative model of surrogate images and also the code of a
Convolutional Neural Network segmenting images.

MODEL:
    the main script is ImageProducer.m and all the functions it uses are stored in the getPatch.m file
    to run Imageproducer you have to create a json file with the parameters_struct_creation.m
    one example of json file is also provided (parameters_64x64_images.json)

CNN FOR SEGMENTATION:
    the main script is unets.py
    it uses the functions stored in func.py
    resume_seg.py is provided in order to resume a paused training (very useful for pre-training a network)
    the last file testing-seg.y allows to only perform testing of an existing network.
    
