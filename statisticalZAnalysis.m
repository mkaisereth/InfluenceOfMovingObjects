% statisticalZAnalysis - Conduct the Z-analysis
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
%           Results from a Z-analysis

function results = statisticalZAnalysis(staticFrameData, dynamicFrameData, varargin)
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
    accuracyMethod = p.Results.AccuracyMethod;

    binWidth = 20e-6; % [m] -> 20um

    % Adapt these to add more or less ROI to the analysis
    %     stepFocusLeft = 0;
    %     ROIFocusLeft = [];
    %     stepFocusRight = 1;
    %     ROIFocusRight = [3];

    stepFocusLeft = 2:9;
    ROIFocusLeft = [2 3];
    stepFocusRight = 2:9;
    ROIFocusRight = [3];

    load('StaircaseData.mat', ...
        'stepDepthsLeft', 'stepDepthsMiddle', 'stepDepthsRight');

    for stepSide = {'left', 'right'}
        for stepNum = 1:10
            for stepROI = 1:4
                if strcmp(stepSide, 'left')
                    if ~ismember(stepNum, stepFocusLeft) || ~ismember(stepROI, ROIFocusLeft)
                        continue;
                    end
                    if stepROI == 1 && stepNum ~=1
                        minSeparation = stepDepthsLeft(stepNum)/2;
                    elseif stepROI == 2
                        minSeparation = stepDepthsMiddle(stepNum)/2;
                    elseif stepROI == 3 && stepNum ~= 10
                        minSeparation = stepDepthsLeft(stepNum+1)/2;
                    end
                elseif strcmp(stepSide, 'right')
                    if ~ismember(stepNum, stepFocusRight) || ~ismember(stepROI, ROIFocusRight)
                        continue;
                    end
                    if stepROI == 1 && stepNum ~=1
                        minSeparation = stepDepthsRight(stepNum)/2;
                    elseif stepROI == 4
                        minSeparation = stepDepthsMiddle(stepNum)/2;
                    elseif stepROI == 3 && stepNum ~= 10
                        minSeparation = stepDepthsRight(stepNum+1)/2;
                    end
                end

                %% Static Frame
                if ~semiSilent && ~silent
                    fprintf('%s\nStarting static frame analysis - %s S%d-S%d - ROI #%d...\n%s\n\n', ...
                        repmat('-', 1, 100), stepSide{:}, stepNum, stepNum+1, stepROI, repmat('-', 1, 100));
                end

                static.data = pcdenoise(staticFrameData.z.steps(stepNum).(stepSide{:})(stepROI));

                static.histvals = static.data.Location(:, 3);
                static.edges = min(static.histvals)-binWidth:binWidth:max(static.histvals)+binWidth;

                if showStaticHistograms
                    % Plot raw histogram and peaks
                    static.f1 = figure;
                    histogram(static.histvals*1e3, static.edges*1e3, 'EdgeColor', 'c', 'FaceColor', 'c');
                    hold on;
                    title('Raw Histogram - Static Frame', ...
                        [stepSide{:}, ' S', num2str(stepNum), '-S', num2str(stepNum+1), ' - ROI #', num2str(stepROI)]);
                    xlabel('Z-Axis Distribution [mm]');
                    ylabel('Point Count [-]');
                    %                         dynamic.counts = dynamic.h.BinCounts;
                end
                static.counts = histcounts(static.histvals, static.edges);

                % Gather results for a single distribution case if a
                % ROI at the edge is being analysed
                if (stepNum == 1 && stepROI ~= 3) || (stepNum == 10 && stepROI == 3) || ...
                        (strcmp(stepSide{:}, 'left') && stepROI == 4) || ...
                        (strcmp(stepSide{:}, 'right') && stepROI == 2)
                    % Use islocalmax to find one dominant peak
                    static.L = islocalmax(static.counts, 'MaxNumExtrema', 1, ...
                        'SamplePoints', static.edges(1:end-1));
                    static.peakIdx = find(static.L);
                    static.dist = 0;
                    static.range = prctile(static.histvals, 90) - prctile(static.histvals, 10);
                    %                     static.range = range(static.histvals);
                else
                    % Use islocalmax to find two dominant peaks
                    %                     static.L = islocalmax(static.counts, 'MaxNumExtrema', 2, 'MinSeparation', minSeparation, ...
                    %                         'SamplePoints', static.edges(1:end-1));
                    %                     static.peakIdx = find(static.L);

                    %%% NEW SUGGESTION -> CONVOLUTION %%%
                    x = 0:binWidth:binWidth*5;
                    g = gaussmf(x, [prctile(x, 90), mean(x)]);
                    c = conv(static.counts, g, 'same');
                    c = c*(max(static.counts)/max(c));
                    if showStaticHistograms
                        hold on;
                        plot(static.edges(2:end)*1e3, c);
                    end
                    static.L = islocalmax(c, 'MaxNumExtrema', 2, 'MinSeparation', minSeparation, ...
                        'SamplePoints', static.edges(1:end-1));
                    static.peakIdx = find(static.L);
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                    if length(static.peakIdx) < 2
                        warning(fprintf('\nSplitting static frame failed - %s S%d-S%d - ROI #%d...\n\n', ...
                            stepSide{:}, stepNum, stepNum+1, stepROI));
                        static.dist = 0;
                        static.median = median(static.histvals);
                        static.range = prctile(static.histvals, 90) - prctile(static.histvals, 10);
                        %                         static.range = range(static.histvals);
                    else
                        % Default values
                        static.median = median(static.histvals);
                        static.range = prctile(static.histvals, 90) - prctile(static.histvals, 10);
                        %                         static.range = range(static.histvals);

                        % Split between peaks to extract closer and further Step
                        static.splitValue = mean([mean([static.edges(static.peakIdx(1)); ...
                            static.edges(static.peakIdx(1)+1)], 1); ...
                            mean([static.edges(static.peakIdx(2)); static.edges(static.peakIdx(2)+1)], 1)]);
                        static.splitIdx = find(static.edges >= static.splitValue, 1);
                        if showStaticHistograms
                            plot(mean([static.edges(static.peakIdx); static.edges(static.peakIdx+1)], 1)*1e3, ...
                                static.counts(static.peakIdx), '*k', 'MarkerSize', 15, 'LineWidth', 2);
                            xline(mean([static.edges(static.splitIdx); static.edges(static.splitIdx+1)], 1)*1e3, ...
                                'LineWidth', 2, 'Color', 'r');
                            set(findall(static.f1,'-property','FontSize'),'FontSize',15);
                        end

                        static.closer.counts = static.counts(1:static.splitIdx-1);
                        static.further.counts = static.counts(static.splitIdx:end);

                        static.closer.step = static.histvals(static.histvals <= static.edges(static.splitIdx - 1));
                        static.closer.edges = static.edges(static.edges <= static.edges(static.splitIdx))*1e3;

                        static.further.step = static.histvals(static.histvals >= static.edges(static.splitIdx));
                        static.further.edges = static.edges(static.edges >= static.edges(static.splitIdx))*1e3;

                        static.closer.median = median(static.closer.step)*1e3;
                        static.further.median = median(static.further.step)*1e3;
                        if strcmp(accuracyMethod, 'MedianDist')
                            static.dist = static.further.median - static.closer.median;
                        else
                            static.dist = diff(mean([static.edges(static.peakIdx); static.edges(static.peakIdx+1)], 1));
                        end
                        static.closer.range = (prctile(static.closer.step, 90) - prctile(static.closer.step, 10))*1e3;
                        %                         static.closer.range = range(static.closer.step)*1e3;
                        static.further.range = (prctile(static.further.step, 90) - prctile(static.further.step, 10))*1e3;
                        %                         static.further.range = range(static.further.step)*1e3;

                        if ~semiSilent && ~silent
                            fprintf('\t\tRelative distance of median values: \t%fmm\n', static.dist);
                            fprintf('\t\tCloser step (%d#) \trange: \t%fmm\n', ...
                                length(static.closer.step), static.closer.range);
                            fprintf('\t\tFurther step (%d#)\trange: \t%fmm\n', ...
                                length(static.further.step), static.further.range);
                            fprintf('\t\tCloser step (%d#) \tMAD: \t%fmm\n', ...
                                length(static.closer.step), mad(static.closer.step, 1)*1e3);
                            fprintf('\t\tFurther step (%d#)\tMAD: \t%fmm\n', ...
                                length(static.further.step), mad(static.further.step, 1)*1e3);
                        end

                        if showStaticHistograms
                            % Plot split histogram with median and range bounds
                            %                             static.f2 = figure();

                            %                             subplot(2, 1, 1);
                            %                             histogram('BinEdges', static.closer.edges, 'BinCounts', ...
                            %                                 static.closer.counts, 'EdgeAlpha', 0.0, 'FaceColor', 'b');
                            %                             hold on;
                            plot(static.closer.median, 0, 'xk', 'LineWidth', 2, 'MarkerSize', 15);
                            plot([prctile(static.closer.step, 90)*1e3, ...
                                prctile(static.closer.step, 10)*1e3], ...
                                [0, 0], '|k', 'LineWidth', 2, 'MarkerSize', 15);
                            %                             plot(mean([static.edges(static.peakIdx(1)); static.edges(static.peakIdx(1)+1)], 1)*1e3, ...
                            %                                 static.counts(static.peakIdx(1)), 'x', 'MarkerSize', 20, 'LineWidth', 5);
                            % plot([median(static.closer.step)+mad(static.closer.step,1), median(static.closer.step)-mad(static.closer.step,1)]*1e3 , [0, 0], 'xm', 'LineWidth', 5, 'MarkerSize', 20);
                            %                             legend({'Histogram', 'Median', '80th Quantile', 'Detected Peak', 'MAD'});
                            %                             title('Closer Step Distribution');
                            %                             xlabel('Z-Axis Distribution [mm]');
                            %                             ylabel('Point Count [-]');

                            %                             subplot(2, 1, 2);
                            %                             histogram('BinEdges', static.further.edges, 'BinCounts', ...
                            %                                 static.further.counts, 'EdgeAlpha', 0.0, 'FaceColor', 'b');
                            %                             hold on;
                            plot(static.further.median, 0, 'xk', 'LineWidth', 2, 'MarkerSize', 15);
                            plot([prctile(static.further.step, 90)*1e3, ...
                                prctile(static.further.step, 10)*1e3], ...
                                [0, 0], '|k', 'LineWidth', 2, 'MarkerSize', 15);
                            %                             plot(mean([static.edges(static.peakIdx(2)); static.edges(static.peakIdx(2)+1)], 1)*1e3, ...
                            %                                 static.counts(static.peakIdx(2)), 'x', 'MarkerSize', 20, 'LineWidth', 5);
                            % plot([median(static.further.step)+mad(static.further.step,1), median(static.further.step)-mad(static.further.step,1)]*1e3 , [0, 0], 'xm', 'LineWidth', 5, 'MarkerSize', 20);
                            %                             legend({'Histogram', 'Median', '80th Quantile', 'Detected Peak', 'MAD'});
                            %                             title('Further Step Distribution');
                            %                             xlabel('Z-Axis Distribution [mm]');
                            %                             ylabel('Point Count [-]');
                            %                             sgtitle(['Split Histogram - Static Frame', ...
                            %                                 ' - ', stepSide{:}, ' S', num2str(stepNum), '-S', ...
                            %                                 num2str(stepNum+1), ' - ROI #', num2str(stepROI)]);
                            %                             set(findall(static.f2,'-property','FontSize'),'FontSize',15);
                            set(findall(static.f1,'-property','FontSize'),'FontSize',15);
                        end
                    end
                end

                %% Dynamic frame
                for frameNum = 1:length(dynamicFrameData)
                    if ~semiSilent && ~silent
                        fprintf('%s\nStarting dynamic frame analysis of frame #%d - %s S%d-S%d - ROI #%d...\n%s\n\n', ...
                            repmat('-', 1, 100), frameNum, stepSide{:}, stepNum, stepNum+1, stepROI, repmat('-', 1, 100));
                    end

                    % Special case when the motion artefacts are as heavy
                    % as that one step disappears completely (evaluated as
                    % if it's one single distribution with infinite distance
                    % and range
                    if isempty(dynamicFrameData{frameNum}.z.steps(stepNum).(stepSide{:})(stepROI).Location)
                        warning('\nExtraction of ROI in dynamic frame failed - %s S%d-S%d - ROI #%d...\n\n', ...
                            stepSide{:}, stepNum, stepNum+1, stepROI);
                        dynamic.dist = inf;
                        dynamic.range = inf;
                        dynamic.histvals = 0;
                        dynamic.peakIdx = 0;
                    else
                        dynamic.data = pcdenoise(dynamicFrameData{frameNum}.z.steps(stepNum).(stepSide{:})(stepROI));

                        dynamic.histvals = dynamic.data.Location(:, 3);
                        dynamic.edges = min(dynamic.histvals)-binWidth:binWidth:max(dynamic.histvals)+binWidth;

                        if showDynamicHistograms
                            % Plot raw histogram and peaks
                            dynamic.f1 = figure;
                            histogram(dynamic.histvals*1e3, dynamic.edges*1e3, 'EdgeColor', 'c', 'FaceColor', 'c');
                            hold on;
                            title('Raw Histogram - Dynamic Frame', ['Frame #', num2str(frameNum), ...
                                ' - ', stepSide{:}, ' S', num2str(stepNum), '-S', num2str(stepNum+1), ' - ROI #', num2str(stepROI)]);
                            xlabel('Z-Axis Distribution [mm]');
                            ylabel('Point Count [-]');
                            %                         dynamic.counts = dynamic.h.BinCounts;
                        end
                        dynamic.counts = histcounts(dynamic.histvals, dynamic.edges);

                        %                         % Gather results for a single distribution case if a
                        %                         % ROI at the edge is being analysed
                        %                         if (stepNum == 1 && stepROI ~= 3) || (stepNum == 10 && stepROI == 3) || ...
                        %                                 (strcmp(stepSide{:}, 'left') && stepROI == 4) || ...
                        %                                 (strcmp(stepSide{:}, 'right') && stepROI == 2)
                        %                             % Use islocalmax to find one dominant peak
                        %                             dynamic.L = islocalmax(dynamic.counts, 'MaxNumExtrema', 1, ...
                        %                                 'SamplePoints', dynamic.edges(1:end-1));
                        %                             dynamic.peakIdx = find(dynamic.L);
                        %                             dynamic.dist = 0;
                        %                             dynamic.median = median(dynamic.histvals);
                        %                             dynamic.range = prctile(dynamic.histvals, 90) - prctile(dynamic.histvals, 10);
                        %                             %                         dynamic.range = range(dynamic.histvals);
                        %                         else
                        % Use islocalmax to find two dominant peaks
                        %                         dynamic.L = islocalmax(dynamic.counts, 'MaxNumExtrema', 2, 'MinSeparation', minSeparation, ...
                        %                             'SamplePoints', dynamic.edges(1:end-1));
                        %                         dynamic.peakIdx = find(dynamic.L);

                        %%% NEW SUGGESTION -> CONVOLUTION %%%
                        x = 0:binWidth:binWidth*30;
                        g = gaussmf(x, [prctile(x, 90), mean(x)]);
                        c = conv(dynamic.counts, g, 'same');
                        c = c*(max(dynamic.counts)/max(c));
                        if showDynamicHistograms
                            hold on;
                            plot(dynamic.edges(1:end-1)*1e3, c);
                        end
                        dynamic.L = islocalmax(c, 'MaxNumExtrema', 2, 'MinSeparation', minSeparation, ...
                            'SamplePoints', dynamic.edges(1:end-1));
                        dynamic.peakIdx = find(dynamic.L);
                        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                        if length(dynamic.peakIdx) < 2
                            warning('\nSplitting dynamic frame failed - %s S%d-S%d - ROI #%d...\n\n', ...
                                stepSide{:}, stepNum, stepNum+1, stepROI);
                            dynamic.dist = inf;
                            dynamic.range = prctile(dynamic.histvals, 90) - prctile(dynamic.histvals, 10);
                            %                             dynamic.range = range(dynamic.histvals);
                        else
                            % Split between peaks to extract closer and further Step
                            dynamic.splitValue = mean([mean([dynamic.edges(dynamic.peakIdx(1)); ...
                                dynamic.edges(dynamic.peakIdx(1)+1)], 1); ...
                                mean([dynamic.edges(dynamic.peakIdx(2)); dynamic.edges(dynamic.peakIdx(2)+1)], 1)]);
                            dynamic.splitIdx = find(dynamic.edges >= dynamic.splitValue, 1);
                            if showDynamicHistograms
                                plot(mean([dynamic.edges(dynamic.peakIdx); dynamic.edges(dynamic.peakIdx+1)], 1)*1e3, ...
                                    dynamic.counts(dynamic.peakIdx), '*k', 'MarkerSize', 15, 'LineWidth', 2);
                                xline(mean([dynamic.edges(dynamic.splitIdx); dynamic.edges(dynamic.splitIdx+1)], 1)*1e3, ...
                                    'LineWidth', 2, 'Color', 'r');
                                set(findall(dynamic.f1,'-property','FontSize'),'FontSize',15);
                            end

                            dynamic.closer.counts = dynamic.counts(1:dynamic.splitIdx-1);
                            dynamic.further.counts = dynamic.counts(dynamic.splitIdx:end);

                            dynamic.closer.step = dynamic.histvals(dynamic.histvals <= dynamic.edges(dynamic.splitIdx - 1));
                            dynamic.closer.edges = dynamic.edges(dynamic.edges <= dynamic.edges(dynamic.splitIdx))*1e3;

                            dynamic.further.step = dynamic.histvals(dynamic.histvals >= dynamic.edges(dynamic.splitIdx));
                            dynamic.further.edges = dynamic.edges(dynamic.edges >= dynamic.edges(dynamic.splitIdx))*1e3;

                            dynamic.closer.median = median(dynamic.closer.step)*1e3;
                            dynamic.further.median = median(dynamic.further.step)*1e3;
                            if strcmp(accuracyMethod, 'MedianDist')
                                dynamic.dist = dynamic.further.median - dynamic.closer.median;
                            else
                                dynamic.dist = diff(mean([dynamic.edges(dynamic.peakIdx); dynamic.edges(dynamic.peakIdx+1)], 1));
                            end
                            dynamic.closer.range = (prctile([dynamic.closer.step], 90) - prctile([dynamic.closer.step], 10))*1e3;
                            %                             dynamic.closer.range = range(dynamic.closer.step)*1e3;
                            dynamic.further.range = (prctile([dynamic.further.step], 90) - prctile([dynamic.further.step], 10))*1e3;
                            %                             dynamic.further.range = range(dynamic.further.step)*1e3;

                            if ~semiSilent && ~silent
                                fprintf('\t\tRelative distance of median values: \t%fmm\n', dynamic.dist);
                                fprintf('\t\tCloser step (%d#) \trange: \t%fmm\n', ...
                                    length(dynamic.closer.step), dynamic.closer.range);
                                fprintf('\t\tFurther step (%d#)\trange: \t%fmm\n', ...
                                    length(dynamic.further.step), dynamic.further.range);
                                fprintf('\t\tCloser step (%d#) \tMAD: \t%fmm\n', ...
                                    length(dynamic.closer.step), mad(dynamic.closer.step, 1)*1e3);
                                fprintf('\t\tFurther step (%d#)\tMAD: \t%fmm\n', ...
                                    length(dynamic.further.step), mad(dynamic.further.step, 1)*1e3);
                            end

                            if showDynamicHistograms
                                % Plot split histogram with median and range bounds
                                %                                 dynamic.f2 = figure();

                                %                                 subplot(2, 1, 1);
                                %                                 histogram('BinEdges', dynamic.closer.edges, 'BinCounts', ...
                                %                                     dynamic.closer.counts, 'EdgeAlpha', 0.0, 'FaceColor', 'b');
                                %                                 hold on;
                                plot(dynamic.closer.median, 0, 'xk', 'LineWidth', 2, 'MarkerSize', 15);
                                plot([prctile(dynamic.closer.step, 90)*1e3, ...
                                    prctile(dynamic.closer.step, 10)*1e3], ...
                                    [0, 0], '|k', 'LineWidth', 2, 'MarkerSize', 15);
                                %                                 plot(mean([dynamic.edges(dynamic.peakIdx(1)); dynamic.edges(dynamic.peakIdx(1)+1)], 1)*1e3, ...
                                %                                     dynamic.counts(dynamic.peakIdx(1)), 'x', 'MarkerSize', 20, 'LineWidth', 5);
                                % plot([median(dynamic.closer.step)+mad(dynamic.closer.step,1), median(dynamic.closer.step)-mad(dynamic.closer.step,1)]*1e3 , [0, 0], 'xm', 'LineWidth', 5, 'MarkerSize', 20);
                                %                                 legend({'Histogram', 'Median', '80th Quantile', 'Detected Peak', 'MAD'});
                                %                                 title('Closer Step Distribution');
                                %                                 xlabel('Z-Axis Distribution [mm]');
                                %                                 ylabel('Point Count [-]');

                                %                                 subplot(2, 1, 2);
                                %                                 histogram('BinEdges', dynamic.further.edges, 'BinCounts', ...
                                %                                     dynamic.further.counts, 'EdgeAlpha', 0.0, 'FaceColor', 'b');
                                %                                 hold on;
                                plot(dynamic.further.median, 0, 'xk', 'LineWidth', 2, 'MarkerSize', 15);
                                plot([prctile(dynamic.further.step, 90)*1e3, ...
                                    prctile(dynamic.further.step, 10)*1e3], ...
                                    [0, 0], '|k', 'LineWidth', 2, 'MarkerSize', 15);
                                %                                 plot(mean([dynamic.edges(dynamic.peakIdx(2)); dynamic.edges(dynamic.peakIdx(2)+1)], 1)*1e3, ...
                                %                                     dynamic.counts(dynamic.peakIdx(2)), 'x', 'MarkerSize', 20, 'LineWidth', 5);
                                % plot([median(dynamic.further.step)+mad(dynamic.further.step,1), median(dynamic.further.step)-mad(dynamic.further.step,1)]*1e3 , [0, 0], 'xm', 'LineWidth', 5, 'MarkerSize', 20);
                                %                                 legend({'Histogram', 'Median', '80th Quantile', 'Detected Peak', 'MAD'});
                                %                                 title('Further Step Distribution');
                                %                                 xlabel('Z-Axis Distribution [mm]');
                                %                                 ylabel('Point Count [-]');
                                %                                 sgtitle(['Split Histogram - Dynamic Frame #', num2str(frameNum), ...
                                %                                     ' - ', stepSide{:}, ' S', num2str(stepNum), '-S', ...
                                %                                     num2str(stepNum+1), ' - ROI #', num2str(stepROI)]);
                                %                                 set(findall(dynamic.f2,'-property','FontSize'),'FontSize',15);
                                set(findall(dynamic.f1,'-property','FontSize'),'FontSize',15);
                            end
                        end
                        %                         end
                    end

                    %% Comparison
                    if ~semiSilent && ~silent
                        fprintf('%s\nStarting comparison of frame #%d - %s S%d-S%d - ROI #%d...\n%s\n\n', ...
                            repmat('-', 1, 100), frameNum, stepSide{:}, stepNum, stepNum+1, stepROI, repmat('-', 1, 100));
                    end

                    % Gather results for a single distribution case if a
                    % ROI at the edge is being analysed or only one peak
                    % could be made out in the static or dynamic frame
                    if (stepNum == 1 && stepROI ~= 3) || (stepNum == 10 && stepROI == 3) || ...
                            (strcmp(stepSide{:}, 'left') && stepROI == 4) || ...
                            (strcmp(stepSide{:}, 'right') && stepROI == 2) || ...
                            length(dynamic.peakIdx) < 2 || length(static.peakIdx) < 2
                        % Store absolute step size error of dynamic to
                        % static frame for accuracy statement
                        intResults(frameNum).stepSizeErr.(stepSide{:})(stepNum, stepROI) = ...
                            abs(static.dist - dynamic.dist);

                        % Store range of both distributions for precision
                        % uncertainty statement
                        intResults(frameNum).staticRange.(stepSide{:})(stepNum, stepROI) = ...
                            {[static.range, 0]};
                        intResults(frameNum).dynamicRange.(stepSide{:})(stepNum, stepROI) = ...
                            {[dynamic.range, 0]};
                        intResults(frameNum).rangeErr.(stepSide{:})(stepNum, stepROI) = ...
                            {[abs(static.range - dynamic.range), 0]};

                        % Store relative density of dynamic to static
                        % distributions to prove ROI placement
                        intResults(frameNum).relDensity.(stepSide{:})(stepNum, stepROI) = ...
                            {[length(dynamic.histvals) / length(static.histvals), 0]};

                        % Store point cloud of static and dynamic
                        % distributions for any further processing
                        intResults(frameNum).staticCloserSteps.(stepSide{:})(stepNum, stepROI) = ...
                            {static.histvals};
                        intResults(frameNum).staticFurtherSteps.(stepSide{:})(stepNum, stepROI) = ...
                            {0};
                        intResults(frameNum).dynamicCloserSteps.(stepSide{:})(stepNum, stepROI) = ...
                            {dynamic.histvals};
                        intResults(frameNum).dynamicFurtherSteps.(stepSide{:})(stepNum, stepROI) = ...
                            {0};

                        if ~semiSilent && ~silent
                            fprintf('\t\tStep size error: \t\t\t\t%fmm\n', abs(static.dist - dynamic.dist));
                            fprintf('\t\trange difference: \t%fmm\n', abs(static.range - dynamic.range));
                            fprintf('\t\tRelative density: \t%f%%\n', ...
                                (length(dynamic.histvals) / length(static.histvals)) * 1e2);
                        end
                    else
                        % Store absolute step size error of dynamic to
                        % static frame for accuracy statement
                        intResults(frameNum).stepSizeErr.(stepSide{:})(stepNum, stepROI) = ...
                            abs(static.dist - dynamic.dist);

                        % Store range of both distributions for precision
                        % uncertainty statement
                        intResults(frameNum).staticRange.(stepSide{:})(stepNum, stepROI) = ...
                            {[static.closer.range, static.further.range]};
                        intResults(frameNum).dynamicRange.(stepSide{:})(stepNum, stepROI) = ...
                            {[dynamic.closer.range, dynamic.further.range]};

                        % Store absolute difference of dynamic ranges to
                        % static ones for a further precision uncertainty
                        % statement
                        intResults(frameNum).rangeErr.(stepSide{:})(stepNum, stepROI) = ...
                            {[abs(static.closer.range - dynamic.closer.range), ...
                            abs(static.further.range - dynamic.further.range)]};

                        %                         % Store relative density of dynamic to static
                        %                         % distributions to prove ROI placement
                        %                         intResults(frameNum).relDensity.(stepSide{:})(stepNum, stepROI) = ...
                        %                             [(length(dynamic.closer.step) / length(static.closer.step)) / ...
                        %                             (length(dynamic.further.step) / length(static.further.step))];

                        % Store point cloud of static and dynamic
                        % distributions for any further processing
                        intResults(frameNum).staticCloserSteps.(stepSide{:})(stepNum, stepROI) = ...
                            {static.closer.step};
                        intResults(frameNum).staticFurtherSteps.(stepSide{:})(stepNum, stepROI) = ...
                            {static.further.step};
                        intResults(frameNum).dynamicCloserSteps.(stepSide{:})(stepNum, stepROI) = ...
                            {dynamic.closer.step};
                        intResults(frameNum).dynamicFurtherSteps.(stepSide{:})(stepNum, stepROI) = ...
                            {dynamic.further.step};

                        if ~semiSilent && ~silent
                            fprintf('\t\tStep size error: \t\t\t\t%fmm\n', abs(static.dist - dynamic.dist));
                            fprintf('\t\tRange difference closer step: \t%fmm\n\t\tRange difference further step: \t%fmm\n', ...
                                abs(static.closer.range - dynamic.closer.range), abs(static.further.range - dynamic.further.range));
                            %                             fprintf('\t\tRelative density closer step: \t%f%%\n\t\tRelative density further step: \t%f%%\n', ...
                            %                                 (length(dynamic.closer.step) / length(static.closer.step)) * 1e2, ...
                            %                                 (length(dynamic.further.step) / length(static.further.step)) * 1e2);
                        end

                        if showDynamicHistograms && showStaticHistograms
                            h = figure();
                            subplot(1, 2, 1);
                            static.data.Color = uint8(repmat([255, 0, 0], height(static.data.Location), 1));
                            pcshow(static.data, 'MarkerSize', 40, 'BackgroundColor', 'w', 'VerticalAxisDir', 'down');
                            title('Static Point Cloud of ROI', 'Color', [0, 0, 0]);
                            xlabel('X [mm]');
                            ylabel('Y [mm]');
                            zlabel('Z [mm]');
                            if stepROI == 1 || stepROI == 3
                                view(90, 180);
                            else
                                view(0, 180);
                            end
                            subplot(1, 2, 2);
                            dynamic.data.Color = uint8(repmat([255, 0, 0], height(dynamic.data.Location), 1));
                            pcshow(dynamic.data, 'MarkerSize', 40, 'BackgroundColor', 'w', 'VerticalAxisDir', 'down');
                            title('Dynamic Point Cloud of ROI');
                            xlabel('X [mm]');
                            ylabel('Y [mm]');
                            zlabel('Z [mm]');
                            if stepROI == 1 || stepROI == 3
                                view(90, 180);
                            else
                                view(0, 180);
                            end
                            sgtitle(['Raw Point Cloud of Step ROI - Static and Dynamic Frame #', ...
                                num2str(frameNum), ' - ', stepSide{:}, ' S', num2str(stepNum), ...
                                '-S',num2str(stepNum+1), ' - ROI #', num2str(stepROI)]);
                            set(findall(h,'-property','FontSize'),'FontSize',15);
                        end
                    end
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
            for stepROI = 1:4
                if strcmp(stepSide, 'left')
                    if ~ismember(stepNum, stepFocusLeft) || ~ismember(stepROI, ROIFocusLeft)
                        continue;
                    end
                else
                    if ~ismember(stepNum, stepFocusRight) || ~ismember(stepROI, ROIFocusRight)
                        continue;
                    end
                end

                frameResults(resultCount).name = sprintf('%s S%d-S%d - ROI #%d', stepSide{:}, stepNum, stepNum+1, stepROI);
                frameResults(resultCount).stepSizeErr = mean([...
                    intResults(1).stepSizeErr.(stepSide{:})(stepNum, stepROI), ...
                    intResults(2).stepSizeErr.(stepSide{:})(stepNum, stepROI), ...
                    intResults(3).stepSizeErr.(stepSide{:})(stepNum, stepROI)]);
                frameResults(resultCount).stepSizeErrArr = [...
                    intResults(1).stepSizeErr.(stepSide{:})(stepNum, stepROI), ...
                    intResults(2).stepSizeErr.(stepSide{:})(stepNum, stepROI), ...
                    intResults(3).stepSizeErr.(stepSide{:})(stepNum, stepROI)];
                frameResults(resultCount).rangeErr = mean([...
                    intResults(1).rangeErr.(stepSide{:}){stepNum, stepROI}, ...
                    intResults(2).rangeErr.(stepSide{:}){stepNum, stepROI}, ...
                    intResults(3).rangeErr.(stepSide{:}){stepNum, stepROI}]);
                frameResults(resultCount).rangeErrArr = [...
                    intResults(1).rangeErr.(stepSide{:}){stepNum, stepROI}, ...
                    intResults(2).rangeErr.(stepSide{:}){stepNum, stepROI}, ...
                    intResults(3).rangeErr.(stepSide{:}){stepNum, stepROI}];
                %                 frameResults(resultCount).relDensity = mean([...
                %                     intResults(1).relDensity.(stepSide{:})(stepNum, stepROI), ...
                %                     intResults(2).relDensity.(stepSide{:})(stepNum, stepROI), ...
                %                     intResults(3).relDensity.(stepSide{:})(stepNum, stepROI)]);
                resultCount = resultCount + 1;
            end
        end
    end

    results.frameResults = frameResults;
    results.meanStepSizeErr = mean([results.frameResults(:).stepSizeErr]);
    results.minStepSizeErr = min([results.frameResults(:).stepSizeErr]);
    results.maxStepSizeErr = max([results.frameResults(:).stepSizeErr]);
    results.meanRangeErr = mean([results.frameResults(:).rangeErr]);
    results.minRangeErr = min([results.frameResults(:).rangeErr]);
    results.maxRangeErr = max([results.frameResults(:).rangeErr]);
    %     results.meanRelDensity = mean([results.frameResults(:).relDensity]);
    %     results.minRelDensity = min([results.frameResults(:).relDensity]);

    if ~silent
        fprintf('\t\tMean step size error: \t%fmm\n', results.meanStepSizeErr);
        fprintf('\t\tMax step size error: \t%fmm\n', results.maxStepSizeErr);
        fprintf('\t\tMean range error: \t\t%fmm\n', results.meanRangeErr);
        fprintf('\t\tMax range error: \t\t%fmm\n', results.maxRangeErr);
        %         fprintf('\t\tMean relative density: \t%f%%\n', results.meanRelDensity*1e2);
        %         fprintf('\t\tMin relative density: \t%f%%\n', results.minRelDensity*1e2);
    end
end
