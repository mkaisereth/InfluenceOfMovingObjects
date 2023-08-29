% estimateSequenceIndices - Find indices of frames in motion in a dataset
%
% Description:
% ------------
%       Loads all the point clouds in a dataset of dynamic frames.
%       Calculates the difference of mean cartesian positions in adjacent
%       frames. Resulting is a graph where this estimated motion can be
%       seen.
%
% Input Arguments:
% ----------------
%       folderpath - string | char array
%           Full folderpath of the dynamic dataset
%       speed - string | char array 
%           Speed of the dataset to evaluate. Must be the same format as
%           corresponding MotionFcn (E.g., '../MotionFcn/0.40_FB/..' must
%           resolve to 'speed = '0.40'')
%       motion - string | char array
%           Motion of the dataset to evaluate. Must be the same format as
%           corresponding MotionFcn (E.g., '../MotionFcn/0.40_FB/..' must
%           resolve to 'motion = 'FB'')

function estimateSequenceIndices(folderpath, speed, motion)
    threshold = 0.005;    % Threshold at which correlation difference a motion is suspected in [m]

    if strcmp(motion, 'FB')
        ROI = [-0.1, 0.1, -0.25, 0.1, 0.2, 1.4];           % Dynamic ROI FB [m]
%         ROI = [-0.05, 0.1, -0.25, 0.1, 0.2, 1.1];
    elseif strcmp(motion, 'LR')
        ROI = [-0.1, 0.45, -0.25, 0.1, 0.2, 1.35];            % Dynamic ROI LR [m]
    else
        error('Invalid motion type! \t''LR'' and ''FB'' are valid input arguments.\n')
    end
    
    % Find files and sort by date
    files = dir(fullfile(folderpath, [speed, '_', motion], '*.ply'));
    [~, sortedIdx] = sort({files.name});
    
    % Read in point-clouds
    for i = 1:length(files)
%         pcArray{i} = pcdenoise(pcread(fullfile(files(1).folder, files(sortedIdx(i)).name)), ...
%             'NumNeighbors', 20, 'Threshold', 0.2);
        pcArray{i} = pcread(fullfile(files(1).folder, files(sortedIdx(i)).name));
        jsonArray{i} = jsondecode(fileread(fullfile(files(1).folder, ...
                [strrep(files(i).name, '.ply', '.json')])));
    end
    fprintf('Evaluating motion in %i frames...\n\n', length(pcArray));

    indicesRoi = pcArray{i}.findPointsInROI(ROI);
    firstGuess = pcArray{i}.select(indicesRoi);
%     f1 = figure();
%     axes = pcshow(firstGuess, 'MarkerSize', 20);
%     % view(0, 270);
%     xlabel('x');
%     ylabel('y');
%     zlabel('z');
%     set(axes, 'ZDir','normal');
%     set(axes, 'YDir','normal');
%     set(axes, 'XDir','normal');
% %     axes.View = [30, -80];
%     axes.View = [0, 270];
%     pause(0.1);
%     axes = f1.CurrentAxes;
    centerPoint = struct('x', (max(firstGuess.Location(:,1)) + ...
        min(firstGuess.Location(:,1))) / 2, ...
        'y', (max(firstGuess.Location(:,2)) + ...
        min(firstGuess.Location(:,2))) / 2, ...
        'z', (max(firstGuess.Location(:,3)) + ...
        min(firstGuess.Location(:,3))) / 2); % [m]
%     cuboidObj = drawcuboid(axes, 'Color', 'white', ...
%         'Position', [centerPoint.x - abs(ROI(1) - ROI(2)) / 2, ...
%         centerPoint.y - abs(ROI(3) - ROI(4)) / 2, ...
%         centerPoint.z - abs(ROI(5) - ROI(6)) / 2, ...
%         abs(ROI(1) - ROI(2)), abs(ROI(3) - ROI(4)), abs(ROI(5) - ROI(6))], ...
%         'InteractionsAllowed', 'all', ...
%         'Selected', 0, 'Label', 'Estimated Object Pose');
%     xlim([ROI(1)-0.5, ROI(2)+0.5]);
%     ylim([ROI(3)-0.5, ROI(4)+0.5]);
%     zlim([ROI(5)-0.5, ROI(6)+0.5]);
%     f2 = uifigure('Position', f1.Position - [0, 0, 200, 250]);
%     uialert(f2, 'Move the cuboid in the other window so it only encloses the Object. Close the window if fitted.', 'Fit cuboid');
%     uiwait(f2);
%     ROI = [cuboidObj.Position(1), cuboidObj.Position(1) + cuboidObj.Position(4), ...
%         cuboidObj.Position(2), cuboidObj.Position(2) + cuboidObj.Position(5), ...
%         cuboidObj.Position(3), cuboidObj.Position(3) + cuboidObj.Position(6)];
%     clear f2;

    sequenceCount = 1;  % Amount of detected motion sequences
    frameCount = 1;     % Amount of frames detected per sequence
    diffArr = [0, 0, 0]; % Array to store cartesian mean differences
    staticIndices{1} = 1; % First frame is assumed to be static
    inMotion = false;
    % Loop through pairs of point-clouds
    for i = 1:length(pcArray)-1
%         if inMotion
%             % ROI to cuboid Position
%             ROIAsCuboid = [min(ROI(1:2)), min(ROI(3:4)), min(ROI(5:6)), ...
%                 abs(ROI(1) - ROI(2)), abs(ROI(3) - ROI(4)), abs(ROI(5) - ROI(6))];
%             MovedROIAsCuboid = ROIAsCuboid + [diffArr(end, 1), diffArr(end, 2), diffArr(end, 3), 0, 0, 0];
%             [x, y, z] = findFramePosition(speed, motion, ROIAsCuboid, MovedROIAsCuboid, ...
%                 jsonArray{i}.FrameTimestamp - jsonArray{i+1}.FrameTimestamp);
%             ROI = ROI + [x, x, y, y, z, z];
%         end
        indicesRoi = pcArray{i}.findPointsInROI(ROI);
        current = pcArray{i}.select(indicesRoi);
        indicesRoi = pcArray{i+1}.findPointsInROI(ROI);
        next = pcArray{i+1}.select(indicesRoi);

%         ax = pcshowpair(current, next, 'MarkerSize', 20);
%         xlabel('x');
%         ylabel('y');
%         zlabel('z');
%         pause(0.01);
% %         ax.View = [30, -80];
%         ax.View = [0, 270];
%         pause(0.1);
%         set(ax, 'ZDir','reverse');
%         set(ax, 'YDir','reverse');
%         set(ax, 'XDir','reverse');
%         ax.View = [-95.1914  -14.1152];

%         % Correct dimensions of point-clouds
%         if current.Count < next.Count
%             next = pcdownsample(next, 'nonuniformgridsample', current.Count);
%         else
%             current = pcdownsample(current, 'nonuniformgridsample', next.Count);
%         end
        
        if current.Count < 500
            warning('Too few points found in ROI. Skipping frame #%s', num2str(i));
            continue;
        end
        
        % Calculate mean difference for each axis
        diff = mean(current.Location) - mean(next.Location);
        meanPos(i, :) = mean(current.Location);
        diffArr(end+1, :) = diff;
        % Motion is suspected if correlation difference is above threshold
        if any(abs(diffArr(end)) > threshold)
            inMotion = true;
            % Direction change or if frames are not adjacent results in a
            % new sequence row
            currDirection = any((diffArr(end-1) - diffArr(end)) < [-threshold, -threshold, -threshold]);
            if exist('motionIndices', 'var')
                if motionIndices{sequenceCount, frameCount-1} + 1 < i || currDirection ~= prevDirection
                    sequenceCount = sequenceCount + 1;
                    frameCount = 1;
                end
                motionIndices{sequenceCount, frameCount} = i+1;
                frameCount = frameCount + 1;
            else
                motionIndices{sequenceCount} = i+1;
                frameCount = frameCount + 1;
            end
            if i == length(pcArray)-1
                motionIndices{sequenceCount, frameCount} = i+1;
                frameCount = frameCount + 1;
            end
            prevDirection = currDirection;
        else
            staticIndices{end+1} = i+1;
        end
    end
    meanPos(i+1, :) = mean(next.Location);
    f2 = figure('units','normalized','outerposition',[0 0 1 1]);
    plot([1:length(meanPos)], meanPos(:, 1), '-o', [1:length(meanPos)], meanPos(:, 2), '-o', [1:length(meanPos)], meanPos(:, 3), '-o');
    legend({'x', 'y', 'z'});
    title('Mean position on each axis of points in ROI');
    xlabel('frame #');
    xticks(1:length(meanPos));
    ylabel('amplitude');

    [dynamicIndices, ~] = ginput(3);

    dynamicIndices = round(dynamicIndices);
    save(fullfile(folderpath, [speed, '_', motion], 'dynamicIndices.mat'), "dynamicIndices");

    close(f2);
end
