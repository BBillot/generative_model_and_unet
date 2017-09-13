#### U-Net for reconstruction ####


import h5py
import io
import os
import pickle
import scipy.io
import numpy as np
import theano
import matplotlib
matplotlib.use('Agg')
from skimage.io import imsave
from keras.layers import Input, Conv2D, MaxPooling2D, UpSampling2D, Dropout
from keras.layers import Conv2DTranspose, concatenate
from keras.models import Model
from keras.optimizers import Adam
from keras.callbacks import ModelCheckpoint
from keras import backend as K
from func import *


#parameters
path_weights = '/data/users/bpb216/results/7_09/nano_seg_lr_5.h5' #path where weightsfrom previous training were saved
path_to_history = '/data/users/bpb216/results/7_09'     # path where the history of the network will be saved
path_files_test = '/data/users/bpb216/dataset/hard_512' # path of the test dataset
result_directory= '/data/users/bpb216/results/7_09'     # path of the result directory (it will be created if it doesn't exist)
saved_model = 'nano_seg'                                # name of the file that will contain the weights

#parameters of the network
num_epochs = 40        # number of epochs
batch_size_test = 4    # batch size for test dataset
im_size_test = 512     # size of the test images
kernel_size = 5        # size of the convolutional kernels
pool_size = 2          # size of the max-pooling masks
drop_prob = 0.3        # dropout probability for convolutional layers

# other parameters
first_lr = 5           # first value of the learning rate (power of ten)
trials = 1             # number of learning rate to be tested from the one defined above
n_thresh = 200         # number of thresholds to be tested


# load and preprocess the data
test_images, test_masks = load_data( path_files_test, 'test', real = 0 )  # real = 0 if surrogate data, 1 if real data


def test(lr,i):

    # get the model
    unet = get_nano_unet( lr, im_size_test, drop_prob, kernel_size, pool_size )
    unet.load_weights( path_weights )
    unet.compile( optimizer=Adam(lr), loss='binary_crossentropy', metrics=['accuracy'])

    # predict the images and saving the matrix
    pred_imgs = unet.predict(test_images, batch_size_test, verbose=1)

    # evaluate the model
    print( 'evaluating the predicted masks' )
    mean_scores, best_score, best_thre, tpr, fpr, precision, thre = evaluation(test_masks, pred_imgs, n_thresh, result_directory)
    scores[i] = best_score
    thresholds[i] = best_thre

    #save the matrix of images and the images themselves
    print('saving data')
    pred_masks = (np.asarray(pred_imgs>best_thre))*1
    save_images_and_masks(test_images, pred_imgs, test_masks, pred_masks,result_directory,
                          path_to_history, first_lr, i, mean_scores, thre, tpr, fpr, precision)


if __name__ == '__main__':
    lr = 1
    smooth = 1
    scores = (np.zeros(trials)).astype('float32')
    thresholds = (np.zeros(trials)).astype('float32')
    for i in range(first_lr-1):
        lr *= 0.1
    for i in range(trials):
        lr *= 0.1
        test(lr,i)
    print_scores(trials,scores,thresholds,first_lr)
    print('-'*30)
