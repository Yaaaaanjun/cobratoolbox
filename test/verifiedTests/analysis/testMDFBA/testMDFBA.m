% The COBRAToolbox: testMDFBA.m
%
% Purpose:
%     - tests whether MDFBA induces fluxes in reactions not seen as active in normal
%     FBA.
%     - Check whether ignoreMets actually ignores the provided metabolites.
%        if not: fail test
%
% Authors:
%     - Thomas Pfau


currentDir = pwd; % save the current path

% initialize the test
fileDir = fileparts(which('testMDFBA'));
cd(fileDir);

% convert the model
model = createToyModelForMDFBA;

solverPkgs = {'gurobi', 'tomlab_cplex', 'ibm_cplex'};
tolerance = 1e-6;
for k = 1:length(solverPkgs)

    % change the COBRA solver (LP)
    solverMILPOK = changeCobraSolver(solverPkgs{k}, 'MILP', 0);
    solverLPOK = changeCobraSolver(solverPkgs{k}, 'LP', 0);

    if solverLPOK == 1 && solverMILPOK == 1
        fprintf(' > Testing MDFBA using %s ...\n', solverPkgs{k});

        res = mdFBA(model);

        %Check that metabolites are excreted.
        assert(all(abs(model.S*res.full - (max([abs(model.lb);model.ub])/10000)) < tolerance ))

        %Check that R4 is now active, while it was inactive before.
        [res2,newAct] = mdFBA(model);
        assert(isequal(model.rxns(4),newAct));
        %The results should not change due to an additional output.
        assert(isequal(res.full,res2.full));

        %Check that is now not active in the optiomal solution, if D, E and
        %F are ignored.
        [res,newAct] = mdFBA(model,'ignoredMets',{'D','C','F'});

        %Check that the objective is lower than an FBA objective, due to
        %the dilution.
        sol = optimizeCbModel(model);
        assert(res.obj < sol.f);

        % add a constraint that restricts the flux over R1 and R2 to a
        % maximum of 500
        modelMod = addCOBRAConstraints(model,{'R1','R2'},500,'dsense','L');
        [res,newAct] = mdFBA(modelMod);
        % with dilution it has to be below 500
        assert(res.obj < 500)
        %and we still activate R4.
        assert(isequal(model.rxns(4),newAct));

    end
end

% delete files generated by some solvers.
if exist('CobraMILPSolver.log', 'file') ~= 0
    delete('CobraMILPSolver.log');
end
if exist('MILPProblem.mat', 'file') == 2
    delete('MILPProblem.mat');
end

% change the directory
cd(currentDir)
