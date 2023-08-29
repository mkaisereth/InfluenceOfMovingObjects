function statisticalAnalysis_alt(staticFrameData, dynamicFrameData, stepDepthsLeft, stepDepthsMiddle, stepDepthsRight)
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
                    static.L = islocalmax(static.counts, 'MaxNumExtrema', 2, 'MinSeparation', minSeparation, ...
                        'SamplePoints', static.edges(1:end-1));
                    static.peakIdx = find(static.L);
%                     plot(mean([static.edges(static.peakIdx); static.edges(static.peakIdx+1)], 1), ...
%                         static.counts(static.peakIdx), 'x', 'MarkerSize', 10, 'LineWidth', 2);
    
                    % Split between peaks to extract closer and further Step
                    static.splitValue = mean([mean([static.edges(static.peakIdx(1)); ...
                        static.edges(static.peakIdx(1)+1)], 1); ...
                        mean([static.edges(static.peakIdx(2)); static.edges(static.peakIdx(2)+1)], 1)]);
                    static.splitIdx = find(static.edges >= static.splitValue, 1);
    
                    static.closer.counts = static.counts(1:static.splitIdx-1);
                    static.further.counts = static.counts(static.splitIdx:end);
    
                    static.closer.step = static.histvals(static.histvals <= static.edges(static.splitIdx - 1));
                    static.closer.edges = static.edges(static.edges <= static.edges(static.splitIdx))*1e3;
    
                    static.further.step = static.histvals(static.histvals >= static.edges(static.splitIdx));
                    static.further.edges = static.edges(static.edges >= static.edges(static.splitIdx))*1e3;
    
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
                    fprintf('\t\tRelative distance of median values: \t%fmm\n', static.dist);
                    fprintf('\t\tCloser step (%d#) \tIQR: \t%fmm\n', ...
                        length(static.closer.step), static.closer.iqr);
                    fprintf('\t\tFurther step (%d#)\tIQR: \t%fmm\n', ...
                        length(static.further.step), static.further.iqr);
    
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
                    
                        % Split between peaks to extract closer and further Step
                        dynamic.splitValue = mean([mean([dynamic.edges(dynamic.peakIdx(1)); ...
                            dynamic.edges(dynamic.peakIdx(1)+1)], 1); ...
                            mean([dynamic.edges(dynamic.peakIdx(2)); dynamic.edges(dynamic.peakIdx(2)+1)], 1)]);
                        dynamic.splitIdx = find(dynamic.edges >= dynamic.splitValue, 1);
                    
                        dynamic.closer.counts = dynamic.counts(1:dynamic.splitIdx-1);
                        dynamic.further.counts = dynamic.counts(dynamic.splitIdx:end);
                    
                        dynamic.closer.step = dynamic.histvals(dynamic.histvals <= dynamic.edges(dynamic.splitIdx - 1));
                        dynamic.closer.edges = dynamic.edges(dynamic.edges <= dynamic.edges(dynamic.splitIdx))*1e3;
                    
                        dynamic.further.step = dynamic.histvals(dynamic.histvals >= dynamic.edges(dynamic.splitIdx));
                        dynamic.further.edges = dynamic.edges(dynamic.edges >= dynamic.edges(dynamic.splitIdx))*1e3;
                    
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
                        fprintf('\t\tRelative distance of median values: \t%fmm\n', dynamic.dist);
                        fprintf('\t\tCloser step (%d#) \tIQR: \t%fmm\n', ...
                            length(dynamic.closer.step), dynamic.closer.iqr);
                        fprintf('\t\tFurther step (%d#)\tIQR: \t%fmm\n', ...
                            length(dynamic.further.step), dynamic.further.iqr);
                    
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

    fprintf('\t\tMean step size error: \t%fmm\n', meanDistErr);
    fprintf('\t\tMax step size error: \t%fmm\n', maxDistErr);
    fprintf('\t\tMean IQR difference: \t%fmm\n', meanIqrErr);
    fprintf('\t\tMax IQR difference: \t%fmm\n', maxIqrErr);
    fprintf('\t\tMean relative density: \t%f%%\n', meanRelDensity*1e2);
    fprintf('\t\tMin relative density: \t%f%%\n', minRelDensity*1e2);

%     for i = 1:9
%         boxplotArrLeft(end+1) = [normalize(results(1).staticFurtherSteps.left{i, 3}'); ...
%             normalize([results(1).dynamicFurtherSteps.left{i, 3}; ...
%             results(2).dynamicFurtherSteps.left{i, 3}; ...
%             results(3).dynamicFurtherSteps.left{i, 3}]')];
%     end
%     figure;
%     subplot(2, 1, 1);
%     boxplot(results(1).staticFurtherSteps.left(1:end-1, 3) )
%     title('Further Steps Left');
%     subplot(2, 1, 2);
%     boxplot();
%     title('Closer Steps Left');
end

