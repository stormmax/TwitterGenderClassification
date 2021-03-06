% Author: Dongni Wang
% Date: Dec 3, 2015
%
% This file demonstrates the prediction results of our four algorithms. 
%

%% Add path
addpath('./NB');
addpath('./KNN');
addpath('./PCA');
addpath('./liblinear');
addpath('./libsvm');

%% Load data
% run prepare_data.m for data process (.txt to .mat)
load('train/genders_train.mat', 'genders_train');
load('train/images_train.mat', 'images_train');
load('train/image_features_train.mat', 'image_features_train');
load('train/words_train.mat', 'words_train');
load('test/images_test.mat', 'images_test');
load('test/image_features_test.mat', 'image_features_test');
load('test/words_test.mat', 'words_test');

%% Variables
Xtrain = words_train;
Ytrain = genders_train;
Xtest = words_test;
Ytest = ones(size(words_test,1),1);

%% Naive Bayes 
[Yhat, ~] = predict_MNNB(Xtrain, Ytrain, Xtest, Ytest);

%% Logistic Regression
Yhat = logistic(Xtrain, Ytrain, Xtest, Ytest);

%% ANN
addpath('./DL_toolbox/util','./DL_toolbox/NN','./DL_toolbox/DBN');
Xtrain = [words_train; words_train(1,:); words_train(2,:)];
Ytrain = [genders_train; genders_train(1); genders_train(2)];
[Yhat,~] = acc_neural_net(Xtrain, Ytrain, Xtest, Ytest);

%% LogitBoost + Trees
IG=calc_information_gain(Ytrain,Xtrain,[1:5000],10);
[~, idx]=sort(IG,'descend');
word_sel=idx(1:350);
Xtrain_selected =Xtrain(:,word_sel);
Xtest_selected = Xtest(:,word_sel);
Yhat = acc_ensemble_trees(Xtrain_selected, Ytrain, Xtest_selected, Ytest);

%% K-nearest Neighbors
IG=calc_information_gain(Ytrain,Xtrain,[1:5000],10);
[~, idx]=sort(IG,'descend');
word_sel=idx(1:70);
Xtrain_selected =Xtrain(:,word_sel);
Xtest_selected = Xtest(:,word_sel);

Yhat = knn_test(16, Xtrain_selected, Ytrain, Xtest_selected);

%% PCA  (This one is not what we used in our classifier. Please refer to README.txt, 
% image_features_extract.m and next section for better test results).
[~, ~, ~, train_grey] = convert_to_img(images_train);
[~, ~, ~, test_grey] = convert_to_img(images_test);
X = cat(3, train_grey, test_grey);
[h w n] = size(X);
x = reshape(X,[h*w n])

[U mu vars] = pca_toolbox(x);
[YPC,~,~] = pcaApply(x, U, mu, 2000 );
YPC = double(YPC');

Xtrain_pca = YPC(1:size(train_grey,3),:);
Xtest_pca = YPC(size(train_grey,3)+1:end,:);
addpath('../libsvm');
[Yhat,~] = svm_predict(Xtrain_pca, Ytrain, Xtest_pca, Ytest);

%% PCA (on pre-loaded features generated by test_face_detection.m)
% Note: this part is only tested on face-detected images, thus the size of 
% the testing results is smaller than the test data size. 
% For the train_hog, we used the first 2 observations twice to make partition of 
% cross-validation easier. This seems to have little impact on the
% classifier. 
image_features_extract
n_train = sum(certain(1:5000,:));
PC_train = YPC(1:n_train,:);
PC_test = YPC(n_train+1:end,:);
Ytest = ones(size(PC_test,1),1);
[Yhat,~] = svm_predict(PC_train, train_y_certain, PC_test, Ytest);
