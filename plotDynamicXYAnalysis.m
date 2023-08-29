% plotDynamicXYAnalysis - Plot results of a dynamic-analysis with several speed-samples
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

function plotDynamicXYAnalysis(firstFolderpath, motion, varargin)
    p = inputParser();
    p.addOptional('SecondFolderpath', '');
    p.parse(varargin{:});
    
    secondFolderpath = p.Results.SecondFolderpath;

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

    firstFiles = dir(fullfile(firstFolderpath, ['*', motion, '*'], 'resultsXY.mat'));

    load(fullfile(firstFiles(1).folder, firstFiles(1).name), 'results');
    if ~exist('results', 'var')
        newResults = load(fullfile(firstFiles(1).folder, firstFiles(1).name), 'intResults');
        firstResults = newResults.intResults;
    end
    for i = 2:length(firstFiles)
        newResults = load(fullfile(firstFiles(i).folder, firstFiles(i).name), 'results');
        if isfield(newResults, 'intResults') || ~isfield(newResults, 'results')
            newResults = load(fullfile(filesScanner(i).folder, filesScanner(i).name), 'intResults');
            results = [results, newResults.intResults];
        else
            results = [results, newResults.results];
        end
    end
    firstResults = results;

    clear results;

    if ~isempty(secondFolderpath)
        secondFiles = dir(fullfile(secondFolderpath, ['*', motion, '*'], 'resultsXY.mat'));
    
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
        firstArrayMean = vertcat(firstResults.meandistErr);
        firstArrayMax = vertcat(firstResults.maxdistErr);
        firstArrayMin = vertcat(firstResults.mindistErr);
        subplot(2, 1, 1);
        plot(firstSpeeds', firstArrayMean(:, 1), '-b', ...
            firstSpeeds', firstArrayMax(:, 1), '--c', ...
            firstSpeeds', firstArrayMin(:, 1), '--c', 'LineWidth', 2);
        hold on;
        grid minor;
        fill([firstSpeeds; firstSpeeds], [firstArrayMax(:, 1)'; firstArrayMin(:, 1)'], 'c', ...
            'FaceAlpha', 0.5);
%         title([firstMode, ' Mode']);
        title('X distribution');
        xlabel('Max velocity [m/s]');
        ylabel('Relative distribution error [-]');
%         set(gca, 'YScale', 'log')
        subplot(2, 1, 2);
        plot(firstSpeeds', firstArrayMean(:, 2), '-r', ...
            firstSpeeds', firstArrayMax(:, 2), '--m', ...
            firstSpeeds', firstArrayMin(:, 2), '--m', 'LineWidth', 2);
        hold on;
        grid minor;
        sgtitle('Relative distribution at different speeds');
        fill([firstSpeeds; firstSpeeds], [firstArrayMax(:, 2)'; firstArrayMin(:, 2)'], 'm', ...
            'FaceAlpha', 0.5);
        sgtitle([firstMode, ' Mode']);
        title('Y distribution');
        xlabel('Max velocity [m/s]');
        ylabel('Relative distribution error [-]');
        set(findall(gcf,'-property','FontSize'),'FontSize',22);
%         set(gca, 'YScale', 'log')

%         figure;
%         plot(firstSpeeds', vertcat(firstResults.emptyROIs));
%         grid minor;
%         title([firstMode, ' Mode']);
%         xlabel('Max velocity [m/s]');
%         ylabel('# of empty ROIs');

        figure;
        secondArrayMean = vertcat(secondResults.meandistErr);
        secondArrayMax = vertcat(secondResults.maxdistErr);
        secondArrayMin = vertcat(secondResults.mindistErr);
        subplot(2, 1, 1);
        plot(secondSpeeds', secondArrayMean(:, 1), '-b', ...
            secondSpeeds', secondArrayMax(:, 1), '--c', ...
            secondSpeeds', secondArrayMin(:, 1), '--c', 'LineWidth', 2);
        hold on;
        grid minor;
        fill([secondSpeeds; secondSpeeds], [secondArrayMax(:, 1)'; secondArrayMin(:, 1)'], 'c', ...
            'FaceAlpha', 0.5);
%         title([secondMode, ' Mode']);
        title('X distribution');
        xlabel('Max velocity [m/s]');
        ylabel('Relative distribution error [-]');
%         set(gca, 'YScale', 'log')
        subplot(2, 1, 2);
        plot(secondSpeeds', secondArrayMean(:, 2), '-r', ...
            secondSpeeds', secondArrayMax(:, 2), '--m', ...
            secondSpeeds', secondArrayMin(:, 2), '--m', 'LineWidth', 2);
        hold on;
        grid minor;
        sgtitle('Relative distribution at different speeds');
        fill([secondSpeeds; secondSpeeds], [secondArrayMax(:, 2)'; secondArrayMin(:, 2)'], 'm', ...
            'FaceAlpha', 0.5);
        sgtitle([secondMode, ' Mode']);
        title('Y distribution');
        xlabel('Max velocity [m/s]');
        ylabel('Relative distribution error [-]');
        set(findall(gcf,'-property','FontSize'),'FontSize',22);
%         set(gca, 'YScale', 'log')

%         figure;
%         plot(secondSpeeds', vertcat(secondResults.emptyROIs));
%         grid minor;
%         title([secondMode, ' Mode']);
%         xlabel('Max velocity [m/s]');
%         ylabel('# of empty ROIs');
    else
        figure;
        firstArrayMean = vertcat(firstResults.meandistErr);
        firstArrayMax = vertcat(firstResults.maxdistErr);
        firstArrayMin = vertcat(firstResults.mindistErr);
        subplot(2, 1, 1);
        plot(firstSpeeds', firstArrayMean(:, 1), '-b', ...
            firstSpeeds', firstArrayMax(:, 1), '--c', ...
            firstSpeeds', firstArrayMin(:, 1), '--c');
        hold on;
        grid minor;
        fill([firstSpeeds; firstSpeeds], [firstArrayMax(:, 1)'; firstArrayMin(:, 1)'], 'c', ...
            'FaceAlpha', 0.5);
%         title([firstMode, ' Mode']);
        title('X distribution');
        xlabel('Max velocity [m/s]');
        ylabel('Relative distribution error [-]');
%         set(gca, 'YScale', 'log')
        subplot(2, 1, 2);
        plot(firstSpeeds', firstArrayMean(:, 2), '-b', ...
            firstSpeeds', firstArrayMax(:, 2), '--c', ...
            firstSpeeds', firstArrayMin(:, 2), '--c');
        hold on;
        grid minor;
        sgtitle('Relative distribution at different speeds');
        fill([firstSpeeds; firstSpeeds], [firstArrayMax(:, 2)'; firstArrayMin(:, 2)'], 'c', ...
            'FaceAlpha', 0.5);
        sgtitle([firstMode, ' Mode']);
        title('Y distribution');
        xlabel('Max velocity [m/s]');
        ylabel('Relative distribution error [-]');
%         set(gca, 'YScale', 'log')

        figure;
        plot(firstSpeeds', vertcat(firstResults.emptyROIs));
        grid minor;
        title([firstMode, ' Mode']);
        xlabel('Max velocity [m/s]');
        ylabel('# of empty ROIs');
    end
end
    