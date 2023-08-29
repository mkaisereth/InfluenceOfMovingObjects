% findIntervalAndSaveFit - Interatively select start and end position for fitting
%
% Description:
% ------------
%       Interactive function where the tracked marker position is
%       displayed. The dominant amplitdue must therefore be viewed at and
%       the respective x-axis position clicked when the crosshair shows up.
%       First click the start then the end position.
%
% Input Arguments:
% ----------------
%        M1 - struct
%           Struct containing cartesian positions of tracked marker M1
%       timestamps - vector
%           Vector of the timestamps at which the cartesian positions are
%           stored
%       speed - string | char array 
%           Speed of the dataset to evaluate. Must be the same format as
%           corresponding MotionFcn (E.g., '../MotionFcn/0.40_FB/..' must
%           resolve to 'speed = '0.40'')
%       motion - string | char array
%           Motion of the dataset to evaluate. Must be the same format as
%           corresponding MotionFcn (E.g., '../MotionFcn/0.40_FB/..' must
%           resolve to 'motion = 'FB'')

function findIntervalAndSaveFit(M1, timestamps, speed, motion)
    figure('units','normalized','outerposition',[0 0 1 1]);
    plot(timestamps/1e3, M1(:, 1), '-*r', ...
        timestamps/1e3,  M1(:, 2), '-*g', ...
        timestamps/1e3,  M1(:, 3), '-*b', 'LineWidth', 2);
    grid minor;
    hold on;
    xlabel('Ticks [s]');
    ylabel('Amplitude [m]');
    legend({'M1 : x', 'M1 : y', 'M1 : z'});
    [x, ~] = ginput(2);
    
    xIdx = [find(timestamps >= x(1)*1e3, 1), find(timestamps >= x(2)*1e3, 1)];
    yIdx = [find(timestamps >= x(1)*1e3, 1), find(timestamps >= x(2)*1e3, 1)];
    zIdx = [find(timestamps >= x(1)*1e3, 1), find(timestamps >= x(2)*1e3, 1)];
    
    f.x = fit((timestamps(xIdx(1):xIdx(2))- timestamps(xIdx(1)))/1e3, ...
        M1(xIdx(1):xIdx(2), 1) - M1(xIdx(1), 1), ...
        'smoothingspline', 'SmoothingParam', 1);
    f.y = fit((timestamps(yIdx(1):yIdx(2))- timestamps(yIdx(1)))/1e3, ...
        M1(yIdx(1):yIdx(2), 2) - M1(yIdx(1), 2), ...
        'smoothingspline', 'SmoothingParam', 1);
    f.z = fit((timestamps(zIdx(1):zIdx(2))- timestamps(zIdx(1)))/1e3, ...
        M1(zIdx(1):zIdx(2), 3) - M1(zIdx(1), 3), ...
        'smoothingspline', 'SmoothingParam', 1);
    
    figure('units','normalized','outerposition',[0 0 1 1]);
    plot((timestamps(xIdx(1):xIdx(2))- timestamps(xIdx(1)))/1e3, ...
        M1(xIdx(1):xIdx(2), 1) - M1(xIdx(1), 1), '-*r', ...
        (timestamps(yIdx(1):yIdx(2))- timestamps(yIdx(1)))/1e3, ...
        M1(yIdx(1):yIdx(2), 2) - M1(yIdx(1), 2), '-*g', ...
        (timestamps(zIdx(1):zIdx(2))- timestamps(zIdx(1)))/1e3, ...
        M1(zIdx(1):zIdx(2), 3) - M1(zIdx(1), 3), '-*b', 'LineWidth', 2);
    grid minor;
    hold on;
    xlabel('Ticks [s]');
    ylabel('Amplitude [m]');
    legend({'M1 : x', 'M1 : y', 'M1 : z'});
    
    plot(f.x);
    plot(f.y);
    plot(f.z);
    ylim([-0.1, 0.4]);
    
    save([pwd, '\', speed, '_', motion, '\fcn_', speed, '.mat'], "f");
end