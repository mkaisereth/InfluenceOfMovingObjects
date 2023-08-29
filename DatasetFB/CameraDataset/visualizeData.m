
if strcmp(motion, 'FB')
    ROI = [-0.1, 0.1, -0.25, 0.1, 0.8, 1.4];            % Dynamic ROI FB [m]
    staticROI = [-0.05, 0.1, -0.25, 0.1, 0.8, 1.1];     % Static ROI FB [m]
elseif strcmp(motion, 'LR')
    ROI = [-0.1, 0.45, -0.25, 0.1, 0.8, 1.35];            % Dynamic ROI LR [m]
    staticROI = [-0.1, 0.45, -0.25, 0.1, 0.8, 1.35];    % Static ROI LR [m]
else
    error('Invalid motion type! \t''LR'' and ''FB'' are valid input arguments.\n')
end

% Find files and sort by date
dynamicFiles = dir(fullfile(datasetFolderpath, '*.ply'));
[~, sortedIdx] = sort({dynamicFiles.name});

% Read in point-clouds
for i = 1:length(dynamicFiles)
    thisPc = pcread(fullfile(dynamicFiles(1).folder, dynamicFiles(sortedIdx(i)).name));
    indicesRoi = thisPc.findPointsInROI(ROI);
    dynamicPcs{i} = thisPc.select(indicesRoi);
%     dynamicPcs{i}.Color = uint8(repmat([0, 0, 255], height(dynamicPcs{i}.Color), 1));
    dynamicJsons{i} = jsondecode(fileread(fullfile(dynamicFiles(1).folder, ...
        strrep(dynamicFiles(sortedIdx(i)).name, '.ply', '.json'))));
end

player = pcplayer(ROI(1:2), ROI(3:4), ROI(5:6), 'MarkerSize', 15, 'BackgroundColor', 'w', 'VerticalAxis', 'Y', 'VerticalAxisDir', 'Up');

for i = 1:length(dynamicPcs)
    if i ~=length(dynamicPcs)
        timestampDiff = dynamicJsons{i+1}.FrameTimestamp - dynamicJsons{i}.FrameTimestamp;
    else
        timestampDiff = 0;
    end
    pc = pointCloud(dynamicPcs{i}.Location);
    player.view(pc)
    pause(timestampDiff/1e3)
end