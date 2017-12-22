#### U-Net of medium size to avoid overfitting ####

import h5py
import io
import os
import pickle
import scipy.io
import numpy as np
import theano
from keras.layers import Input, Conv2D, MaxPooling2D, UpSampling2D, Dropout
from keras.layers import Conv2DTranspose, concatenate
from keras.models import Model
from keras.optimizers import Adam
from keras.callbacks import ModelCheckpoint
from keras import backend as K
from func import *


# dataset paths and results directory
path_files_train = '/data/users/bpb216/dataset/real_500' # path of the training and validation dataset
path_files_test = '/data/users/bpb216/dataset/real_data' # path of the test dataset
path_to_history = '/data/users/bpb216/results/15_09'     # path where the history of the network will be saved
result_directory = '/data/users/bpb216/results/15_09'    # path of the result directory (it will be created if it doesn't exist)
saved_model = 'nano_seg'                                 # name of the file that will contain the weights

#parameters of the network
num_epochs = 40        # number of epochs
batch_size_train = 64  # batch size for training and validation datasets
batch_size_test = 4    # batch size for test dataset
im_size_train = 128    # size of the training and validation images
im_size_test = 512     # size of the test images
kernel_size = 5        # size of the convolutional kernels
pool_size = 2          # size of the max-pooling masks
drop_prob = 0.3        # dropout probability for convolutional layers

# other parameters
first_lr = 5           # first value of the learning rate (power of ten)
trials = 1             # number of learning rate to be tested from the one defined above
n_thresh = 200         # number of thresholds to be tested

# load and preprocess the data
images, masks = load_data( path_files_train, 'train', real=1 )         # real = 0 if surrogate data, 1 if real data
val_images, val_masks = load_data( path_files_train, 'val', real=1 )   # real = 0 if surrogate data, 1 if real data
test_images, test_masks = load_data( path_files_test, 'test', real=1 ) # real = 0 if surrogate data, 1 if real data


def train(lr,i):
    print('-'*30)
    print('learning rate: 1e-0'+str(i+first_lr))

    # get the unet model
    unet = get_nano_unet( lr, im_size_train, drop_prob, kernel_size, pool_size )
    unet.compile( optimizer=Adam(lr), loss=dice_coef_loss, metrics=[dice_coef] )

    # fit the model and save the best weights as well as the training history
    if not os.path.exists(result_directory):
        os.mkdir(result_directory)
    model_path=os.path.join(result_directory,saved_model+'_lr_'+str(i+first_lr)+'.h5')
    unet_checkpoint = ModelCheckpoint(model_path,
                                      monitor='val_loss',
                                      save_best_only=True)
    history = unet.fit(images, masks,
             batch_size_train,
             num_epochs,
             verbose = 1,
             shuffle = True,
             validation_data = (val_images,val_masks),
             callbacks = [unet_checkpoint]
             )
    save_history( history, i, path_to_history )

    return model_path


def test(model_path, lr,i):

    # get the model
    unet = get_nano_unet( lr, im_size_test, drop_prob, kernel_size, pool_size )
    unet.load_weights(model_path)
    unet.compile( optimizer=Adam(lr), loss=dice_coef_loss, metrics=[dice_coef])

    # predict the images
    pred_imgs = unet.predict(test_images, batch_size_test, verbose=1)

    # evaluate the model
    print('evaluating model')
    mean_scores, best_score, best_thre, tpr, fpr, precision, thre = evaluation(test_masks, pred_imgs, n_thresh, result_directory)
    scores[i] = best_score
    thresholds[i] = best_thre

    #save the matrix of images and the images themselves
    print('saving data')
    pred_masks = (np.asarray(pred_imgs>best_thre))*1
    save_images_and_masks(test_images, pred_imgs, test_masks, pred_masks, result_directory,
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
        model_path =train(lr,i)
        test( model_path, lr, i)
    print_scores(trials, scores, thresholds, first_lr)
    print('-'*30)
