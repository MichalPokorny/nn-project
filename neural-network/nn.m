%% Load data

filename = '../feature_extraction/matlab.csv';
data = csvread(filename);

%% Preprocess data so that inputs and outputs are columns

targets = data(:,1)';
uniq = unique(targets);

targetM = zeros(length(uniq), length(targets));
for i = 1:length(uniq)
    for j = 1:length(targets)
        targetM(i,j) = (targets(j) == uniq(i));
    end
end

inputs = data(:,2:end)';

