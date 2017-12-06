function [map2, Flux2, fluxMap] = addFluxFBA(map, model, FBAsolution, color)
% Change reactions type for a specific list of reactions
% Visualize the fluxes obtained in a cobra model (FBA) in a CD map 
%
% USAGE:
%
%   [map2 rxnsList width fluxLbUb] = addFluxFBA(map,model,FBAsolution,rxnsColour)
%
% INPUTS:
%   map:            A parsed model structure generated by 
%                   'transformXML2MatStruct' function
%   model:          A COBRA model
%   FBAsolution:    Structure obtain from Flux balance analysis 
%
% OPTIONAL INPUTS: 
%   color:          Add colour to the reactions carrying fluxes   
%
% OUTPUTS:
%    map2:          New parsed file with the changes in the reactions   
%    Flux:          Fluxes and normalized fluxes through all rxns 
%    fluxMap:       List of reactions carrying flux in the map + width value 
%
% .. Author: - J.modamio 18/07/2017. Belval, Luxembourg, 18/07/2017.


    if nargin<4
        color = 'RED' ;
    end

    % Rename the map to do not overwrite 
    map2 = map;
    
    % Call function to give color name instead color code
    Colors = createColorsMap;

    % Obtain fluxes in the map from FBA solution
    Flux = FBAsolution.v;
    idx = find(Flux); % indx reactions carrying fluxes in the model
    rxn = model.rxns(idx,1); % reaction name

    % Obtain list of reaction carrying fluxes and the value
    Flux2 = [rxn,num2cell(Flux(idx,1))];

    % Find this reactions in the map and give them a flux and color  
    index = ismember(map.rxnName,rxn); % find non-zeros elements 
    map2.rxnColor(index,1) = {Colors(color)}; 

    % Normalize fluxes to give width
    flux2(:,1)=FBAsolution.v;
    
    % Normalise the flux values
    absFlux=abs(flux2);
    rxnWidth=absFlux/max(absFlux);
    
    % Normalize the values in the descending order
    rxnWidth(rxnWidth>=1)=8;   
    rxnWidth(rxnWidth>0.8 & rxnWidth<1)=6;
    rxnWidth(rxnWidth>0.5 & rxnWidth<=0.8)=5;
    rxnWidth(rxnWidth>0.2 & rxnWidth<=0.5)=4;
    rxnWidth(rxnWidth>1e-3 & rxnWidth<=0.2)=3;
    rxnWidth(rxnWidth<1e-3)=1;
    
    % Normalized values
    normalizedFlux=model.rxns;
    normalizedFlux(:,2)= num2cell(rxnWidth(:,1));

    % Create 
    Flux2 = [Flux2 num2cell(rxnWidth(idx,1))];
    % Add specific width to each reaction in the map based on the fluxes
    for i = 1:length(map.rxnName)
        a = find(ismember(model.rxns,map.rxnName{i}));
        if isempty(a)
            map2.rxnWidth{i}=1;   
        else
            map2.rxnWidth{i}=rxnWidth(a);
        end
    end

     fluxMap = [map.rxnName map.rxnWidth];

end 