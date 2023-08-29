% dynAnalysis - Conduct a dynamic analysis on a specified dataset
%
% Description:
% ------------
%       Entry-point for a full dynamic analysis using Z-analysis and
%       X-Y-analysis. Can also be used to simply run the statistical
%       section again.
%       Raw point clouds are accepted of a motion with a specifed
%       MotionFcn. A static point cloud of the starting posiion of said
%       motion must be delivered.
%       Out of the folder specifed as the dynamic dataset, the function
%       will estimate the general motion in the underlying frames. The user
%       will be presented a graph representing that motion, and will be
%       prompted to select three frames.
%       These three frames are then used for the dynamic-analysis. Their
%       indices will be saved to the dataset folder, so this motion
%       estimation must not be done again and the same frames can be used
%       to repeat an analysis.
%       Placement of the first dynamic bounding box is done by hand and
%       shall be equal to the one presented in the static frame. Error will
%       occur if the data is too artefact heavy for an accuracte placement,
%       or if the placement was not good enough.
%       Intermediate (ROI point cloud data of each step) and final results 
%       are stored to the dataset folder.
%
% Input Arguments:
% ----------------
%       staticFilepath - string | char array
%           Full filepath of the static frame.
%       datasetFolderpath - string | char array
%           Full folderpath of the dynamic dataset
%       speed - string | char array 
%           Speed of the dataset to evaluate. Must be the same format as
%           corresponding MotionFcn (E.g., '../MotionFcn/0.40_FB/..' must
%           resolve to 'speed = '0.40'')
%       motion - string | char array
%           Motion of the dataset to evaluate. Must be the same format as
%           corresponding MotionFcn (E.g., '../MotionFcn/0.40_FB/..' must
%           resolve to 'motion = 'FB'')
%
%       Optional Name-Value Pairs:
%           SameIndices - false | (true)
%               Select to use same dynamic frames for dynamic-analysis. 
%               Skips the step of motion estimation in the raw data.
%           AnalysisOnly - false | (true)
%               Select to only run the statistical analysis again with the
%               intermediately saved data. Can be useful if method of
%               statistical analysis has changed.
%           Type - 'Both' | ('zAnalysis' | 'xyAnalysis')
%               Select which analysis type to run (starting from bounding
%               box placement and subsequent ROI placement).
%           Save - true | (false)
%               Select if indices of dynamic frames in raw data,
%               intermediate data and results shall be saved.
%
%       Optional Name-Value Pairs of Subfunctions (are passed through):
%           SemiSilent - false | (true) - statisticalZAnalysis | statisticalXYAnalsis
%               Select to not print ROI-analysis results but only
%               frame-analysis and dynamic-analysis results.
%           Silent - false | (true) - statisticalZAnalysis | statisticalXYAnalsis
%               Select to only print the dynamic-analysis results.
%           ShowDynamicHistograms - false | (true) - statisticalZAnalysis | statisticalXYAnalsis
%               Select to plot all the raw and split histograms of all the
%               ROI in every dynamic frame. WARNING: This is a lot!
%           ShowStaticHistograms - false | (true) - statisticalZAnalysis | statisticalXYAnalsis
%               Select to plot all the raw and split histograms of all the
%               ROI in the static frame. WARNING: This is a lot!
%
%   Output Arguments
%   ----------------
%       staticFrameData - struct
%           Struct containing point cloud data of ROI on a staircase in a 
%           static frame. Can be used to call a statistical*Analysis.
%       dynamicFrameData - struct
%           Struct containing point cloud data of ROI on a staircase in a
%           dynamic frame. Can be used to call a statistical*Analysis.

function [staticFrameData, dynamicFrameData] = dynAnalysis(staticFilepath, datasetFolderpath, speed, motion, varargin)
    p = inputParser();
    p.KeepUnmatched = true;
    p.addOptional('SameIndices', false);
    p.addOptional('AnalysisOnly', false);
    p.addOptional('Type', 'Both', @(s) any(strcmp(s, {'Both', 'zAnalysis', 'xyAnalysis'})));
    p.addOptional('Save', true);
    p.addOptional('BoxOrientation', 'Vertical', @(s) any(strcmp(s, {'Vertical', 'Horizontal'})));
    p.parse(varargin{:});
    
    sameIndices = p.Results.SameIndices;
    analysisOnly = p.Results.AnalysisOnly;
    type = p.Results.Type;
    Save = p.Results.Save;
    boxOrientation = p.Results.BoxOrientation;

    if ~analysisOnly
        if ~sameIndices
            estimateSequenceIndices(datasetFolderpath, speed, motion);
        end
        load([datasetFolderpath, '\', speed, '_', motion, '\dynamicIndices.mat'], 'dynamicIndices');
        
        if strcmp(motion, 'FB')
            ROI = [-0.1, 0.1, -0.25, 0.1, 0.2, 1.4];            % Dynamic ROI FB [m]
            staticROI = [-0.05, 0.1, -0.25, 0.1, 0.2, 1.1];     % Static ROI FB [m]
        elseif strcmp(motion, 'LR')
            ROI = [-0.5, 0.5, -0.5, 0.5, 0.2, 1.1];            % Dynamic ROI LR [m]
            staticROI = [-0.06, 0.04, -0.19, 0.17, 0.9, 1.025];            % Static ROI LR [m]
        else
            error('Invalid motion type! \t''LR'' and ''FB'' are valid input arguments.\n')
        end

        if strcmp(boxOrientation, 'Horizontal')
            ROItemp(1:2) = ROI(1:2);
            ROI(1:2) = ROI(3:4);
            ROI(3:4) = ROItemp(1:2);
            staticROItemp(1:2) = staticROI(1:2);
            staticROI(1:2) = staticROI(3:4);
            staticROI(3:4) = staticROItemp(1:2);
        end
    
        % Read in static frame
        staticFile = dir(fullfile(staticFilepath));
        thisPc = pcread(fullfile(staticFile.folder, staticFile.name));
        thisPc = pointCloud(thisPc.Location/1e3);
        indicesRoi = thisPc.findPointsInROI(staticROI);
        staticPc = thisPc.select(indicesRoi);
    
        % Find files and sort by date
        dynamicFiles = dir(fullfile(datasetFolderpath, [speed, '_', motion], '*.ply'));
        [~, sortedIdx] = sort({dynamicFiles.name});
    
        fprintf('%s\nProcessing dynamic frames #%d, #%d and #%d...\n%s\n\n', ...
            repmat('-', 1, 100), dynamicIndices(1), dynamicIndices(2), dynamicIndices(3), repmat('-', 1, 100));
    
        % Read in point-clouds
        for i = 1:length(dynamicIndices)
            thisPc = pcread(fullfile(dynamicFiles(1).folder, dynamicFiles(sortedIdx(dynamicIndices(i))).name));
            indicesRoi = thisPc.findPointsInROI(ROI);
            dynamicPcs{i} = thisPc.select(indicesRoi);
            dynamicPcs{i}.Color = uint8(repmat([255, 255, 255], height(dynamicPcs{i}.Color), 1));
            dynamicJsons{i} = jsondecode(fileread(fullfile(dynamicFiles(1).folder, ...
                [strrep(dynamicFiles(sortedIdx(dynamicIndices(i))).name, '.ply', '.json')])));
        end
    
        %% Static frame
        [fs, staticObjCuboid] = placeObjCuboid(pcdenoise(staticPc), ROI, boxOrientation);
        staticRoiCuboids = placeRoiCuboids(fs, staticObjCuboid, boxOrientation);
        staticFrameData = findPCsOnStaircase(fs, staticPc, staticRoiCuboids, boxOrientation);
    
        %% First dynamic frame
        [fd(1), dynamicObjCuboid(1)] = placeObjCuboid(dynamicPcs{1}, ROI, boxOrientation, ...
            'Interactive', true, 'StaticObjCuboid', staticObjCuboid);
        dynamicRoiCuboids{1} = placeRoiCuboids(fd(1), dynamicObjCuboid(1), boxOrientation);
        dynamicFrameData{1} = findPCsOnStaircase(fd(1), dynamicPcs{1}, dynamicRoiCuboids{1}, boxOrientation);
    
        %% Dynamic frames
        for i = 2:length(dynamicPcs)
            timestampDiff = dynamicJsons{i}.FrameTimestamp - dynamicJsons{1}.FrameTimestamp;
            [fd(i), dynamicObjCuboid(i)] = placeObjCuboid(dynamicPcs{i}, ROI, boxOrientation, ...
                'Speed', speed, ...
                'Motion', motion, 'StaticObjCuboid', staticObjCuboid, ...
                'FirstDynamicObjCuboid', dynamicObjCuboid(1), 'Timestamp', timestampDiff, ...
                'PcStatic', staticPc);
            dynamicRoiCuboids{i} = placeRoiCuboids(fd(i), dynamicObjCuboid(i), boxOrientation);
            dynamicFrameData{i} = findPCsOnStaircase(fd(i), dynamicPcs{i}, dynamicRoiCuboids{i}, boxOrientation);
        end
    
        if Save
            save([datasetFolderpath, '\', speed, '_', motion, '\frameData.mat'], ...
                'staticFrameData', 'dynamicFrameData');
        end
    else
        load([datasetFolderpath, '\', speed, '_', motion, '\frameData.mat'], ...
        'staticFrameData', 'dynamicFrameData');
    end

    switch type
        case 'Both'
            results = statisticalZAnalysis(staticFrameData, dynamicFrameData, p.Unmatched);
            if Save
                save([datasetFolderpath, '\', speed, '_', motion, '\resultsZ.mat'], 'results');
            end
%             results.z = results;
            fprintf('%s\nStoring z-analysis results in: \n\t%s\n%s\n\n', ...
                repmat('~', 1, 100), [datasetFolderpath, '\', speed, '_', motion, '\resultsZ.mat'], repmat('~', 1, 100));

            results = statisticalXYAnalysis(staticFrameData, dynamicFrameData, p.Unmatched);
            if Save
                save([datasetFolderpath, '\', speed, '_', motion, '\resultsXY.mat'], 'results');
            end
%             results.xy = results;
            fprintf('%s\nStoring xy-analysis results in: \n\t%s\n%s\n\n', ...
                repmat('~', 1, 100), [datasetFolderpath, '\', speed, '_', motion, '\resultsXY.mat'], repmat('~', 1, 100));
        case 'zAnalysis'
            results = statisticalZAnalysis(staticFrameData, dynamicFrameData, p.Unmatched);
            if Save
                save([datasetFolderpath, '\', speed, '_', motion, '\resultsZ.mat'], 'results');
            end
%             results.z = results;
            fprintf('%s\nStoring z-analysis results in: \n\t%s\n%s\n\n', ...
                repmat('~', 1, 100), [datasetFolderpath, '\', speed, '_', motion, '\resultsZ.mat'], repmat('~', 1, 100));
        case 'xyAnalysis'
            results = statisticalXYAnalysis(staticFrameData, dynamicFrameData, p.Unmatched);
            if Save
                save([datasetFolderpath, '\', speed, '_', motion, '\resultsXY.mat'], 'results');
            end
%             results.xy = results;
            fprintf('%s\nStoring xy-analysis results in: \n\t%s\n%s\n\n', ...
                repmat('~', 1, 100), [datasetFolderpath, '\', speed, '_', motion, '\resultsXY.mat'], repmat('~', 1, 100));
    end
end