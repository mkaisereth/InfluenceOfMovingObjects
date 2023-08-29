close all; clear all; clc;
baseFolderPath = pwd;

silent = true;
analysisOnly = true;
save = false;
accuracyMethod = 'MedianDist';

folderpath = append(baseFolderPath, '\DatasetFB\CameraDataset');
filepath = append(baseFolderPath, '\Static\Static_FB.ply');
speedCell = {'0.01', '0.04', '0.07', '0.10', '0.13', '0.16', '0.19', '0.22', '0.25', '0.28', '0.31', '0.34', '0.37', '0.40', '0.43', '0.46', '0.49', '0.52', '0.55', '0.58', '0.60'};
for i = 1:length(speedCell)
    dynAnalysis(filepath, folderpath, speedCell{i}, 'FB', 'Silent', silent, 'AnalysisOnly', analysisOnly, 'Save', save, 'AccuracyMethod', accuracyMethod);
end

folderpath = append(baseFolderPath, '\DatasetFB\ScannerDataset');
filepath = append(baseFolderPath, '\Static\Static_FB.ply');
speedCell = {'0.004', '0.007', '0.01', '0.04', '0.07', '0.10', '0.13', '0.16', '0.19'};
for i = 1:length(speedCell)
    dynAnalysis(filepath, folderpath, speedCell{i}, 'FB', 'Silent', silent, 'AnalysisOnly', analysisOnly, 'Save', save, 'AccuracyMethod', accuracyMethod);
end

%%
plotDynamicZAnalysis([baseFolderPath, '\DatasetFB\ScannerDataset'], 'FB', 'SecondFolderpath', [baseFolderPath, '\DatasetFB\CameraDataset']);