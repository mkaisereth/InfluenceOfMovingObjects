close all; clear all; clc;

relativeFolder = '.';
% an example call to generate the tracking motion function for speed 0.1
% and forward-backward (FB) movement
% speedCell = {'0.01', '0.04', '0.07', '0.10', '0.13', '0.16', '0.19', '0.22', '0.25', '0.28', '0.31', '0.34', '0.37', '0.40', '0.43', '0.46', '0.49', '0.52', '0.55', '0.58', '0.60'};
% for i = 1:length(speedCell)
%     trackingMotionFcnGenerator(relativeFolder, speedCell{i}, 'FB');
% end
% an example call to generate the tracking motion function for speed 0.1
% and left-right (LR) movement
speedCell = {'0.01', '0.04', '0.07', '0.10', '0.13', '0.16', '0.19', '0.22', '0.25', '0.28', '0.31', '0.34', '0.37', '0.40', '0.43', '0.46', '0.49', '0.52', '0.55', '0.58', '0.60'};
for i = 1:length(speedCell)
    trackingMotionFcnGenerator(relativeFolder, speedCell{i}, 'LR');
end