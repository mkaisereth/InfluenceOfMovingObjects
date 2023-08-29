% findPCsOnStaircase - Place all ROI cuboids on a point cloud
%
% Description:
% ------------
%       Can only be called from dynAnalyis with a prior call to
%       placeObjCuboid and placeRoiCuboids. Places the ROI on top of the
%       staircase point cloud and extracts the points in it. ROI placement
%       is based on positions of initially placed ones and
%       'StaircaseData.mat'.
%
% Input Arguments:
% ----------------
%       f1 - figure
%           Figure where the point cloud, bounding box and initial ROI are visible
%       pc - pointcloud
%           Point cloud data of this frame.
%       roiCuboids - cuboid
%           Instance of the bounding box of this point cloud frame
%
%   Output Arguments
%   ----------------
%       frameData - struct
%           Structure containing point clouds in all the ROI.

function frameData = findPCsOnStaircase(f1, pc, roiCuboids, boxOrientation)
    load('StaircaseData.mat', ...
        'stepWidth', 'stepLength', 'stepDepthsLeft', 'stepDepthsRight');

    axes = f1.CurrentAxes;

    % Z-Analysis
    for i = 1:length(roiCuboids.z) % Place right boxes and extract first eight ROI (4 left, 4 right)
        indRoiLeft = pc.findPointsInROI([...
            roiCuboids.z(i).Position(1), roiCuboids.z(i).Position(1) + roiCuboids.z(i).Position(4), ...
            roiCuboids.z(i).Position(2), roiCuboids.z(i).Position(2) + roiCuboids.z(i).Position(5), ...
            roiCuboids.z(i).Position(3), roiCuboids.z(i).Position(3) + roiCuboids.z(i).Position(6)]);
        frameData.z.steps(1).left(i) = pc.select(indRoiLeft);

        if strcmp(boxOrientation, 'Vertical')
            drawcuboid(axes, 'Color', 'green', ...
                'Position', [roiCuboids.z(i).Position(1) + stepWidth, roiCuboids.z(i).Position(2), roiCuboids.z(i).Position(3), ...
                roiCuboids.z(i).Position(4), ...
                roiCuboids.z(i).Position(5), ...
                roiCuboids.z(i).Position(6)], ...
                'Label', num2str(i), ...
                'EdgeAlpha', 0.2, 'FaceAlpha', 0.1, 'LabelAlpha', 0.2);
            indRoiRight = pc.findPointsInROI([...
                roiCuboids.z(i).Position(1) + stepWidth, roiCuboids.z(i).Position(1) + roiCuboids.z(i).Position(4) + stepWidth, ...
                roiCuboids.z(i).Position(2), roiCuboids.z(i).Position(2) + roiCuboids.z(i).Position(5), ...
                roiCuboids.z(i).Position(3), roiCuboids.z(i).Position(3) + roiCuboids.z(i).Position(6)]);
        else
            drawcuboid(axes, 'Color', 'green', ...
                'Position', [roiCuboids.z(i).Position(1), roiCuboids.z(i).Position(2) + stepWidth, roiCuboids.z(i).Position(3), ...
                roiCuboids.z(i).Position(4), ...
                roiCuboids.z(i).Position(5), ...
                roiCuboids.z(i).Position(6)], ...
                'Label', num2str(i), ...
                'EdgeAlpha', 0.2, 'FaceAlpha', 0.1, 'LabelAlpha', 0.2);
            indRoiRight = pc.findPointsInROI([...
                roiCuboids.z(i).Position(1), roiCuboids.z(i).Position(1) + roiCuboids.z(i).Position(4), ...
                roiCuboids.z(i).Position(2) + stepWidth, roiCuboids.z(i).Position(2) + roiCuboids.z(i).Position(5) + stepWidth, ...
                roiCuboids.z(i).Position(3), roiCuboids.z(i).Position(3) + roiCuboids.z(i).Position(6)]);
        end
        frameData.z.steps(1).right(i) = pc.select(indRoiRight);
    end
    if strcmp(boxOrientation, 'Vertical')
        for j = 2:length(stepDepthsRight)
            for i = 1:length(roiCuboids.z)
                indRoiLeft = pc.findPointsInROI([...
                    roiCuboids.z(i).Position(1), roiCuboids.z(i).Position(1) + roiCuboids.z(i).Position(4), ...
                    roiCuboids.z(i).Position(2) + (j-1)*stepLength, roiCuboids.z(i).Position(2) + roiCuboids.z(i).Position(5) + (j-1)*stepLength, ...
                    roiCuboids.z(i).Position(3) + sum(stepDepthsLeft(1:j)), roiCuboids.z(i).Position(3) + roiCuboids.z(i).Position(6) + sum(stepDepthsLeft(1:j))]);
                frameData.z.steps(j).left(i) = pc.select(indRoiLeft);

                drawcuboid(axes, 'Color', 'red', ...
                    'Position', [roiCuboids.z(i).Position(1), roiCuboids.z(i).Position(2) + (j-1)*stepLength, roiCuboids.z(i).Position(3) + sum(stepDepthsLeft(1:j)), ...
                    roiCuboids.z(i).Position(4), ...
                    roiCuboids.z(i).Position(5), ...
                    roiCuboids.z(i).Position(6)], ...
                    'Label', num2str(i), ...
                    'EdgeAlpha', 0.2, 'FaceAlpha', 0.1, 'LabelAlpha', 0.2);

                indRoiRight = pc.findPointsInROI([...
                    roiCuboids.z(i).Position(1) + stepWidth, roiCuboids.z(i).Position(1) + roiCuboids.z(i).Position(4) + stepWidth, ...
                    roiCuboids.z(i).Position(2) + (j-1)*stepLength, roiCuboids.z(i).Position(2) + roiCuboids.z(i).Position(5) + (j-1)*stepLength, ...
                    roiCuboids.z(i).Position(3) + sum(stepDepthsRight(1:j)), roiCuboids.z(i).Position(3) + roiCuboids.z(i).Position(6) + sum(stepDepthsRight(1:j))]);

                drawcuboid(axes, 'Color', 'green', ...
                    'Position', [roiCuboids.z(i).Position(1) + stepWidth, roiCuboids.z(i).Position(2) + (j-1)*stepLength, roiCuboids.z(i).Position(3) + sum(stepDepthsRight(1:j)), ...
                    roiCuboids.z(i).Position(4), ...
                    roiCuboids.z(i).Position(5), ...
                    roiCuboids.z(i).Position(6)], ...
                    'Label', num2str(i), ...
                    'EdgeAlpha', 0.2, 'FaceAlpha', 0.1, 'LabelAlpha', 0.2);

                frameData.z.steps(j).right(i) = pc.select(indRoiRight);
            end
        end
    else
        for j = 2:length(stepDepthsRight)
            for i = 1:length(roiCuboids.z)
                indRoiLeft = pc.findPointsInROI([...
                    roiCuboids.z(i).Position(1) - (j-1)*stepLength, roiCuboids.z(i).Position(1) + roiCuboids.z(i).Position(4) - (j-1)*stepLength, ...
                    roiCuboids.z(i).Position(2), roiCuboids.z(i).Position(2) + roiCuboids.z(i).Position(5), ...
                    roiCuboids.z(i).Position(3) + sum(stepDepthsLeft(1:j)), roiCuboids.z(i).Position(3) + roiCuboids.z(i).Position(6) + sum(stepDepthsLeft(1:j))]);
                frameData.z.steps(j).left(i) = pc.select(indRoiLeft);

                drawcuboid(axes, 'Color', 'red', ...
                    'Position', [roiCuboids.z(i).Position(1) - (j-1)*stepLength, roiCuboids.z(i).Position(2), roiCuboids.z(i).Position(3) + sum(stepDepthsLeft(1:j)), ...
                    roiCuboids.z(i).Position(4), ...
                    roiCuboids.z(i).Position(5), ...
                    roiCuboids.z(i).Position(6)], ...
                    'Label', num2str(i), ...
                    'EdgeAlpha', 0.2, 'FaceAlpha', 0.1, 'LabelAlpha', 0.2);

                indRoiRight = pc.findPointsInROI([...
                    roiCuboids.z(i).Position(1) - (j-1)*stepLength, roiCuboids.z(i).Position(1) + roiCuboids.z(i).Position(4) - (j-1)*stepLength, ...
                    roiCuboids.z(i).Position(2) + stepWidth, roiCuboids.z(i).Position(2) + roiCuboids.z(i).Position(5) + stepWidth, ...
                    roiCuboids.z(i).Position(3) + sum(stepDepthsRight(1:j)), roiCuboids.z(i).Position(3) + roiCuboids.z(i).Position(6) + sum(stepDepthsRight(1:j))]);

                drawcuboid(axes, 'Color', 'green', ...
                    'Position', [roiCuboids.z(i).Position(1) - (j-1)*stepLength, roiCuboids.z(i).Position(2) + stepWidth, roiCuboids.z(i).Position(3) + sum(stepDepthsRight(1:j)), ...
                    roiCuboids.z(i).Position(4), ...
                    roiCuboids.z(i).Position(5), ...
                    roiCuboids.z(i).Position(6)], ...
                    'Label', num2str(i), ...
                    'EdgeAlpha', 0.2, 'FaceAlpha', 0.1, 'LabelAlpha', 0.2);

                frameData.z.steps(j).right(i) = pc.select(indRoiRight);
            end
        end
    end

    % XY-Analysis
    roiLeft = [...
        roiCuboids.xy.Position(1), roiCuboids.xy.Position(1) + roiCuboids.xy.Position(4), ...
        roiCuboids.xy.Position(2), roiCuboids.xy.Position(2) + roiCuboids.xy.Position(5), ...
        roiCuboids.xy.Position(3), roiCuboids.xy.Position(3) + roiCuboids.xy.Position(6)];
    indRoiLeft = pc.findPointsInROI(roiLeft);

    frameData.xy.roi(1).left = roiLeft;
    frameData.xy.steps(1).left = pc.select(indRoiLeft);

    if strcmp(boxOrientation, 'Vertical')
        roiRight = [...
            roiCuboids.xy.Position(1) + stepWidth, roiCuboids.xy.Position(1) + roiCuboids.xy.Position(4) + stepWidth, ...
            roiCuboids.xy.Position(2), roiCuboids.xy.Position(2) + roiCuboids.xy.Position(5), ...
            roiCuboids.xy.Position(3), roiCuboids.xy.Position(3) + roiCuboids.xy.Position(6)];
        indRoiRight = pc.findPointsInROI(roiRight);

        drawcuboid(axes, 'Color', 'green', ...
            'Position', [roiCuboids.xy.Position(1) + stepWidth, roiCuboids.xy.Position(2), roiCuboids.xy.Position(3), ...
            roiCuboids.xy.Position(4), ...
            roiCuboids.xy.Position(5), ...
            roiCuboids.xy.Position(6)], ...
            'Label', num2str(1), ...
            'EdgeAlpha', 0.2, 'FaceAlpha', 0.1, 'LabelAlpha', 0.2);
    else
        roiRight = [...
            roiCuboids.xy.Position(1), roiCuboids.xy.Position(1) + roiCuboids.xy.Position(4), ...
            roiCuboids.xy.Position(2) + stepWidth, roiCuboids.xy.Position(2) + roiCuboids.xy.Position(5) + stepWidth, ...
            roiCuboids.xy.Position(3), roiCuboids.xy.Position(3) + roiCuboids.xy.Position(6)];
        indRoiRight = pc.findPointsInROI(roiRight);

        drawcuboid(axes, 'Color', 'green', ...
            'Position', [roiCuboids.xy.Position(1), roiCuboids.xy.Position(2) + stepWidth, roiCuboids.xy.Position(3), ...
            roiCuboids.xy.Position(4), ...
            roiCuboids.xy.Position(5), ...
            roiCuboids.xy.Position(6)], ...
            'Label', num2str(1), ...
            'EdgeAlpha', 0.2, 'FaceAlpha', 0.1, 'LabelAlpha', 0.2);
    end

    frameData.xy.roi(1).right = roiRight;
    frameData.xy.steps(1).right = pc.select(indRoiRight);

    if strcmp(boxOrientation, 'Vertical')
        for j = 2:length(stepDepthsRight)
            roiLeft = [...
                roiCuboids.xy.Position(1), roiCuboids.xy.Position(1) + roiCuboids.xy.Position(4), ...
                roiCuboids.xy.Position(2) + (j-1)*stepLength, roiCuboids.xy.Position(2) + roiCuboids.xy.Position(5) + (j-1)*stepLength, ...
                roiCuboids.xy.Position(3) + sum(stepDepthsLeft(1:j)), roiCuboids.xy.Position(3) + roiCuboids.xy.Position(6) + sum(stepDepthsLeft(1:j))];
            indRoiLeft = pc.findPointsInROI(roiLeft);

            drawcuboid(axes, 'Color', 'red', ...
                'Position', [roiCuboids.xy.Position(1), roiCuboids.xy.Position(2) + (j-1)*stepLength, roiCuboids.xy.Position(3) + sum(stepDepthsLeft(1:j)), ...
                roiCuboids.xy.Position(4), ...
                roiCuboids.xy.Position(5), ...
                roiCuboids.xy.Position(6)], ...
                'Label', num2str(j), ...
                'EdgeAlpha', 0.2, 'FaceAlpha', 0.1, 'LabelAlpha', 0.2);

            frameData.xy.roi(j).left = roiLeft;
            frameData.xy.steps(j).left = pc.select(indRoiLeft);

            roiRight = [...
                roiCuboids.xy.Position(1) + stepWidth, roiCuboids.xy.Position(1) + roiCuboids.xy.Position(4) + stepWidth, ...
                roiCuboids.xy.Position(2) + (j-1)*stepLength, roiCuboids.xy.Position(2) + roiCuboids.xy.Position(5) + (j-1)*stepLength, ...
                roiCuboids.xy.Position(3) + sum(stepDepthsRight(1:j)), roiCuboids.xy.Position(3) + roiCuboids.xy.Position(6) + sum(stepDepthsRight(1:j))];
            indRoiRight = pc.findPointsInROI(roiRight);

            drawcuboid(axes, 'Color', 'green', ...
                'Position', [roiCuboids.xy.Position(1) + stepWidth, roiCuboids.xy.Position(2) + (j-1)*stepLength, roiCuboids.xy.Position(3) + sum(stepDepthsRight(1:j)), ...
                roiCuboids.xy.Position(4), ...
                roiCuboids.xy.Position(5), ...
                roiCuboids.xy.Position(6)], ...
                'Label', num2str(j), ...
                'EdgeAlpha', 0.2, 'FaceAlpha', 0.1, 'LabelAlpha', 0.2);

            frameData.xy.roi(j).right = roiRight;
            frameData.xy.steps(j).right = pc.select(indRoiRight);
        end
    else
        for j = 2:length(stepDepthsRight)
            roiLeft = [...
                roiCuboids.xy.Position(1) - (j-1)*stepLength, roiCuboids.xy.Position(1) - roiCuboids.xy.Position(4) + (j-1)*stepLength, ...
                roiCuboids.xy.Position(2), roiCuboids.xy.Position(2) + roiCuboids.xy.Position(5), ...
                roiCuboids.xy.Position(3) + sum(stepDepthsLeft(1:j)), roiCuboids.xy.Position(3) + roiCuboids.xy.Position(6) + sum(stepDepthsLeft(1:j))];
            indRoiLeft = pc.findPointsInROI(roiLeft);

            drawcuboid(axes, 'Color', 'red', ...
                'Position', [roiCuboids.xy.Position(1) - (j-1)*stepLength, roiCuboids.xy.Position(2), roiCuboids.xy.Position(3) + sum(stepDepthsLeft(1:j)), ...
                roiCuboids.xy.Position(4), ...
                roiCuboids.xy.Position(5), ...
                roiCuboids.xy.Position(6)], ...
                'Label', num2str(j), ...
                'EdgeAlpha', 0.2, 'FaceAlpha', 0.1, 'LabelAlpha', 0.2);

            frameData.xy.roi(j).left = roiLeft;
            frameData.xy.steps(j).left = pc.select(indRoiLeft);

            roiRight = [...
                roiCuboids.xy.Position(1) - (j-1)*stepLength, roiCuboids.xy.Position(1) - roiCuboids.xy.Position(4) + (j-1)*stepLength, ...
                roiCuboids.xy.Position(2) + stepWidth, roiCuboids.xy.Position(2) + roiCuboids.xy.Position(5) + stepWidth, ...
                roiCuboids.xy.Position(3) + sum(stepDepthsRight(1:j)), roiCuboids.xy.Position(3) + roiCuboids.xy.Position(6) + sum(stepDepthsRight(1:j))];
            indRoiRight = pc.findPointsInROI(roiRight);

            drawcuboid(axes, 'Color', 'green', ...
                'Position', [roiCuboids.xy.Position(1) - (j-1)*stepLength, roiCuboids.xy.Position(2) + stepWidth, roiCuboids.xy.Position(3) + sum(stepDepthsRight(1:j)), ...
                roiCuboids.xy.Position(4), ...
                roiCuboids.xy.Position(5), ...
                roiCuboids.xy.Position(6)], ...
                'Label', num2str(j), ...
                'EdgeAlpha', 0.2, 'FaceAlpha', 0.1, 'LabelAlpha', 0.2);

            frameData.xy.roi(j).right = roiRight;
            frameData.xy.steps(j).right = pc.select(indRoiRight);
        end
    end
end
