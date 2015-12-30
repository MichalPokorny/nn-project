% Trains a neural network to check whether the "authorized user"
% is typing.

%% Load data
filename = '../feature_extraction/matlab.csv';
data = csvread(filename);

%% Preprocess data so that inputs and outputs are columns
% filter out 0, 1 users
data = data(data(:,1) ~= 0 & data(:,1) ~= 1,:);
userids = data(:,1)';
inputs = data(:,2:end)';

uniq = unique(userids);
%idxes = 1:5;
idxes = 1:length(uniq);

tprs = 0:0.01:1;
% false positive rates corresponding to tprs
fprs = zeros(length(idxes), length(tprs));

for i = 1:length(uniq)
%for i = idxes
    detectedUserId = uniq(i);
    
    disp('training to check for user ' + uniq(i));
    % Check for the i-th user.
    % target: 1 means "intruder"
    %target = zeros(2, length(userids));
    target = zeros(1, length(userids));
    for j = 1:length(userids)
        if (userids(j) == detectedUserId)
            target(1,j) = 0;
        else
            target(1,j) = 1;
        end
    end

    %   inputs - input data.
    %   target - target data.

    x = inputs;
    t = target;
    
    % net has 60 inputs, 61 outputs
    
    trainFcn = 'trainbr';
    hiddenLayerSize = 10;
    net = patternnet(hiddenLayerSize);
    net.trainParam.showWindow = false;
    net.trainParam.showCommandLine = false;
    net.trainParam.epochs = 10000;
    net.trainParam.max_fail = 1000;  % maximum failed validation checks in a row
%    net.trainParam.epochs = 100;

    % Setup Division of Data for Training, Validation, Testing
    net.divideParam.trainRatio = 70/100;
    net.divideParam.valRatio = 15/100;
    net.divideParam.testRatio = 15/100;

    % Train the Network
    [net,tr] = train(net,x,t);

    % Test the Network
    y = net(x);
    e = gsubtract(t,y);
    performance = perform(net,t,y);
    tind = vec2ind(t);
    yind = vec2ind(y);
    percentErrors = sum(tind ~= yind)/numel(tind);

    [tpr, fpr, thresholds] = roc(t, y);
    for tprIndex = 1:length(tprs)
        tprLevel = tprs(tprIndex);
        disp('looking for tpr level ' + tprLevel);
        for j = 1:length(tpr)
            if (tpr(j) >= tprLevel || j == length(tpr))
                disp(['found tpr level ', num2str(tpr(j)), ' at ', num2str(j), ', corresponding fpr ', num2str(fpr(j))]);
                fprs(i,tprIndex) = fpr(j);
                break;
            end
        end
    end

    % Plots
    % Uncomment these lines to enable various plots.
    %figure, plotperform(tr)
    %figure, plottrainstate(tr)
    %figure, ploterrhist(e)
    %figure, plotconfusion(t,y)
    %figure, plotroc(t,y)
end

% Plot average ROC
plot(tprs, mean(fprs));
print('average_roc', '-dpng');

%errorbars(tprs, mean(fprs), 2*std(fprs));
