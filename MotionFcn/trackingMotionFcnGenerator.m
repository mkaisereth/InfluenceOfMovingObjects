% dynAnalysis - Conduct a dynamic analysis on a specified dataset
%
% Description:
% ------------
%       Entry-point for creation of a MotionFcn. Dataset must be of a
%       tracked marker mounted at the robots end-effector. Stores the
%       fitted MotionFcn in the folder of the specified dataset. The
%       fitting is done by interactively selecting the start and end
%       position on the dominant amplitude.
%
% Input Arguments:
% ----------------
%       folderpath - string | char array
%           Full folderpath of the dataset used to create the MotionFcn
%       speed - string | char array 
%           Speed of the dataset to evaluate. Must be the same format as
%           corresponding MotionFcn (E.g., '../MotionFcn/0.40_FB/..' must
%           resolve to 'speed = '0.40'')
%       motion - string | char array
%           Motion of the dataset to evaluate. Must be the same format as
%           corresponding MotionFcn (E.g., '../MotionFcn/0.40_FB/..' must
%           resolve to 'motion = 'FB'')
%
%   Output Arguments
%   ----------------
%       M1 - struct
%           Struct containing cartesian positions of tracked marker M1
%       timestamps - vector
%           Vector of the timestamps at which the cartesian positions are
%           stored

function [M1, timestamps] = trackingMotionFcnGenerator(folderpath, speed, motion)
    installedMarkers = 1;
    if strcmp(motion, 'FB')
        ROI = [-0.02, 0.02, -0.12, -0.08, 0.2, 1.4];           % Dynamic ROI FB [m]
    elseif strcmp(motion, 'LR')
        ROI = [-0.02, 0.37, -0.12, -0.08, 0.2, 1.3];            % Dynamic ROI LR [m]
    else
        error('Invalid motion type! \t''LR'' and ''FB'' are valid input arguments.\n')
    end

    % Find files and sort by date
    files = dir(fullfile(folderpath, ['*', speed, '_', motion], ['*', 'Photoneo', '*.ply']));
    [~, sortedIdx] = sort({files.name});

    % Read in point-clouds
    for i = 1:length(files)
        pcArray{i} = pcread(fullfile(files(1).folder, files(sortedIdx(i)).name));
        indicesRoi = pcArray{i}.findPointsInROI(ROI);
        pcArray{i} = pcArray{i}.select(indicesRoi);
        jsonFile = dir(fullfile(files(1).folder, ['*', ...
            strrep(files(sortedIdx(i)).name, '.ply', '.json')]));
        jsonArray{i} = jsondecode(fileread(fullfile(jsonFile.folder, jsonFile.name)));
    end

    for i = 1:length(pcArray)
%         pcshow(pcArray{i}, 'MarkerSize', 20);

        % Find max brightness points
        indices = all(pcArray{i}.Color >= [240, 240, 240], 2);

        % Filter outliers
        markers = pcArray{i}.select(indices);
        if markers.Count < 2
            warning('\tFrame #%d failed to find sufficient marker points!', i);
            continue;
        end
        [markers, ~, ~] = pcdenoise(markers, 'NumNeighbors', 3, 'Threshold', 0.003);
%         pcshow(markers, 'MarkerSize', 100);

        % Segment into separate clusters
        thisPoint = markers.select(1);
        markerPCs = {markers.select(markers.findNeighborsInRadius(thisPoint.Location, 0.015))};
        for j = 2:markers.Count
            thisPoint = markers.select(j);
            if ismembertol(thisPoint.Location, pccat([markerPCs{:}]).Location, 0.001, 'ByRows', true)
                continue
            end
            markerPCs(end+1) = {markers.select(markers.findNeighborsInRadius(thisPoint.Location, 0.015))};
        end

        if length(markerPCs) > installedMarkers
            warning('Too many markers detected %d! Dropping frame #%d', length(markerPCs), i);
            continue
        end
        if i >=35
            pause(0.1);
        end
%         for j = 1:length(markerPCs)
            % Calculate marker position and store in struct
        tracking(i).position = [mean(markerPCs{1}.Location)];
%         end
%         timestamps(i) = jsonArray{i}.FrameTimestamp;
    end

    %%
    trackingArray = vertcat(tracking(:).position);
    for i = 2:length(trackingArray)
        if length(trackingArray(i, :)) < 3
            if length(trackingArray(i+1)) < 3
                trackingArray(i:end, :) = [];
            else
                trackingArray(i, :) = mean([trackingArray(i-1, :); trackingArray(i+1, :)]);
            end
        end
    end
    
%     M1 = [trackingArray(1:end-1, :); trackingArray(end-1, :)]
%     M1 = [trackingArray; trackingArray(end, :)];
    M1 = trackingArray;
    timestamps = [jsonArray{1}.FrameTimestamp];
    for k = 2:length(M1)
        timestamps = vertcat(timestamps, jsonArray{k}.FrameTimestamp);
    end
    timestamps = timestamps - timestamps(1);
%     timestamps = [timestamps; timestamps(end)+timestamps(2)]


%     figure;
%     plot(timestamps/1e3, M1(:, 1), '-*r', ...
%         timestamps/1e3,  M1(:, 2), '-*g', ...
%         timestamps/1e3,  M1(:, 3), '-*b', 'LineWidth', 2);
%     grid minor;
%     hold on;
%     xlabel('Ticks [s]');
%     ylabel('Amplitude [m]');
%     legend({'M1 : x', 'M1 : y', 'M1 : z'});
    save([pwd, '\', speed, '_', motion, '\', 'motionData.mat'], "M1", "timestamps");

    findIntervalAndSaveFit(M1, timestamps, speed, motion);
    
%     f.x = fit(timestamps/1e3, M1(:, 1), 'smoothingspline', ...
%         'SmoothingParam', 0.9999347751165584);
%     f.y = fit(timestamps/1e3, M1(:, 2), 'smoothingspline', ...
%         'SmoothingParam', 0.9999347751165584);
%     f.z = fit(timestamps/1e3, M1(:, 3), 'smoothingspline', ...
%         'SmoothingParam', 0.9999347751165584);
%     plot(f.x);
%     plot(f.y);
%     plot(f.z);
% 
%     figure;
%     hold on
%     grid minor;
%     cart = {'x', 'y', 'z'};
%     for i = 1:3
%         y = (M1(:,i) - min(M1(:,i)));
%         ydT = diff(y)./diff(timestamps/1e3);
%         xdT = ((timestamps(2:end)/1e3)+(timestamps(1:end-1)/1e3))/2;
%         plot(xdT, ydT);
%         maxSpeed = max(ydT);
%         fprintf('\t\tMax speed in %s: %fm/s\n', cart{i}, maxSpeed);
%     end
%     xlabel('Ticks [s]');
%     ylabel('Velocity [m/s]');
%     legend({'M1 : x''', 'M1 : y''', 'M1 : z'''});
end
