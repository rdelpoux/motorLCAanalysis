function problem = SetProblemType(problemType,N,I,beta,theta)
% function: SetProblemType
%
arguments
    problemType {mustBeMember(problemType,["no_load","stalled_rotor","one_OP","Xp2FEMM","default"])}
    N {mustBeNumeric}
    I {mustBeNumeric}
    beta {mustBeNumeric}
    theta {mustBeNumeric}
end
problem = struct;
problem.type = problemType;

if(problemType == "no_load")
    % idq = Is[cos(beta), sin(beta)]'
    % Current Map Is = linspace(iMin,iMax,iN)
    problem.iMin = 0;   % Amps
    problem.iMax = 0;  % Amps
    problem.iN = 1;    % Amps
    % Angle Map beta = linspace(betaMin,betaMax,beatN)
    problem.betaMin = pi/2;  % °
    problem.betaMax = pi/2; % °
    problem.betaN   = 1;  % °
    % Shaft rotation during one simulation
    problem.theta = theta; %mecanical rad
    problem.thetaN = N;

elseif(problemType == "stalled_rotor")
    % idq = Is[cos(beta), sin(beta)]'
    % Current Map Is = linspace(iMin,iMax,iN)
    problem.iMin = I;   % Amps
    problem.iMax = I;  % Amps
    problem.iN = 1;    %

    % Angle Map beta = linspace(betaMin,betaMax,beatN)
    problem.betaMin = pi/2;  % Rad
    problem.betaMax = pi/2; % Rad
    problem.betaN   = 1;  %

    % Shaft rotation during one simulation
    problem.theta = theta; %mecanical degree
    problem.thetaN = N;

elseif(problemType == "one_OP")
    % idq = Is[cos(beta), sin(beta)]'
    % Current Map Is = linspace(iMin,iMax,iN)
    problem.iMin = I;   % Amps
    problem.iMax = I;  % Amps
    problem.iN = 1;    % 

    % Angle Map beta = linspace(betaMin,betaMax,beatN)
    problem.betaMin = beta;  % rad
    problem.betaMax = beta; % rad
    problem.betaN   = 1;  %

    % Shaft rotation during one simulation
    problem.theta = theta; %mecanical degree
    problem.thetaN = N;    
elseif(problemType == "Xp2FEMM")
    dataFoldder =  strcat(fileparts(pwd),'\04_ProceededData');
    [fichier, chemin] = uigetfile(fullfile(dataFoldder, '*.mat'), 'Sélectionnez un fichier .mat');

    Data = load(fullfile(chemin,fichier));
    % idq = Is[cos(beta), sin(beta)]'
    % Current Map Is = linspace(iMin,iMax,iN)
    problem.iMin = -1;   % Amps
    problem.iMax = -1;  % Amps
    problem.iN = 1;    % 

    % Angle Map beta = linspace(betaMin,betaMax,beatN)
    problem.betaMin = -1;  % rad
    problem.betaMax = -1; % rad
    problem.betaN   = 1;  %

    % Shaft rotation during one simulation
    problem.theta = Data.dataHBK.data1Rev.theta(end); %mecanical degree
    problem.thetaN = length(Data.dataHBK.data1Rev.theta);    
    problem.fichier = fichier;
    problem.chemin = chemin;
else

    % idq = Is[cos(beta), sin(beta)]'
    % Current Map Is = linspace(iMin,iMax,iN)
    problem.iMin = 0;   % Amps
    problem.iMax = 0;  % Amps
    problem.iN = 0;    %

    % Angle Map beta = linspace(betaMin,betaMax,beatN)
    problem.betaMin = 0;  % Rad
    problem.betaMax = 0; % Rad
    problem.betaN   = 0;  %

    % Shaft rotation during one simulation
    problem.thetaElec = 0; %mecanical degree
    problem.thetaN = 0;
end



