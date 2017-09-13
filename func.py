### file defining all the functions used to run the unet ###

import os
import io
import h5py
import scipy.io
import numpy as np
import warnings
import pickle
import glob
import matplotlib
matplotlib.use('Agg')
from matplotlib import pyplot as plt
from skimage.io import imsave
from skimage.transform import resize
from keras.layers import Input, Conv2D, MaxPooling2D, UpSampling2D, Dropout
from keras.layers import Conv2DTranspose, concatenate
from keras.models import Model
from keras.optimizers import Adam
from keras.callbacks import ModelCheckpoint
from keras import backend as K
from random import randint


def get_nano_unet(lr,im_size,drop_prob=0,kernel_size=3,pool_size=2):   
    #contracting path
    inp=Input(shape=(im_size,im_size,1))
    
    conv1=Conv2D( 32,(kernel_size,kernel_size),activation='relu',padding='same')(inp)
    pool1=MaxPooling2D( (pool_size,pool_size),padding='same')(conv1)
    drop1=Dropout(drop_prob)(pool1)

    conv2=Conv2D( 64,(kernel_size,kernel_size),activation='relu',padding='same')(drop1)
    pool2=MaxPooling2D( (pool_size,pool_size),padding='same')(conv2)
    drop2=Dropout(drop_prob)(pool2)

    conv3=Conv2D( 128,(kernel_size,kernel_size),activation='relu',padding='same')(pool2)

    #expansive path
    up4=UpSampling2D( (2,2) )(conv3)
    conc4=concatenate([up4,conv2], axis=3) 
    conv4=Conv2D( 64,(kernel_size,kernel_size),activation='relu',padding='same')(conc4)
    drop4=Dropout(drop_prob)(conv4)

    up5=UpSampling2D( (2,2))(drop4)
    conc5=concatenate([up5,conv1], axis=3)
    conv5=Conv2D( 32,(kernel_size,kernel_size),activation='relu',padding='same')(conc5)
    drop5=Dropout(drop_prob)(conv5)

    conv6=Conv2D( 1, (1,1), activation='sigmoid', padding='same')(conv5)

    #creates model
    unet=Model(inputs=[inp],outputs=[conv6])

    return unet


def load_data( path_files, purpose, real): #load training, validation or test images and masks
    print('loading '+purpose+' data')

    if real is 0:
        lim=[f for f in os.listdir(path_files) if f.startswith(purpose+'_images')] #gets all the chunks of data
        for l in range(len(lim)):
            path_images=os.path.join(path_files,lim[l]) #loads the images and converts them to npy format
            with h5py.File(path_images,'r') as f:
                    im=f['images'][()]
            im=im.astype('float32')
            im/=255 #normalise the images
            if l is 0:
                ima=im
            else:
                ima=np.concatenate((ima,im)) #concatenate all chunks in one single np matrix
        images = ima[..., np.newaxis]
        lma=[fi for fi in os.listdir(path_files) if fi.startswith(purpose+'_masks')] # same procedure for the corresponding masks
        for l in range(len(lma)):
            path_masks=os.path.join(path_files,lma[l])
            with h5py.File(path_masks,'r') as f:
                    ma=f['axon_masks'][()]
            ma=ma.astype('float32')
            ma/=255
            if l is 0:
                mas=ma
            else:
                mas=np.concatenate((mas,ma))
        masks = mas[..., np.newaxis]

    if real is 1: # real data already in npy format
        if purpose is 'train':
            path_image = os.path.join( path_files, purpose+'_images_500.npy')
            path_masks = os.path.join( path_files, purpose+'_masks_500.npy' )
            images = np.load(path_image)
            masks =  np.load(path_masks)
        if purpose is 'val':
            path_image = os.path.join( path_files, purpose+'_images_500.npy')
            path_masks = os.path.join( path_files, purpose+'_masks_500.npy' )
            images = np.load(path_image)
            masks =  np.load(path_masks)
        if purpose is 'test':
            path_image = os.path.join( path_files, purpose+'_images.npy')
            path_masks = os.path.join( path_files, purpose+'_masks.npy' )
            images = np.load(path_image)
            masks =  np.load(path_masks)
        
        
    return images, masks
    


def dice_coef(y_true, y_pred,smooth=1): #define the dice_coefficient metrics for training
    y_true_f = K.flatten(y_true)
    y_pred_f = K.flatten(y_pred)
    intersection = K.sum(y_true_f * y_pred_f) #measure the overlapping pixels between the two images
    dice=(2. * intersection + smooth) / (K.sum(y_true_f) + K.sum(y_pred_f) + smooth)
    return dice


def dice_coef_loss(y_true, y_pred): #define loss metrics based on dice coef
    return -dice_coef(y_true, y_pred)


def dice_test( y_true, y_pred, smooth=1 ): #define dice coef test procedure
    y_true_f = y_true.flatten()
    y_pred_f = y_pred.flatten()
    intersection = np.sum(y_true_f * y_pred_f)
    dice = (2. * intersection + smooth) / (np.sum(y_true_f) + np.sum(y_pred_f) + smooth)
    dice = np.clip(dice, 0, 1.0 - 1e-8)
    return dice


def tpr_fpr( y_true, y_pred ): #calculate the true positive rate et false positive rate of segmented pixels
    y_true_f = y_true.flatten()
    y_pred_f = y_pred.flatten()
    tp = np.sum(y_true_f * y_pred_f)
    fn = np.sum(y_true_f * np.logical_not(y_pred_f))
    fp = np.sum(np.logical_not(y_true_f) * y_pred_f)
    tn = np.sum(np.logical_not(y_true_f )* np.logical_not(y_pred_f))
    tpr = tp / (tp+fn)
    fpr = fp / (fp+tn)
    precision = tp / (tp+fp)
    return tpr, fpr, precision


def evaluation( y_true, y_pred, nb_thresholds,result_directory ):

    temp_dice = np.zeros(y_pred.shape[0])                 #temp variable containing the dice coef between predicted and obtained mask
    temp_tpr = np.zeros(y_pred.shape[0])                  #temp variable containing tpr
    temp_fpr = np.zeros(y_pred.shape[0])                  #temp variable containing fpr
    temp_precision = np.zeros(y_pred.shape[0])            #temp variable containing precision
    thresholds = np.linspace(0.005, 0.995, nb_thresholds) #define all the thresholds to be tested
    mean_test_scores = np.zeros(nb_thresholds)            #contains the average dice coef for all tested thresholds
    mean_tpr= np.zeros(nb_thresholds)                     #contains tpr for all tested thresholds
    mean_fpr = np.zeros(nb_thresholds)                    #contains fpr for all tested thresholds
    mean_precision = np.zeros(nb_thresholds)              #contains precision for all tested thresholds

    for a in np.arange(nb_thresholds): #for all thresholds
        for i in np.arange(y_pred.shape[0]): #for all test images
            t = thresholds[a] #get current threshold
            temp_dice[i] = dice_test(np.asarray(y_true[i]), np.asarray(y_pred[i]>t)) #dice coef of thresholded predicted mask
            temp_tpr[i], temp_fpr[i], temp_precision[i] = tpr_fpr(np.asarray(y_true[i]), np.asarray(y_pred[i]>t))
        mean_test_scores[a] = np.mean(temp_dice) #for this threshold calculate average dice coef over all test images
        mean_tpr[a] = np.mean(temp_tpr) #idem for tpr
        mean_fpr[a] = np.mean(temp_fpr) #idem for fpr
        mean_precision[a] = np.mean(temp_precision) #idem for precision
    best_average_score = np.max(mean_test_scores) #get best average dice cief
    best_average_threshold = thresholds[np.argmax(mean_test_scores)] #get corresponding threshold
    
    th = {} #mean scores, tpr, fpr and precision are saved in a dictionary stored in the result directory
    th['mean_test_scores'] = mean_test_scores
    th['mean_tpr'] = mean_tpr
    th['mean_fpr'] = mean_fpr
    th['mean_precision'] = mean_precision
    if not os.path.exists(result_directory): #creates result directory if it doesn't exist
        os.mkdir(result_directory)
    with open(os.path.join(result_directory,'threshold_data'), 'wb') as file_pi:
            pickle.dump(th, file_pi)
    
    return mean_test_scores, best_average_score, best_average_threshold, mean_tpr, mean_fpr, mean_precision, thresholds

        
def save_history( history, i, path_to_history, path_old_history='', resume=0 , first_lr=5 ):
    #this fuction saves the history of the training (dice coef and loss for training and validation datasets
    # if the training has been resumed from previous sessions, the current history is appended to the previous one

    if resume is 0:
        with open(os.path.join(path_to_history,'trainHistoryDict'+'_lr_'+str(i+first_lr)), 'wb') as file_pi:
            pickle.dump(history.history, file_pi) #save history

    if resume is 1:
        # get previous history
        with open(os.path.join(path_old_history,'trainHistoryDict'+'_lr_'+str(i+first_lr)), 'rb') as file_pi:
            depick = pickle.Unpickler(file_pi)
            score = depick.load()
        dice_coef = score['dice_coef']
        val_dice_coef = score['val_dice_coef'] 
        val_loss = score['val_loss']       
        loss = score['loss']
        # get current history
        dice_coef1 = history.history['dice_coef']
        val_dice_coef1 = history.history['val_dice_coef']
        val_loss1 = history.history['val_loss']
        loss1 = history.history['loss']
        # concatenate the two and save them in a dictionnary
        dice_coef = dice_coef + dice_coef1
        val_dice_coef = val_dice_coef + val_dice_coef1
        val_loss = val_loss + val_loss1
        loss = loss + loss1
        h = {}
        h[ 'dice_coef' ] = dice_coef
        h[ 'val_dice_coef' ] = val_dice_coef
        h[ 'val_loss' ] = val_loss
        h[ 'loss' ] = loss
        with open(os.path.join(path_to_history,'trainHistoryDict'+'_lr_'+str(i+first_lr)), 'wb') as file_pi:
            pickle.dump(h, file_pi)
        

def save_images_and_masks(test_images, pred_imgs, test_masks, pred_masks, result_directory,
                          path_to_history, first_lr, i, mean_scores, thre, tpr, fpr, precision ):

    if not os.path.exists(result_directory): #create result directory if it doesn't exist
        os.mkdir(result_directory)
        
    #plots a roc curve (tpr aginst fpr) for every threshold
    plt.plot(fpr, tpr, 'o')
    axes = plt.gca()
    axes.set_xlim([0,np.max(fpr)+0.0001])
    plt.xlabel('FPR')
    plt.ylabel('TPR')
    plt.savefig(os.path.join(result_directory,'threshold_roc_curve.png'))
    plt.close()
    #plots tpr against fpr for evey threshold
    colors = matplotlib.cm.rainbow(np.linspace(0, 1, thre.shape[0]))
    plt.scatter(tpr, precision, color=colors)
    plt.xlabel('TPR')
    plt.ylabel('precision')
    plt.savefig(os.path.join(result_directory,'threshold_precision_curve.png'))
    plt.close()
    
    #open history
    with open(os.path.join(path_to_history,'trainHistoryDict'+'_lr_'+str(i+first_lr)), 'rb') as file_pi:
        depick = pickle.Unpickler(file_pi)
        score = depick.load()
    trainCost = score['dice_coef']
    valCost = score['val_dice_coef']
    # plot training and validation dice coef after each epoch
    plt.plot(trainCost, label="train")
    plt.plot(valCost, label="validation")
    plt.legend()
    plt.xlabel('iter')
    plt.ylabel('dice_coef')
    plt.savefig(os.path.join(result_directory,'training_dice_coef.png'))
    plt.close()
    
    #plot average dice coef for each threshold
    plt.plot( thre, mean_scores)
    plt.xlabel('thresholds')
    plt.ylabel('dice_coef')
    plt.savefig(os.path.join(result_directory,'dice_coef_with_thresholds_lr_'+str(i+first_lr)+'.png'))
    plt.close()

    length = 2
    images_id=np.arange(1,pred_imgs.shape[0]+1)
    start=randint(0,pred_imgs.shape[0]-length-2)

    im_dir='predicted_images_lr_'+str(i+first_lr)
    im_path=result_directory+'/'+im_dir #name of the directory where the predicted images will be stored
    ma_dir='predicted_masks_lr_'+str(i+first_lr)
    ma_path=result_directory+'/'+ma_dir #name of the directory where the predicted maps will be stored

    # figure to compare original test image and predicted map
    rec_im=np.vstack((test_images[start,:,:,0],pred_imgs[start,:,:,0]))
    for j in range(start+1,start+length):
       rec_im=np.hstack((rec_im,np.vstack((test_images[j,:,:,0],pred_imgs[j,:,:,0]))))
    fig_im=plt.figure()
    plt.imshow(rec_im,cmap="gray")
    plt.axis('off')
    im_name_plot='image_comparaison_lr_'+str(i+first_lr)+'.png'
    plt.savefig(os.path.join(result_directory,im_name_plot))
    
    # figure to compare expected and predicted maps
    rec_ma=np.vstack((test_masks[start,:,:,0],pred_masks[start,:,:,0]))
    for j in range(start+1,start+length):
        rec_ma=np.hstack((rec_ma,np.vstack((test_masks[j,:,:,0],pred_masks[j,:,:,0]))))
    fig_ma=plt.figure()
    plt.imshow(rec_ma,cmap="gray")
    plt.axis('off')
    ma_name_plot='mask_comparaison_lr_'+str(i+first_lr)+'.png'
    plt.savefig(os.path.join(result_directory,ma_name_plot))

    #save the matrices containing the predicted images and their maps
    np.save(os.path.join(result_directory,im_dir+'.npy'), pred_imgs)
    np.save(os.path.join(result_directory,ma_dir+'.npy'), pred_masks)

    #save predicted images in png format
    if not os.path.exists(im_path):
        os.mkdir(im_path)
    for im, im_id in zip(pred_imgs, images_id):
        im = im[:, :, 0]
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            imsave(os.path.join(im_path, str(im_id) + '_pred.png'), im)

     #save predicted maps in png format
    if not os.path.exists(ma_path):
        os.mkdir(ma_path)
    for ma, ma_id in zip(pred_masks, images_id):
        ma = ma[:, :, 0]*255
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            imsave(os.path.join(ma_path, str(ma_id) + '_pred.png'), ma)
        

def print_scores(trials,scores,thresholds,first_lr): #this function displays the best score and the corresponding threshold
    for i in range(trials):
        print('learning rate: 1e-0'+str(i+first_lr)+' best dice_coef on test data: '+str(scores[i])
              +'  for threshold: '+str(thresholds[i]))
