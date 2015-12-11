%% Load data

filename = '../feature_extraction/matlab.csv';
data = csvread(filename);

%% Preprocess data so that inputs and outputs are columns

% filter 0, 1 users
data = data(data(:,1) ~= 0 & data(:,1) ~= 1,:);

data = data(data(:,1) == 144 | data(:,1) == 145,:);

targets = data(:,1)';

uniq = unique(targets);
freq = zeros(1, length(uniq));

targetM = zeros(length(uniq), length(targets));
for i = 1:length(uniq)
    for j = 1:length(targets)
        if (targets(j) == uniq(i))
            targetM(i,j) = 1;
            freq(i) = freq(i) + 1;
        end
    end
end

inputs = data(:,2:end)';

