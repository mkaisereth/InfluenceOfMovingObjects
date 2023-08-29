% placeObjCuboid - Place bounding box cuboid on a point cloud
%
% Description:
% ------------
%       Can only be called from dynAnalyis. Requires manual interaction for
%       first dynamic frame.
%
% Input Arguments:
% ----------------
%       pc - pointCloud
%           Point cloud object to position bounding box in
%       ROI - [1x6] vector
%           ROI used in this frame. Used for visualization only.
%
%       Optional Name-Value Pairs:
%           Interactive - true | (false)
%               Select if this placement must be interactive or automatic.
%               Interactive only used for first dynamic frame.
%           Speed - string | char array 
%               Speed of the dataset to evaluate. Must be the same format as
%               corresponding MotionFcn (E.g., '../MotionFcn/0.40_FB/..' must
%               resolve to 'speed = '0.40'')
%           Motion - string | char array
%               Motion of the dataset to evaluate. Must be the same format as
%               corresponding MotionFcn (E.g., '../MotionFcn/0.40_FB/..' must
%               resolve to 'motion = 'FB'')
%           StaticObjCuboid - cuboid
%               Cuboid object of the bounding box in the static frame.
%           FirstDynamicObjCuboid - cuboid
%               Cuboid object of the bounding box in the first dynamic
%               frame.
%           Timestamp - scalar
%               Timestamp difference of the second or third dynamic frame,
%               respective to the first dynamic frame.
%           PcStatic - pointCloud
%               Point cloud data of the static frame. Used to display the
%               static frame on top the second or third dynamic frame.
%
%   Output Arguments
%   ----------------
%       f1 - figure
%           Figure containing the point cloud and respective bounding box.
%       objCuboid - cuboid
%           Instance of the bounding box cuboid.

function [f1, objCuboid] = placeObjCuboid(pc, ROI, boxOrientation, varargin)
    p = inputParser();
    p.addOptional('Interactive', false);
    p.addOptional('Speed', []);
    p.addOptional('Motion', []);
    p.addOptional('StaticObjCuboid', []);
    p.addOptional('FirstDynamicObjCuboid', []);
    p.addOptional('Timestamp', []);
    p.addOptional('PcStatic', []);
    p.parse(varargin{:});
    
    interactive = p.Results.Interactive;
    speed = p.Results.Speed;
    motion = p.Results.Motion;
    staticObjCuboid = p.Results.StaticObjCuboid;
    firstDynamicObjCuboid = p.Results.FirstDynamicObjCuboid;
    timestamp = p.Results.Timestamp;
    pcStatic = p.Results.PcStatic;

    load('StaircaseData.mat', 'objDim');
    if strcmp(boxOrientation, 'Horizontal')
        xTemp = objDim.x;
        objDim.x = objDim.y;
        objDim.y = xTemp;
    end

    pc = pointCloud(pc.Location);
    % Show estimated object position in frame and opt user to change
    % this position
    f1 = figure;%('units','normalized','outerposition',[0 0 1 1]);%'Position', [2882, -78, 958, 1074]);
%     subplot(1,2,1);
    pcshow(pc, 'MarkerSize', 20, 'BackgroundColor', 'w');
    view(0, 270);
    xlabel('X [m]');
    ylabel('Y [m]');
    zlabel('Z [m]');
    xlim(ROI(1:2));
    ylim(ROI(3:4));
    zlim(ROI(5:6));
    set(findall(f1,'-property','FontSize'),'FontSize',15);
    axes = f1.CurrentAxes;
%     subplot(1,2,2);
%     pcshow(pc, 'MarkerSize', 50, 'BackgroundColor', 'w', 'VerticalAxisDir', 'down');
%     hold on;
%     xlabel('X [mm]');
%     ylabel('Y [mm]');
%     zlabel('Z [mm]');
%     view(90, 180);
%     set(findall(f1,'-property','FontSize'),'FontSize',15);

    % Positioning based on the principle that center of whole point cloud
    % is center of estimated object position. Errors when initial ROI
    % wasn't defined well
    cp = struct('x', (max(pc.Location(:,1)) + ...
        min(pc.Location(:,1))) / 2, ...
        'y', (max(pc.Location(:,2)) + ...
        min(pc.Location(:,2))) / 2, ...
        'z', (max(pc.Location(:,3)) + ...
        min(pc.Location(:,3))) / 2); % [m]

    if interactive && ~isempty(staticObjCuboid)
        objCuboid = drawcuboid(axes, 'Color', 'black', ...
            'Position', staticObjCuboid.Position, ...
            'InteractionsAllowed', 'translate', ...
            'Selected', 0, 'Label', 'Bounding Box');
    
        warning('off');
        f2 = uifigure();
        f2.Position(3:4) = [440, 160];
        uialert(f2, ['Close this window once the white box is aligned with the object.', ...
            'Focus on X and Y axis position and center the box as good as possible to the assumed real position.'], ...
            'Align ROI', 'Icon', 'info', 'CloseFcn', {'evalin(''caller'', ''uiresume(f2)'')'});
        uiwait(f2);
        delete(f2);
        warning('on');
    elseif isempty(staticObjCuboid)
        objCuboid = drawcuboid(axes, 'Color', 'white', ...
            'Position', [cp.x - (objDim.x / 2), ...
            cp.y - (objDim.y / 2), ...
            cp.z - (objDim.z / 2), ...
            objDim.x, objDim.y, objDim.z], ...
            'InteractionsAllowed', 'none', ...
            'Selected', 0, 'Label', 'Bounding Box');
    
%         warning('off');
%         f2 = uifigure();
%         f2.Position(3:4) = [440, 160];
%         uialert(f2, ['Close this window once the white box is aligned with the object.', ...
%             'Focus on X and Y axis position and center the box as good as possible to the assumed real position.'], ...
%             'Align ROI', 'Icon', 'info', 'CloseFcn', {'evalin(''caller'', ''uiresume(f2)'')'});
%         uiwait(f2);
%         delete(f2);
%         warning('on');
%         view(0, 270);
    else
        sFPosition = staticObjCuboid.Position(1:3) - staticObjCuboid.Position(4:6)/2;
        fMFPosition = firstDynamicObjCuboid.Position(1:3) - firstDynamicObjCuboid.Position(4:6)/2;

        [x, y, z] = findFramePosition(speed, motion, sFPosition, fMFPosition, timestamp);

        position = [staticObjCuboid.Position(1), ...
            staticObjCuboid.Position(2), ...
            staticObjCuboid.Position(3), ...
            objDim.x, objDim.y, objDim.z] + ...
            [x, y, z, 0, 0, 0];

        objCuboid = drawcuboid(axes, 'Color', 'white', ...
            'Position', position, ...
            'InteractionsAllowed', 'none', ...
            'Selected', 0, 'Label', 'Bounding Box');
        
        if ~isempty(pcStatic)
            rot = [1, 0, 0; 0, 1, 0; 0, 0, 1];
            trans = [x, y, z];
            tform = rigid3d(rot, trans);
            pcStatic = pcalign(pcStatic, tform);
            f2 = figure;
            pcshowpair(pcStatic, pc, 'BackgroundColor', 'w', 'MarkerSize', 20, 'VerticalAxisDir', 'down');
            xlabel('X [m]');
            ylabel('Y [m]');
            zlabel('Z [m]');
            xlim([position(1)-objDim.x/5,position(1)+objDim.x+objDim.x/5]);
            ylim([position(2)-objDim.y/5,position(2)+objDim.y+objDim.y/5]);
            zlim([position(3)-objDim.z/5,position(3)+objDim.z+objDim.z/5]);
            set(findall(f2,'-property','FontSize'),'FontSize',15);
        end
    end
end

