% statisticalXYAnalysis - Conduct the X-Y-analysis
%
% Description:
% ------------
%       Requires intermediate data from a dynAnalysis. This data can be loaded 
%       from a dynamic dataset folder if 'frameData.mat' exists. Else a
%       dynAnalysis must be run beforehand.
%
% Input Arguments:
% ----------------
%       staticFrameData - string | char array
%           Struct containing point cloud data of ROI on a staircase in a 
%           static frame (see description).
%       dynamicFrameData - string | char array
%           Struct containing point cloud data of ROI on a staircase in a
%           dynamic frame (see description).
%
%       Optional Name-Value Pairs:
%           SemiSilent - false | (true)
%               Select to not print ROI-analysis results but only
%               frame-analysis and dynamic-analysis results.
%           Silent - false | (true)
%               Select to only print the dynamic-analysis results.
%           ShowDynamicHistograms - false | (true)
%               Select to plot all the raw and split histograms of all the
%               ROI in every dynamic frame. WARNING: This is a lot!
%           ShowStaticHistograms - false | (true)
%               Select to plot all the raw and split histograms of all the
%               ROI in the static frame. WARNING: This is a lot!
%
%   Output Arguments
%   ----------------
%       results - struct
%           Results from a X-Y-analysis

function results = statisticalXYAnalysis(staticFrameData, dynamicFrameData, varargin)
    p = inputParser();
    p.addOptional('SemiSilent', false);
    p.addOptional('Silent', false);
    p.addOptional('ShowDynamicHistograms', false);
    p.addOptional('ShowStaticHistograms', false);
    p.addOptional('AccuracyMethod', 'MedianDist', @(s) any(strcmp(s, {'MedianDist', 'PeakDist'})));
    p.parse(varargin{:});

    semiSilent = p.Results.SemiSilent;
    silent = p.Results.Silent;
    showDynamicHistograms = p.Results.ShowDynamicHistograms;
    showStaticHistograms = p.Results.ShowStaticHistograms;

    binWidth = 600e-6; % [m] -> 600um

    % Adapt these to add more or less ROI to the analysis
    stepFocusLeft = 1:10;
    stepFocusRight = 1:10;

    for stepSide = {'left', 'right'}
        for stepNum = 1:10
            if strcmp(stepSide, 'left')
                if ~ismember(stepNum, stepFocusLeft)
                    continue;
                end
            elseif strcmp(stepSide, 'right')
                if ~ismember(stepNum, stepFocusRight)
                    continue;
                end
            end

            %% Static Frame
            if ~semiSilent && ~silent
                fprintf('%s\nStarting static frame analysis - %s step #%d...\n%s\n\n', ...
                    repmat('-', 1, 100), stepSide{:}, stepNum, repmat('-', 1, 100));
            end

            static.data = pcdenoise(staticFrameData.xy.steps(stepNum).(stepSide{:}));
            static.roi = staticFrameData.xy.roi(stepNum).(stepSide{:});

            % X-Axis
            static.x.histvals = static.data.Location(:, 1);
            syncOffset.x = min(static.x.histvals) - min(static.roi(1:2));
            static.x.edges = min(static.x.histvals)+(binWidth/2 - syncOffset.x):binWidth:max(static.x.histvals)-(binWidth/2 + syncOffset.x);

            static.x.counts = histcounts(static.x.histvals, static.x.edges);

            meanCounts = mean(static.x.counts);


            if showStaticHistograms
                %  Plot histogram
                static.f1 = figure('Position', [356 50 1020 840]);

                subplot(2,1,1);
                histogram('BinEdges', static.x.edges, 'BinCounts', static.x.counts, 'EdgeAlpha', 0.0, 'FaceColor', 'b');
                hold on;
%                 plot(static.x.edges(1), meanCounts, 'xr', ...
%                     [static.x.edges(1), static.x.edges(1)], ...
%                     [mean(static.x.counts) + std(static.x.counts), mean(static.x.counts) - std(static.x.counts)], 'xg');
                plot(static.x.edges(2), max(static.x.counts), 'xg', 'LineWidth', 5, 'MarkerSize', 20); % - mean(max(static.x.counts) - static.x.counts)
                legend({'Histogram', 'Range'});
                title('X Distribution');
                xlabel('X-Axis Distribution [mm]');
                ylabel('Point Cloud Count [-]');
            end

            % Y-Axis
            static.y.histvals = static.data.Location(:, 2);
            syncOffset.y = min(static.y.histvals) - min(static.roi(3:4));
            static.y.edges = min(static.y.histvals)+(binWidth/2 - syncOffset.y):binWidth:max(static.y.histvals)-(binWidth/2 + syncOffset.y);

            static.y.counts = histcounts(static.y.histvals, static.y.edges);

            if showStaticHistograms
                %  Plot histogram
%                 static.f2 = figure('Name', ['Histogram Y - Static Frame', ...
%                     ' - ', stepSide{:}, ' Step #', num2str(stepNum)]);

                subplot(2,1,2);
                histogram('BinEdges', static.y.edges, 'BinCounts', static.y.counts, 'EdgeAlpha', 0.0, 'FaceColor', 'b');
                hold on;
%                 plot(static.y.edges(1), mean(static.y.counts), 'xr', ...
%                     [static.y.edges(1), static.y.edges(1)], ...
%                     [mean(static.y.counts) + std(static.y.counts), mean(static.y.counts) - std(static.y.counts)], 'xg');
                plot(static.y.edges(2), max(static.y.counts), 'xg', 'LineWidth', 5, 'MarkerSize', 20); %  - mean(max(static.y.counts) - static.y.counts)
                legend({'Histogram', 'Range'});
%                 legend({'Y Distribution', 'Mean', 'STD'});
                title('Y Distribution');
                xlabel('Y-Axis Distribution [mm]');
                ylabel('Point Cloud Count [-]');
                sgtitle(['Histogram - Static Frame', ...
                    ' - ', stepSide{:}, ' Step #', num2str(stepNum)]);
                set(findall(static.f1,'-property','FontSize'),'FontSize',15);
            end

            %% Dynamic frame
            for frameNum = 1:length(dynamicFrameData)
                if ~semiSilent && ~silent
                    fprintf('%s\nStarting dynamic frame analysis of frame #%d - %s step #%d...\n%s\n\n', ...
                        repmat('-', 1, 100), frameNum, stepSide{:}, stepNum, repmat('-', 1, 100));
                end

                if ~isempty(dynamicFrameData{frameNum}.xy.steps(stepNum).(stepSide{:}).Location)
                    dynamic.data = pcdenoise(dynamicFrameData{frameNum}.xy.steps(stepNum).(stepSide{:}));
                    % X-Axis
                    dynamic.x.histvals = dynamic.data.Location(:, 1);
                    dynamic.x.edges = min(dynamic.x.histvals)-(binWidth/2 - syncOffset.x):binWidth:max(dynamic.x.histvals)+(binWidth/2 - syncOffset.x);
                    % Y-Axis
                    dynamic.y.histvals = dynamic.data.Location(:, 2);
                    dynamic.y.edges = min(dynamic.y.histvals)-(binWidth/2 - syncOffset.y):binWidth:max(dynamic.y.histvals)+(binWidth/2 - syncOffset.y);
                else
                    dynamic.x.histvals = [];
                    dynamic.y.histvals = [];
                end
                
                % X-Axis
                if ~isempty(dynamic.x.histvals) && length(dynamic.x.edges) >= 2
                    dynamic.x.counts = histcounts(dynamic.x.histvals, dynamic.x.edges);

                    intResults(frameNum).meanError.(stepSide{:})(stepNum).x = abs(mean(dynamic.x.counts) - mean(static.x.counts));
%                     intResults(frameNum).distErr.(stepSide{:})(stepNum).x = abs(range(dynamic.x.counts) - range(static.x.counts));
                    intResults(frameNum).distErr.(stepSide{:})(stepNum).x = abs(mean(max(dynamic.x.counts) - dynamic.x.counts) - mean(max(static.x.counts) - static.x.counts)); %mean(max(static.x.counts) - static.x.counts))

                    if showDynamicHistograms
                        %  Plot histogram
                        dynamic.f1 = figure('Position', [356 50 1020 840]);
    
                        subplot(2,1,1);
                        histogram('BinEdges', dynamic.x.edges, 'BinCounts', dynamic.x.counts, 'EdgeAlpha', 0.0, 'FaceColor', 'b');
                        hold on;
%                         plot(dynamic.x.edges(1), mean(dynamic.x.counts), 'xr', ...
%                             [dynamic.x.edges(1), dynamic.x.edges(1)], ...
%                             [mean(dynamic.x.counts) + std(dynamic.x.counts), mean(dynamic.x.counts) - std(dynamic.x.counts)], 'xg');
                        plot(dynamic.x.edges(1), max(dynamic.x.counts) - mean(max(dynamic.x.counts) - dynamic.x.counts), 'xg', 'LineWidth', 5, 'MarkerSize', 20);
                        legend({'Histogram', 'Range'});
%                         legend({'X Distribution', 'Mean', 'STD'});
                        title('X Distribution');
                        xlabel('X-Axis Distribution [mm]');
                        ylabel('Point Cloud Count [-]');
                    end
                else
                    intResults(frameNum).meanError.(stepSide{:})(stepNum).x = [];
                    intResults(frameNum).distErr.(stepSide{:})(stepNum).x = abs(0 - max(static.x.counts));
                end

                % Y-Axis                
                if ~isempty(dynamic.y.histvals) && length(dynamic.y.edges) >= 2
                    dynamic.y.counts = histcounts(dynamic.y.histvals, dynamic.y.edges);
    
                    intResults(frameNum).meanError.(stepSide{:})(stepNum).y = abs(mean(dynamic.y.counts) - mean(static.y.counts));
%                     intResults(frameNum).distErr.(stepSide{:})(stepNum).y = abs(range(dynamic.y.counts) - range(static.y.counts));
                    intResults(frameNum).distErr.(stepSide{:})(stepNum).y = abs(mean(max(dynamic.y.counts) - dynamic.y.counts) - mean(max(static.y.counts) - static.y.counts)); % mean(max(static.y.counts) - static.y.counts))
    
                    if showDynamicHistograms
                        %  Plot histogram
%                         dynamic.f2 = figure('Name', ['Histogram Y - Dynamic Frame', ...
%                             ' - ', stepSide{:}, ' Step #', num2str(stepNum)]);
    
                        subplot(2,1,2);
                        histogram('BinEdges', dynamic.y.edges, 'BinCounts', dynamic.y.counts, 'EdgeAlpha', 0.0, 'FaceColor', 'b');
                        hold on;
%                         plot(dynamic.y.edges(1), std(dynamic.y.counts), 'xr', ...
%                             [dynamic.y.edges(1), dynamic.y.edges(1)], ...
%                             [mean(dynamic.y.counts) + std(dynamic.y.counts), mean(dynamic.y.counts) - std(dynamic.y.counts)], 'xg');
                        plot(dynamic.y.edges(1), max(dynamic.y.counts) - mean(max(dynamic.y.counts) - dynamic.y.counts), 'xg', 'LineWidth', 5, 'MarkerSize', 20);
                        legend({'Histogram', 'Range'});
%                         legend({'Y Distribution', 'Mean', 'STD'});
                        title('Y Distribution');
                        xlabel('Y-Axis Distribution [mm]');
                        ylabel('Point Cloud Count [-]');
                        sgtitle(['Histogram - Dynamic Frame', ...
                            ' - ', stepSide{:}, ' Step #', num2str(stepNum)]);
                        set(findall(dynamic.f1,'-property','FontSize'),'FontSize',15);
                    end
                else
                    intResults(frameNum).meanError.(stepSide{:})(stepNum).y = [];
                    intResults(frameNum).distErr.(stepSide{:})(stepNum).y = abs(0 - max(static.x.counts));
                end
            end
        end
    end
    %% Summary
    if ~semiSilent && ~silent
        fprintf('%s\nStarting summary of dynamic Z-analysis...\n%s\n\n', repmat('-', 1, 100), repmat('-', 1, 100));
    end
    resultCount = 1;
    for stepSide = {'left', 'right'}
        for stepNum = 1:10
            if strcmp(stepSide, 'left')
                if ~ismember(stepNum, stepFocusLeft)
                    continue;
                end
            else
                if ~ismember(stepNum, stepFocusRight)
                    continue;
                end
            end

            numOfResults = length([...
                intResults(1).distErr.(stepSide{:})(stepNum).x, ...
                intResults(2).distErr.(stepSide{:})(stepNum).x, ...
                intResults(3).distErr.(stepSide{:})(stepNum).x]);

            if numOfResults ~= 3
%                 warning('%d frame(s) contain(s) no points in the ROI of %s step #%d!', ...
%                     3-numOfResults, stepSide{:}, stepNum);
                frameResults(resultCount).emptyCounter = 3-numOfResults;
            else
                frameResults(resultCount).emptyCounter = 0;
            end
            frameResults(resultCount).name = sprintf('%s step #%d', stepSide{:}, stepNum);
            frameResults(resultCount).distErr = [mean([...
                intResults(1).distErr.(stepSide{:})(stepNum).x, ...
                intResults(2).distErr.(stepSide{:})(stepNum).x, ...
                intResults(3).distErr.(stepSide{:})(stepNum).x], 'omitnan'), ...
                mean([ ...
                intResults(1).distErr.(stepSide{:})(stepNum).y, ...
                intResults(2).distErr.(stepSide{:})(stepNum).y, ...
                intResults(3).distErr.(stepSide{:})(stepNum).y], 'omitnan')];
            resultCount = resultCount + 1;
        end
    end

    results.frameResults = frameResults;
    results.meandistErr = mean(vertcat(results.frameResults.distErr), 'omitnan');
    results.mindistErr = min(vertcat(results.frameResults.distErr));
    results.maxdistErr = max(vertcat(results.frameResults.distErr));
    results.emptyROIs = sum([results.frameResults.emptyCounter]);

    if ~silent
        fprintf('\t\tMean distribution error: \t[%f, %f]\n', results.meandistErr);
        fprintf('\t\tMin distribution error: \t\t[%f, %f]\n', results.mindistErr);
        fprintf('\t\tMax distribution error: \t\t[%f, %f]\n', results.maxdistErr);
        fprintf('\t\tNumber of empty ROIs: \t\t%d\n', results.emptyROIs);
    end
end
