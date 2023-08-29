% plotDynamicZAnalysis - Plot results of a dynamic-analysis with several speed-samples
%
% Description:
% ------------
%       Requires dynamic-analysis results to be stored in the respective
%       dynamic dataset folder.
%
% Input Arguments:
% ----------------
%       firstFolderpath - string | char array
%           Full folderpath to a collection of dynamic dataset folders.
%       motion - string | char array
%           Motion of the dataset to evaluate. Must be the same format as
%           corresponding MotionFcn (E.g., '../MotionFcn/0.40_FB/..' must
%           resolve to 'motion = 'FB'')
%
%       Optional Name-Value Pairs:
%           SecondFolderpath - false | (true)
%               Full folderpath to another collection of dynamic dataset folders.

function plotDynamicZAnalysis(firstFolderpath, motion, varargin)
    p = inputParser();
    p.addOptional('SecondFolderpath', '');
    p.parse(varargin{:});
    
    secondFolderpath = p.Results.SecondFolderpath;

%     firstSpeeds = 0.10;
%     secondSpeeds = 0.10;
%     firstMode = 'Vert';
%     secondMode = 'Horz';
    if contains(firstFolderpath, 'Camera')
        firstSpeeds = [0.01:0.03:0.58, 0.60];
        if strcmp(motion, 'FB')
            secondSpeeds = [0.004, 0.007, 0.01:0.03:0.19];
        else
            secondSpeeds = [0.004, 0.007, 0.01:0.03:0.13];
        end
        firstMode = 'Camera';
        secondMode= 'Scanner';
    elseif contains(firstFolderpath, 'Scanner')
        if strcmp(motion, 'FB')
            firstSpeeds = [0.004, 0.007, 0.01:0.03:0.19];
        else
            firstSpeeds = [0.004, 0.007, 0.01:0.03:0.13];
        end
        secondSpeeds = [0.01:0.03:0.58, 0.60];
        firstMode = 'Scanner';
        secondMode = 'Camera';
    end

    firstFiles = dir(fullfile(firstFolderpath, ['*', motion, '*'], 'resultsZ.mat'));

    load(fullfile(firstFiles(1).folder, firstFiles(1).name), 'results');
    if ~exist('results', 'var')
        newResults = load(fullfile(firstFiles(1).folder, firstFiles(1).name), 'intResults');
        firstResults = newResults.intResults;
    end
    for i = 2:length(firstFiles)
        newResults = load(fullfile(firstFiles(i).folder, firstFiles(i).name), 'results');
%         if ~isfield(newResults, 'intResults')
%             newResults = load(fullfile(filesScanner(i).folder, filesScanner(i).name), 'intResults');
%             resultsScanner = [results, newResults.intResults];
%         else
            results = [results, newResults.results];
%         end
    end
    firstResults = results;

    clear results;

    if ~isempty(secondFolderpath)
        secondFiles = dir(fullfile(secondFolderpath, ['*', motion, '*'], 'resultsZ.mat'));
    
        load(fullfile(secondFiles(1).folder, secondFiles(1).name), 'results');
        if ~exist('results', 'var')
            newResults = load(fullfile(secondFiles(1).folder, secondFiles(1).name), 'intResults');
            if ~isfield(newResults, 'intResults')
                results = newResults.results;
            else
                results = newResults.intResults;
            end
        end
        for i = 2:length(secondFiles)
            newResults = load(fullfile(secondFiles(i).folder, secondFiles(i).name), 'results');
            if isfield(newResults, 'intResults') || ~isfield(newResults, 'results')
                newResults = load(fullfile(secondFiles(i).folder, secondFiles(i).name), 'intResults');
                results = [results, newResults.intResults];
            else
                results = [results, newResults.results];
            end
        end
        secondResults = results;
    
        figure;
        subplot(2, 1, 1);
        plot(firstSpeeds, [firstResults.meanRangeErr], '-b', ...
            firstSpeeds, [firstResults.maxRangeErr], '--c', firstSpeeds, [firstResults.minRangeErr], '--c', 'LineWidth', 2);
        hold on;
        grid minor;
        fill([firstSpeeds; firstSpeeds], [firstResults.maxRangeErr; firstResults.minRangeErr], 'c', ...
            'FaceAlpha', 0.5);
%         title([firstMode, ' Mode']);
        xlabel('Velocity [m/s]');
        ylabel('Precision error [mm]');
%         set(gca, 'YScale', 'log')
        sgtitle([firstMode, ' Mode']);

        subplot(2, 1, 2);
        plot(firstSpeeds, [firstResults.meanStepSizeErr], '-r', ...
            firstSpeeds, [firstResults.maxStepSizeErr], '--m', firstSpeeds, [firstResults.minStepSizeErr], '--m', 'LineWidth', 2);
        hold on;
        grid minor;
        fill([firstSpeeds; firstSpeeds], [firstResults.maxStepSizeErr; firstResults.minStepSizeErr], 'm', ...
            'FaceAlpha', 0.5);
%         title([firstMode, ' Mode']);
        xlabel('Velocity [m/s]');
        ylabel('Relative accuracy error [mm]');
        set(findall(gcf,'-property','FontSize'),'FontSize',22);
%         set(gca, 'YScale', 'log')
%         sgtitle('Precision error at different speeds');
%         legend({'Scanner Mode', 'Camera Mode'});

        figure;
%         subplot(1, length(firstResults), 1);
%         boxplot([firstResults(1).frameResults.rangeErrArr]');
        plotData = [firstResults(1).frameResults.rangeErrArr]';
%         xlabel([num2str(firstSpeeds(1)), ' m/s']);
        labelData = repmat([num2str(firstSpeeds(1)), ' m/s'], length([firstResults(1).frameResults.rangeErrArr]'), 1);
        hold on;
        for i = 2:length(firstResults)-3
%             subplot(1, length(firstResults), i);
%             boxplot([firstResults(i).frameResults.rangeErrArr]');
            plotData = vertcat(plotData, [firstResults(i).frameResults.rangeErrArr]');
%             xlabel([num2str(firstSpeeds(i)), ' m/s']);
            labelData = char(labelData, repmat([num2str(firstSpeeds(i)), ' m/s'], length([firstResults(i).frameResults.rangeErrArr]'), 1));
        end
        boxplot(plotData, labelData, 'DataLim', [0, 40]);%'Jitter',1);%'ExtremeMode','compress');
        xlabel('Velocity [m/s]');
        ylabel('Precision error [mm]');
        title([firstMode, ' Mode']);
        figure;
%         subplot(1, length(firstResults), 1);
%         boxplot([firstResults(1).frameResults.stepSizeErrArr]');
        plotData = [firstResults(1).frameResults.stepSizeErrArr]';
%         xlabel([num2str(firstSpeeds(1)), ' m/s']);
        labelData = repmat([num2str(firstSpeeds(1)), ' m/s'], length([firstResults(1).frameResults.stepSizeErrArr]'), 1);
%         hold on;
        for i = 2:length(firstResults)-3
%             subplot(1, length(firstResults), i);
%             boxplot([firstResults(i).frameResults.stepSizeErrArr]');
            plotData = vertcat(plotData, [firstResults(i).frameResults.stepSizeErrArr]');
%             xlabel([num2str(firstSpeeds(i)), ' m/s']);
            labelData = char(labelData, repmat([num2str(firstSpeeds(i)), ' m/s'], length([firstResults(i).frameResults.stepSizeErrArr]'), 1));
        end
        boxplot(plotData, labelData, 'DataLim', [0, 40]);%'Jitter',1);%'ExtremeMode','compress');
        xlabel('Velocity [m/s]');
        ylabel('Relative accuracy error [mm]');
        title([firstMode, ' Mode']);
    
        figure;
        subplot(2, 1, 1);
        plot(secondSpeeds, [secondResults.meanRangeErr], '-b', ...
            secondSpeeds, [secondResults.maxRangeErr], '--c', secondSpeeds, [secondResults.minRangeErr], '--c', 'LineWidth', 2);
        hold on;
        grid minor;
        fill([secondSpeeds; secondSpeeds], [secondResults.maxRangeErr; secondResults.minRangeErr], 'c', ...
            'FaceAlpha', 0.5);
%         title([secondMode, ' Mode']);
        xlabel('Velocity [m/s]');
        ylabel('Precision error [mm]');
%         set(gca, 'YScale', 'log')

        subplot(2, 1, 2);
        plot(secondSpeeds, [secondResults.meanStepSizeErr], '-r', ...
            secondSpeeds, [secondResults.maxStepSizeErr], '--m', secondSpeeds, [secondResults.minStepSizeErr], '--m', 'LineWidth', 2);
        hold on;
        grid minor;
        fill([secondSpeeds; secondSpeeds], [secondResults.maxStepSizeErr; secondResults.minStepSizeErr], 'm', ...
            'FaceAlpha', 0.5);
%         title([secondMode, ' Mode']);
        xlabel('Velocity [m/s]');
        ylabel('Relative accuracy error [mm]');
        sgtitle([secondMode, ' Mode']);
        set(findall(gcf,'-property','FontSize'),'FontSize',22);
%         set(gca, 'YScale', 'log')
%         sgtitle('Relative accuracy error at different speeds');
%         legend({'Scanner Mode', 'Camera Mode'});

        figure;
%         subplot(1, length(secondResults), 1);
%         boxplot([secondResults(1).frameResults.rangeErrArr]');
        plotData = [secondResults(1).frameResults.rangeErrArr]';
%         xlabel([num2str(secondSpeeds(1)), ' m/s']);
        labelData = repmat([num2str(secondSpeeds(1))], length([secondResults(1).frameResults.rangeErrArr]'), 1);
        hold on;
        for i = 2:length(secondResults)
%             subplot(1, length(secondResults), i);
%             boxplot([secondResults(i).frameResults.rangeErrArr]');
            plotData = vertcat(plotData, [secondResults(i).frameResults.rangeErrArr]');
%             xlabel([num2str(secondSpeeds(i)), ' m/s']);
            labelData = char(labelData, repmat([num2str(secondSpeeds(i))], length([secondResults(i).frameResults.rangeErrArr]'), 1));
        end
        boxplot(plotData, labelData, 'DataLim', [0, 5]);%'Jitter',1);%'ExtremeMode','compress');
        xlabel('Velocity [m/s]');
        ylabel('Precision error [mm]');
        title([secondMode, ' Mode']);
        figure;
%         subplot(1, length(secondResults), 1);
%         boxplot([secondResults(1).frameResults.stepSizeErrArr]');
        plotData = [secondResults(1).frameResults.stepSizeErrArr]';
%         xlabel([num2str(secondSpeeds(1)), ' m/s']);
        labelData = repmat([num2str(secondSpeeds(1))], length([secondResults(1).frameResults.stepSizeErrArr]'), 1);
%         hold on;
        for i = 2:length(secondResults)
%             subplot(1, length(secondResults), i);
%             boxplot([secondResults(i).frameResults.stepSizeErrArr]');
            plotData = vertcat(plotData, [secondResults(i).frameResults.stepSizeErrArr]');
%             xlabel([num2str(secondSpeeds(i)), ' m/s']);
            labelData = char(labelData, repmat([num2str(secondSpeeds(i))], length([secondResults(i).frameResults.stepSizeErrArr]'), 1));
        end
        boxplot(plotData, labelData, 'DataLim', [0, 5]);%'Jitter',1);%'ExtremeMode','compress');
        xlabel('Velocity [m/s]');
        ylabel('Relative accuracy error [mm]');
        title([secondMode, ' Mode']);
    else
        figure;
        subplot(2, 1, 1);
        plot(firstSpeeds, [firstResults.meanStepSizeErr], '-b', ...
            firstSpeeds, [firstResults.maxStepSizeErr], '--c', firstSpeeds, [firstResults.minStepSizeErr], '--c');
        hold on;
        grid minor;
        fill([firstSpeeds; firstSpeeds], [firstResults.maxStepSizeErr; firstResults.minStepSizeErr], 'c', ...
            'FaceAlpha', 0.5);
        title('Relative accuracy error at different speeds');
        subtitle([firstMode, ' Mode']);
        xlabel('Velocity [m/s]');
        ylabel('Relative accuracy error [mm]');
        set(gca, 'YScale', 'log')
%         legend({[mode, ' Mode']});
    
        subplot(2, 1, 2);
        plot(firstSpeeds, [firstResults.meanRangeErr], '-b', ...
            firstSpeeds, [firstResults.maxRangeErr], '--c', firstSpeeds, [firstResults.minRangeErr], '--c');
        hold on;
        grid minor;
        fill([firstSpeeds; firstSpeeds], [firstResults.maxRangeErr; firstResults.minRangeErr], 'c', ...
            'FaceAlpha', 0.5);
        title('Precision error at different speeds');
        subtitle([firstMode, ' Mode']);
        xlabel('Velocity [m/s]');
        ylabel('Precision error [mm]'); 
        set(gca, 'YScale', 'log')
%         legend({[mode, ' Mode']});
    end
end
    