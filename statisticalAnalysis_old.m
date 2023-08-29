function statisticalAnalysis(staticFrameData, dynamicFrameData, stepDepthsLeft, stepDepthsMiddle, stepDepthsRight)
    binWidth = 20e-6; % [m] -> 20um
    
    for stepSide = {'left', 'right'}
        for stepNum = 1:10
            for stepROI = 1:4
                static.data = pcdenoise(staticFrameData.steps(stepNum).(stepSide{:})(stepROI));
                
               if strcmp(stepSide, 'left')
                    if stepROI == 1 && stepNum ~=1
                        minSeparation = stepDepthsLeft(stepNum)/2.5;
                    elseif stepROI == 2
                        minSeparation = stepDepthsMiddle(stepNum)/2.5;
                    elseif stepROI == 3 && stepNum ~= 10
                        minSeparation = stepDepthsLeft(stepNum+1)/2.5;
                    end
                else
                    if stepROI == 1 && stepNum ~=1
                        minSeparation = stepDepthsRight(stepNum)/2.5;
                    elseif stepROI == 4
                        minSeparation = stepDepthsMiddle(stepNum)/2.5;
                    elseif stepROI == 3 && stepNum ~= 10
                        minSeparation = stepDepthsRight(stepNum+1)/2.5;
                    end
                end

                %% Static Frame
                fprintf('%s\nStarting static frame analysis - %s step #%d - ROI #%d...\n%s\n\n', ...
                    repmat('-', 1, 100), stepSide{:}, stepNum, stepROI, repmat('-', 1, 100));

                static.histvals = static.data.Location(:, 3);
                static.edges = min(static.histvals)-binWidth:binWidth:max(static.histvals)+binWidth;

%                 % Plot raw histogram and peaks
%                 static.f1 = figure;
%                 static.h = histogram(static.histvals, static.edges);
%                 hold on;
%                 title('Raw Histogram - Static Frame', ['Static Frame', ...
%                     ' - ', stepSide{:}, ' Step #', num2str(stepNum), ' - ROI #', num2str(stepROI)]);
%                 xlabel('Z-Axis Distance Distribution [mm]');
%                 ylabel('Point Cloud Count [-]');
%                 static.counts = static.h.BinCounts;
                static.counts = histcounts(static.histvals, static.edges);

                if (stepNum == 1 && stepROI ~= 3) || (stepNum == 10 && stepROI == 3) || (strcmp(stepSide{:}, 'left') && stepROI == 4) || (strcmp(stepSide{:}, 'right') && stepROI == 2)
                    % Use islocalmax to find one dominant peak
                    static.L = islocalmax(static.counts, 'MaxNumExtrema', 1, ...
                        'SamplePoints', static.edges(1:end-1));
                    static.peakIdx = find(static.L);
%                     plot(mean(static.edges(static.peakIdx)), ...
%                         static.counts(static.peakIdx), 'x', 'MarkerSize', 10, 'LineWidth', 2);
                    static.dist = 0;
                    static.iqr = iqr(static.histvals);
                else
                    % Use islocalmax to find two dominant peaks
                    [static.L, ~] = islocalmax(static.counts, 'MaxNumExtrema', 2, 'MinSeparation', minSeparation, 'SamplePoints', static.edges(1:end-1));
                    peakIdx = find(static.L);
%                     plot(mean([static.edges(peakIdx); static.edges(peakIdx+1)], 1), static.counts(peakIdx), 'x', 'MarkerSize', 10, 'LineWidth', 2);

                    % Extract values of closer and further gauss
                    startIdxCloser = peakIdx(1) - find(flip(static.counts(1:peakIdx(1)))==0, 1, 'first') + 2;
                    if isempty(startIdxCloser)
                        startIdxCloser = 1;
                    end
                    endIdxCloser = peakIdx(1) + find(static.counts(peakIdx(1):end)==0, 1, 'first') - 2;
                    if isempty(endIdxCloser)
                        endIdxCloser = length(static.counts);
                    end
                    static.closer.counts = zeros(1, length(static.counts));
                    static.closer.counts(startIdxCloser:endIdxCloser) = static.counts(startIdxCloser:endIdxCloser);
                    static.closer.step = static.histvals(static.histvals > static.edges(startIdxCloser-1) & static.histvals < static.edges(endIdxCloser+1));
                    static.closer.edges = static.edges;

%                     if length(peakIdx) == 1
%                         furtherGauss = static.closer.step;
%                         furtherGaussCounts = static.closer.counts;
%                     else
                        startIdxFurther = peakIdx(2) - find(flip(static.counts(1:peakIdx(2)))==0, 1, 'first') + 2;
                        if isempty(startIdxFurther)
                            startIdxFurther = 1;
                        end
                        endIdxFurther = peakIdx(2) + find(static.counts(peakIdx(2):end)==0, 1, 'first') - 2;
                        if isempty(endIdxFurther)
                            endIdxFurther = length(static.counts);
                        end
                        static.further.counts = zeros(1, length(static.counts));
                        static.further.counts(startIdxFurther:endIdxFurther) = static.counts(startIdxFurther:endIdxFurther);
                        static.further.step = static.histvals(static.histvals > static.edges(startIdxFurther-1) & static.histvals < static.edges(endIdxFurther+1));
%                     end

                    if isequal(static.closer.step, static.further.step)
%                         static.outliers.count = static.counts - static.closer.counts;
                        static.outliers.step = static.histvals(~ismember(static.histvals, static.closer.step));
                    else
                        % Store outliers
%                         static.outliers.count = static.counts - static.closer.counts - static.further.counts;
                        static.outliers.step = static.histvals(~ismember(static.histvals, static.closer.step) & ~ismember(static.histvals, static.further.step));
                    end

                    %     [static.closer.h, static.closer.p] = adtest(static.closer.step);
                    %     if static.closer.h
                    %         warning(sprintf('The test for normality failed for the closer step with p = %f', static.closer.p));
                    %     end
                    %
                    %     [static.further.h, static.further.p] = adtest(static.further.step);
                    %     if static.further.h
                    %         warning(sprintf('The test for normality failed for the further step with p = %f', static.further.p));
                    %     end
    
                    static.closer.median = median(static.closer.step)*1e3;
                    static.further.median = median(static.further.step)*1e3;
                    static.dist = static.further.median - static.closer.median;
                    static.closer.iqr = iqr(static.closer.step)*1e3;
                    static.further.iqr = iqr(static.further.step)*1e3;
                    static.outliers.percentage = (length(static.outliers.step)/length(static.histvals))*100;
                    fprintf('\t\tRelative distance of median values: \t%fmm\n', static.dist);
                    fprintf('\t\tCloser step (%d#) \tIQR: \t%fmm\n', ...
                        length(static.closer.step), static.closer.iqr);
                    fprintf('\t\tFurther step (%d#)\tIQR: \t%fmm\n', ...
                        length(static.further.step), static.further.iqr);
                    fprintf('\t\tPercentage of outliers: \t%f%%\n', ...
                        static.outliers.percentage);
    
%                     % Plot split histogram with median and iqr bounds
%                     static.f2 = figure('Name', ['Split Histogram - Static Frame', ...
%                         ' - ', stepSide{:}, ' Step #', num2str(stepNum), ' - ROI #', num2str(stepROI)]);
%     
%                     subplot(2, 1, 1);
%                     histogram('BinEdges', static.closer.edges, 'BinCounts', static.closer.counts, 'EdgeAlpha', 0.0, 'FaceColor', 'b');
%                     hold on;
%                     plot(static.closer.median, 0, 'x', 'LineWidth', 5, 'MarkerSize', 5)
%                     plot([static.closer.median+(static.closer.iqr/2), ...
%                         static.closer.median-(static.closer.iqr/2)], ...
%                         [0, 0], 'xg', 'LineWidth', 5, 'MarkerSize', 5)
%                     legend({'Histogram', 'Median', 'IQR Bound'});
%                     title('Closer Step Distribution');
%                     xlabel('Z-Axis Distance Distribution [mm]');
%                     ylabel('Point Cloud Count [-]');
%     
%                     subplot(2, 1, 2);
%                     histogram('BinEdges', static.further.edges, 'BinCounts', static.further.counts, 'EdgeAlpha', 0.0, 'FaceColor', 'b');
%                     hold on;
%                     plot(static.further.median, 0, 'x', 'LineWidth', 5, 'MarkerSize', 5)
%                     plot([static.further.median+(static.further.iqr/2), ...
%                         static.further.median-(static.further.iqr/2)], ...
%                         [0, 0], 'xg', 'LineWidth', 5, 'MarkerSize', 5)
%                     legend({'Histogram', 'Median', 'IQR Bound'});
%                     title('Further Step Distribution');
%                     xlabel('Z-Axis Distance Distribution [mm]');
%                     ylabel('Point Cloud Count [-]');
                end

                %% Dynamic frame
                for frameNum = 1:length(dynamicFrameData)
                    dynamic.data = pcdenoise(dynamicFrameData{frameNum}.steps(stepNum).(stepSide{:})(stepROI));
                    
                    fprintf('%s\nStarting dynamic frame analysis of frame #%d - %s step #%d - ROI #%d...\n%s\n\n', ...
                        repmat('-', 1, 100), frameNum, stepSide{:}, stepNum, stepROI, repmat('-', 1, 100));
                
                    dynamic.histvals = dynamic.data.Location(:, 3);
                    dynamic.edges = min(dynamic.histvals)-binWidth:binWidth:max(dynamic.histvals)+binWidth;
                
%                     % Plot raw histogram and peaks
%                     dynamic.f1 = figure;
%                     dynamic.h = histogram(dynamic.histvals, dynamic.edges);
%                     hold on;
%                     title('Raw Histogram - Dynamic Frame', ['Frame #', num2str(frameNum), ...
%                         ' - ', stepSide{:}, ' Step #', num2str(stepNum), ' - ROI #', num2str(stepROI)]);
%                     xlabel('Z-Axis Distance Distribution [mm]');
%                     ylabel('Point Cloud Count [-]');
%                     dynamic.counts = dynamic.h.BinCounts;
                    dynamic.counts = histcounts(dynamic.histvals, dynamic.edges);

                    if (stepNum == 1 && stepROI ~= 3) || (stepNum == 10 && stepROI == 3) || (strcmp(stepSide{:}, 'left') && stepROI == 4) || (strcmp(stepSide{:}, 'right') && stepROI == 2)
                        % Use islocalmax to find one dominant peak
                        dynamic.L = islocalmax(dynamic.counts, 'MaxNumExtrema', 1, ...
                            'SamplePoints', dynamic.edges(1:end-1));
                        dynamic.peakIdx = find(dynamic.L);
%                         plot(mean(dynamic.edges(dynamic.peakIdx)), ...
%                             dynamic.counts(dynamic.peakIdx), 'x', 'MarkerSize', 10, 'LineWidth', 2);
                        dynamic.dist = 0;
                        dynamic.iqr = iqr(dynamic.histvals);
                    else
                        % Use islocalmax to find two dominant peaks
                        dynamic.L = islocalmax(dynamic.counts, 'MaxNumExtrema', 2, 'MinSeparation', minSeparation, ...
                            'SamplePoints', dynamic.edges(1:end-1));
                        dynamic.peakIdx = find(dynamic.L);
%                         plot(mean([dynamic.edges(dynamic.peakIdx); dynamic.edges(dynamic.peakIdx+1)], 1), ...
%                             dynamic.counts(dynamic.peakIdx), 'x', 'MarkerSize', 10, 'LineWidth', 2);
                    
                        % Extract values of closer and further gauss
                        startIdxCloser = dynamic.peakIdx(1) - find(flip(dynamic.counts(1:dynamic.peakIdx(1)))==0, 1, 'first') + 2;
                        if isempty(startIdxCloser)
                            startIdxCloser = 1;
                        end
                        endIdxCloser = dynamic.peakIdx(1) + find(dynamic.counts(dynamic.peakIdx(1):end)==0, 1, 'first') - 2;
                        if isempty(endIdxCloser)
                            endIdxCloser = length(dynamic.counts);
                        end
                        dynamic.closer.counts = zeros(1, length(dynamic.counts));
                        dynamic.closer.counts(startIdxCloser:endIdxCloser) = dynamic.counts(startIdxCloser:endIdxCloser);
                        dynamic.closer.step = dynamic.histvals(dynamic.histvals > dynamic.edges(startIdxCloser-1) & dynamic.histvals < dynamic.edges(endIdxCloser+1));
                        dynamic.closer.edges = dynamic.edges;
                        
                        %                     if length(peakIdx) == 1
                        %                         furtherGauss = dynamic.closer.step;
                        %                         furtherGaussCounts = dynamic.closer.counts;
                        %                     else
                        startIdxFurther = dynamic.peakIdx(2) - find(flip(dynamic.counts(1:dynamic.peakIdx(2)))==0, 1, 'first') + 2;
                        if isempty(startIdxFurther)
                            startIdxFurther = 1;
                        end
                        endIdxFurther = dynamic.peakIdx(2) + find(dynamic.counts(dynamic.peakIdx(2):end)==0, 1, 'first') - 2;
                        if isempty(endIdxFurther)
                            endIdxFurther = length(dynamic.counts);
                        end
                        dynamic.further.counts = zeros(1, length(dynamic.counts));
                        dynamic.further.counts(startIdxFurther:endIdxFurther) = dynamic.counts(startIdxFurther:endIdxFurther);
                        dynamic.further.step = dynamic.histvals(dynamic.histvals > dynamic.edges(startIdxFurther-1) & dynamic.histvals < dynamic.edges(endIdxFurther+1));
                        %                     end
                        
                        if isequal(dynamic.closer.step, dynamic.further.step)
%                             dynamic.outliers.count = dynamic.counts - dynamic.closer.counts;
                            dynamic.outliers.step = dynamic.histvals(~ismember(dynamic.histvals, dynamic.closer.step));
                        else
                            % Store outliers
%                             dynamic.outliers.count = dynamic.counts - dynamic.closer.counts - dynamic.further.counts;
                            dynamic.outliers.step = dynamic.histvals(~ismember(dynamic.histvals, dynamic.closer.step) & ~ismember(dynamic.histvals, dynamic.further.step));
                        end
                    
                    %     [dynamic.closer.h, dynamic.closer.p] = adtest(dynamic.closer.step);
                    %     if dynamic.closer.h
                    %         warning(sprintf('The test for normality failed for the closer step with p = %f', dynamic.closer.p));
                    %     end
                    % 
                    %     [dynamic.further.h, dynamic.further.p] = adtest(dynamic.further.step);
                    %     if dynamic.further.h
                    %         warning(sprintf('The test for normality failed for the further step with p = %f', dynamic.further.p));
                    %     end
                    
                        dynamic.closer.median = median(dynamic.closer.step)*1e3;
                        dynamic.further.median = median(dynamic.further.step)*1e3;
                        dynamic.dist = dynamic.further.median - dynamic.closer.median;
                        dynamic.closer.iqr = iqr(dynamic.closer.step)*1e3;
                        dynamic.further.iqr = iqr(dynamic.further.step)*1e3;
                        dynamic.outliers.percentage = (length(dynamic.outliers.step)/length(dynamic.histvals))*100;
                        fprintf('\t\tRelative distance of median values: \t%fmm\n', dynamic.dist);
                        fprintf('\t\tCloser step (%d#) \tIQR: \t%fmm\n', ...
                            length(dynamic.closer.step), dynamic.closer.iqr);
                        fprintf('\t\tFurther step (%d#)\tIQR: \t%fmm\n', ...
                            length(dynamic.further.step), dynamic.further.iqr);
                        fprintf('\t\tPercentage of outliers: \t%f%%\n', ...
                            dynamic.outliers.percentage);
                    
%                         % Plot split histogram with median and iqr bounds
%                         dynamic.f2 = figure('Name', ['Split Histogram - Dynamic Frame #', num2str(frameNum), ...
%                             ' - ', stepSide{:}, ' Step #', num2str(stepNum), ' - ROI #', num2str(stepROI)]);
%                     
%                         subplot(2, 1, 1);
%                         histogram('BinEdges', dynamic.closer.edges, 'BinCounts', dynamic.closer.counts, 'EdgeAlpha', 0.0, 'FaceColor', 'b');
%                         hold on;
%                         plot(dynamic.closer.median, 0, 'x', 'LineWidth', 5, 'MarkerSize', 5)
%                         plot([dynamic.closer.median+(dynamic.closer.iqr/2), ...
%                             dynamic.closer.median-(dynamic.closer.iqr/2)], ...
%                             [0, 0], 'xg', 'LineWidth', 5, 'MarkerSize', 5)
%                         legend({'Histogram', 'Median', 'IQR Bound'});
%                         title('Closer Step Distribution');
%                         xlabel('Z-Axis Distance Distribution [mm]');
%                         ylabel('Point Cloud Count [-]');
%                     
%                         subplot(2, 1, 2);
%                         histogram('BinEdges', dynamic.further.edges, 'BinCounts', dynamic.further.counts, 'EdgeAlpha', 0.0, 'FaceColor', 'b');
%                         hold on;
%                         plot(dynamic.further.median, 0, 'x', 'LineWidth', 5, 'MarkerSize', 5)
%                         plot([dynamic.further.median+(dynamic.further.iqr/2), ...
%                             dynamic.further.median-(dynamic.further.iqr/2)], ...
%                             [0, 0], 'xg', 'LineWidth', 5, 'MarkerSize', 5)
%                         legend({'Histogram', 'Median', 'IQR Bound'});
%                         title('Further Step Distribution');
%                         xlabel('Z-Axis Distance Distribution [mm]');
%                         ylabel('Point Cloud Count [-]');
                    end

                    %% Comparison
                    fprintf('%s\nStarting comparison of frame #%d - %s step #%d - ROI #%d...\n%s\n\n', ...
                        repmat('-', 1, 100), frameNum, stepSide{:}, stepNum, stepROI, repmat('-', 1, 100));
                
                    results(frameNum).distErr.(stepSide{:})(stepNum, stepROI) = ...
                        abs(static.dist - dynamic.dist);
                    if (stepNum == 1 && stepROI ~= 3) || (stepNum == 10 && stepROI == 3) || (strcmp(stepSide{:}, 'left') && stepROI == 4) || (strcmp(stepSide{:}, 'right') && stepROI == 2)
                        results(frameNum).iqrErr.(stepSide{:})(stepNum, stepROI) = ...
                            {[abs(static.iqr - dynamic.iqr), 0]};

                        results(frameNum).relDensity.(stepSide{:})(stepNum, stepROI) = ...
                            {[length(dynamic.histvals) / length(static.histvals), 0]};

                        results(frameNum).staticCloserSteps.(stepSide{:})(stepNum, stepROI) = ...
                            {static.histvals}; 
                        results(frameNum).staticFurtherSteps.(stepSide{:})(stepNum, stepROI) = ...
                            {0};
                        results(frameNum).staticIqr.(stepSide{:})(stepNum, stepROI) = ...
                            {[static.iqr, 0]};

                        results(frameNum).dynamicCloserSteps.(stepSide{:})(stepNum, stepROI) = ...
                            {dynamic.histvals}; 
                        results(frameNum).dynamicFurtherSteps.(stepSide{:})(stepNum, stepROI) = ...
                            {0};
                        results(frameNum).dynamicIqr.(stepSide{:})(stepNum, stepROI) = ...
                            {[dynamic.iqr, 0]};

                        fprintf('\t\tStep size error: \t\t\t\t%fmm\n', abs(static.dist - dynamic.dist));
                        fprintf('\t\tIQR difference: \t%fmm\n', abs(static.iqr - dynamic.iqr));
                        fprintf('\t\tRelative density: \t%f%%\n', ...
                            (length(dynamic.histvals) / length(static.histvals)) * 1e2);
                    else
                        results(frameNum).iqrErr.(stepSide{:})(stepNum, stepROI) = ...
                            {[abs(static.closer.iqr - dynamic.closer.iqr), ...
                            abs(static.further.iqr - dynamic.further.iqr)]};

                        results(frameNum).relDensity.(stepSide{:})(stepNum, stepROI) = ...
                            {[length(dynamic.closer.step) / length(static.closer.step), ...
                            length(dynamic.further.step) / length(static.further.step)]};

                        results(frameNum).staticCloserSteps.(stepSide{:})(stepNum, stepROI) = ...
                            {static.closer.step}; 
                        results(frameNum).staticFurtherSteps.(stepSide{:})(stepNum, stepROI) = ...
                            {static.further.step};
                        results(frameNum).staticIqr.(stepSide{:})(stepNum, stepROI) = ...
                            {[static.closer.iqr, static.further.iqr]};

                        results(frameNum).dynamicCloserSteps.(stepSide{:})(stepNum, stepROI) = ...
                            {dynamic.closer.step}; 
                        results(frameNum).dynamicFurtherSteps.(stepSide{:})(stepNum, stepROI) = ...
                            {dynamic.further.step};
                        results(frameNum).dynamicIqr.(stepSide{:})(stepNum, stepROI) = ...
                            {[dynamic.closer.iqr, dynamic.further.iqr]};

                        results(frameNum).outliersErr.(stepSide{:})(stepNum, stepROI) = ...
                            abs(static.outliers.percentage - dynamic.outliers.percentage);
                        fprintf('\t\tStep size error: \t\t\t\t%fmm\n', abs(static.dist - dynamic.dist));
                        fprintf('\t\tIQR difference closer step: \t%fmm\n\t\tIQR difference further step: \t%fmm\n', ...
                            abs(static.closer.iqr - dynamic.closer.iqr), abs(static.further.iqr - dynamic.further.iqr));
                        fprintf('\t\tRelative density closer step: \t%f%%\n\t\tRelative density further step: \t%f%%\n', ...
                            (length(dynamic.closer.step) / length(static.closer.step)) * 1e2, ...
                            (length(dynamic.further.step) / length(static.further.step)) * 1e2);
                
%                         f4 = figure;
%                         subplot(2, 1, 1);
%                         g = [repmat({sprintf('Static #%d', length(static.closer.step))}, size(static.closer.step)); ...
%                             repmat({sprintf('Dynamic #%d', length(dynamic.closer.step))}, size(dynamic.closer.step))];
%                         boxplot([normalize(static.closer.step); normalize(dynamic.closer.step)], g, 'Whisker', 10);
%                         title('Closer Step Boxplot Comparison');
%                         ylabel('Z Distribution Normalized [mm]');
%                         grid minor;
%                     
%                         subplot(2, 1, 2);
%                         g = [repmat({sprintf('Static #%d', length(static.further.step))}, size(static.further.step)); ...
%                             repmat({sprintf('Dynamic #%d', length(dynamic.further.step))}, size(dynamic.further.step))];
%                         boxplot([normalize(static.further.step); normalize(dynamic.further.step)], g, 'Whisker', 10);
%                         title('Further Step Boxplot Comparison');
%                         ylabel('Z Distribution Normalized [mm]');
%                         grid minor;
%                     
%                         dynamic.data.Color = uint8(repmat([105, 150, 115], height(dynamic.data.Color), 1));
%                         static.data.Color = uint8(repmat([105, 155, 190], height(static.data.Color), 1));
                    
%                         h = figure('Name', ['Raw Point Cloud of Step ROI - Static and Dynamic Frame #', ...
%                             num2str(frameNum), ' - ', stepSide{:}, ' Step #', num2str(stepNum), ...
%                             ' - ROI #', num2str(stepROI)]);
%                         subplot(2, 1, 1);
%                         pcshow(static.data, 'MarkerSize', 40);
%                         title('Static Point Cloud of ROI', 'Color', [0, 0, 0]);
%                         xlabel('X [mm]');
%                         ylabel('Y [mm]');
%                         zlabel('Z [mm]');
%                         h.Color = 'w';
%                         view(0, 180);
%                         ax = gca;
%                         ax.Color = 'w';
%                         ax.XAxis.Color = 'k';
%                         ax.XAxisLocation = 'bottom';
%                         ax.YAxis.Color = 'k';
%                         ax.YAxisLocation = 'left';
%                         ax.ZAxis.Color = 'k';
%                         ax.FontWeight = 'bold';
%                         subplot(2, 1, 2);
%                         pcshow(dynamic.data, 'MarkerSize', 40);
%                         title('Dynamic Point Cloud of ROI', 'Color', [0, 0, 0]);
%                         xlabel('X [mm]');
%                         ylabel('Y [mm]');
%                         zlabel('Z [mm]');-
%                         h.Color = 'w';
%                         view(0, 180);
%                         ax = gca;
%                         ax.Color = 'w';
%                         ax.XAxis.Color = 'k';
%                         ax.XAxisLocation = 'bottom';
%                         ax.YAxis.Color = 'k';
%                         ax.YAxisLocation = 'left';
%                         ax.ZAxis.Color = 'k';
%                         ax.FontWeight = 'bold';
                    end
                end
            end
        end
    end
    %% Summary
    fprintf('%s\nStarting summary of dynamic Z-analysis...\n%s\n\n', repmat('-', 1, 100), repmat('-', 1, 100));
    meanDistErr = mean([mean(nonzeros(results(1).distErr.left)), mean(nonzeros(results(2).distErr.left)), mean(nonzeros(results(3).distErr.left)), ...
        mean(nonzeros(results(1).distErr.right)), mean(nonzeros(results(2).distErr.right)), mean(nonzeros(results(3).distErr.right))]);
    maxDistErr = max([max(nonzeros(results(1).distErr.left)), max(nonzeros(results(2).distErr.left)), max(nonzeros(results(3).distErr.left)), ...
        max(nonzeros(results(1).distErr.right)), max(nonzeros(results(2).distErr.right)), max(nonzeros(results(3).distErr.right))]);
    meanIqrErr = mean([mean(nonzeros([results(1).iqrErr.left{:}])), mean(nonzeros([results(2).iqrErr.left{:}])), mean(nonzeros([results(3).iqrErr.left{:}])), ...
        mean(nonzeros([results(1).iqrErr.right{:}])), mean(nonzeros([results(2).iqrErr.right{:}])), mean(nonzeros([results(3).iqrErr.right{:}]))]);
    maxIqrErr = max([max(nonzeros([results(1).iqrErr.left{:}])), max(nonzeros([results(2).iqrErr.left{:}])), max(nonzeros([results(3).iqrErr.left{:}])), ...
        max(nonzeros([results(1).iqrErr.right{:}])), max(nonzeros([results(2).iqrErr.right{:}])), max(nonzeros([results(3).iqrErr.right{:}]))]);
    meanRelDensity = mean([mean(nonzeros([results(1).relDensity.left{:}])), mean(nonzeros([results(2).relDensity.left{:}])), mean(nonzeros([results(3).relDensity.left{:}])), ...
        mean(nonzeros([results(1).relDensity.right{:}])), mean(nonzeros([results(2).relDensity.right{:}])), mean(nonzeros([results(3).relDensity.right{:}]))]);
    minRelDensity = min([min(nonzeros([results(1).relDensity.left{:}])), min(nonzeros([results(2).relDensity.left{:}])), min(nonzeros([results(3).relDensity.left{:}])), ...
        min(nonzeros([results(1).relDensity.right{:}])), min(nonzeros([results(2).relDensity.right{:}])), min(nonzeros([results(3).relDensity.right{:}]))]);
    meanOutliersErr = mean([mean(nonzeros([results(1).outliersErr.left])), mean(nonzeros([results(2).outliersErr.left])), mean(nonzeros([results(3).outliersErr.left])), ...
        mean(nonzeros([results(1).outliersErr.right])), mean(nonzeros([results(2).outliersErr.right])), mean(nonzeros([results(3).outliersErr.right]))]);
    maxOutliersErr = max([max(nonzeros([results(1).outliersErr.left])), max(nonzeros([results(2).outliersErr.left])), max(nonzeros([results(3).outliersErr.left])), ...
        max(nonzeros([results(1).outliersErr.right])), max(nonzeros([results(2).outliersErr.right])), max(nonzeros([results(3).outliersErr.right]))]);

    fprintf('\t\tMean step size error: \t%fmm\n', meanDistErr);
    fprintf('\t\tMax step size error: \t%fmm\n', maxDistErr);
    fprintf('\t\tMean IQR difference: \t%fmm\n', meanIqrErr);
    fprintf('\t\tMax IQR difference: \t%fmm\n', maxIqrErr);
    fprintf('\t\tMean relative density: \t%f%%\n', meanRelDensity*1e2);
    fprintf('\t\tMin relative density: \t%f%%\n', minRelDensity*1e2);
    fprintf('\t\tMean outliers error: \t%f%%\n', meanOutliersErr);
    fprintf('\t\tMax outliers error: \t%f%%\n', maxOutliersErr);

%     %%
%     h = histogram(histvals, edges);
%     hold on;
%     title(['Raw histogram - ', strrep(filename, '_', '\_')], ['Frame #', num2str(frameNum), ...
%         ' - ', stepSide, ' step #', num2str(stepNum), ' - ROI #', num2str(stepROI)]);
%     xlabel('Z-axis distance distribution [mm]');
%     ylabel('Point cloud count [-]');
%     counts = h.BinCounts;
%     % Use islocalmax to find two dominant peaks
%     [L, P] = islocalmax(counts, 'MaxNumExtrema', 2, 'MinSeparation', 100*binWidth, 'SamplePoints', edges(1:end-1));
%     peakIdx = find(L);
%     plot(mean([edges(peakIdx); edges(peakIdx+1)], 1), counts(peakIdx), 'x', 'MarkerSize', 10, 'LineWidth', 2);
% 
%     f3 = figure;
%     % Extract values of closer and further gauss
%     startIdxCloser = peakIdx(1) - find(flip(counts(1:peakIdx(1)))==0, 1, 'first') + 2;
%     if isempty(startIdxCloser)
%         startIdxCloser = 1;
%     end
%     endIdxCloser = peakIdx(1) + find(counts(peakIdx(1):end)==0, 1, 'first') - 2;
%     if isempty(endIdxCloser)
%         endIdxCloser = length(counts);
%     end
%     closerGaussCounts = zeros(1, length(counts));
%     closerGaussCounts(startIdxCloser:endIdxCloser) = counts(startIdxCloser:endIdxCloser);
%     closerGauss = histvals(histvals > edges(startIdxCloser-1) & histvals < edges(endIdxCloser+1));
% 
%     if length(peakIdx) == 1
%         furtherGauss = closerGauss;
%         furtherGaussCounts = closerGaussCounts;
%     else
%         startIdxFurther = peakIdx(2) - find(flip(counts(1:peakIdx(2)))==0, 1, 'first') + 2;
%         if isempty(startIdxFurther)
%             startIdxFurther = 1;
%         end
%         endIdxFurther = peakIdx(2) + find(counts(peakIdx(2):end)==0, 1, 'first') - 2;
%         if isempty(endIdxFurther)
%             endIdxFurther = length(counts);
%         end
%         furtherGaussCounts = zeros(1, length(counts));
%         furtherGaussCounts(startIdxFurther:endIdxFurther) = counts(startIdxFurther:endIdxFurther);
%         furtherGauss = histvals(histvals > edges(startIdxFurther-1) & histvals < edges(endIdxFurther+1));
%     end
% 
%     if isequal(closerGauss, furtherGauss)
%         outliersCount = counts - closerGaussCounts;
%         outliers = histvals(~ismember(histvals, closerGauss));
%     else
%         % Store outliers
%         outliersCount = counts - closerGaussCounts - furtherGaussCounts;
%         outliers = histvals(~ismember(histvals, closerGauss) & ~ismember(histvals, furtherGauss));
%     end
% 
%     histogram('BinEdges', edges, 'BinCounts', closerGaussCounts, 'EdgeAlpha', 0.0, 'FaceColor', 'b');
%     hold on;
%     histogram('BinEdges', edges, 'BinCounts', furtherGaussCounts, 'EdgeAlpha', 0.0, 'FaceColor', 'g');
%     histogram('BinEdges', edges, 'BinCounts', outliersCount, 'EdgeAlpha', 0.0, 'FaceColor', 'r');
%     title(['Split histogram - ', strrep(filename, '_', '\_')], ['Frame #', num2str(frameNum), ...
%         ' - ', stepSide, ' step #', num2str(stepNum), ' - ROI #', num2str(stepROI)]);
%     xlabel('Z-axis distance distribution [mm]');
%     ylabel('Point cloud count [-]');
%     legend({'Closer gauss', 'Further gauss', 'Outliers'});
%     % % Retrieve some properties from the histogram
%     % V = h.Values;
%     % E = h.BinEdges;
%     %
%     % % Use islocalmax
%     % [L, P] = islocalmax(V,'MinSeparation', 100*binWidth, 'SamplePoints', edges(1:end-1));
%     % % Find the centers of the bins that islocalmax identified as peaks
%     % left = E(L);
%     % right = E([false L]);
%     % center = (left + right)/2;
%     % % Plot markers on those bins
%     % hold on
%     % plot(center, V(L), 'r*')
%     %
%     % k = kmeans(V', sum(L));
%     % % % gm = gmdistribution(edges(L), 100*binWidth);
%     % %
%     % % % plot(x, pdf(gmdist, x'), 'k');
%     % % gmdist = fitgmdist(histvals, sum(L));
%     % % for i = 1:length(gmdist)
%     % %     p = pdf('Normal', edges, gmdist.mu(i), sqrt(gmdist.Sigma(i)));
%     % %     plot(edges, p*gmdist.ComponentProportion(i))
%     % % end
%     % plot(edges(k == 1), V(k == 1))
% 
%     [h, p] = adtest(closerGauss);
%     if h
%         warning(sprintf('The test for normality failed for the closer gauss with p = %f', p))
%     end
% 
%     [h, p] = adtest(furtherGauss);
%     if h
%         warning(sprintf('The test for normality failed for the further gauss with p = %f', p))
%     end
% 
%     closerMedian = median(closerGauss);
%     furtherMedian = median(furtherGauss);
%     dist = furtherMedian - closerMedian;
%     fprintf('\t\tRelative distance of median values: \t%fmm\n', dist*1e3);
%     fprintf('\t\tCloser gauss (%d#) \tIQR: \t%fmm \tMAD: \t%fmm\n', ...
%         length(closerGauss), iqr(closerGauss)*1e3, mad(closerGauss, 1)*1e3);
%     fprintf('\t\tFurther gauss (%d#)\tIQR: \t%fmm \tMAD: \t%fmm\n', ...
%         length(furtherGauss), iqr(furtherGauss)*1e3, mad(furtherGauss, 1)*1e3);
%     fprintf('\t\tPercentage of outliers: \t%f%%\n', (length(outliers)/length(histvals))*100);
% 
%     figure;
%     edges = min(closerGauss)-binWidth:binWidth:max(closerGauss)+binWidth;
%     histogram(closerGauss, edges);
%     xlabel('Z-axis distance distribution [mm]');
%     ylabel('Point cloud count [-]');
%     hold on
%     plot(median(closerGauss), 0, 'x', 'LineWidth', 5, 'MarkerSize', 5)
%     plot([median(closerGauss)+mad(closerGauss,1), median(closerGauss)-mad(closerGauss,1)] , [1, 1], 'xm', 'LineWidth', 5, 'MarkerSize', 5)
%     plot([median(closerGauss)+(iqr(closerGauss,1)/2), median(closerGauss)-(iqr(closerGauss,1)/2)], [2, 2], 'xg', 'LineWidth', 5, 'MarkerSize', 5)
%     legend({'Histogram non-normal', 'Median', 'MAD bound', 'IQR bound'});
% 
%     f = figure;
%     g = [repmat({'Dynamic'}, size(closerGauss)); repmat({'Static'}, size(static.closerGauss))];
%     boxplot([normalize(closerGauss); normalize(static.closerGauss)], g);
% 
%     % [h, p, ci, stats] = ttest2(closerGaussCounts, furtherGaussCounts, 'Vartype', 'unequal');
%     % fprintf('\t\tT-Stat: \t%f\n', stats.tstat)
%     % fprintf('\t\tSTD of further gauss (%d#) is: \t%fmm \n\t\tSTD of closer gauss (%d#) is: \t%fmm\n', ...
%     %     length(furtherGauss), stats.sd(2)*1e3, length(closerGauss), stats.sd(1)*1e3);
%     % fprintf('\t\tT-Value: \t%f \n\t\tP-Value: \t%f\n\t\tDOF: \t%f\n', h, p, stats.df);
%     % fprintf('\t\tConfidence-interval of further gauss (95%%): \t%f\n\t\tConfidence-interval of closer gauss (95%%): \t%f\n', ...
%     %     ci(2), ci(1));
% 
%     figure;
%     pcshow(thisFrame);
%     title(['Raw point cloud of step ROI - ', strrep(filename, '_', '\_')], ...
%         ['Frame #', num2str(frameNum), ' - ', stepSide, ' step #', num2str(stepNum), ...
%         ' - ROI #', num2str(stepROI)], 'Color', [0.8, 0.8, 0.8]);
%     xlabel('X [mm]');
%     ylabel('Y [mm]');
%     zlabel('Z [mm]');
%     view(90, 0);
end

