% findFramePosition - Find position of second and third dynamic frames
%
% Description:
% ------------
%       Can only be called from dynAnalyis and if a corresponding 
%       MotionFcn exists. Finds the offset in x-y-z axis of the second 
%       and third dynamic frames, in relation to the first dynamic frame.
%
% Input Arguments:
% ----------------
%       speed - string | char array 
%           Speed of the dataset to evaluate. Must be the same format as
%           corresponding MotionFcn (E.g., '../MotionFcn/0.40_FB/..' must
%           resolve to 'speed = '0.40'')
%       motion - string | char array
%           Motion of the dataset to evaluate. Must be the same format as
%           corresponding MotionFcn (E.g., '../MotionFcn/0.40_FB/..' must
%           resolve to 'motion = 'FB'')
%       sFPosition - [1x6] vector
%           Position of the static frame bounding box cuboid.
%       fMFPosition - [1x6] vector
%           Position of the first dynamic frame bounding box cuboid.
%       timestamp - scalar
%           Timestamp difference of the second or third dynamic frame,
%           respective to the first dynamic frame.
%
%   Output Arguments
%   ----------------
%       [x, y, z] - [1x3] vector
%           Translational offsets.

function [x, y, z] = findFramePosition(speed, motion, sFPosition, fMFPosition, timestamp)
    timestamp = timestamp/1e3; % Convert from [ms] to [s]
    path = mfilename('fullpath');
    fcnPath = fullfile(path, '..', 'MotionFcn');
    
    load(fullfile(fcnPath, [speed, '_', motion], ['fcn_', speed, '.mat']), 'f');
    
    offsetPos = abs(fMFPosition - sFPosition);

    options = optimset('Display','off');
    switch motion
        case 'LR'
            startTimestamp = (0.45/str2num(speed)) + (1/2)*(0.45/0.6)^2;
            fMFTimestamp = fzero(@(x) feval(f.x, x) - offsetPos(1), feval(f.x, startTimestamp), options);
            xOffset = fzero(@(x) feval(f.x, x) - 0.0001, feval(f.x, startTimestamp));
        case 'FB'
            startTimestamp = (0.35/str2num(speed)) + (1/2)*(0.35/0.6)^2;
            fMFTimestamp = fzero(@(x) feval(f.z, x) - offsetPos(3), feval(f.z, startTimestamp), options);
            xOffset = fzero(@(x) feval(f.z, x) - 0.0001, feval(f.z, startTimestamp));
        case 'C'
            startTimestamp = (0.35/str2num(speed)) + (1/2)*(0.35/0.6)^2;
            fMFTimestamp = fzero(@(x) feval(f.z, x) - offsetPos(3), feval(f.z, startTimestamp), options);
            xOffset = fzero(@(x) feval(f.z, x) - 0.0001, feval(f.z, startTimestamp));
        case 'HB'
            startTimestamp = (0.35/str2num(speed)) + (1/2)*(0.35/0.6)^2;
            fMFTimestamp = fzero(@(x) feval(f.z, x) - offsetPos(3), feval(f.z, startTimestamp), options);
            xOffset = fzero(@(x) feval(f.z, x) - 0.0001, feval(f.z, startTimestamp));
        case 'T'
            startTimestamp = (0.35/str2num(speed)) + (1/2)*(0.35/0.6)^2;
            fMFTimestampX = fzero(@(x) feval(f.x, x) - offsetPos(1), feval(f.x, startTimestamp), options);
            xOffsetX = fzero(@(x) feval(f.x, x) - 0.0001, feval(f.x, startTimestamp));
            fMFTimestampZ = fzero(@(x) feval(f.z, x) - offsetPos(3), feval(f.z, startTimestamp), options);
            xOffsetZ = fzero(@(x) feval(f.z, x) - 0.0001, feval(f.z, startTimestamp));
            if fMFTimestampX ~= fMFTimestampZ
                % Dunno yet but shouldn't happen. 'T' not yet tested
            end
            fMFTimestamp = fMFTimestampX;
            xOffset = xOffsetX;
    end
    
    % Calculate displacement using timestamp offset to first moving frame
    x = feval(f.x, fMFTimestamp + timestamp);
    y = feval(f.y, fMFTimestamp + timestamp);
    z = feval(f.z, fMFTimestamp + timestamp);
end
